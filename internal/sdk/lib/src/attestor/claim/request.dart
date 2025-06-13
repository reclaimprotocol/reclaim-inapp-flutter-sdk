import 'dart:collection';

import 'options.dart';

enum ZKOperationType { snarkJs, gnarkRpc }

class AttestorClaimRequest {
  final ZKOperationType operationType;
  final UnmodifiableMapView<String, Object?> message;

  const AttestorClaimRequest({required this.operationType, required this.message});

  factory AttestorClaimRequest.create({
    required final ZKOperationType operationType,
    required final AttestorClaimOptions options,
    required final Map<String, Object?> request,
  }) {
    final message = <String, Object?>{...request, "zkProofConcurrency": 1};
    if (operationType == ZKOperationType.gnarkRpc) {
      message["zkEngine"] = "gnark";
      message["zkOperatorMode"] = "rpc";
      message["zkProofConcurrency"] = 2;
    }
    final authRequest = options.attestorAuthenticationRequest;
    if (authRequest != null) {
      message["authRequest"] = authRequest;
    }
    return AttestorClaimRequest(operationType: operationType, message: UnmodifiableMapView(message));
  }

  Map<String, Object?> toJson() {
    return message;
  }
}
