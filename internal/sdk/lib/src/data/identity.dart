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

  static SessionIdentity mergeWithLatest({
    required String appId,
    required String providerId,
    required String sessionId,
  }) {
    final it = latest;
    if (it == null) {
      return SessionIdentity(appId: appId, providerId: providerId, sessionId: sessionId);
    } else {
      final newAppId = it.appId.isEmpty ? appId : it.appId;
      final newProviderId = it.providerId.isEmpty ? providerId : it.providerId;
      final newSessionId = it.sessionId.isEmpty ? sessionId : it.sessionId;

      if (newAppId == it.appId && newProviderId == it.providerId && newSessionId == it.sessionId) {
        return it;
      }

      return it.copyWith(appId: newAppId, providerId: newProviderId, sessionId: newSessionId);
    }
  }

  SessionIdentity merge(SessionIdentity? other) {
    if (other == null) return this;

    String withFallback(String? it, String fallback) {
      if (it == null || it.trim().isEmpty) return fallback;
      return it;
    }

    final newAppId = withFallback(other.appId, appId);
    final newProviderId = withFallback(other.providerId, providerId);
    final newSessionId = withFallback(other.sessionId, sessionId);

    if (newAppId == appId && newProviderId == providerId && newSessionId == sessionId) {
      return this;
    }

    return SessionIdentity(appId: newAppId, providerId: newProviderId, sessionId: newSessionId);
  }

  @override
  bool operator ==(Object other) {
    return other is SessionIdentity &&
        other.appId == appId &&
        other.providerId == providerId &&
        other.sessionId == sessionId;
  }

  Map<String, String> toJson() {
    return {'appId': appId, 'providerId': providerId, 'sessionId': sessionId};
  }

  @override
  int get hashCode => Object.hash(appId, providerId, sessionId);

  @override
  String toString() {
    return json.encode({'type': "SessionIdentity", ...toJson()});
  }

  static SessionIdentity? _latest;

  /// Use with caution, recommended only where context is not available.
  /// Prefer using [VerificationController.request.identity].
  static SessionIdentity? get latest => _latest;

  static final StreamController<SessionIdentity?> _streamController = StreamController.broadcast();

  static Stream<SessionIdentity?> get onChanged => _streamController.stream;

  static SessionIdentity updateLatest(SessionIdentity updated) {
    _latest = updated;
    _streamController.add(updated);
    return updated;
  }
}
