import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:reclaim_verifier_module/reclaim_verifier_module.dart';

export 'package:reclaim_inapp_sdk/attestor.dart';
export 'package:reclaim_inapp_sdk/overrides.dart';
export 'package:reclaim_inapp_sdk/reclaim_inapp_sdk.dart'
    hide ReclaimVerification;

export 'package:reclaim_verifier_module/reclaim_verifier_module.dart';
export './src/extensions.dart';

// ignore: unused_element
final _logger = Logger('reclaim_flutter_sdk.reclaim_verifier_module');

class ReclaimCapabilityException implements Exception {
  final String message;

  const ReclaimCapabilityException(this.message);

  @override
  String toString() => 'ReclaimCapabilityException: $message';
}

SessionIdentity? latestSessionIdentity;

Future<T> _useFlow<T>(
  BuildContext context,
  Future<T> Function(ReclaimModuleExternalApi api) cb,
) async {
  CAPABILITY_ACCESS_TOKEN_VERIFICATION_KEY =
      _CAPABILITY_ACCESS_TOKEN_VERIFICATION_KEY;
  final key = GlobalKey<ReclaimModuleAppState>();
  final completer = Completer<ReclaimModuleExternalApi>();
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) {
        return ReclaimModuleApp.build(
          key: key,
          onApi: (api) {
            completer.complete(api);
          },
        );
      },
    ),
  );
  final api = await completer.future.timeout(
    Duration(seconds: 5),
    onTimeout: () {
      throw StateError('Could not start ReclaimModule');
    },
  );
  api.setSessionIdentityListener((s) {
    latestSessionIdentity = s;
    return;
  });
  try {
    final result = await cb(api);

    return result;
  } catch (e, s) {
    logger.severe('API Failed', e, s);
    rethrow;
  } finally {
    final inappSdkContext = key.currentContext;
    if (inappSdkContext != null && inappSdkContext.mounted) {
      final navigator = Navigator.of(inappSdkContext, rootNavigator: true);
      navigator.pop();
    }
  }
}

class ReclaimInAppSdk {
  final BuildContext context;

  ReclaimInAppSdk.of(this.context);

  static Future<void> preWarm() async {
    WidgetsFlutterBinding.ensureInitialized();

    return ReclaimModuleApp.preWarm();
  }

  Future<void> setVerificationOptions(
    ReclaimApiVerificationOptions? options,
  ) async {
    return _useFlow(context, (api) {
      return api.setVerificationOptions(options);
    });
  }

  Future<ReclaimApiVerificationResponse> startVerification(
    ReclaimVerificationRequest request,
  ) async {
    final sessionFuture = request.sessionProvider();
    return _useFlow(context, (api) async {
      final session = await sessionFuture;
      return api.startVerification(
        ReclaimApiVerificationRequest(
          appId: request.applicationId,
          providerId: request.providerId,
          // always generated from session
          secret: '',
          signature: session.signature,
          timestamp: session.timestamp,
          context: request.contextString ?? '',
          sessionId: session.sessionId,
          parameters: request.parameters,
          providerVersion: ProviderVersionApi(
            versionExpression: session.version.versionExpression,
            resolvedVersion: session.version.resolvedVersion,
          ),
        ),
      );
    });
  }

  Future<ReclaimApiVerificationResponse> startVerificationFromUrl(
    String url, {
    int depth = 0,
  }) async {
    return _useFlow(context, (api) {
      return api.startVerificationFromUrl(url);
    });
  }

  Future<ReclaimApiVerificationResponse> startVerificationFromJson(
    Map<dynamic, dynamic> template,
  ) {
    return _useFlow(context, (api) {
      return api.startVerificationFromJson(template);
    });
  }

  Future<void> clearAllOverrides() async {
    return _useFlow(context, (api) {
      return api.clearAllOverrides();
    });
  }

  Future<void> setOverrides({
    ClientProviderInformationOverride? provider,
    ClientFeatureOverrides? feature,
    ClientLogConsumerOverride? logConsumer,
    ClientReclaimSessionManagementOverride? sessionManagement,
    ClientReclaimAppInfoOverride? appInfo,
    String? capabilityAccessToken,
    required ReclaimHostOverridesApi overridesHandlerApi,
  }) async {
    return _useFlow(context, (api) {
      return api.setOverrides(
        provider,
        feature,
        logConsumer,
        sessionManagement,
        appInfo,
        capabilityAccessToken,
        overridesHandlerApi: overridesHandlerApi,
      );
    });
  }
}

const _CAPABILITY_ACCESS_TOKEN_VERIFICATION_KEY =
    'eyJraWQiOiI4NjgyNGJkMS04ZDU4LTQ5YWQtODVlMC03YzYxYWUyYTNjM2IiLCJrZXlfb3BzIjpbInNpZ24iXSwiZXh0Ijp0cnVlLCJrdHkiOiJFQyIsIngiOiJfNHpINjBTSTRJMmFwblZWM3lBUy1sUGFqcG80R3k0ZmFfTThSWDBlWkdFIiwieSI6IkpOZVhMZ2dCQ3ZvUGdZWGE2cURoQlhzejhnNTJKR0g2T0h1MlJraS16eVEiLCJjcnYiOiJQLTI1NiIsImQiOiJjcm9BUkg4UXgzbGc4bUphckV0WnVqemZXUVUyVUoyeU1TYTlVaUltME84In0';
