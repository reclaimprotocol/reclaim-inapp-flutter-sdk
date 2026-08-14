import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../attestor/data/data.dart';
import '../constants.dart';
import '../data/session_init.dart';
import '../exception/exception.dart';
import '../logging/logging.dart';
import '../overrides/overrides.dart';
import '../utils/dio.dart';
import '../utils/ip.dart';
import 'logging.dart';

export '../data/session_init.dart';

final _sessionHttpClient = buildDio();

@Deprecated('Prefer using LogEventType')
enum SessionStatus {
  USER_STARTED_VERIFICATION,
  USER_INIT_VERIFICATION,
  USER_INTERACTED,
  USER_TYPED,
  PROOF_GENERATION_STARTED,
  PROOF_GENERATION_RETRY,
  PROOF_GENERATION_SUCCESS,
  PROOF_GENERATION_FAILED,
  PROOF_SUBMITTED,
  AI_PROOF_SUBMITTED,
  PROOF_SUBMISSION_FAILED,
  // This spelling mistake is intentional to match the backend.
  PROOF_MANUAL_VERIFICATION_SUBMITED;

  LogEventType toLogEventType() {
    return switch (this) {
      SessionStatus.USER_STARTED_VERIFICATION => LogEventType.USER_STARTED_VERIFICATION,
      SessionStatus.USER_INIT_VERIFICATION => LogEventType.USER_INIT_VERIFICATION,
      SessionStatus.USER_INTERACTED => LogEventType.USER_INTERACTED,
      SessionStatus.USER_TYPED => LogEventType.USER_TYPED,
      SessionStatus.PROOF_GENERATION_STARTED => LogEventType.PROOF_GENERATION_STARTED,
      SessionStatus.PROOF_GENERATION_RETRY => LogEventType.PROOF_GENERATION_RETRY,
      SessionStatus.PROOF_GENERATION_SUCCESS => LogEventType.PROOF_GENERATION_SUCCESS,
      SessionStatus.PROOF_GENERATION_FAILED => LogEventType.PROOF_GENERATION_FAILED,
      SessionStatus.PROOF_SUBMITTED => LogEventType.PROOF_SUBMITTED,
      SessionStatus.AI_PROOF_SUBMITTED => LogEventType.AI_PROOF_SUBMITTED,
      SessionStatus.PROOF_SUBMISSION_FAILED => LogEventType.PROOF_SUBMISSION_FAILED,
      SessionStatus.PROOF_MANUAL_VERIFICATION_SUBMITED => LogEventType.PROOF_MANUAL_VERIFICATION_SUBMITTED,
    };
  }
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

class SessionAttestorAuthRequest {
  final String appId;
  final String providerId;
  final String sessionId;
  final String signature;
  final String timestamp;
  final String resolvedVersion;

  const SessionAttestorAuthRequest({
    required this.appId,
    required this.providerId,
    required this.sessionId,
    required this.signature,
    required this.timestamp,
    required this.resolvedVersion,
  });

