import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:reclaim_flutter_sdk/constants.dart';
import 'package:reclaim_flutter_sdk/exception/exception.dart';
import 'package:reclaim_flutter_sdk/logging/logging.dart';
import 'package:reclaim_flutter_sdk/overrides/overrides.dart';
import 'package:reclaim_flutter_sdk/services/ai_flow_service.dart';
import 'package:reclaim_flutter_sdk/utils/dio.dart';
import 'package:reclaim_flutter_sdk/utils/ip.dart';

import '../types/manual_verification.dart';

extension _DioResponseExtension<T> on Future<Response<T>> {
  static final _logger = logging.child('DioErrorResponse');
  Future<Response<T>> logWhenResponseErrors() async {
    try {
      return await this;
    } on DioException catch (e) {
      final response = e.response?.data;
      _logger.info(response);
      rethrow;
    }
  }
}

abstract interface class SessionUpdateHandler {
  const SessionUpdateHandler();

  Future<String> createSession({
    required String appId,
    required String providerId,
    required String timestamp,
    required String signature,
  });

  Future<void> updateSession(
    String sessionId,
    SessionStatus status,
  );

  Future<void> sendLogs({
    required String appId,
    required String providerId,
    required String sessionId,
    required String logType,
    Map<String, dynamic>? metadata,
  });

  Future<void> dumpNetworkRequests(
    String sessionId,
    List<RequestLog> requestLogs,
    String providerName,
    String providerId,
    Map<String, String> parameters,
    String screenshotUrl,
  ) async {
    final log = logging.child('dumpNetworkRequests');
    final dio = buildDio();
    dio.options.headers['accept'] = '*/*';
    dio.options.headers['accept-language'] = 'en-GB,en-US;q=0.9,en;q=0.8';
    dio.options.headers['Content-Type'] = 'application/json';
    final data = jsonEncode({
      "sessionId": sessionId,
      "networkRequests": requestLogs,
      "screenshotUrl": screenshotUrl,
    });

    final response = await dio
        .post<String>(
          '${ReclaimBackend.MANUAL_VERIFICATION_PREFIX}/dump-requests',
          data: data,
        )
        .logWhenResponseErrors();
    log.finest('Dumped network requests, response: ${response.statusCode}');
  }

