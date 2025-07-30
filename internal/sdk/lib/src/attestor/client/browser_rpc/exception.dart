class AttestorWebViewClientNotReadyException implements Exception {
  const AttestorWebViewClientNotReadyException(this.message);

  final String message;

  @override
  String toString() {
    return 'AttestorWebViewClientNotReadyException: $message';
  }
}

class AttestorWebViewClientReloadException implements AttestorWebViewClientNotReadyException {
  const AttestorWebViewClientReloadException(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'AttestorWebViewClientReloadException: $message';
  }
}

class AttestorWebViewClientGoneException implements AttestorWebViewClientNotReadyException {
  const AttestorWebViewClientGoneException(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'AttestorWebViewClientGoneException: $message';
  }
}
