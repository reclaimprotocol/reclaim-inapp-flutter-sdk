import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../platform_interface.dart';
import '../rpc/client.dart';
import '../rpc/message_codec.dart';
import 'error_handling.dart';

/// An implementation of [ReclaimInappFlutterSdkPlatform] that uses method channels.
class MethodChannelReclaimInappFlutterSdk extends ReclaimInappFlutterSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  static const channel = BasicMessageChannel('org.reclaimprotocol.inapp_sdk.rpc', JsonRpcMessageCodec());

  late final rpcClient = PlatformRpcClient(channel: channel);

  @override
  Future<String?> ping() async {
    final response = await rpcClient.sendRequest('ping', null);
    return switch (response) {
      RpcResult(:final result) => result as String,
      RpcError(:final error) => throw error,
    };
  }

  @override
  Future<ReclaimVerificationResponse> startVerification(ReclaimVerificationRequest request) async {
    final response = await rpcClient.sendRequest('startVerification', {"request": request});
    return switch (response) {
      RpcResult() => ReclaimVerificationResponse.fromJson(response.result as Map),
      RpcError() => throw createVerificationExceptionFromRpcError(response, null),
    };
  }
}
