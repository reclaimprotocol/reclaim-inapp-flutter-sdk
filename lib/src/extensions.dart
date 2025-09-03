import 'package:reclaim_verifier_module/reclaim_verifier_module.dart';

extension MapApiReclaimApiVerificationResponse
    on ReclaimApiVerificationResponse {
  Map<String, Object?> toEncodable() {
    return {
      'sessionId': sessionId,
      'didSubmitManualVerification': didSubmitManualVerification,
      'proofs': proofs,
      'exception': exception?.toEncodable(),
    };
  }
}

extension MapApiReclaimApiVerificationException
    on ReclaimApiVerificationException {
  Map<String, Object?> toEncodable() {
    return {
      'message': message,
      'stackTraceAsString': stackTraceAsString,
      'type': type.name,
    };
  }
}
