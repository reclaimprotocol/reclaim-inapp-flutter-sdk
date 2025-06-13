// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_cache_manager/src/cache_store.dart';
import 'package:flutter_cache_manager/src/web/mime_converter.dart';
import 'package:flutter_cache_manager/src/web/web_helper.dart';

import 'dio.dart';

class ReclaimCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'libReclaimCachedImageData';

  static final ReclaimCacheManager _instance = ReclaimCacheManager._();

  factory ReclaimCacheManager() {
    return _instance;
  }

  ReclaimCacheManager.custom(
    super.config, {
    super.cacheStore,
    super.webHelper,
    // ignore: invalid_use_of_visible_for_testing_member
  }) : super.custom();

  factory ReclaimCacheManager._() {
    final config = Config(key);
    final cache = CacheStore(config);
    final helper = WebHelper(cache, HttpFileService());

    return ReclaimCacheManager.custom(config, cacheStore: cache, webHelper: helper);
  }
}

final _httpClient = buildDio();

class HttpFileService extends FileService {
  HttpFileService();

  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) async {
    final httpResponse = await _httpClient.get<List<int>>(
      url,
      options: Options(headers: headers, responseType: ResponseType.bytes),
    );

    return HttpDioGetResponse(httpResponse);
  }
}

/// Basic implementation of a [FileServiceResponse] for http requests.
class HttpDioGetResponse implements FileServiceResponse {
  HttpDioGetResponse(this._response);

  final DateTime _receivedTime = clock.now();

  final Response<List<int>> _response;

  @override
  int get statusCode => _response.statusCode ?? 0;

  String? _header(String name) {
    return _response.headers[name]?.firstOrNull;
  }

  @override
  Stream<List<int>> get content => Stream.value(_response.data ?? const []);

  @override
  int? get contentLength => _response.data?.length;

  @override
  DateTime get validTill {
    // Without a cache-control header we keep the file for a week
    var ageDuration = const Duration(days: 7);
    final controlHeader = _header(HttpHeaders.cacheControlHeader);
    if (controlHeader != null) {
      final controlSettings = controlHeader.split(',');
      for (final setting in controlSettings) {
        final sanitizedSetting = setting.trim().toLowerCase();
        if (sanitizedSetting == 'no-cache') {
          ageDuration = Duration.zero;
        }
        if (sanitizedSetting.startsWith('max-age=')) {
          final validSeconds = int.tryParse(sanitizedSetting.split('=')[1]) ?? 0;
          if (validSeconds > 0) {
            ageDuration = Duration(seconds: validSeconds);
          }
        }
      }
    }

    return _receivedTime.add(ageDuration);
  }

  @override
  String? get eTag => _header(HttpHeaders.etagHeader);

  @override
  String get fileExtension {
    var fileExtension = '';
    final contentTypeHeader = _header(HttpHeaders.contentTypeHeader);
    if (contentTypeHeader != null) {
      final contentType = ContentType.parse(contentTypeHeader);
      fileExtension = contentType.fileExtension;
    }
    return fileExtension;
  }
}
