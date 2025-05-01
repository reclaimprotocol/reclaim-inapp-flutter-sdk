import 'package:reclaim_flutter_sdk/constants.dart';
import 'package:reclaim_flutter_sdk/overrides/overrides.dart';
import 'package:reclaim_flutter_sdk/exception/exception.dart'
    show ReclaimExpiredSessionException, ReclaimInitSessionException;

/// {@template session_create_request}
/// A signature of a function that creates a session.
///
/// This function is called when a session is created.
/// It is used to create a session with the given app id, provider id, timestamp and signature.
/// It returns a string value which is an identifier for this session and used as session id.
/// When returned null, [ReclaimInitSessionException] is thrown, resulting in reclaim verification to close with this exception.
/// {@endtemplate}
typedef SessionCreateRequest =
    Future<String?> Function({
      required String appId,
      required String providerId,
      required String timestamp,
      required String signature,
    });

/// {@template session_update_callback}
/// A signature of a function that is called when a session status needs updated.
///
/// This function is called when a session is updated.
/// It is used to update a session with the given session id, and [SessionStatus].
/// It returns a boolean value indicating whether the session was updated successfully.
/// When false, the caller will throw [ReclaimExpiredSessionException], resulting in reclaim verification to close with this exception.
/// {@endtemplate}
typedef SessionUpdateCallback =
    Future<bool> Function(String sessionId, SessionStatus status);

/// {@template session_log_record_callback}
/// A signature of a function that is called when a session log record needs to be logged.
///
/// This function is called when a session log record needs to be logged.
/// It is used to log a session log record with the given session id, provider id, log type, and application id.
/// {@endtemplate}
typedef SessionLogRecordCallback =
    void Function({
      required String appId,
      required String providerId,
      required String sessionId,
      required String logType,
      Map<String, dynamic>? metadata,
    });

class ReclaimSessionOverride extends ReclaimOverride<ReclaimSessionOverride> {
  const ReclaimSessionOverride._raw({
    this.createSession,
    this.logRecord,
    this.updateSession,
  });

  const ReclaimSessionOverride.sessionUpdates({
    required SessionUpdateCallback this.updateSession,
    this.logRecord,
  }) : createSession = null;

  const ReclaimSessionOverride.session({
    required SessionCreateRequest this.createSession,
    required SessionUpdateCallback this.updateSession,
    this.logRecord,
  });

  const ReclaimSessionOverride.useDefault()
    : createSession = null,
      updateSession = null,
      logRecord = null;

  /// {@macro session_create_request}
  final SessionCreateRequest? createSession;

  /// {@macro session_update_callback}
  final SessionUpdateCallback? updateSession;

  /// {@macro session_log_record_callback}
  final SessionLogRecordCallback? logRecord;

  @override
  ReclaimSessionOverride copyWith({
    SessionCreateRequest? createSession,
    SessionLogRecordCallback? logRecord,
    SessionUpdateCallback? updateSession,
  }) {
    return ReclaimSessionOverride._raw(
      createSession: createSession ?? this.createSession,
      logRecord: logRecord ?? this.logRecord,
      updateSession: updateSession ?? this.updateSession,
    );
  }
}
