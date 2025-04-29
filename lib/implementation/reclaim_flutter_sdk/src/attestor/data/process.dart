import 'dart:async';

import '../client/browser_rpc/message.dart';

/// Represents an attestation process with a request and response lifecycle.
///
/// An `AttestorProcess` encapsulates the request, response, and update stream for
/// a specific attestation operation identified by `id` and `type`.
///
/// Type parameters:
/// - [REQUEST]: The type of the request payload.
/// - [RESPONSE]: The type of the response payload.

class AttestorProcess<
    REQUEST extends Object?,
    RESPONSE extends Object?> {
  final String
      id;
  final String
      type;
  final REQUEST
      request;
  final Future<RESPONSE>
      response;
  final Stream<Map<String, Object?>>
      updateStream;

  const AttestorProcess({
    required this.id,
    required this.type,
    required this.request,
    required this.response,
    required this.updateStream,
  });

  RpcRequest<REQUEST>
      createRequest({
    required String
        module,
    required String
        channel,
  }) {
    return RpcRequest<
        REQUEST>(
      id: id,
      type:
          type,
      request:
          request,
      module:
          module,
      channel:
          channel,
    );
  }
}
