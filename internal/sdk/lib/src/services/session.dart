import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants.dart';
import '../data/session_init.dart';
import '../exception/exception.dart';
import '../logging/logging.dart';
import '../overrides/overrides.dart';
import '../utils/dio.dart';
import '../utils/ip.dart';

export '../data/session_init.dart';

final _sessionHttpClient = buildDio();

enum SessionStatus {
  USER_STARTED_VERIFICATION,
  USER_INIT_VERIFICATION,
  PROOF_GENERATION_STARTED,
  PROOF_GENERATION_RETRY,
  PROOF_GENERATION_SUCCESS,
  PROOF_GENERATION_FAILED,
  PROOF_SUBMITTED,
  PROOF_SUBMISSION_FAILED,
  // This spelling mistake is intentional to match the backend.
  PROOF_MANUAL_VERIFICATION_SUBMITED,
}

extension _DioResponseExtension<T> on Future<Response<T>> {
  static final _logger = logging.child('DioErrorResponse');
  Future<Response<T>> logWhenResponseErrors() async {
    try {
      return await this;
    } on DioException catch (e, s) {
      _logger.warning('response failed', e, s);
      final response = e.response?.data;
      _logger.info(response);
      rethrow;
    }
  }
}

abstract interface class SessionUpdateHandler {
  const SessionUpdateHandler();

  Future<SessionInitResponse> createSession({
    required String appId,
    required String providerId,
    required String timestamp,
    required String signature,
    required String providerVersion,
  });

  /// Implementations should throw [ReclaimExpiredSessionException] for expired sessions.
  Future<void> updateSession(String sessionId, SessionStatus status, {Map<String, dynamic>? metadata});

  Future<void> sendLogs({
    required String appId,
    required String providerId,
    required String sessionId,
    required String logType,
    Map<String, dynamic>? metadata,
  });
}

class _DefaultSessionUpdateHandler extends SessionUpdateHandler {
  const _DefaultSessionUpdateHandler();

  @override
  @mustCallSuper
  Future<SessionInitResponse> createSession({
    required String appId,
    required String providerId,
    required String timestamp,
    required String signature,
    required String providerVersion,
  }) async {
    final logger = logging.child('createSession');
    try {
      _sessionHttpClient.options.headers['Content-Type'] = 'application/json';
      logger.info('Initializing session');
      final data = json.encode({
        'providerId': providerId,
        'appId': appId,
        'timestamp': timestamp,
        'signature': signature,
        'versionNumber': providerVersion,
      });
      logger.info('Creating session: $data');
      final response =
          await _sessionHttpClient.post<String>(ReclaimUrls.SESSION_INIT, data: data).logWhenResponseErrors();
      logger.info('Session created successfully response :$response');
      final sessionData = json.decode(response.data ?? '');
      return SessionInitResponse.fromJson({...sessionData as Map});
    } catch (error, stackTrace) {
      if (error is DioException && error.response != null) {
        logger.severe(
          'Error creating session. Status code: ${error.response?.statusCode}. Response: ${error.response?.data}',
          error,
          stackTrace,
        );
        final data = error.response?.data;
        if (data is String && data.toLowerCase().contains('session already exists')) {
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
  Future<void> updateSession(String sessionId, SessionStatus status, {Map<String, dynamic>? metadata}) async {
    final logger = logging.child('ReclaimSession.updateSession');
    try {
      _sessionHttpClient.options.headers['Content-Type'] = 'application/json';

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

      final data = json.encode({
        'sessionId': sessionId,
        'status': status.name,
        'deviceId': deviceId,
        'deviceType': '$brand $model',
        'publicIpAddress': publicIpAddress,
        if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
      });

      logger.info('Updating session: $data');
      await _sessionHttpClient.post<String>(ReclaimUrls.SESSION_URL, data: data).logWhenResponseErrors();
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

      _sessionHttpClient.options.headers['Content-Type'] = 'application/json';
      final response =
          await _sessionHttpClient.post<String>(ReclaimUrls.LOGS_API, data: json.encode(data)).logWhenResponseErrors();

      if (response.statusCode != 200) {
        logger.info('Failed to Send logs, response status: ${response.statusCode}');
      }
    } catch (error, stackTrace) {
      logger.severe('Error sending logs to backend server', error, stackTrace);
    }
  }
}

class _SessionUpdateHandlerImpl extends _DefaultSessionUpdateHandler {
  const _SessionUpdateHandlerImpl();

  @override
  Future<SessionInitResponse> createSession({
    required String appId,
    required String providerId,
    required String timestamp,
    required String signature,
    required String providerVersion,
  }) async {
    final createSession = ReclaimOverrides.session?.createSession;
    if (createSession != null) {
      final session = await createSession(
        appId: appId,
        providerId: providerId,
        timestamp: timestamp,
        signature: signature,
        providerVersion: providerVersion,
      );
      final sessionId = session?.sessionId;
      if (session == null || sessionId == null || sessionId.isEmpty) {
        throw const ReclaimInitSessionException();
      }
      return session;
    }
    return super.createSession(
      appId: appId,
      providerId: providerId,
      timestamp: timestamp,
      signature: signature,
      providerVersion: providerVersion,
    );
  }

  @override
  Future<void> updateSession(String sessionId, SessionStatus status, {Map<String, dynamic>? metadata}) async {
    final updateSession = ReclaimOverrides.session?.updateSession;
    if (updateSession != null) {
      final isSessionOk = await updateSession(sessionId, status, metadata);
      if (!isSessionOk) {
        throw const ReclaimExpiredSessionException();
      }
      return;
    }
    return super.updateSession(sessionId, status, metadata: metadata);
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
      logRecord(appId: appId, sessionId: sessionId, providerId: providerId, logType: logType, metadata: metadata);
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
}

const ReclaimSession = _SessionUpdateHandlerImpl();
