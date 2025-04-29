import '../../../logging/logging.dart';

class AttestorException
    implements
        Exception {
  const AttestorException(
      this.message);

  final Object?
      message;

  @override
  String
      toString() {
    return 'AttestorException: $message';
  }
}

class AttestorRequestException
    implements
        AttestorException {
  const AttestorRequestException(
      this.message);

  @override
  final Object?
      message;

  static StackTrace?
      tryParseStackTrace(dynamic stack) {
    if (stack
        is String) {
      try {
        return StackTrace.fromString(stack);
      } catch (e, s) {
        final log = logging.child(
          'AttestorRequestException.tryParseStackTrace',
        );
        log.warning('Error parsing stack trace', e, s);
        return null;
      }
    }

    return null;
  }

  @override
  String
      toString() {
    return 'AttestorRequestException: $message';
  }
}

class AttestorRequestCancelledException
    implements
        AttestorException {
  const AttestorRequestCancelledException()
      : message = 'Request cancelled';

  @override
  final String
      message;

  @override
  String
      toString() {
    return 'AttestorRequestCancelledException: $message';
  }
}

class AttestorRequestMessagingException
    implements
        AttestorException {
  const AttestorRequestMessagingException(
      Object
          error)
      : message = 'Request messaging exception caused by $error';

  @override
  final String
      message;

  @override
  String
      toString() {
    return 'AttestorRequestMessagingException: $message';
  }
}
