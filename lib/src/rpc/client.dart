import 'package:uuid/uuid.dart';

sealed class RpcMessage {
  final String id;

  const RpcMessage({required this.id});

  Map<String, Object?> toJson();

  factory RpcMessage.fromJson(Map<dynamic, dynamic> json) {
    if (!json.containsKey('method')) {
      return RpcResponse.fromJson(json);
    }
    return RpcRequest.fromJson(json);
  }
}

final class RpcRequest extends RpcMessage {
  final String method;
  final Object? params;

  const RpcRequest({
    required this.method,
    required this.params,
    required super.id,
  });

  RpcRequest.withGeneratedId({
    required this.method,
    required this.params,
  }) : super(id: const Uuid().v4());

  factory RpcRequest.fromJson(Map<dynamic, dynamic> json) {
    return RpcRequest(
      method: json['method'] as String,
      params: json['params'],
      id: json['id'] as String,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return {'id': id, 'method': method, 'params': params};
  }
}

sealed class RpcResponse extends RpcMessage {
  const RpcResponse({required super.id});

  factory RpcResponse.fromJson(Map<dynamic, dynamic> json) {
    if (json.containsKey('error')) {
      return RpcError.fromJson(json);
    }
    return RpcResult.fromJson(json);
  }
}

final class RpcResult extends RpcResponse {
  final Object? result;

  const RpcResult({required this.result, required super.id});

  @override
  Map<String, Object?> toJson() {
    return {'id': id, 'result': result};
  }

  factory RpcResult.fromJson(Map<dynamic, dynamic> json) {
    return RpcResult(result: json['result'], id: json['id'] as String);
  }
}

class RpcErrorCode {
  final int code;

  const RpcErrorCode(this.code);

  int toJson() {
    return code;
  }

  factory RpcErrorCode.fromJson(int code) {
    for (final value in values) {
      if (value.code == code) {
        return value;
      }
    }
    return RpcErrorCode(code);
  }

  bool get isServerError => code >= -32099 && code <= -32000;

  static const parseError = RpcErrorCode(-32700);
  static const invalidRequest = RpcErrorCode(-32600);
  static const methodNotFound = RpcErrorCode(-32601);
  static const invalidParams = RpcErrorCode(-32602);
  static const internalError = RpcErrorCode(-32603);

  static const values = [
    parseError,
    invalidRequest,
    methodNotFound,
    invalidParams,
    internalError,
  ];
}

final class RpcErrorInformation {
  final RpcErrorCode code;
  final String message;
  final Object? data;

  const RpcErrorInformation({
    required this.code,
    required this.message,
    this.data,
  });

  Map<String, Object?> toJson() {
    return {'code': code, 'message': message, 'data': data};
  }

  factory RpcErrorInformation.fromJson(Map<dynamic, dynamic> json) {
    return RpcErrorInformation(
      code: RpcErrorCode.fromJson(json['code'] as int),
      message: json['message'] as String,
      data: json['data'],
    );
  }

  factory RpcErrorInformation.parseError([Object? data]) {
    return RpcErrorInformation(
      code: RpcErrorCode.parseError,
      message: 'Parse error',
      data: data,
    );
  }

  factory RpcErrorInformation.invalidRequest([Object? data]) {
    return RpcErrorInformation(
      code: RpcErrorCode.invalidRequest,
      message: 'Invalid request',
      data: data,
    );
  }

  factory RpcErrorInformation.methodNotFound([Object? data]) {
    return RpcErrorInformation(
      code: RpcErrorCode.methodNotFound,
      message: 'Method not found',
      data: data,
    );
  }

  factory RpcErrorInformation.invalidParams([Object? data]) {
    return RpcErrorInformation(
      code: RpcErrorCode.invalidParams,
      message: 'Invalid params',
      data: data,
    );
  }

  factory RpcErrorInformation.internalError([Object? data]) {
    return RpcErrorInformation(
      code: RpcErrorCode.internalError,
      message: 'Internal error',
      data: data,
    );
  }

  factory RpcErrorInformation.serverError(int code, [Object? data]) {
    assert(code >= -32099 && code <= -32000);
    return RpcErrorInformation(
      code: RpcErrorCode.fromJson(code),
      message: 'Server error',
      data: data,
    );
  }
}

final class RpcError extends RpcResponse {
  final RpcErrorInformation error;

  const RpcError({required this.error, required super.id});

  @override
  Map<String, Object?> toJson() {
    return {'id': id, 'error': error};
  }

  factory RpcError.fromJson(Map<dynamic, dynamic> json) {
    return RpcError(
      error: RpcErrorInformation.fromJson(
        json['error'] as Map<dynamic, dynamic>,
      ),
      id: json['id'] as String,
    );
  }
}

abstract class RpcClient {
  const RpcClient();

  void send(RpcMessage message);

  Future<RpcResponse> sendRequest(String method, Object? params) {
    final request = RpcRequest.withGeneratedId(method: method, params: params);
    final response = messageStream.firstWhere((message) {
      return message is RpcResponse && message.id == request.id;
    }, orElse: () {
      return RpcError(
          error: RpcErrorInformation.internalError(
            'Client closed before a response was received',
          ),
          id: request.id);
    }).then((it) => it as RpcResponse);
    send(request);
    return response;
  }

  Stream<RpcMessage> get messageStream;

  void close();
}
