/// Base exception for all Reclaim operator errors
///
/// This exception is used by both TEE and GNARK operators to provide
/// consistent error handling across different attestation modes.
class ReclaimOperatorException implements Exception {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  const ReclaimOperatorException(this.message, {this.cause, this.stackTrace});

  @override
  String toString() {
    final buffer = StringBuffer('ReclaimOperatorException: $message');
    if (cause != null) {
      buffer.write('\nCaused by: $cause');
    }
    if (stackTrace != null) {
      buffer.write('\n$stackTrace');
    }
    return buffer.toString();
  }
}

/// Exception thrown when network operations fail
///
/// Used for connection errors, timeouts, and server communication failures
class ReclaimNetworkException extends ReclaimOperatorException {
  const ReclaimNetworkException(super.message, {super.cause, super.stackTrace});

  @override
  String toString() => 'ReclaimNetworkException: $message';
}

/// Exception thrown when proof generation fails
///
/// Used for ZK proof computation errors, circuit failures, and TEE execution errors
class ReclaimProofGenerationException extends ReclaimOperatorException {
  const ReclaimProofGenerationException(super.message, {super.cause, super.stackTrace});

  @override
  String toString() => 'ReclaimProofGenerationException: $message';
}

/// Exception thrown when validation fails
///
/// Used for input validation errors, signature verification failures, and claim validation errors
class ReclaimValidationException extends ReclaimOperatorException {
  const ReclaimValidationException(super.message, {super.cause, super.stackTrace});

  @override
  String toString() => 'ReclaimValidationException: $message';
}
