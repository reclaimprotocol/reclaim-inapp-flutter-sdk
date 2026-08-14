import 'dart:async';
import 'dart:convert';

import 'package:reclaim_tee_operator_flutter/reclaim_tee_operator_flutter.dart';

import '../../attestor.dart';

import '../attestor/client/native/client.dart' show TeeUrls;
import '../constants.dart';
import '../data/identity.dart';
import '../data/providers.dart';
import '../exception/exception.dart';
import '../logging/logging.dart';
import '../repository/feature_flags.dart';
import '../services/base_http.dart';

class ZkOperatorManager {
  final log = logging.child('ZkOperatorManager');

  bool providerUsesOprfMpc(HttpProvider provider) {
    final requestUsesOprfMpc = provider.requestData.fold<bool>(false, (previous, e) {
      final needsOprfCircuit = e.responseRedactions.any(
        (r) => r.hash?.trim().isNotEmpty == true && r.hash?.trim().toLowerCase() == 'oprf-mpc',
      );
      if (needsOprfCircuit) {
        return true;
      }
      return previous;
    });
    return requestUsesOprfMpc || provider.customInjection?.toLowerCase().contains('oprf-mpc') == true;
  }

  // Can improve performance by 12% by pre-initializing the algorithms that are needed for the requests (Computed from tests).
  Future<void> prepareOperatorForAlgorithmWithHints(HttpProvider provider) async {
    final logger = log.child('prepareZKOperatorWithHints');
    try {
      logger.info('preparing operator by hint from provider');
      if (!Attestor.instance.useTeeOperator) {
        logger.info('Setting up CHACHA20 for proxy mode');
        ProverAlgorithmInitializer.instance.ensureInitialized(ProverAlgorithmType.CHACHA20);
      }
      final needsOprfCircuitCount = provider.requestData.fold<int>(0, (previous, e) {
        final needsOprfCircuit = e.responseRedactions.any(
          (r) => r.hash?.trim().isNotEmpty == true && r.hash?.trim().toLowerCase() != 'oprf-mpc',
        );
        if (needsOprfCircuit) {
          return previous + 1;
        }
        return previous;
      });
      final requestCount = provider.requestData.length;
      final needsOprfCircuitForHashing = needsOprfCircuitCount > 0;
      logger.info(
        'needsOprfCircuitForHashing: $needsOprfCircuitForHashing, needsHashingCount: $needsOprfCircuitCount, requestCount: $requestCount',
      );
      if (needsOprfCircuitForHashing) {
        final requestCount = provider.requestData.length;
        if (requestCount > 1) {
          final int count = (requestCount - needsOprfCircuitCount).clamp(1, 6);
          final initializationDelay = Duration(seconds: count * 5);
          logger.info('initializationDelay: $initializationDelay');
          await Future.delayed(initializationDelay);
        }
        ProverAlgorithmInitializer.instance.ensureInitialized(ProverAlgorithmType.CHACHA20_OPRF);
      }
    } catch (e, s) {
      logger.severe('Failed to prepare ZKOperator with hints', e, s);
    }
  }

  Future<TeeUrls> getTeeUrls() async {
    final sessionIdentity = SessionIdentity.latest!;
    final featureFlagRepository = FeatureFlagRepository();

    final teeUrlsJson = await featureFlagRepository.getFeatureFlag(sessionIdentity, FeatureFlag.teeUrls);

    // Parse TEE URLs from JSON string with fallbacks to defaults
    String attestorWsUrl = ReclaimUrls.DEFAULT_TEE_ATTESTOR_WS_URL;
    String routerUrl = ReclaimUrls.DEFAULT_TEE_ROUTER_URL;

    try {
      if (teeUrlsJson.isNotEmpty) {
        final teeUrlsMap = json.decode(teeUrlsJson) as Map<String, dynamic>;
        attestorWsUrl = teeUrlsMap['teeAttestorUrl'] as String? ?? ReclaimUrls.DEFAULT_TEE_ATTESTOR_WS_URL;
        routerUrl = teeUrlsMap['routerUrl'] as String? ?? ReclaimUrls.DEFAULT_TEE_ROUTER_URL;
        log.info('🔐 TEE URLS: Using URLs from feature flags - attestorWsUrl: $attestorWsUrl, routerUrl: $routerUrl');
      }
    } catch (e) {
      log.warning('🔐 TEE URLS: Failed to parse teeUrls JSON, using defaults: $e');
    }

    return TeeUrls(attestorWsUrl: attestorWsUrl, routerUrl: routerUrl);
  }

