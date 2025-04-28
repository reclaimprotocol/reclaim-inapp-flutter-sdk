import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'client.dart';

final _jsonToBytes = json.fuse(utf8);

class JsonRpcMessageCodec implements MessageCodec<RpcMessage?> {
  const JsonRpcMessageCodec();

  @override
  RpcMessage? decodeMessage(ByteData? message) {
    if (message == null) return null;
    final bytes = message.buffer.asUint8List();
    assert(bytes.isNotEmpty, 'Message is empty');
    final data = _jsonToBytes.decode(bytes) as Map;
    final rpcMessage = RpcMessage.fromJson(data);
    return rpcMessage;
  }

  @override
  ByteData? encodeMessage(RpcMessage? message) {
    if (message == null) return null;
    final data = ByteData.sublistView(
      Uint8List.fromList(_jsonToBytes.encode(message)),
    );
    return data;
  }
}

class PlatformRpcClient extends RpcClient {
  final BasicMessageChannel<RpcMessage?> channel;
  final StreamController<RpcMessage> _controller = StreamController<RpcMessage>.broadcast();

  PlatformRpcClient({required this.channel}) {
    channel.setMessageHandler(_onMessage);
  }

  @override
  Stream<RpcMessage> get messageStream => _controller.stream;

  @override
  Future<void> send(RpcMessage message) async {
    if (kDebugMode) {
      print('send: ${json.encode(message)}');
    }
    final result = await channel.send(message);
    if (result != null) {
      _onMessage(result);
    }
  }

  Future<RpcMessage?> _onMessage(RpcMessage? message) async {
    if (kDebugMode) {
      print('onMessage: ${json.encode(message)}');
    }
    if (message == null) return null;
    _controller.sink.add(message);
    return null;
  }

  @override
  void close() {
    channel.setMessageHandler(null);
    _controller.close();
  }
}
