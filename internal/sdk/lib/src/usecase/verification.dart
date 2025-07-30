import 'dart:async';
import 'dart:collection';

import 'package:flutter_inappwebview/flutter_inappwebview.dart' show UserScript;

import '../../attestor.dart';
import '../data/app_info.dart';
import '../data/identity.dart';
import '../data/providers.dart';
import '../data/verification/verification.dart';
import '../exception/exception.dart';
import '../logging/logging.dart';
import '../repository/feature_flags.dart';
import '../services/cookie_service.dart';
import '../services/provider.dart';
import '../services/user_script_service.dart';
import '../web_scripts/hawkeye/interception_method.dart';
import 'session_manager.dart';

class VerificationFlowManager {
  final log = logging.child('VerificationFlowManager');

  StreamSubscription<String> startAttestorUrlUpdates(SessionIdentity identity) {
    return FeatureFlagRepository().watchFeatureFlag(identity, FeatureFlag.attestorBrowserRpcUrl).listen((url) {
      final uri = Uri.tryParse(url);
      if (uri == null) {
        log.severe('Invalid attestor browser rpc url: $url');
        return;
      }
      Attestor.instance.setAttestorUrl(uri);
    });
  }

  Future<HttpProvider> fetchProvider({
    required String applicationId,
    required String providerId,
    required ReclaimSessionInformation sessionInformation,
    required ProviderVersionExact version,
  }) async {
    try {
      final response = await ReclaimProviderService().getProviders(
        applicationId,
        providerId,
        sessionInformation.sessionId,
        sessionInformation.signature,
        sessionInformation.timestamp,
        resolvedVersion: version.resolvedVersion,
      );

      final httpProvider = response?.providers?.httpProvider?.firstOrNull;

      if (httpProvider == null) {
        throw const ReclaimVerificationProviderNotFoundException();
      }

      return httpProvider;
    } on ReclaimException {
      rethrow;
    } catch (e, s) {
      logging.severe('Error fetching provider', e, s);
      throw ReclaimVerificationProviderLoadException('Error fetching provider');
    }
  }

  Future<AttestorAuthenticationRequest?> fetchAttestorAuthenticationRequest({
    required HttpProvider provider,
    required ReclaimAttestorAuthenticationRequestCallback callback,
  }) async {
    final logger = log.child('fetchAttestorAuthenticationRequest');
    try {
      return await callback(provider);
    } catch (e) {
      logger.severe('Error fetching attestor authentication request', e);
      // We want to show the error to the developer.
      throw ReclaimAttestorException('Error fetching attestor authentication request');
    }
  }

  Future<HttpProvider> fetchRequestedProvider({
    required String applicationId,
    required String providerId,
    required ReclaimSessionInformation sessionInformation,
    required ProviderVersionExact version,
  }) async {
    final provider = await VerificationFlowManager().fetchProvider(
      applicationId: applicationId,
      providerId: providerId,
      sessionInformation: sessionInformation,
      version: version,
    );

    await SessionManager().onRequestedProvidersFetched(
      applicationId: applicationId,
      providerId: providerId,
      sessionId: sessionInformation.sessionId,
    );

    return provider;
  }

  Future<bool> _hasRecurringProofs(Future<AppInfo> appInfoFuture) async {
    try {
      final appInfo = await appInfoFuture;
      return appInfo.isRecurring;
    } catch (e, s) {
      log.child('hasRecurringProofs').severe('Error checking if app has recurring proofs', e, s);
      return false;
    }
  }

  Future<void> clearWebStorageIfRequired(
    SessionIdentity identity,
    Future<AppInfo> appInfoFuture,
    bool canClearWebStorage,
  ) async {
    try {
      log.fine('canClearWebStorage: $canClearWebStorage');
      if (canClearWebStorage) {
        // clear storage if sdk consumer does't want to prevent it
        final canSaveWebStorageDevPreference = await FeatureFlagRepository().getFeatureFlag(
          identity,
          FeatureFlag.canSaveWebStorageDev,
        );
        log.config('canSaveWebStorageDevPreference: $canSaveWebStorageDevPreference');
        // dont clear storage if developer toggled saving
        if (!canSaveWebStorageDevPreference) {
          final isRecurring = await _hasRecurringProofs(appInfoFuture);
          log.info('app.isRecurring: $isRecurring');
          if (!isRecurring) {
            final cs = CookieService();
            await cs.clearCookies();
          }
        }
      }
    } catch (e, s) {
      log.severe('Error clearing web storage', e, s);
    }
  }

  Future<UnmodifiableListView<UserScript>> loadUserScripts({
    required HttpProvider provider,
    required Map<String, String> parameters,
    required HawkeyeInterceptionMethod hawkeyeInterceptionMethod,
  }) async {
    try {
      return await UserScriptService.createUserScripts(
        providerData: provider,
        parameters: parameters,
        idleTimeThreshold: 10,
        hawkeyeInterceptionMethod: hawkeyeInterceptionMethod,
      );
    } catch (e, s) {
      log.severe('Error loading user scripts for provider', e, s);
      throw ReclaimVerificationProviderLoadException('Error loading user scripts for provider');
    }
  }
}