  Map<String, Object?> toJson() {
    return {
      'appId': appId,
      'providerId': providerId,
      'sessionId': sessionId,
      'signature': signature,
      'timestamp': timestamp,
      'resolvedVersion': resolvedVersion,
    };
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

  Future<void> requestAttestorAuth(SessionAttestorAuthRequest sessionAttestorAuthRequest);

  Future<void> sendLogs({
    required String appId,
    required String providerId,
    required String sessionId,
    required LogEventType logType,
    Map<String, dynamic>? metadata,
  });

  Future<void> sendErrorCallback({required String sessionId, required Map<String, dynamic> error, String? callbackUrl});
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
      logger.info('Creating session for provider=$providerId, app=$appId');
      logger.finer('Session create payload: $data');
      final response = await _sessionHttpClient
          .post<String>(ReclaimUrls.SESSION_INIT, data: data)
          .logWhenResponseErrors();
      logger.info('Session created successfully response: $response');
      final sessionData = json.decode(response.data ?? '');
      return SessionInitResponse.fromJson({...sessionData as Map});
    } catch (error, stackTrace) {
      if (error is DioException && error.response != null) {
        logger.event(
          Level.SEVERE.withEvent(LogEventType.RECLAIM_INIT_SESSION_EXCEPTION),
          'Error creating session. Status code: ${error.response?.statusCode}. Response: ${error.response?.data}',
          error,
          stackTrace,
        );
        final data = error.response?.data;
        final statusCode = error.response?.statusCode;
        final isInvalidStatus = statusCode != null && statusCode >= 400 && statusCode < 500;
        if (data is String && data.toLowerCase().contains('session already exists') || isInvalidStatus) {
          logger.event(
            Level.SEVERE.withEvent(LogEventType.RECLAIM_EXPIRED_SESSION_EXCEPTION),
            'Error creating session. Status code: ${error.response?.statusCode}. Response: ${error.response?.data}',
            error,
            stackTrace,
          );
          String? message;
          try {
            final msg = data is String ? json.decode(data)['message'] : null;
            if (msg is String) {
              message = msg;
            }
          } catch (_) {}
          throw ReclaimExpiredSessionException(message);
        }
      } else {
        logger.event(
          Level.SEVERE.withEvent(LogEventType.RECLAIM_INIT_SESSION_EXCEPTION),
          'Error creating session',
          error,
          stackTrace,
        );
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
      String deviceType = '';
      String deviceId = '';
      String osVersion = '';

      if (defaultTargetPlatform == TargetPlatform.android) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceType = '${androidInfo.brand} ${androidInfo.model}';
        deviceId = androidInfo.id;
        osVersion = 'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceType = 'Apple ${iosInfo.modelName}';
        deviceId = iosInfo.identifierForVendor ?? '';
        osVersion = '${iosInfo.systemName} ${iosInfo.systemVersion}';
      }
      if (deviceId.trim().isEmpty || deviceId.trim().replaceAll('-', '').replaceAll('0', '').isEmpty) {
        try {
          final diagnosticLoggingId = await DiagnosticLogging.getDeviceLoggingId();
          deviceId = 'diagid-$diagnosticLoggingId';
        } catch (e, s) {
          logger.warning('Failed to get device logging id', e, s);
        }
      }

      // Get public IP address
      final String publicIpAddress = await getPublicIp();

      final data = json.encode({
        'sessionId': sessionId,
        'status': status.name,
        'deviceId': deviceId,
        'deviceType': deviceType,
        'osVersion': osVersion,
        'publicIpAddress': publicIpAddress,
        if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
      });

      logger.info('Updating session=$sessionId, status=${status.name}');
      logger.finer('Session update payload: $data');
      final response = await _sessionHttpClient
          .post<String>(ReclaimUrls.SESSION_URL, data: data)
          .logWhenResponseErrors();
      final statusCode = response.statusCode;
      final isInvalidStatus = statusCode != null && statusCode >= 400 && statusCode < 500;
      if (isInvalidStatus) {
        logger.event(Level.SEVERE.withEvent(LogEventType.RECLAIM_EXPIRED_SESSION_EXCEPTION), 'Session expired');
        throw const ReclaimExpiredSessionException();
      }
    } catch (error, stackTrace) {
      logger.severe('Error updating session', error, stackTrace);
      if (error is DioException && error.response != null) {
        final data = error.response?.data;
        final statusCode = error.response?.statusCode;
        final isInvalidStatus = statusCode != null && statusCode >= 400 && statusCode < 500;
        if (data is String &&
                [
                  // Response message when using a session id that's has already completed with a failure
                  'session already failed. cannot update it!',
                  // Response message when using a session id that's has already completed successfully
                  'invalid status',
                ].any(data.toLowerCase().contains) ||
            isInvalidStatus) {
          logger.event(Level.SEVERE.withEvent(LogEventType.RECLAIM_EXPIRED_SESSION_EXCEPTION), 'Session expired');
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
    required LogEventType logType,
    Map<String, dynamic>? metadata,
  }) async {
    final logger = logging.child('utils.sendLogs');

    try {
      // Get device information
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String deviceType = '';
      String deviceId = '';
      String osVersion = '';

      if (defaultTargetPlatform == TargetPlatform.android) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceType = '${androidInfo.brand} ${androidInfo.model}';
        deviceId = androidInfo.id;
        osVersion = 'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceType = 'Apple ${iosInfo.modelName}';
        deviceId = iosInfo.identifierForVendor ?? '';
        osVersion = '${iosInfo.systemName} ${iosInfo.systemVersion}';
      }
      // deviceId is never logged locally or in uploaded records — it's only included in the
      // structured payload sent to the backend (kept for session tracking). See below.
      // FINEST is dev-only (never leaves the device): emit the raw deviceId
      // so engineers can debug locally without surgery. Gated by logger level.
      logger.finest('deviceType: $deviceType, deviceId: $deviceId, osVersion: $osVersion');

      // Get public IP address
      String publicIpAddress = await getPublicIp();

      // Prepare the body of the POST request
      Map<String, dynamic> data = {
        'sessionId': sessionId,
        'date': DateTime.now().toUtc().toIso8601String(),
        'deviceId': deviceId,
        'deviceType': deviceType,
        'osVersion': osVersion,
        'providerId': providerId,
        'applicationId': appId,
        'publicIpAddress': publicIpAddress,
        'logType': logType.name,
        'metadata': ?metadata,
      };

      _sessionHttpClient.options.headers['Content-Type'] = 'application/json';
      final response = await _sessionHttpClient
          .post<String>(ReclaimUrls.LOGS_API, data: json.encode(data))
          .logWhenResponseErrors();

      if (response.statusCode != 200) {
        logger.info('Failed to Send logs, response status: ${response.statusCode}');
      }
    } catch (error, stackTrace) {
      logger.severe('Error sending logs to backend server', error, stackTrace);
    }
  }

