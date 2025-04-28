import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_inapp_flutter_sdk/src/method_channel.dart';
import 'package:reclaim_inapp_flutter_sdk/src/rpc/client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelReclaimInappFlutterSdk platform = MethodChannelReclaimInappFlutterSdk();
  const channel = MethodChannelReclaimInappFlutterSdk.channel;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockDecodedMessageHandler(
      channel,
      (message) async {
        if (message == null) return RpcError(error: RpcErrorInformation.invalidParams(), id: message?.id ?? '');
        return RpcResult(result: '42', id: message.id);
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockDecodedMessageHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