  Future<String> getSignedUploadUrlFromS3ForManualVerificationSessionScreenshot(
      String sessionId, String screenshot) async {
    final dio = buildDio();
    final response = await dio.post<String>(
      '${ReclaimBackend.MANUAL_VERIFICATION_PREFIX}/session/$sessionId/get-upload-url',
      options: Options(headers: {
        'Content-Type': 'application/json',
        'accept': '*/*',
        'accept-language': 'en-GB,en-US;q=0.9,en;q=0.8',
      }),
      data: jsonEncode({
        'fileType': 'image/png',
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get pre-signed URL for screenshot upload');
    }

    final url = jsonDecode(response.toString())['url'];

    final uploadResponse = await dio
        .put(url,
            options: Options(headers: {'Content-Type': 'image/png'}),
            data: base64Decode(screenshot))
        .logWhenResponseErrors();

    if (uploadResponse.statusCode != 200) {
      throw Exception('Failed to upload screenshot');
    }

    final urlWithoutQuery = url.split('?').first;

    return urlWithoutQuery;
  }

  Future<Map<String, dynamic>> checkScreenshotWithAI(
      Dio dio, String httpProviderId, String base64Screenshot) async {
    final dio = buildDio();

    final response = await dio.post(
      '${ReclaimBackend.MANUAL_VERIFICATION_PREFIX}/$httpProviderId/check-screenshot',
      data: {'screenshot': base64Screenshot},
    );
    if (response.data['isSuccess']) {
      final aiResult = {
        'isDataShown': response.data['data']['is_data_shown'],
        'isRelatedToLogin': response.data['data']['isRelatedToLogin'],
        'recommendation': response.data['data']['recommendation'],
      };
      return aiResult;
    } else {
      throw Exception('Failed to validate screenshot');
    }
  }

  static Future<Map<String, dynamic>> checkLoggedInStateWithAI(
      String url, String base64Screenshot, String heuristicSummary) async {
    final dio = buildDio();
    final logger = logging.child('checkLoggedInStateWithAI');
    final response = await dio.post(
      '${ReclaimBackend.MANUAL_VERIFICATION_PREFIX}/check-logged-in-state',
      data: {
        'screenshot': base64Screenshot,
        'url': url,
        'heuristicSummary': heuristicSummary
      },
    );
    logger.info('response: $response');
    if (response.data['isSuccess']) {
      final aiResult = {
        'isLoggedIn': response.data['data']['isLoggedIn'],
        'recommendation': response.data['data']['recommendation'],
      };
      return aiResult;
    } else {
      throw Exception('Failed to validate screenshot');
    }
  }

  Future<Map<String, dynamic>> checkLoggedInStateWithAiV2(
      Dio dio, String url, String heuristicSummary) async {
    final logger = logging.child('checkLoggedInStateWithAI');
    final response = await dio.post(
      '${ReclaimBackend.MANUAL_VERIFICATION_PREFIX}/check-logged-in-stateV2',
      data: {'url': url, 'heuristicSummary': heuristicSummary},
    );
    logger.info('response: $response');
    if (response.data['isSuccess']) {
      final aiResult = {
        'isLoggedIn': response.data['data']['isLoggedIn'],
        'recommendation': response.data['data']['recommendation'],
      };
      return aiResult;
    } else {
      throw Exception('Failed to validate screenshot');
    }
  }

  Future<void> createManualVerificationSession(
      CreateManualVerificationSessionPayload payload) async {
    final dio = buildDio();
    dio.options.headers['accept'] = '*/*';
    dio.options.headers['accept-language'] = 'en-GB,en-US;q=0.9,en;q=0.8';
    dio.options.headers['Content-Type'] = 'application/json';

    final data = jsonEncode(payload);
    logging.info({
      'msg': 'Creating manual verification session',
      'request': data,
    });

    final response = await dio
        .post<String>(
          '${ReclaimBackend.MANUAL_VERIFICATION_PREFIX}/session',
          data: data,
        )
        .logWhenResponseErrors();
    logging.info({
      'msg': 'Manual verification session created',
      'response': response,
    });
  }

  Future<Map<String, dynamic>> getManualVerificationSessionStatus(
      String sessionId) async {
    final logger = logging.child('getManualVerificationSessionStatus');
    try {
      final dio = buildDio();
      final response = await dio.get<String>(
        '${ReclaimBackend.MANUAL_VERIFICATION_PREFIX}/session/$sessionId',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.toString());
        final sessionData = data['session'];
        final Map<String, dynamic>? claim =
            sessionData['aiReceipt']?['claim'] as Map<String, dynamic>?;
        logger.info('Session Retrieved');
        logger.info(claim);
        return {'status': sessionData['status'], 'claim': claim};
      } else {
        throw Exception(
            'Failed to get session status. Status code: ${response.statusCode}');
      }
    } catch (error, stackTrace) {
      logger.severe('Error getting manual verification session status', error,
          stackTrace);
      rethrow;
    }
  }
}

class _DefaultSessionUpdateHandler extends SessionUpdateHandler {
  const _DefaultSessionUpdateHandler();

