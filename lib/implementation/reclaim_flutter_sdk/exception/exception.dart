class ReclaimException
    implements
        Exception {
  const ReclaimException(
      [this.message]);

  final String?
      message;

  @override
  String
      toString() {
    return 'ReclaimException: $message';
  }

  factory ReclaimException.onError(
      dynamic
          value) {
    if (value
        is ReclaimException)
      return value;
    if (value ==
        null)
      return const ReclaimVerificationDismissedException();
    return ReclaimException(
        value.toString());
  }
}

class ReclaimVerificationManualReviewException
    extends ReclaimException {
  const ReclaimVerificationManualReviewException(
      [String?
          message])
      : super(message ?? 'Manual review initiated');

  @override
  String
      toString() {
    return 'ReclaimVerificationManualReviewException: $message';
  }
}

class ReclaimVerificationProviderException
    extends ReclaimException {
  const ReclaimVerificationProviderException([
    String?
        message,
    this.providerError,
  ]) : super(message ?? 'Verification failed');

  final Map<
      String,
      dynamic>? providerError;

  @override
  String
      toString() {
    return 'ReclaimVerificationProviderException: $message, $providerError';
  }
}

class ReclaimVerificationRequirementException
    extends ReclaimException {
  const ReclaimVerificationRequirementException()
      : super('Requirement for verification could not be met');
}

abstract class ReclaimSessionException
    extends ReclaimException {
  const ReclaimSessionException(
      super.message);
}

class ReclaimExpiredSessionException
    extends ReclaimSessionException {
  const ReclaimExpiredSessionException(
      [String?
          message])
      : super(message ?? 'Session expired');

  @override
  String
      toString() {
    return 'ReclaimExpiredSessionException: $message';
  }
}

class ReclaimInitSessionException
    extends ReclaimSessionException {
  const ReclaimInitSessionException(
      [String?
          message])
      : super(message ?? 'Error initializing session');

  @override
  String
      toString() {
    return 'ReclaimInitSessionException: $message';
  }
}

class ReclaimVerificationCancelledException
    extends ReclaimException {
  const ReclaimVerificationCancelledException(
      [String?
          message])
      : super(message ?? 'Verification cancelled');

  @override
  String
      toString() {
    return 'ReclaimVerificationCancelledException: $message';
  }
}

class ReclaimVerificationDismissedException
    extends ReclaimException {
  const ReclaimVerificationDismissedException(
      [String?
          message])
      : super(message ?? 'Verification cancelled');

  @override
  String
      toString() {
    return 'ReclaimVerificationDismissedException: $message';
  }
}
