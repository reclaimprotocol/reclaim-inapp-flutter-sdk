class ClaimCreationException implements Exception {
  final String message;

  const ClaimCreationException(this.message);

  @override
  String toString() {
    return 'ClaimCreationException: $message';
  }
}
