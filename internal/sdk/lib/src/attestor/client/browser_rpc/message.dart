// Base class for all RPC messages in the Attestor RPC messaging.
//
// This sealed class defines the common properties for all RPC messages
// and enforces implementation of the `toJson` method for serialization.

sealed class RpcMessage {
  const RpcMessage({required this.id, required this.type, required this.module});

  final String id;
  final String type;
  final String module;

  // Require toJson to be implemented by subclasses for json encoding
  Map<String, dynamic> toJson();
}

final class RpcRequest<REQUEST extends Object?> extends RpcMessage {
  const RpcRequest({
    required super.id,
    required super.type,
    required super.module,
    required this.request,
    required this.channel,
  });

  final REQUEST request;
  final String channel;

  @override
  Map<String, dynamic> toJson() {
    return {'id': id, 'type': type, 'module': module, 'channel': channel, 'request': request};
  }
}

final class RpcResponse<RESPONSE extends Object?> extends RpcMessage {
  const RpcResponse({required super.id, required super.type, required super.module, required this.response});

  final RESPONSE response;

  @override
  Map<String, dynamic> toJson() {
    return {'id': id, 'type': type, 'module': module, 'response': response, 'isResponse': true};
  }
}

class RpcResponseErrorData {
  const RpcResponseErrorData({required this.message, required this.stack});
  final String message;
  final String stack;

  factory RpcResponseErrorData.fromException(Object exception, StackTrace? stackTrace) {
    return RpcResponseErrorData(message: exception.toString(), stack: stackTrace?.toString() ?? '');
  }

  factory RpcResponseErrorData.fromJson(Map<String, dynamic> json) {
    return RpcResponseErrorData(message: json['message'] as String? ?? '', stack: json['stack'] as String? ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'message': message, 'stack': stack};
  }
}

final class RpcResponseError<RpcResponseErrorData> extends RpcMessage {
  const RpcResponseError({required super.id, required super.module, required this.data}) : super(type: 'error');

  final RpcResponseErrorData data;

  @override
  Map<String, dynamic> toJson() {
    return {'id': id, 'type': type, 'module': module, 'data': data, 'isResponse': true};
  }
}
