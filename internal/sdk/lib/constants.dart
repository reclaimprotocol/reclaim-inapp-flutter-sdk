import 'package:flutter/material.dart';

class ReclaimTheme {
  static const primary = Color(0xFF332FED);
  static const Color grayBackground = Color(0xFFF7F7F8);
  static const Color green = Color(0xFF16A34A);
}

class ReclaimBackend {
  static const String SESSION_URL =
      'https://api.reclaimprotocol.org/api/sdk/update/session';
  static const String SESSION_INIT =
      'https://api.reclaimprotocol.org/api/sdk/init/session';
  static const String MANUAL_VERIFICATION_PREFIX =
      'https://api.reclaimprotocol.org/api/manual-verification';
  static const String LOGS_API =
      'https://logs.reclaimprotocol.org/api/business-logs/app';
  static const String FEATURE_FLAGS_API =
      'https://api.reclaimprotocol.org/api/feature-flags';
  static const String DEFAULT_ATTESTOR_WEB_URL =
      'https://attestor.reclaimprotocol.org/browser-rpc';
}

final templateParamRegex = RegExp(r'{{(.*?)}}');

enum SessionStatus {
  USER_STARTED_VERIFICATION,
  USER_INIT_VERIFICATION,
  PROOF_GENERATION_STARTED,
  PROOF_GENERATION_RETRY,
  PROOF_GENERATION_SUCCESS,
  PROOF_GENERATION_FAILED,
  PROOF_SUBMITTED,
  PROOF_SUBMISSION_FAILED,
  PROOF_MANUAL_VERIFICATION_SUBMITED,
}

const Map<SessionStatus, String> sessionStatusStrings = {
  SessionStatus.USER_STARTED_VERIFICATION: 'USER_STARTED_VERIFICATION',
  SessionStatus.USER_INIT_VERIFICATION: 'USER_INIT_VERIFICATION',
  SessionStatus.PROOF_GENERATION_STARTED: 'PROOF_GENERATION_STARTED',
  SessionStatus.PROOF_GENERATION_RETRY: 'PROOF_GENERATION_RETRY',
  SessionStatus.PROOF_GENERATION_SUCCESS: 'PROOF_GENERATION_SUCCESS',
  SessionStatus.PROOF_GENERATION_FAILED: 'PROOF_GENERATION_FAILED',
  SessionStatus.PROOF_SUBMITTED: 'PROOF_SUBMITTED',
  SessionStatus.PROOF_SUBMISSION_FAILED: 'PROOF_SUBMISSION_FAILED',
  SessionStatus.PROOF_MANUAL_VERIFICATION_SUBMITED:
      'PROOF_MANUAL_VERIFICATION_SUBMITED',
};