  Future<bool> isServiceAccessible(String url) async {
    final logger = log.child('isServiceAccessible');
    final uri = Uri.parse(url);
    try {
      final response = await reclaimHttpBaseClient.head(
        uri.replace(scheme: uri.host.contains('localhost') ? 'http' : 'https'),
      );
      final isAccessible = response.statusCode >= 200 && response.statusCode < 500;
      if (!isAccessible) {
        logger.warning(
          '🔐 TEE URLS: Failed to pre-test with failed status code ${response.statusCode} for TEE $url URL',
        );
      }
      return isAccessible;
    } catch (e, s) {
      logger.warning('🔐 TEE URLS: Failed to pre-test TEE $url URL', e, s);
      return false;
    }
  }

  Future<void> preTestTeeUrls() async {
    final logger = log.child('preTestTeeUrls');

    final teeUrls = await getTeeUrls();

    final String attestorWsUrl = teeUrls.attestorWsUrl;
    final String routerUrl = teeUrls.routerUrl;

    logger.info('🔐 TEE URLS: Can use URLs - attestorWsUrl: $attestorWsUrl, routerUrl: $routerUrl');

    try {
      final attestorUrlAsync = isServiceAccessible(attestorWsUrl);
      final routerUrlAsync = isServiceAccessible(routerUrl);
      await Future.wait([attestorUrlAsync, routerUrlAsync]);
      logger.info(
        '🔐 TEE URLS: Pre-tested TEE URLs, results: attestorWsUrlResult=${await attestorUrlAsync}, routerUrlResult=${await routerUrlAsync}',
      );
    } catch (e, s) {
      log.warning('🔐 TEE URLS: Failed to pre-test TEE URLs', e, s);
    }
  }

  Future<void> setupZkOperator(SessionIdentity identity, {bool? explicitUseTeeOperator}) async {
    try {
      // Fetch rollout configuration from feature flags in parallel
      final featureFlagsRepo = FeatureFlagRepository();

      // Determine final decision: toggle override or feature flag
      final bool shouldUseTeeMode;
      final String reason;

      if (explicitUseTeeOperator != null) {
        // Manual override from toggle
        shouldUseTeeMode = explicitUseTeeOperator;
        reason = 'toggle-override';
      } else {
        final useTEE = await featureFlagsRepo.getFeatureFlag(identity, FeatureFlag.useTEE);
        log.info('🎯 TEE Rollout Configuration: useTEE=$useTEE ');

        // Use feature flag
        shouldUseTeeMode = useTEE;
        reason = 'feature-flag';
      }
      log.info('✅ TEE mode decision: $shouldUseTeeMode (reason: $reason)');

      Attestor.instance.setUseTeeOperator(shouldUseTeeMode);

      // Apply the decision
      if (shouldUseTeeMode) {
        log.info('🔐 TEE: Enabling TEE mode - using native TEE operator');
        preTestTeeUrls();
      } else {
        // For proxy mode, use provided operator or create GNARK operator
        log.info('🔧 PROXY: Enabling Proxy mode - using GNARK operator');
      }
    } catch (e, s) {
      log.severe('Error setting up zk operator', e, s);
      throw const ReclaimAttestorException('Error initializing attestor');
    }

    if (!(await Attestor.instance.isPlatformSupported())) {
      log.event(
        Level.SEVERE.withEvent(LogEventType.RECLAIM_VERIFICATION_PLATFORM_NOT_SUPPORTED_EXCEPTION),
        'SDK is not running with a 64 bit runtime environment',
      );
      throw const ReclaimVerificationPlatformNotSupportedException();
    }

    unawaited(Attestor.instance.ensureReady());
  }
}