  @override
  @mustCallSuper
  Future<String> createSession({
    required String appId,
    required String providerId,
    required String timestamp,
    required String signature,
  }) async {
    final logger = logging.child('createSession');
    try {
      final dio = buildDio();
      dio.options.headers['Content-Type'] = 'application/json';
      logger.info('Initializing session');
      final data = json.encode({
        'providerId': providerId,
        'appId': appId,
        'timestamp': timestamp,
        'signature': signature,
      });
      logger.info('Creating session: $data');
      final response = await dio
          .post<String>(
            ReclaimBackend.SESSION_INIT,
            data: data,
          )
          .logWhenResponseErrors();
      logger.info('Session created successfully response :$response');
      final sessionData = json.decode(response.data ?? '');
      return sessionData['sessionId'];
    } catch (error, stackTrace) {
      if (error is DioException && error.response != null) {
        logger.severe(
          'Error creating session. Status code: ${error.response?.statusCode}. Response: ${error.response?.data}',
          error,
          stackTrace,
        );
        final data = error.response?.data;
        if (data is String &&
            data.toLowerCase().contains('session already exists')) {
          throw const ReclaimExpiredSessionException();
        }
      } else {
        logger.severe('Error creating session', error, stackTrace);
      }
      throw const ReclaimInitSessionException();
    }
  }

  @override
  @mustCallSuper
  Future<void> updateSession(String sessionId, SessionStatus status) async {
    final logger = logging.child('ReclaimSession.updateSession');
    try {
      final dio = buildDio();
      dio.options.headers['Content-Type'] = 'application/json';

      // Get device information
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String brand = '';
      String model = '';
      String deviceId = '';

      if (defaultTargetPlatform == TargetPlatform.android) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        brand = androidInfo.brand;
        model = androidInfo.model;
        deviceId = androidInfo.id;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        brand = 'Apple';
        model = iosInfo.utsname.machine;
        deviceId = iosInfo.identifierForVendor ?? '';
      }

      // Get public IP address
      final String publicIpAddress = await getPublicIp();

      final data = json.encode(
        {
          'sessionId': sessionId,
          'status': sessionStatusStrings[status],
          'deviceId': deviceId,
          'deviceType': '$brand $model',
          'publicIpAddress': publicIpAddress,
        },
      );

      logger.info('Updating session: $data');
      await dio
          .post<String>(
            ReclaimBackend.SESSION_URL,
            data: data,
          )
          .logWhenResponseErrors();
    } catch (error, stackTrace) {
      logger.severe('Error updating session', error, stackTrace);
      if (error is DioException && error.response != null) {
        final data = error.response?.data;
        if (data is String &&
            [
              // Response message when using a session id that's has already completed with a failure
              'session already failed. cannot update it!',
              // Response message when using a session id that's has already completed successfully
              'invalid status',
            ].any(data.toLowerCase().contains)) {
          logger.info('Session expired');
          throw const ReclaimExpiredSessionException();
        }
      }
    }
  }

  @override
  @mustCallSuper
  Future<void> sendLogs({
    required String appId,
    required String providerId,
    required String sessionId,
    required String logType,
    Map<String, dynamic>? metadata,
  }) async {
    final logger = logging.child('utils.sendLogs');

    try {
      // Get device information
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String brand = '';
      String model = '';
      String deviceId = '';

      if (defaultTargetPlatform == TargetPlatform.android) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        brand = androidInfo.brand;
        model = androidInfo.model;
        deviceId = androidInfo.id;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        brand = 'Apple';
        model = iosInfo.utsname.machine;
        deviceId = iosInfo.identifierForVendor ?? '';
      }

      // Get public IP address
      String publicIpAddress = await getPublicIp();

      // Prepare the body of the POST request
      Map<String, dynamic> data = {
        'sessionId': sessionId,
        'date': DateTime.now().toUtc().toIso8601String(),
        'deviceId': deviceId,
        'deviceType': '$brand $model',
        'providerId': providerId,
        'applicationId': appId,
        'publicIpAddress': publicIpAddress,
        'logType': logType,
        if (metadata != null) 'metadata': metadata,
      };

      // Send the POST request
      final dio = buildDio();
      dio.options.headers['Content-Type'] = 'application/json';
      final response = await dio
          .post<String>(
            ReclaimBackend.LOGS_API,
            data: jsonEncode(data),
          )
          .logWhenResponseErrors();

      if (response.statusCode != 200) {
        logger.info(
            'Failed to Send logs, response status: ${response.statusCode}');
      }
    } catch (error, stackTrace) {
      logger.severe('Error sending logs to backend server', error, stackTrace);
    }
  }
}

