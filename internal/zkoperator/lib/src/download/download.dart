import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:cronet_http/cronet_http.dart' as cronet;
import 'package:cupertino_http/cupertino_http.dart' as cupertino;
import 'package:logging/logging.dart';
import 'package:retry/retry.dart';
import 'package:path/path.dart' as path;

import 'package:flutter/services.dart';

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

final _buildClientLogger = Logger('reclaim_flutter_sdk.reclaim_gnark_zkoperator._buildClient');

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
    return _buildClientWithDefaultCaching();
  }
  return http.Client();
}

class _RetryableHttpException extends http.ClientException {
  _RetryableHttpException(super.message, [super.uri]);
}

class _EmptyResponseException extends http.ClientException {
  _EmptyResponseException(String message, [Uri? uri]) : super('Empty response: $message', uri);
}

extension _ReadUnstreamed on http.Client {
  String _createMessage(http.BaseResponse response, Uri url) {
    var message = 'Request to $url failed with status ${response.statusCode}';
    if (response.reasonPhrase != null) {
      message = '$message: ${response.reasonPhrase}';
    }
    return message;
  }

  Future<Uint8List> readUnstreamed(Uri uri) async {
    final request = http.Request('GET', uri);
    final streamedResponse = await send(request);
    final bodyBytes = await streamedResponse.stream.toBytes();
    final statusCode = streamedResponse.statusCode;
    if (statusCode >= 500) {
      throw _RetryableHttpException(_createMessage(streamedResponse, uri), uri);
    }
    if (bodyBytes.isEmpty) {
      throw _EmptyResponseException(_createMessage(streamedResponse, uri), uri);
    }
    return bodyBytes;
  }
}

final Map<String, http.Client> _cachedClients = {};

final _downloadWithHttpLogger = Logger('reclaim_flutter_sdk.reclaim_gnark_zkoperator.downloadWithHttp');

Future<Uint8List?> downloadWithHttp(
  String url, {

  /// When null, a new client is built for each use.
  /// This should be unique for each isolate, otherwise it will cause an illegal state exception on android
  /// and then a default caching mechanism on androids is used as a fallback.
  String? cacheDirName,
}) async {
  final isUsingCommonClient = cacheDirName != null;
  _downloadWithHttpLogger.config(
    'Downloading $url with: cache dir $cacheDirName, isUsingCommonClient $isUsingCommonClient',
  );
  final uri = Uri.parse(url);
  final client =
      isUsingCommonClient
          // Only build the client once if [_cachedClients[cacheDirName]] is null
          ? (_cachedClients[cacheDirName] ??= _buildClient(cacheDirName))
          // Build a new client for each download
          : _buildClient();

  try {
    final response = await retry(
      () {
        return client.readUnstreamed(uri);
      },
      // Retry on SocketException or TimeoutException or _RetryableHttpException
      retryIf: (e) {
        return e is SocketException ||
            e is TimeoutException ||
            e.toString().contains('net::ERR_TIMED_OUT') ||
            e is _RetryableHttpException ||
            e is _EmptyResponseException;
      },
    );
    return response;
  } catch (_) {
    rethrow;
  } finally {
    if (!isUsingCommonClient) {
      client.close();
    }
  }
}
