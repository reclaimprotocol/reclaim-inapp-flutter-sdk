import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:reclaim_flutter_sdk/logging/data/log.dart';
import 'package:reclaim_flutter_sdk/logging/logging.dart';
import 'package:reclaim_flutter_sdk/reclaim_flutter_sdk.dart';
import 'package:reclaim_flutter_sdk/services/capability/capability.dart';
import 'package:reclaim_flutter_sdk/types/claim_creation_type.dart';
import 'package:reclaim_gnark_zkoperator/reclaim_gnark_zkoperator.dart';
// ignore: implementation_imports
import 'package:reclaim_gnark_zkoperator/src/download/download.dart'
    show downloadWithHttp;

import 'overrides.dart';

export 'package:reclaim_flutter_sdk/data/providers.dart' show HttpProvider;
export 'package:reclaim_flutter_sdk/exception/exception.dart';
export 'package:reclaim_flutter_sdk/reclaim_flutter_sdk.dart'
    show ReclaimSessionInformation, SessionStatus;
export 'package:reclaim_flutter_sdk/src/attestor/data/attestor/auth.dart'
    show AttestorAuthenticationRequest;
export 'package:reclaim_flutter_sdk/types/claim_creation_type.dart';
export 'package:reclaim_flutter_sdk/types/create_claim.dart';
export 'package:reclaim_flutter_sdk/types/verification_options.dart';
export 'overrides.dart';

final _logger = Logger('reclaim_flutter_sdk.reclaim_verifier_module');

class ReclaimVerificationRequest {
  final String appId;
  final String providerId;
  final String secret;
  final ReclaimSessionInformation sessionInformation;
  final String contextString;
  final Map<String, String> parameters;
  final bool autoSubmit;
  final bool hideCloseButton;
  final String? webhookUrl;
  final ReclaimVerificationOptions? verificationOptions;
  final ClaimCreationType claimCreationType;

  ReclaimVerificationRequest({
    required this.appId,
    required this.providerId,
    required this.sessionInformation,
    this.secret = '',
    this.contextString = '',
    this.parameters = const {},
    this.verificationOptions,
    this.claimCreationType = ClaimCreationType.standalone,
    this.autoSubmit = true,
    this.hideCloseButton = false,
    this.webhookUrl,
  }) : assert(sessionInformation.isValid || secret.isNotEmpty,
            'A valid session information or application secret is required');
}

class ReclaimInAppSdk {
  final BuildContext context;

  const ReclaimInAppSdk.of(this.context);

  static Future<void> preWarm() async {
    // Getting the Gnark prover instance to initialize in advance before usage because initialization can take time.
    // This can also be done in the `main` function.
    // Calling this more than once is safe.
    await ReclaimZkOperator.getInstance();
  }

  static Future<String> _onComputeAttestorProof(String type, List args,
      OnZKComputePerformanceReportCallback onPerformanceReport) async {
    // Get gnark prover instance and compute the attestor proof.
    return (await ReclaimZkOperator.getInstance()).computeAttestorProof(
        type, args, onPerformanceReport: (algorithm, report) {
      onPerformanceReport(ZKComputePerformanceReport(
        algorithmName: algorithm?.name ?? '',
        report: report,
      ));
    });
  }

  Future<List<CreateClaimOutput>?> startVerification(
      ReclaimVerificationRequest request) async {
    preWarm();

    late ReclaimVerification verification;
    if (request.sessionInformation.isValid) {
      verification = ReclaimVerification.withSession(
          buildContext: context,
          appId: request.appId,
          providerId: request.providerId,
          context: request.contextString,
          parameters: request.parameters,
          sessionInformation: request.sessionInformation,
          verificationOptions: request.verificationOptions,
          claimCreationType: request.claimCreationType,
          autoSubmit: request.autoSubmit,
          acceptAiProviders: false,
          hideCloseButton: request.hideCloseButton,
          webhookUrl: request.webhookUrl,
          computeAttestorProof: _onComputeAttestorProof);
    } else {
      verification = ReclaimVerification(
          buildContext: context,
          appId: request.appId,
          providerId: request.providerId,
          secret: request.secret,
          context: request.contextString,
          parameters: request.parameters,
          verificationOptions: request.verificationOptions,
          claimCreationType: request.claimCreationType,
          autoSubmit: request.autoSubmit,
          acceptAiProviders: false,
          hideCloseButton: request.hideCloseButton,
          webhookUrl: request.webhookUrl,
          computeAttestorProof: _onComputeAttestorProof);
    }
    return verification.startVerification();
  }