  @override
  @mustCallSuper
  Future<void> sendErrorCallback({
    required String sessionId,
    required Map<String, dynamic> error,
    String? callbackUrl,
  }) async {
    final logger = logging.child('ReclaimSession.sendErrorCallback');
    try {
      _sessionHttpClient.options.headers['Content-Type'] = 'application/json';
      final url = callbackUrl ?? ReclaimUrls.getErrorCallbackUrl(sessionId);
      logger.info('Sending error callback for session: $sessionId, callbackUrl: $url');
      await _sessionHttpClient.post<String>(url, data: json.encode(error)).logWhenResponseErrors();
    } catch (error, stackTrace) {
      logger.severe('Error sending error callback', error, stackTrace);
    }
  }

  @override
  @mustCallSuper
  Future<AttestorAuthenticationRequest?> requestAttestorAuth(
    SessionAttestorAuthRequest sessionAttestorAuthRequest,
  ) async {
    final logger = logging.child('ReclaimSession.sendErrorCallback');
    try {
      _sessionHttpClient.options.headers['Content-Type'] = 'application/json';
      final url = ReclaimUrls.SESSION_ATTESTOR_AUTH;
      logger.info('Sending attestor auth request for session: ${sessionAttestorAuthRequest.sessionId}');
      final response = await _sessionHttpClient
          .post<String>(url, data: json.encode(sessionAttestorAuthRequest))
          .logWhenResponseErrors();
      final content = response.data;
      if (content == null || content.isEmpty) return null;
      final decodedJsonData = json.decode(utf8.decode(base64.decode(content)));
      return AttestorAuthenticationRequest.fromJson(decodedJsonData);
    } catch (error, stackTrace) {
      logger.severe('Error requesting attestor auth from sdk', error, stackTrace);
    }
    return null;
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
        logging.event(
          Level.SEVERE.withEvent(LogEventType.RECLAIM_INIT_SESSION_EXCEPTION),
          'Error initializing session',
        );
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
    logging.event(LevelWithEvent(Level.INFO, status.toLogEventType(), metadata: metadata), '');

    final updateSession = ReclaimOverrides.session?.updateSession;
    if (updateSession != null) {
      final isSessionOk = await updateSession(sessionId, status, metadata);
      if (!isSessionOk) {
        logging
            .child('updateSession')
            .event(Level.SEVERE.withEvent(LogEventType.RECLAIM_EXPIRED_SESSION_EXCEPTION), 'Session expired');
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
    required LogEventType logType,
    Map<String, dynamic>? metadata,
  }) async {
    logging.event(LevelWithEvent(Level.INFO, logType, metadata: metadata), '');

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

  @override
  Future<AttestorAuthenticationRequest?> requestAttestorAuth(SessionAttestorAuthRequest sessionAttestorAuthRequest) {
    final requestAttestorAuth = ReclaimOverrides.session?.requestAttestorAuth;
    if (requestAttestorAuth != null) {
      return requestAttestorAuth(sessionAttestorAuthRequest);
    }
    return super.requestAttestorAuth(sessionAttestorAuthRequest);
  }
}

const ReclaimSession = _SessionUpdateHandlerImpl();
