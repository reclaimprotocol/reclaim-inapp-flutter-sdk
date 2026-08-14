// ignore_for_file: deprecated_member_use

part of 'api.dart';

extension ReclaimSessionStatusExtension on ReclaimSessionStatus {
  static ReclaimSessionStatus fromSessionStatus(SessionStatus status) {
    return switch (status) {
      SessionStatus.PROOF_GENERATION_FAILED => ReclaimSessionStatus.PROOF_GENERATION_FAILED,
      SessionStatus.PROOF_GENERATION_SUCCESS => ReclaimSessionStatus.PROOF_GENERATION_SUCCESS,
      SessionStatus.PROOF_SUBMITTED => ReclaimSessionStatus.PROOF_SUBMITTED,
      SessionStatus.PROOF_SUBMISSION_FAILED => ReclaimSessionStatus.PROOF_SUBMISSION_FAILED,
      // This spelling mistake is intentional to match the backend.
      SessionStatus.PROOF_MANUAL_VERIFICATION_SUBMITED => ReclaimSessionStatus.PROOF_MANUAL_VERIFICATION_SUBMITTED,
      SessionStatus.USER_INIT_VERIFICATION => ReclaimSessionStatus.USER_INIT_VERIFICATION,
      SessionStatus.USER_STARTED_VERIFICATION => ReclaimSessionStatus.USER_STARTED_VERIFICATION,
      SessionStatus.PROOF_GENERATION_STARTED => ReclaimSessionStatus.PROOF_GENERATION_STARTED,
      SessionStatus.PROOF_GENERATION_RETRY => ReclaimSessionStatus.PROOF_GENERATION_RETRY,
      SessionStatus.AI_PROOF_SUBMITTED => ReclaimSessionStatus.AI_PROOF_SUBMITTED,
      SessionStatus.USER_INTERACTED => ReclaimSessionStatus.USER_INTERACTED,
      SessionStatus.USER_TYPED => ReclaimSessionStatus.USER_TYPED,
    };
  }
}
