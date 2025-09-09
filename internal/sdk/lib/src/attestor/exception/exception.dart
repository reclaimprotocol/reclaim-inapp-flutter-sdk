import '../../logging/logging.dart';

class AttestorException implements Exception {
  const AttestorException(this.message);

  final Object? message;

  @override
  String toString() {
    return 'AttestorException: $message';
  }
}

class AttestorRequestException implements AttestorException {
  const AttestorRequestException(this.message);

  @override
  final Object? message;

  static StackTrace? tryParseStackTrace(dynamic stack) {
    if (stack is String) {
      try {
        return StackTrace.fromString(stack);
      } catch (e, s) {
        final log = logging.child('AttestorRequestException.tryParseStackTrace');
        log.warning('Error parsing stack trace', e, s);
        return null;
      }
    }

    return null;
  }

  @override
  String toString() {
    return 'AttestorRequestException: $message';
  }
}

class AttestorRequestCancelledException implements AttestorException {
  const AttestorRequestCancelledException() : message = 'Request cancelled';

  @override
  final String message;

  @override
  String toString() {
    return 'AttestorRequestCancelledException: $message';
  }
}

class AttestorRequestMessagingException implements AttestorException {
  const AttestorRequestMessagingException(Object error) : message = 'Request messaging exception caused by $error';

  @override
  final String message;

  @override
  String toString() {
    return 'AttestorRequestMessagingException: $message';
  }
}

sealed class AttestorClientNotReadyException implements Exception {
  const AttestorClientNotReadyException(this.message);

  final String message;

  @override
  String toString() {
    return 'AttestorClientNotReadyException: $message';
  }
}

final class AttestorClientInitializationException implements AttestorClientNotReadyException {
  const AttestorClientInitializationException(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'AttestorClientInitializationException: $message';
  }
}

final class AttestorClientReloadException implements AttestorClientNotReadyException {
  const AttestorClientReloadException(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'AttestorClientReloadException: $message';
  }
}

final class AttestorClientGoneException implements AttestorClientNotReadyException {
  const AttestorClientGoneException(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'AttestorClientGoneException: $message';
  }
}
