import '../rpc/client.dart';

sealed class ReclaimVerificationException implements Exception {
  const ReclaimVerificationException(this.message, {required this.innerRpcError, required this.reason, required this.sessionId});

  final String message;
  final RpcErrorInformation innerRpcError;
  final String reason;
  final String? sessionId;

  @override
  String toString() => 'ReclaimVerificationException: $message';
}

final class ReclaimVerificationCancelledException extends ReclaimVerificationException {
  const ReclaimVerificationCancelledException(super.message, {required super.innerRpcError, required super.reason, required super.sessionId});
}

final class ReclaimVerificationFailedException extends ReclaimVerificationException {
  const ReclaimVerificationFailedException(super.message, {required super.innerRpcError, required super.reason, required super.sessionId});
}

final class ReclaimVerificationSessionExpiredException extends ReclaimVerificationException {
  const ReclaimVerificationSessionExpiredException(super.message, {required super.innerRpcError, required super.reason, required super.sessionId});
}

final class ReclaimVerificationDismissedException extends ReclaimVerificationException {
  const ReclaimVerificationDismissedException(super.message, {required super.innerRpcError, required super.reason, required super.sessionId});
}
