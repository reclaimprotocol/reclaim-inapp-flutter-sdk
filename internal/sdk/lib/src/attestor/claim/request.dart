import 'dart:collection';
import 'dart:convert';

import 'options.dart';

enum ZKOperationType { snarkJs, gnarkRpc, gnarkTEENative }

class AttestorClaimRequest {
  final ZKOperationType operationType;
  final UnmodifiableMapView<String, Object?> message;

  const AttestorClaimRequest({required this.operationType, required this.message});

  factory AttestorClaimRequest.create({
    required ZKOperationType operationType,
    required AttestorClaimOptions options,
    required Map<String, Object?> request,
  }) {
    final message = <String, Object?>{...request, "zkProofConcurrency": 1};
    if (operationType == ZKOperationType.gnarkRpc) {
      message["zkEngine"] = "gnark";
      message["zkOperatorMode"] = "rpc";
      message["zkProofConcurrency"] = 2;
    }
    final authRequest = options.attestorAuthenticationRequest;
    if (authRequest != null) {
      switch (operationType) {
        case ZKOperationType.snarkJs:
        case ZKOperationType.gnarkRpc:
          message["authRequest"] = authRequest;
          break;
        case ZKOperationType.gnarkTEENative:
          message["authRequest"] = _jsonToBase64Codec.encode({
            'data': authRequest.data,
            'signature': authRequest.signature?.value,
          });
          break;
      }
    }
    return AttestorClaimRequest(operationType: operationType, message: UnmodifiableMapView(message));
  }

  Map<String, Object?> toJson() {
    return message;
  }
}

final _jsonToBase64Codec = json.fuse(utf8.fuse(base64));
