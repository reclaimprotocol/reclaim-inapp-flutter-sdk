sealed class ReclaimException implements Exception {
  const ReclaimException([this.message]);

  final String? message;

  @override
  String toString() {
    return 'ReclaimException: $message';
  }
}

final class ReclaimVerificationManualReviewException extends ReclaimException {
  const ReclaimVerificationManualReviewException([String? message]) : super(message ?? 'Manual review initiated');

  @override
  String toString() {
    return 'ReclaimVerificationManualReviewException: $message';
  }
}

final class InvalidRequestReclaimException extends ReclaimException {
  const InvalidRequestReclaimException([super.message]);

  @override
  String toString() {
    return 'InvalidRequestReclaimException: $message';
  }
}

sealed class ReclaimVerificationProviderException extends ReclaimException {
  const ReclaimVerificationProviderException([super.message]);

  @override
  String toString() {
    return 'ReclaimVerificationProviderException: $message';
  }
}

final class ReclaimVerificationProviderNotFoundException extends ReclaimVerificationProviderException {
  const ReclaimVerificationProviderNotFoundException() : super('Provider not found');

  @override
  String toString() {
    return 'ReclaimVerificationProviderNotFoundException: $message';
  }
}

final class ReclaimVerificationProviderLoadException extends ReclaimVerificationProviderException {
  const ReclaimVerificationProviderLoadException([String? message]) : super(message ?? 'Provider load failed');

  @override
  String toString() {
    return 'ReclaimVerificationProviderLoadException: $message';
  }
}

/// Exception thrown when the provider script reports an error to stop the verification process.
final class ReclaimVerificationProviderScriptException extends ReclaimException {
  const ReclaimVerificationProviderScriptException([String? message, this.providerError])
    : super(message ?? 'Verification failed');

  final Map<String, dynamic>? providerError;

  @override
  String toString() {
    return 'ReclaimVerificationProviderScriptException: $message, $providerError';
  }
}

/// An exception thrown when verification is cancelled. Likely because another verification was started.
final class ReclaimVerificationCancelledException extends ReclaimException {
  const ReclaimVerificationCancelledException([String? message]) : super(message ?? 'Verification cancelled');

  @override
  String toString() {
    return 'ReclaimVerificationCancelledException: $message';
  }
}

/// An exception thrown when verification was skipped. Likely because user reused proofs.
final class ReclaimVerificationSkippedException extends ReclaimException {
  const ReclaimVerificationSkippedException([String? message]) : super(message ?? 'Verification skipped');

  @override
  String toString() {
    return 'ReclaimVerificationSkippedException: $message';
  }
}

/// An exception thrown when verification is dismissed by the user.
final class ReclaimVerificationDismissedException extends ReclaimException {
  const ReclaimVerificationDismissedException([String? message]) : super(message ?? 'Verification dismissed by user');

  @override
  String toString() {
    return 'ReclaimVerificationDismissedException: $message';
  }
}

/// An exception thrown when claim creation request could not be created because of requirements not met.
final class ReclaimVerificationRequirementException extends ReclaimException {
  const ReclaimVerificationRequirementException() : super('Requirement for verification could not be met');
}

sealed class ReclaimSessionException extends ReclaimException {
  const ReclaimSessionException(super.message);
}

/// An exception thrown when a session is expired. Can also be thrown when a session is not found.
final class ReclaimExpiredSessionException extends ReclaimSessionException {
  const ReclaimExpiredSessionException([String? message]) : super(message ?? 'Session expired');

  @override
  String toString() {
    return 'ReclaimExpiredSessionException: $message';
  }
}

final class ReclaimInitSessionException extends ReclaimSessionException {
  const ReclaimInitSessionException([String? message]) : super(message ?? 'Error initializing session');

  @override
  String toString() {
    return 'ReclaimInitSessionException: $message';
  }
}

final class ReclaimAttestorException extends ReclaimException {
  const ReclaimAttestorException([String? message]) : super(message ?? 'Error in Attestor');

  @override
  String toString() {
    return 'ReclaimAttestorException: $message';
  }
}
