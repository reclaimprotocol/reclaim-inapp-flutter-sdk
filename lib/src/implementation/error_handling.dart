import '../exception/exception.dart';
import '../rpc/client.dart';
import 'rpc_error_code.dart';

ReclaimVerificationException createVerificationExceptionFromRpcError(RpcError rpcError, String? sessionId) {
  switch (rpcError.error.code.code) {
    case RpcApplicationErrorCode.verification:
      final data = rpcError.error.data as Map;
      final maybeSessionId = data['sessionId'] ?? sessionId;
      switch (data['type']) {
        case 'cancelled':
          return ReclaimVerificationCancelledException(data['message'] ?? 'Verification cancelled', innerRpcError: rpcError.error, reason: data['reason'] ?? "Verification cancelled", sessionId: maybeSessionId);
        case 'dismissed':
          return ReclaimVerificationDismissedException(data['message'] ?? 'Verification dismissed', innerRpcError: rpcError.error, reason: data['reason'] ?? "Verification dismissed", sessionId: maybeSessionId);
        case 'failed':
          return ReclaimVerificationFailedException(data['message'] ?? 'Verification failed', innerRpcError: rpcError.error, reason: data['reason'] ?? "Verification failed", sessionId: maybeSessionId);
        case 'sessionExpired':
          return ReclaimVerificationSessionExpiredException(data['message'] ?? 'Verification session expired', innerRpcError: rpcError.error, reason: data['reason'] ?? "Verification session expired", sessionId: maybeSessionId);
        default:
          break;
      }
    default:
      break;
  }
  return ReclaimVerificationFailedException("Verification failed", innerRpcError: rpcError.error, reason: "Verification failed", sessionId: sessionId);
}
