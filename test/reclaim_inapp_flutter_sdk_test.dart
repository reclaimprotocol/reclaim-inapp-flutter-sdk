import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:reclaim_inapp_flutter_sdk/platform_interface.dart';
import 'package:reclaim_inapp_flutter_sdk/reclaim_inapp_flutter_sdk.dart';
import 'package:reclaim_inapp_flutter_sdk/src/method_channel.dart';

class MockReclaimInappFlutterSdkPlatform with MockPlatformInterfaceMixin implements ReclaimInappFlutterSdkPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ReclaimInappFlutterSdkPlatform initialPlatform = ReclaimInappFlutterSdkPlatform.instance;

  test('$MethodChannelReclaimInappFlutterSdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelReclaimInappFlutterSdk>());
  });

  test('getPlatformVersion', () async {
    ReclaimVerirication reclaimInappFlutterSdkPlugin = ReclaimVerirication();
    MockReclaimInappFlutterSdkPlatform fakePlatform = MockReclaimInappFlutterSdkPlatform();
    ReclaimInappFlutterSdkPlatform.instance = fakePlatform;

    expect(await reclaimInappFlutterSdkPlugin.getPlatformVersion(), '42');
  });
}
