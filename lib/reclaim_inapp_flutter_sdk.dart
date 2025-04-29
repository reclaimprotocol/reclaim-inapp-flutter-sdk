import 'platform_interface.dart';

export 'src/data/data.dart';
export 'src/exception/exception.dart';

class ReclaimVerification {
  Future<String?> ping() {
    return ReclaimInappFlutterSdkPlatform.instance.ping();
  }

  Future<ReclaimVerificationResponse> startVerification(ReclaimVerificationRequest request) {
    return ReclaimInappFlutterSdkPlatform.instance.startVerification(request);
  }
}
