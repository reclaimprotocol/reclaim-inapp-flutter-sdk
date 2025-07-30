import 'dart:async';

import '../../reclaim_inapp_sdk.dart';
import '../constants.dart';
import '../logging/logging.dart';
import '../utils/future.dart';

class SessionStartResponse {
  final SessionIdentity identity;
  final ReclaimSessionInformation sessionInformation;

  const SessionStartResponse({required this.identity, required this.sessionInformation});
}

class SessionManager {
  Future<SessionStartResponse> startSession(
    String applicationId,
    String providerId,
    SessionProvider sessionProvider,
  ) async {
    try {
      final session = await sessionProvider();

      final identity = SessionIdentity.updateLatest(
        SessionIdentity(appId: applicationId, providerId: providerId, sessionId: session.sessionId),
      );

      await onSessionStarted(session.sessionId);

      return SessionStartResponse(identity: identity, sessionInformation: session);
    } on ReclaimSessionException {
      rethrow;
    } catch (e, s) {
      logging.severe('Error session start', e, s);
      throw ReclaimInitSessionException('Could not start session');
    }
  }

  Future<void> onSessionStarted(String sessionId) async {
    try {
      // Calling this which may throw [ReclaimSessionException].
      // If this is done in the UI, the experience on error may cause the UI abruptly closing which is not a good ux.
      await ReclaimSession.updateSession(sessionId, SessionStatus.USER_STARTED_VERIFICATION);
    } on ReclaimSessionException {
      rethrow;
    } catch (e, s) {
      logging.severe('Error updating session', e, s);
      // ignoring other exceptions to silently continue verification
    }
  }

  Future<void> onRequestedProvidersFetched({
    required String applicationId,
    required String providerId,
    required String sessionId,
  }) async {
    unawaited(
      ReclaimSession.sendLogs(
        appId: applicationId,
        providerId: providerId,
        sessionId: sessionId,
        logType: "FETCHED_PROVIDERS",
      ),
    );
  }

  Future<void> onReclaimException({
    required String applicationId,
    required String providerId,
    required String sessionId,
    required ReclaimException exception,
  }) async {
    unawaitedSequence([
      ReclaimSession.sendLogs(
        appId: applicationId,
        sessionId: sessionId,
        providerId: providerId,
        logType: 'RECLAIM_EXCEPTION',
        metadata: {'exception': exception},
      ),
    ]);
  }

  Future<void> onProofSubmitted({
    required String applicationId,
    required String providerId,
    required String sessionId,
  }) async {
    unawaitedSequence([
      ReclaimSession.sendLogs(
        appId: applicationId,
        sessionId: sessionId,
        providerId: providerId,
        logType: 'PROOF_SUBMITTED',
      ),
      ReclaimSession.updateSession(sessionId, SessionStatus.PROOF_SUBMITTED),
    ]);
  }

  Future<void> onProofSubmissionFailed({
    required String applicationId,
    required String providerId,
    required String sessionId,
  }) async {
    unawaitedSequence([
      ReclaimSession.sendLogs(
        appId: applicationId,
        sessionId: sessionId,
        providerId: providerId,
        logType: 'PROOF_SUBMISSION_FAILED',
      ),
      ReclaimSession.updateSession(sessionId, SessionStatus.PROOF_SUBMISSION_FAILED),
    ]);
  }

  Future<void> onManualVerificationRequestSubmitted({
    required String applicationId,
    required String sessionId,
    required String providerId,
  }) async {
    unawaitedSequence([
      ReclaimSession.sendLogs(
        appId: applicationId,
        sessionId: sessionId,
        providerId: providerId,
        logType: 'PROOF_MANUAL_VERIFICATION_SUBMITTED',
      ),
      ReclaimSession.updateSession(sessionId, SessionStatus.PROOF_MANUAL_VERIFICATION_SUBMITED),
    ]);
  }

  Future<void> onLoginDetected({
    required String applicationId,
    required String sessionId,
    required String providerId,
    required String url,
  }) async {
    await ReclaimSession.sendLogs(
      appId: applicationId,
      sessionId: sessionId,
      providerId: providerId,
      logType: 'LOGIN_DETECTED',
      metadata: {'url': url},
    );
  }

  Future<void> onLoginRequiredDetected({
    required String applicationId,
    required String sessionId,
    required String providerId,
    required String url,
    required bool hasLoginRelatedTokenInUrl,
    required bool? hasLoginRelatedElementInPage,
  }) async {
    await ReclaimSession.sendLogs(
      appId: applicationId,
      sessionId: sessionId,
      providerId: providerId,
      logType: 'LOGIN_REQUIRED_DETECTED',
      metadata: {
        'url': url,
        'hasLoginRelatedTokenInUrl': hasLoginRelatedTokenInUrl,
        'hasLoginRelatedElementInPage': hasLoginRelatedElementInPage,
      },
    );
  }

  Uri getDefaultCallbackUrl(String sessionId) {
    return Uri.parse(ReclaimUrls.DEFAULT_CALLBACK_URL_PATH).replace(queryParameters: {'callbackId': sessionId});
  }
}
