import 'dart:async';
import 'dart:convert';

/// Identification information of a session.
class SessionIdentity {
  /// The application id.
  final String appId;

  /// The provider id.
  final String providerId;

  /// The session id.
  final String sessionId;

  const SessionIdentity({required this.appId, required this.providerId, required this.sessionId});

  SessionIdentity copyWith({String? appId, String? providerId, String? sessionId}) {
    return SessionIdentity(
      appId: appId ?? this.appId,
      providerId: providerId ?? this.providerId,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  SessionIdentity merge(SessionIdentity? other) {
    String withFallback(String? it, String fallback) {
      if (it == null || it.trim().isEmpty) return fallback;
      return it;
    }

    return SessionIdentity(
      appId: withFallback(other?.appId, appId),
      providerId: withFallback(other?.providerId, providerId),
      sessionId: withFallback(other?.sessionId, sessionId),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SessionIdentity &&
        other.appId == appId &&
        other.providerId == providerId &&
        other.sessionId == sessionId;
  }

  @override
  int get hashCode => Object.hash(appId, providerId, sessionId);

  @override
  String toString() {
    return json.encode({
      'type': "SessionIdentity",
      'appId': appId,
      'providerId': providerId,
      'sessionId': sessionId,
    });
  }

  static SessionIdentity? _latest;

  static SessionIdentity? get latest => _latest;

  static final StreamController<SessionIdentity?> _streamController = StreamController.broadcast();

  static Stream<SessionIdentity?> get onChanged => _streamController.stream;

  static SessionIdentity update({
    required String appId,
    required String providerId,
    required String sessionId,
  }) {
    final updated = SessionIdentity(appId: appId, providerId: providerId, sessionId: sessionId);
    _latest = updated;
    _streamController.add(updated);
    return updated;
  }
}
