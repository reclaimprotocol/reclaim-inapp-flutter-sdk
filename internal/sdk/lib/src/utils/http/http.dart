import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cronet_http/cronet_http.dart' as cronet;
import 'package:cupertino_http/cupertino_http.dart' as cupertino;
import 'package:http/http.dart' as http;
import 'package:http/retry.dart' as http_retry;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import '../../logging/logging.dart';
import '../../services/source/source.dart';
import 'status_codes.dart';

Directory _getCacheDir([String? cacheDirName]) {
  final tempDir = Directory.systemTemp;
  if (cacheDirName == null) {
    return tempDir.createTempSync('http_cache');
  }
  final cacheDir = Directory(path.join(tempDir.path, cacheDirName));
  if (!cacheDir.existsSync()) {
    cacheDir.createSync(recursive: true);
  }
  return cacheDir;
}

final _buildClientLogger = logging.child('http.buildClient');

http.Client _buildClientWithDefaultCaching() {
  _buildClientLogger.config('Building client with default caching');
  if (Platform.isAndroid) {
    return cronet.CronetClient.fromCronetEngine(
      cronet.CronetEngine.build(enableBrotli: true, enableHttp2: true, enableQuic: true),
      closeEngine: true,
    );
  } else if (Platform.isIOS || Platform.isMacOS) {
    final config = cupertino.URLSessionConfiguration.defaultSessionConfiguration();
    config.discretionary = true;
    config.allowsCellularAccess = true;
    config.allowsConstrainedNetworkAccess = true;
    config.allowsExpensiveNetworkAccess = true;
    return cupertino.CupertinoClient.fromSessionConfiguration(config);
  }
  return http.Client();
}

http.Client _buildClient([String? cacheDirName]) {
  final cacheDir = _getCacheDir(cacheDirName);
  _buildClientLogger.config('Building client with cache dir $cacheDir');
  try {
    if (Platform.isAndroid) {
      return cronet.CronetClient.fromCronetEngine(
        cronet.CronetEngine.build(
          cacheMode: cronet.CacheMode.disk,
          // 200MB cache
          cacheMaxSize: 200 * 1024 * 1024,
          storagePath: cacheDir.path,
          enableBrotli: true,
          enableHttp2: true,
          enableQuic: true,
        ),
        closeEngine: true,
      );
    } else if (Platform.isIOS || Platform.isMacOS) {
      final config = cupertino.URLSessionConfiguration.defaultSessionConfiguration();
      config.discretionary = true;
      config.cache = cupertino.URLCache.withCapacity(
        memoryCapacity: 200 * 1024 * 1024,
        diskCapacity: 200 * 1024 * 1024,
        directory: cacheDir.uri,
      );
      config.allowsCellularAccess = true;
      config.allowsConstrainedNetworkAccess = true;
      config.allowsExpensiveNetworkAccess = true;
      return cupertino.CupertinoClient.fromSessionConfiguration(config);
    }
  } catch (e, s) {
    _buildClientLogger.severe('Error building client', e, s);
    // fallback with a client that has default caching mechanism
    try {
      return _buildClientWithDefaultCaching();
    } catch (e, s) {
      _buildClientLogger.severe('Error building client with default caching', e, s);
    }
  }
  return http.Client();
}

class _RetryableHttpException extends http.ClientException {
  _RetryableHttpException(super.message, [super.uri]);
}

class _RetryableResponseHttpClient extends http.BaseClient {
  _RetryableResponseHttpClient(this.inner);

  final http.Client inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await inner.send(request);
    if (isHttpResponseStatusRetryable(response.statusCode)) {
      throw _RetryableHttpException(_createMessage(response, request.url), request.url);
    }
    return response;
  }

  String _createMessage(http.BaseResponse response, Uri url) {
    var message = 'Request to $url failed with status ${response.statusCode}';
    if (response.reasonPhrase != null) {
      message = '$message: ${response.reasonPhrase}';
    }
    return message;
  }

  @override
  void close() {
    inner.close();
  }
}

class ReclaimHttpClient extends http.BaseClient {
  ReclaimHttpClient({String? cacheDirName, this.canSetClientSource = true}) : _cacheDirName = cacheDirName;

  final String? _cacheDirName;
  final bool canSetClientSource;

  late final Completer<http.Client> _innerHttpClientCompleter = _buildInnerHttpClient();

  @visibleForTesting
  static http.Client? testClient;

  http.Client _buildRetryClient() {
    return http_retry.RetryClient(
      _RetryableResponseHttpClient(_buildClient(_cacheDirName)),
      retries: 6,
      whenError: (e, s) {
        if (_isClosed) {
          return false;
        }
        logging.warning('Http failed. Checking if we can retry..', e);
        return e is SocketException ||
            e is TimeoutException ||
            e.toString().contains('net::ERR_TIMED_OUT') ||
            e is _RetryableHttpException;
      },
    );
  }

  Completer<http.Client> _buildInnerHttpClient() {
    final completer = Completer<http.Client>();
    () async {
      try {
        final client = testClient ?? _buildRetryClient();
        completer.complete(client);
      } catch (e, s) {
        completer.completeError(e, s);
      }
    }();
    return completer;
  }

  Future<T> _runWithClient<T>(FutureOr<T> Function(http.Client client) fn) async {
    final inner = await _innerHttpClientCompleter.future;
    return fn(inner);
  }

  static String? _clientSource;

  Future<void> setClientSource(http.BaseRequest request) async {
    if (!canSetClientSource) return;
    try {
      request.headers['reclaim-api-client'] = _clientSource ??= await getClientSource();
    } catch (e, s) {
      // request headers are not mutable, request may be finalized
      logging.warning('Failed to add reclaim-api-client header', e, s);
    }
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    await setClientSource(request);
    return _runWithClient((client) => client.send(request));
  }

  bool _isClosed = false;

  @override
  void close() {
    _isClosed = true;
    _runWithClient((client) {
      return client.close();
    });
  }
}

extension JsonDecodeResponse on http.Response {
  dynamic get bodyAsJson {
    return json.decode(body);
  }

  bool get isSuccess {
    return statusCode >= 200 && statusCode < 300;
  }
}

extension JsonDecodeResponseFuture on Future<http.Response> {
  Future<dynamic> get bodyAsJson {
    return then((response) => response.bodyAsJson);
  }
}