class _SessionUpdateHandlerImpl extends _DefaultSessionUpdateHandler {
  const _SessionUpdateHandlerImpl();

  @override
  Future<String> createSession({
    required String appId,
    required String providerId,
    required String timestamp,
    required String signature,
  }) async {
    final createSession = ReclaimOverrides.session?.createSession;
    if (createSession != null) {
      final sessionId = await createSession(
        appId: appId,
        providerId: providerId,
        timestamp: timestamp,
        signature: signature,
      );
      if (sessionId == null) {
        throw const ReclaimInitSessionException();
      }
      return sessionId;
    }
    return super.createSession(
      appId: appId,
      providerId: providerId,
      timestamp: timestamp,
      signature: signature,
    );
  }

  @override
  Future<void> updateSession(
    String sessionId,
    SessionStatus status,
  ) async {
    final updateSession = ReclaimOverrides.session?.updateSession;
    if (updateSession != null) {
      final isSessionOk = await updateSession(sessionId, status);
      if (!isSessionOk) {
        throw const ReclaimExpiredSessionException();
      }
      return;
    }
    return super.updateSession(sessionId, status);
  }

  @override
  Future<void> sendLogs({
    required String appId,
    required String providerId,
    required String sessionId,
    required String logType,
    Map<String, dynamic>? metadata,
  }) async {
    final logRecord = ReclaimOverrides.session?.logRecord;
    if (logRecord != null) {
      logRecord(
        appId: appId,
        sessionId: sessionId,
        providerId: providerId,
        logType: logType,
        metadata: metadata,
      );
      return;
    }
    return super.sendLogs(
      appId: appId,
      providerId: providerId,
      sessionId: sessionId,
      logType: logType,
      metadata: metadata,
    );
  }

  Future<List<AIFlowDataReceipt>> extractParamsFromHtml(
    Dio dio,
    String url,
    String html,
    List<String> descriptionParts, String sessionId,
  ) async {
    final log = logging.child('extractParamsFromHtml');
    final dio = buildDio();
    dio.options.headers['accept'] = '*/*';
    dio.options.headers['accept-language'] = 'en-GB,en-US;q=0.9,en;q=0.8';
    dio.options.headers['Content-Type'] = 'application/json';
    final data = jsonEncode({
      "url": url,
      "fullHtml": html,
      "requestedParams": descriptionParts,
      'sessionId': sessionId
    });

    final response = await dio
        .post<dynamic>(
          '${ReclaimBackend.MANUAL_VERIFICATION_PREFIX}/extract-params-from-html',
          data: data,
        )
        .logWhenResponseErrors();
    log.finest('Extracted params from html, response: ${response.statusCode}');
    final result = jsonDecode(response.toString());
    final List<dynamic> params = result['params'] as List<dynamic>;
    
    return params.map((e) => AIFlowDataReceipt.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> checkLoggedInStateWithAIV2(
      Dio dio,
      String url, String heuristicSummary) async {
    final logger = logging.child('checkLoggedInStateWithAI');
    final response = await dio.post(
      '${ReclaimBackend.MANUAL_VERIFICATION_PREFIX}/check-logged-in-stateV2',
      data: {'url': url, 'heuristicSummary': heuristicSummary},
    );
    logger.info('response: $response');
    if (response.data['isSuccess']) {
      final aiResult = {
        'isLoggedIn': response.data['data']['isLoggedIn'],
        'recommendation': response.data['data']['recommendation'],
      };
      return aiResult;
    } else {
      throw Exception('Failed to validate screenshot');
    }
  }
}

const ReclaimSession = _SessionUpdateHandlerImpl();
