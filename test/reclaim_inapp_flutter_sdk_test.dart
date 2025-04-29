import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:reclaim_inapp_flutter_sdk/platform_interface.dart';
import 'package:reclaim_inapp_flutter_sdk/reclaim_inapp_flutter_sdk.dart';
import 'package:reclaim_inapp_flutter_sdk/src/implementation/method_channel.dart';

class MockReclaimInappFlutterSdkPlatform with MockPlatformInterfaceMixin implements ReclaimInappFlutterSdkPlatform {
  @override
  Future<String?> ping() => Future.value('pong');

  @override
  Future<ReclaimVerificationResponse> startVerification(ReclaimVerificationRequest request) {
    throw UnimplementedError();
  }
}

void main() {
  group('api mock test', () {
    final ReclaimInappFlutterSdkPlatform initialPlatform = ReclaimInappFlutterSdkPlatform.instance;

    test('$MethodChannelReclaimInappFlutterSdk is the default instance', () {
      expect(initialPlatform, isInstanceOf<MethodChannelReclaimInappFlutterSdk>());
    });

    test('ping', () async {
      ReclaimVerification reclaimInappFlutterSdkPlugin = ReclaimVerification();
      MockReclaimInappFlutterSdkPlatform fakePlatform = MockReclaimInappFlutterSdkPlatform();
      ReclaimInappFlutterSdkPlatform.instance = fakePlatform;

      expect(await reclaimInappFlutterSdkPlugin.ping(), 'pong');
    });
  });
}
