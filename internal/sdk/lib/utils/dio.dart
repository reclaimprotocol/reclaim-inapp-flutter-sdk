import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:native_dio_adapter/native_dio_adapter.dart';

import 'package:reclaim_flutter_sdk/logging/logging.dart';

import 'interceptor/api_client.dart';

Dio buildDio() {
  final logger = logging.child('buildDio.RetryInterceptor');
  final dio = Dio();
  if (!Platform.environment.containsKey('FLUTTER_TEST')) {
    dio.httpClientAdapter = NativeAdapter(
      createCupertinoConfiguration: () {
        return URLSessionConfiguration.ephemeralSessionConfiguration();
      },
      createCronetEngine: () {
        return CronetEngine.build(
          cacheMode: CacheMode.disk,
          enableBrotli: true,
          enableHttp2: true,
          enableQuic: true,
        );
      },
    );
  }
  dio.interceptors.add(ApiClientInsertionInterceptor());
  dio.interceptors.add(RetryInterceptor(
    dio: dio,
    logPrint: logger.finest,
    retries: 3,
    retryDelays: const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
    ],
    retryEvaluator: ReclaimDioRetryEvaluator({
      ...defaultRetryableStatuses,
    }).evaluate,
  ));
  return dio;
}

class ReclaimDioRetryEvaluator {
  ReclaimDioRetryEvaluator(this._retryableStatuses);

  final Set<int> _retryableStatuses;
  int currentAttempt = 0;

  /// Returns true only if the response hasn't been cancelled
  ///   or got a bad status code.
  // ignore: avoid-unused-parameters
  FutureOr<bool> evaluate(DioException error, int attempt) {
    final log = logging.child('ReclaimDioRetryEvaluator.evaluate');
    bool shouldRetry;
    if (error.type == DioExceptionType.unknown ||
        error.toString().contains('net::ERR_TIMED_OUT')) {
      log.warning(
        {
          "reason": "An Unknown client error occurred",
          "exception": error.toString(),
        },
        error.error,
        error.stackTrace,
      );
      shouldRetry = true;
    } else if (error.type == DioExceptionType.badResponse) {
      final statusCode = error.response?.statusCode;
      if (statusCode != null) {
        shouldRetry = isRetryable(statusCode);
      } else {
        shouldRetry = true;
      }
    } else {
      shouldRetry = error.type != DioExceptionType.cancel &&
          error.error is! FormatException;
    }
    currentAttempt = attempt;
    return shouldRetry;
  }

  bool isRetryable(int statusCode) => _retryableStatuses.contains(statusCode);
}
