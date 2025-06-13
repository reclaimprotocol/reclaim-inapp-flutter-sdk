import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_inapp_sdk/src/services/session.dart';

const Map<SessionStatus, String> sessionStatusStrings = {
  SessionStatus.USER_STARTED_VERIFICATION: 'USER_STARTED_VERIFICATION',
  SessionStatus.USER_INIT_VERIFICATION: 'USER_INIT_VERIFICATION',
  SessionStatus.PROOF_GENERATION_STARTED: 'PROOF_GENERATION_STARTED',
  SessionStatus.PROOF_GENERATION_RETRY: 'PROOF_GENERATION_RETRY',
  SessionStatus.PROOF_GENERATION_SUCCESS: 'PROOF_GENERATION_SUCCESS',
  SessionStatus.PROOF_GENERATION_FAILED: 'PROOF_GENERATION_FAILED',
  SessionStatus.PROOF_SUBMITTED: 'PROOF_SUBMITTED',
  SessionStatus.PROOF_SUBMISSION_FAILED: 'PROOF_SUBMISSION_FAILED',
  SessionStatus.PROOF_MANUAL_VERIFICATION_SUBMITED: 'PROOF_MANUAL_VERIFICATION_SUBMITED',
};

void main() {
  group('SessionStatus', () {
    test('should have correct values', () {
      expect(sessionStatusStrings.length, equals(SessionStatus.values.length));
      for (final status in SessionStatus.values) {
        expect(sessionStatusStrings[status], equals(status.name));
      }
    });
  });
}
