import '../../attestor/data/attestor/auth.dart' show AttestorAuthenticationRequest;
import '../../exception/exception.dart' show ReclaimExpiredSessionException, ReclaimInitSessionException;
import '../../logging/event_type.dart';
import '../../overrides/overrides.dart';
import '../../services/session.dart';

export '../../attestor/data/attestor/auth.dart' show AttestorAuthenticationRequest;
export '../../data/verification/version.dart';

/// {@template session_create_request}
/// A signature of a function that creates a session.
///
/// This function is called when a session is created.
/// It is used to create a session with the given app id, provider id, timestamp and signature.
/// It returns an object [SessionInitResponse] which has sessionId for identifying this session.
/// When returned null, [ReclaimInitSessionException] is thrown, resulting in reclaim verification to close with this exception.
/// {@endtemplate}
typedef SessionCreateRequest = Future<SessionInitResponse?> Function({
  required String appId,
  required String providerId,
  required String timestamp,
  required String signature,
  required String providerVersion,
});

/// {@template session_update_callback}
/// A signature of a function that is called when a session status needs updated.
///
/// This function is called when a session is updated.
/// It is used to update a session with the given session id, and [SessionStatus].
/// It returns a boolean value indicating whether the session was updated successfully.
/// When false, the caller will throw [ReclaimExpiredSessionException], resulting in reclaim verification to close with this exception.
/// {@endtemplate}
typedef SessionUpdateCallback = Future<bool> Function(
  String sessionId,
  SessionStatus status,
  Map<String, dynamic>? metadata,
);

/// {@template session_log_record_callback}
/// A signature of a function that is called when a session log record needs to be logged.
///
/// This function is called when a session log record needs to be logged.
/// It is used to log a session log record with the given session id, provider id, log type, and application id.
/// {@endtemplate}
typedef SessionLogRecordCallback = void Function({
  required String appId,
  required String providerId,
  required String sessionId,
  required LogEventType logType,
  Map<String, dynamic>? metadata,
});

typedef SessionAttestorAuthRequestCallback = Future<AttestorAuthenticationRequest?> Function(
  SessionAttestorAuthRequest sessionAttestorAuthRequest,
);

class ReclaimSessionOverride extends ReclaimOverride<ReclaimSessionOverride> {
  const ReclaimSessionOverride._raw({this.createSession, this.logRecord, this.updateSession, this.requestAttestorAuth});

  const ReclaimSessionOverride.sessionUpdates({required SessionUpdateCallback this.updateSession, this.logRecord})
    : createSession = null,
      requestAttestorAuth = null;

  const ReclaimSessionOverride.session({
    required SessionCreateRequest this.createSession,
    required SessionUpdateCallback this.updateSession,
    this.logRecord,
    this.requestAttestorAuth,
  });

  const ReclaimSessionOverride.useDefault()
    : createSession = null,
      updateSession = null,
      logRecord = null,
      requestAttestorAuth = null;

  /// {@macro session_create_request}
  final SessionCreateRequest? createSession;

  /// {@macro session_update_callback}
  final SessionUpdateCallback? updateSession;

  /// {@macro session_log_record_callback}
  final SessionLogRecordCallback? logRecord;

  final SessionAttestorAuthRequestCallback? requestAttestorAuth;

  @override
  ReclaimSessionOverride copyWith({
    SessionCreateRequest? createSession,
    SessionLogRecordCallback? logRecord,
    SessionUpdateCallback? updateSession,
    SessionAttestorAuthRequestCallback? requestAttestorAuth,
  }) {
    return ReclaimSessionOverride._raw(
      createSession: createSession ?? this.createSession,
      logRecord: logRecord ?? this.logRecord,
      updateSession: updateSession ?? this.updateSession,
      requestAttestorAuth: requestAttestorAuth ?? this.requestAttestorAuth,
    );
  }
}
