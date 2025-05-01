import 'package:reclaim_flutter_sdk/constants.dart';
import 'package:reclaim_flutter_sdk/logging/logging.dart';
import 'package:reclaim_flutter_sdk/utils/crypto.dart';
import 'package:reclaim_flutter_sdk/utils/session.dart';

class ReclaimSessionInformation {
  final String timestamp;
  final String sessionId;
  final String signature;

  const ReclaimSessionInformation({
    required this.sessionId,
    required this.signature,
    required this.timestamp,
  });

  const ReclaimSessionInformation.empty()
    : sessionId = '',
      signature = '',
      timestamp = '';

  bool get isValid {
    return signature.trim().isNotEmpty && timestamp.trim().isNotEmpty;
  }

  static Future<ReclaimSessionInformation> generateNew({
    required String providerId,
    required String applicationSecret,
    required String applicationId,
  }) async {
    final String ts = DateTime.now().millisecondsSinceEpoch.toString();

    final Map<String, dynamic> options = {
      "providerId": providerId,
      "timestamp": ts,
    };

    final signature = signMap(options, applicationSecret);

    try {
      final sessionId = await ReclaimSession.createSession(
        appId: applicationId,
        providerId: providerId,
        timestamp: ts,
        signature: signature,
      );
      await ReclaimSession.updateSession(
        sessionId,
        SessionStatus.USER_INIT_VERIFICATION,
      );
      return ReclaimSessionInformation(
        timestamp: ts,
        sessionId: sessionId,
        signature: signature,
      );
    } catch (e, s) {
      logging.severe('Error generating new session', e, s);
      rethrow;
    }
  }
}
