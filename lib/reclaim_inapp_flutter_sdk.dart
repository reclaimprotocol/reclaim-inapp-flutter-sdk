import 'platform_interface.dart';

class ReclaimVerirication {
  Future<String?> getPlatformVersion() {
    return ReclaimInappFlutterSdkPlatform.instance.getPlatformVersion();
  }
}
