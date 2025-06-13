import 'dart:async';

import '../logging/logging.dart';
import '../services/session.dart';
import '../utils/crypto.dart';
import 'verification/version.dart';

export '../services/session.dart' show SessionStatus;
export 'verification/version.dart';

typedef SessionProvider = FutureOr<ReclaimSessionInformation> Function();

const _anyProviderVersion = '';

final class ReclaimSessionInformation {
  final String timestamp;
  final String sessionId;
  final String signature;
  final ProviderVersionExact version;

  const ReclaimSessionInformation({
    required this.sessionId,
    required this.signature,
    required this.timestamp,
    required this.version,
  });

  bool get isValid {
    return signature.trim().isNotEmpty && timestamp.trim().isNotEmpty;
  }

  static Future<ReclaimSessionInformation> generateNew({
    required String applicationId,
    required String applicationSecret,
    required String providerId,
    String providerVersion = _anyProviderVersion,
  }) async {
    final String ts = DateTime.now().millisecondsSinceEpoch.toString();

    final Map<String, dynamic> options = {"providerId": providerId, "timestamp": ts};

    final signature = signMap(options, applicationSecret);

    try {
      logging.config(
        'Creating new session with appId: $applicationId, providerId: $providerId, timestamp: $ts, signature: $signature',
      );
      final session = await ReclaimSession.createSession(
        appId: applicationId,
        providerId: providerId,
        timestamp: ts,
        signature: signature,
        providerVersion: providerVersion,
      );
      await ReclaimSession.updateSession(session.sessionId, SessionStatus.USER_INIT_VERIFICATION);
      logging.config('new session created: ${session.sessionId}');
      return ReclaimSessionInformation(
        timestamp: ts,
        sessionId: session.sessionId,
        signature: signature,
        version: ProviderVersionExact(session.resolvedProviderVersion ?? '', versionExpression: providerVersion),
      );
    } catch (e, s) {
      logging.severe('Error generating new session', e, s);
      rethrow;
    }
  }
}
