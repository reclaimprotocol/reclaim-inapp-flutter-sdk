import 'package:flutter/widgets.dart';

import 'reclaim_verifier_module.dart';

export 'package:flutter/widgets.dart' show BuildContext;
export 'package:reclaim_inapp_sdk/capability_access.dart';
export 'package:reclaim_inapp_sdk/logging.dart';
export 'package:reclaim_inapp_sdk/overrides.dart';
export 'package:reclaim_inapp_sdk/reclaim_inapp_sdk.dart' hide ReclaimVerification;
export 'package:reclaim_inapp_sdk/ui.dart';
export 'src/api.dart';
export 'src/pigeon/messages.pigeon.dart';

class ReclaimInAppSdkUIScope extends StatelessWidget {
  const ReclaimInAppSdkUIScope({super.key, required this.sdk, required this.child});

  final ReclaimInAppSdk sdk;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ReclaimThemeProvider(
      applicationId: null,
      builder: (context) {
        sdk.setVerificationContext(context);

        return child;
      },
    );
  }
}

class ReclaimInAppSdk {
  /// Ensure WidgetsBinding.ensureInitialized() is called before creating an instance of ReclaimInAppSdk.
  ReclaimInAppSdk();

  final api = ReclaimModuleExternalApi();

  /// To remove listener, pass null.
  /// You can only set 1 listener at a time.
  Future<void> setSessionIdentityListener(void Function(SessionIdentity?)? onSessionIdentity) {
    return api.setSessionIdentityListener(onSessionIdentity);
  }

  void setVerificationContext(BuildContext context) {
    api.setVerificationContext(context);
  }

  void dispose() {
    api.dispose();
  }

  Future<void> setVerificationOptions(ReclaimApiVerificationOptions? options) async {
    return api.setVerificationOptions(options);
  }

  Future<ReclaimApiVerificationResponse> startVerification(
    BuildContext context,
    ReclaimVerificationRequest request,
  ) async {
    api.setVerificationContext(context);
    final sessionFuture = request.sessionProvider();
    final session = await sessionFuture;
    return api.startVerification(
      ReclaimApiVerificationRequest(
        appId: request.applicationId,
        providerId: request.providerId,
        // always generated from session, secret not needed
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
  }

  Future<ReclaimApiVerificationResponse> startVerificationFromUrl(BuildContext context, String url) async {
    api.setVerificationContext(context);
    return api.startVerificationFromUrl(url);
  }

  Future<ReclaimApiVerificationResponse> startVerificationFromJson(
    BuildContext context,
    Map<dynamic, dynamic> template,
  ) async {
    api.setVerificationContext(context);
    return api.startVerificationFromJson(template);
  }

  Future<void> clearAllOverrides() async {
    return api.clearAllOverrides();
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
    return api.setOverrides(
      provider,
      feature,
      logConsumer,
      sessionManagement,
      appInfo,
      capabilityAccessToken,
      overridesHandlerApi: overridesHandlerApi,
    );
  }

  Future<void> setConsoleLogging(bool enabled) async {
    return api.setConsoleLogging(enabled);
  }
}
