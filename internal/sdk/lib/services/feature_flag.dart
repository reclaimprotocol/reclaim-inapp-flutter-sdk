import 'package:dio/dio.dart';
import 'package:reclaim_flutter_sdk/data/identity.dart';
import 'package:reclaim_flutter_sdk/overrides/overrides.dart';
import 'package:reclaim_flutter_sdk/utils/dio.dart';
import 'package:reclaim_flutter_sdk/utils/keys.dart';
import 'package:reclaim_flutter_sdk/utils/storage.dart';

import '../constants.dart';
import '../logging/logging.dart';

class FeatureFlagService {
  static final Dio _dio = buildDio();

  static Future<ReclaimFeatureFlagData> getFeatureFlagsWithOverrides(SessionIdentity identity) async {
    final logger = logging.child('FeatureFlags.getFeatureFlagsWithOverrides');

    final featureFlagsOverrides = ReclaimOverrides.featureFlag;

    logger.info({
      'overriden_flags': featureFlagsOverrides,
    });

    final attestorBrowserRpcUrlOverride = featureFlagsOverrides?.attestorBrowserRpcUrl;

    final featureFlagNames = [
      if (featureFlagsOverrides?.idleTimeThresholdForManualVerificationTrigger == null)
        'idleTimeThresholdForManualVerificationTrigger',
      if (featureFlagsOverrides?.sessionTimeoutForManualVerificationTrigger == null)
        'sessionTimeoutForManualVerificationTrigger',
      if (attestorBrowserRpcUrlOverride == null || attestorBrowserRpcUrlOverride.isEmpty)
        'attestorBrowserRpcUrl',
      if (featureFlagsOverrides?.isAIFlowEnabled == null)
        'isAIFlowEnabled',
      if (featureFlagsOverrides?.canUseAiFlow == null)
        'canUseAiFlow',
      if (featureFlagsOverrides?.manualReviewMessage == null)
        'manualReviewMessage',
    ];

    logger.info({
      'flags_to_fetch_from_server': featureFlagNames,
    });
  
    final flags = await getFeatureFlagsRaw(identity, featureFlagNames);

    final effectiveFlags = ReclaimFeatureFlagData(
      idleTimeThresholdForManualVerificationTrigger: featureFlagsOverrides?.idleTimeThresholdForManualVerificationTrigger ?? flags['idleTimeThresholdForManualVerificationTrigger'],
      sessionTimeoutForManualVerificationTrigger: featureFlagsOverrides?.sessionTimeoutForManualVerificationTrigger ?? flags['sessionTimeoutForManualVerificationTrigger'],
      attestorBrowserRpcUrl: attestorBrowserRpcUrlOverride != null && attestorBrowserRpcUrlOverride.isNotEmpty
        ? attestorBrowserRpcUrlOverride
        : flags['attestorBrowserRpcUrl'],
      isAIFlowEnabled: featureFlagsOverrides?.isAIFlowEnabled ?? flags['isAIFlowEnabled'] ?? false,
      canUseAiFlow: featureFlagsOverrides?.canUseAiFlow ?? flags['canUseAiFlow'] ?? false,
      manualReviewMessage: featureFlagsOverrides?.manualReviewMessage ?? flags['manualReviewMessage'],
    );

    logger.info({
      'effective_flags': effectiveFlags,
    });

    return effectiveFlags;
  }

  static Future<Map<String, dynamic>> getFeatureFlagsRaw(
    SessionIdentity identity,
    Iterable<String> featureFlagNames,
  ) async {
    if (featureFlagNames.isEmpty) return const {};

    const storage = ReclaimStorage();
    final String privateKey = await storage.getData('ReclaimOwnerPrivateKey');
    final String publicKey = getPublicKey(privateKey);
    logging
        .child('FeatureFlags')
        .info('Extracted public key: $publicKey, SessionIdentity: $identity');
    try {
      return await FeatureFlagService.fetchFeatureFlagsFromServer(
        featureFlagNames: featureFlagNames.toSet().toList(),
        appId: identity.appId,
        providerId: identity.providerId,
        sessionId: identity.sessionId,
        publicKey: publicKey,
      );
    } catch (e, s) {
      logging
          .child('FeatureFlags')
          .severe('Error fetching feature flags', e, s);
      return const {};
    }
  }

  static Future<Map<String, dynamic>> fetchFeatureFlagsFromServer({
    required List<String> featureFlagNames,
    String? publicKey,
    String? appId,
    String? providerId,
    String? sessionId,
  }) async {
    final queryParams = {
      if (publicKey != null) 'publicKey': publicKey,
      'featureFlagNames': featureFlagNames,
      if (appId != null) 'appId': appId,
      if (providerId != null) 'providerId': providerId,
      if (sessionId != null) 'sessionId': sessionId,
    };

    try {
      final response = await _dio.get(
        '${ReclaimBackend.FEATURE_FLAGS_API}/get',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = response.data as List<dynamic>;
        final Map<String, dynamic> featureFlags = {};

        for (var flag in responseData) {
          if (flag is Map<String, dynamic>) {
            final String flagName = flag['name'] as String;
            final dynamic flagValue = flag['value'];
            if (flag['type'] == 'boolean') {
              featureFlags[flagName] = flagValue as bool? ?? false;
            } else if (flag['type'] == 'string') {
              featureFlags[flagName] = flagValue as String? ?? '';
            } else if (flag['type'] == 'number') {
              featureFlags[flagName] = flagValue as int? ?? 0;
            }
          }
        }

        return featureFlags;
      } else {
        throw Exception('Failed to load feature flags: ${response.statusCode}');
      }
    } catch (e) {
      logging.child('FeatureFlags').severe('Error fetching feature flags: $e');
      return {};
    }
  }
}