  Future<void> clearAllOverrides() async {
    ReclaimOverride.clearAll();
  }

  Future<bool> canUseCapability(String capabilityName) async {
    final capabilityAccessVerifier = CapabilityAccessVerifier();

    if (await capabilityAccessVerifier.canUse(capabilityName)) {
      return true;
    }

    throw ReclaimException('Unauthorized use of capability: $capabilityName');
  }

  Future<void> setOverrides({
    ClientProviderInformationOverride? provider,
    ClientFeatureOverrides? feature,
    ClientLogConsumerOverride? logConsumer,
    ClientReclaimSessionManagementOverride? sessionManagement,
    ClientReclaimAppInfoOverride? appInfo,
    String? capabilityAccessToken,
    ReclaimHostOverridesApi? overridesHandlerApi,
  }) async {
    if (capabilityAccessToken != null) {
      try {
        ReclaimOverride.set(
          CapabilityAccessToken.import(
              capabilityAccessToken, _CAPABILITY_ACCESS_TOKEN_VERIFICATION_KEY),
        );
      } on CapabilityAccessTokenException catch (e, s) {
        _logger.severe('Failed to set capability access token', e, s);
        throw ReclaimException(e.message);
      }
    }

    if (feature?.attestorBrowserRpcUrl != null ||
        provider != null ||
        logConsumer?.canSdkCollectTelemetry == false ||
        sessionManagement?.enableSdkSessionManagement == true) {
      await canUseCapability('overrides_v1');
    }

    void sendLogsToHost(LogRecord record, SessionIdentity? identity) {
      final entry = LogEntry.fromRecord(
        record,
        identity,
        fallbackSessionIdentity: SessionIdentity.latest ??
            SessionIdentity(appId: '', providerId: '', sessionId: ''),
      );
      assert(overridesHandlerApi != null,
          'ReclaimInAppSdk.setOverrides(overridesHandlerApi:) is required');
      overridesHandlerApi?.onLogs(json.encode(entry));
    }

    ReclaimOverride.setAll([
      if (feature != null)
        ReclaimFeatureFlagData(
          cookiePersist: feature.cookiePersist,
          singleReclaimRequest: feature.singleReclaimRequest,
          idleTimeThresholdForManualVerificationTrigger:
              feature.idleTimeThresholdForManualVerificationTrigger,
          sessionTimeoutForManualVerificationTrigger:
              feature.sessionTimeoutForManualVerificationTrigger,
          attestorBrowserRpcUrl: feature.attestorBrowserRpcUrl,
          isAIFlowEnabled: feature.isAIFlowEnabled ?? false,
          canUseAiFlow: feature.canUseAiFlow ?? false,
        ),
      if (provider != null)
        ReclaimProviderOverride(
          fetchProviderInformation: ({
            required String appId,
            required String providerId,
            required String sessionId,
            required String signature,
            required String timestamp,
          }) async {
            Map<String, dynamic> providerInformation = {};
            try {
              if (provider.providerInformationUrl != null) {
                final response = await downloadWithHttp(
                  provider.providerInformationUrl!,
                  cacheDirName: 'inapp_sdk_provider_information',
                );

                if (response == null) {
                  throw ReclaimException(
                    'Failed to fetch provider information from ${provider.providerInformationUrl}',
                  );
                }

                providerInformation = json.decode(utf8.decode(response));
              } else if (provider.providerInformationJsonString != null) {
                providerInformation =
                    json.decode(provider.providerInformationJsonString!);
              } else if (provider.canFetchProviderInformationFromHost) {
                assert(overridesHandlerApi != null,
                    'ReclaimInAppSdk.setOverrides(overridesHandlerApi:) is required');
                final String rawProviderInformation =
                    await overridesHandlerApi!.fetchProviderInformation(
                  appId: appId,
                  providerId: providerId,
                  sessionId: sessionId,
                  signature: signature,
                  timestamp: timestamp,
                );
                providerInformation = json.decode(rawProviderInformation);
              }
            } catch (e, s) {
              _logger.severe('Failed to fetch provider information', e, s);
              if (e is ReclaimException) {
                rethrow;
              }
              throw ReclaimException(
                  'Failed to fetch provider information due to $e');
            }

            try {
              return HttpProvider.fromJson(providerInformation);
            } catch (e, s) {
              _logger.severe('Failed to parse provider information', e, s);
              throw ReclaimException(
                  'Failed to parse provider information: ${e.toString()}');
            }
          },
        ),
      if (logConsumer != null)
        LogConsumerOverride(
          // Setting this to true will print logs from reclaim_flutter_sdk to the console.
          canPrintLogs: logConsumer.canSdkPrintLogs ?? reclaimCanPrintDebugLogs,
          onRecord: logConsumer.enableLogHandler
              ? (record, identity) {
                  sendLogsToHost(record, identity);
                  return logConsumer.canSdkCollectTelemetry;
                }
              : (!logConsumer.canSdkCollectTelemetry ? (_, __) => false : null),
        ),
      // A handler has been provided. We'll not let SDK manage sessions in this case.
      // Disabling [enableSdkSessionManagement] lets the host manage sessions.
      if (sessionManagement != null &&
          !sessionManagement.enableSdkSessionManagement)
        ReclaimSessionOverride.session(
          createSession: ({
            required String appId,
            required String providerId,
            required String timestamp,
            required String signature,
          }) async {
            assert(overridesHandlerApi != null,
                'ReclaimInAppSdk.setOverrides(overridesHandlerApi:) is required');
            return overridesHandlerApi!.createSession(
              appId: appId,
              providerId: providerId,
              timestamp: timestamp,
              signature: signature,
            );
          },
          updateSession: (sessionId, status) async {
            assert(overridesHandlerApi != null,
                'ReclaimInAppSdk.setOverrides(overridesHandlerApi:) is required');
            return overridesHandlerApi!.updateSession(
              sessionId: sessionId,
              status: status,
            );
          },
          logRecord: ({
            required appId,
            required logType,
            required providerId,
            required sessionId,
            Map<String, dynamic>? metadata,
          }) {
            assert(overridesHandlerApi != null,
                'ReclaimInAppSdk.setOverrides(overridesHandlerApi:) is required');
            overridesHandlerApi!.logSession(
                appId: appId,
                providerId: providerId,
                sessionId: sessionId,
                logType: logType);
          },
        ),
      if (appInfo != null)
        AppInfo(
            appName: appInfo.appName,
            appImage: appInfo.appImageUrl,
            isRecurring: appInfo.isRecurring),
    ]);
  }
}

const _CAPABILITY_ACCESS_TOKEN_VERIFICATION_KEY =
    'eyJraWQiOiI4NjgyNGJkMS04ZDU4LTQ5YWQtODVlMC03YzYxYWUyYTNjM2IiLCJrZXlfb3BzIjpbInNpZ24iXSwiZXh0Ijp0cnVlLCJrdHkiOiJFQyIsIngiOiJfNHpINjBTSTRJMmFwblZWM3lBUy1sUGFqcG80R3k0ZmFfTThSWDBlWkdFIiwieSI6IkpOZVhMZ2dCQ3ZvUGdZWGE2cURoQlhzejhnNTJKR0g2T0h1MlJraS16eVEiLCJjcnYiOiJQLTI1NiIsImQiOiJjcm9BUkg4UXgzbGc4bUphckV0WnVqemZXUVUyVUoyeU1TYTlVaUltME84In0';
