// ignore_for_file: overridden_fields

sealed class ReclaimException implements Exception {
  const ReclaimException([this.message]);

  final String? message;
  // To save name from obfuscation
  String get exceptionName;

  Map<String, Object?> toJson() {
    return {'type': exceptionName, 'message': message};
  }

  @override
  String toString() {
    return '$exceptionName: $message';
  }
}

/// Exceptions caused by provider during the verification flow.
sealed class ReclaimVerificationProviderException extends ReclaimException {
  const ReclaimVerificationProviderException([super.message]);
}

/// An exception thrown when verification is cancelled. Likely because another verification was started or request was invalid.
final class ReclaimVerificationCancelledException extends ReclaimException {
  const ReclaimVerificationCancelledException([String? message]) : super(message ?? 'Verification cancelled');

  @override
  final exceptionName = 'ReclaimVerificationCancelledException';
}

/// An exception thrown when verification is dismissed by the user.
final class ReclaimVerificationDismissedException extends ReclaimException {
  const ReclaimVerificationDismissedException([String? message]) : super(message ?? 'Verification dismissed by user');

  @override
  final exceptionName = 'ReclaimVerificationDismissedException';
}

sealed class ReclaimSessionException extends ReclaimException {
  const ReclaimSessionException(super.message);
}

final class ReclaimAttestorException extends ReclaimException {
  const ReclaimAttestorException(String super.message);

  @override
  final exceptionName = 'ReclaimAttestorException';
}

/// An exception that is thrown when verification was skipped. Likely because user reused proofs, or manual review was submitted.
final class ReclaimVerificationSkippedException extends ReclaimException {
  const ReclaimVerificationSkippedException([String? message]) : super(message ?? 'Verification skipped');

  @override
  final exceptionName = 'ReclaimVerificationSkippedException';
}

/// The request to start reclaim verification is invalid.
final class InvalidRequestReclaimException extends ReclaimVerificationCancelledException {
  const InvalidRequestReclaimException([super.message]);

  @override
  final exceptionName = 'InvalidRequestReclaimException';
}

final class ReclaimVerificationPlatformNotSupportedException extends ReclaimVerificationCancelledException {
  const ReclaimVerificationPlatformNotSupportedException([String? message])
    : super(message ?? 'Platform not supported');

  @override
  final exceptionName = 'ReclaimVerificationPlatformNotSupportedException';
}

/// The verification was submitted for manual review by the user.
final class ReclaimVerificationManualReviewException extends ReclaimVerificationSkippedException {
  const ReclaimVerificationManualReviewException([String? message]) : super(message ?? 'Manual review initiated');

  @override
  final exceptionName = 'ReclaimVerificationManualReviewException';
}

final class ReclaimVerificationProviderNotFoundException extends InvalidRequestReclaimException {
  const ReclaimVerificationProviderNotFoundException() : super('Provider not found');

  @override
  final exceptionName = 'ReclaimVerificationProviderNotFoundException';
}

/// Exception thrown when the provider script reports an error to stop the verification process.
final class ReclaimVerificationProviderScriptException extends ReclaimVerificationProviderException {
  const ReclaimVerificationProviderScriptException(String super.message, [this.providerError]);

  final Map<String, dynamic>? providerError;

  @override
  final exceptionName = 'ReclaimVerificationProviderScriptException';

  @override
  Map<String, Object?> toJson() {
    return {...super.toJson(), 'providerError': providerError};
  }
}

final class ReclaimVerificationNoActivityDetectedException extends ReclaimVerificationProviderException {
  const ReclaimVerificationNoActivityDetectedException(String super.message);

  @override
  final exceptionName = 'ReclaimVerificationNoActivityDetectedException';
}

/// An exception thrown when claim creation request could not be created because of requirements not met.
final class ReclaimVerificationRequirementException extends ReclaimVerificationProviderException {
  const ReclaimVerificationRequirementException() : super('Requirement for verification could not be met');

  @override
  final exceptionName = 'ReclaimVerificationRequirementException';
}

final class ReclaimVerificationProviderLoadException extends ReclaimVerificationProviderException {
  const ReclaimVerificationProviderLoadException([String? message]) : super(message ?? 'Provider load failed');

  @override
  final exceptionName = 'ReclaimVerificationProviderLoadException';
}

/// An exception thrown when a session is expired. Can also be thrown when a session is not found.
final class ReclaimExpiredSessionException extends ReclaimSessionException {
  const ReclaimExpiredSessionException([String? message]) : super(message ?? 'Session expired');

  @override
  final exceptionName = 'ReclaimExpiredSessionException';
}

final class ReclaimInitSessionException extends ReclaimSessionException {
  const ReclaimInitSessionException([String? message]) : super(message ?? 'Error initializing session');

  @override
  final exceptionName = 'ReclaimInitSessionException';
}
