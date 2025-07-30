import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:reclaim_gnark_zkoperator/reclaim_gnark_zkoperator.dart';
// ignore: implementation_imports
import 'package:reclaim_gnark_zkoperator/src/download/download.dart'
    show downloadWithHttp;
import 'package:reclaim_inapp_sdk/capability_access.dart';
import 'package:reclaim_inapp_sdk/logging.dart';
import 'package:reclaim_inapp_sdk/overrides.dart';
import 'package:reclaim_inapp_sdk/reclaim_inapp_sdk.dart';

import 'data.dart';

export 'package:reclaim_inapp_sdk/attestor.dart';
export 'package:reclaim_inapp_sdk/overrides.dart';
export 'package:reclaim_inapp_sdk/reclaim_inapp_sdk.dart'
    hide ReclaimVerification;

export 'data.dart';

final _logger = Logger('reclaim_flutter_sdk.reclaim_verifier_module');

class ReclaimCapabilityException implements Exception {
  final String message;

  const ReclaimCapabilityException(this.message);

  @override
  String toString() => 'ReclaimCapabilityException: $message';
}

class ReclaimInAppSdk {
  final BuildContext context;
  final ReclaimVerification _reclaim;

  ReclaimInAppSdk.of(this.context) : _reclaim = ReclaimVerification.of(context);

  static Future<void> preWarm() async {
    // Getting the Gnark prover instance to initialize in advance before usage because initialization can take time.
    // This can also be done in the `main` function.
    // Calling this more than once is safe.
    await ReclaimZkOperator.getInstance();
  }

  final _defaultReclaimVerificationOptions = ReclaimVerificationOptions(
    canAutoSubmit: true,
    isCloseButtonVisible: true,
    attestorZkOperator: AttestorZkOperatorWithCallback.withReclaimZKOperator(
      onComputeProof: (type, args, onPerformanceReport) async {
        // Get gnark prover instance and compute the attestor proof.
        return (await ReclaimZkOperator.getInstance()).computeAttestorProof(
          type,
          args,
          onPerformanceReport: (algorithm, report) {
            onPerformanceReport(ZKComputePerformanceReport(
                algorithmName: algorithm?.name ?? '', report: report));
          },
        );
      },
    ),
  );

  late ReclaimVerificationOptions _reclaimVerificationOptions =
      _defaultReclaimVerificationOptions;

  Future<void> setVerificationOptions(
      ReclaimVerificationOptions? options) async {
    final log = _logger.child('setVerificationOptions');
    if (options == null) {
      log.info('Setting verification options to null');
      _reclaimVerificationOptions = _defaultReclaimVerificationOptions;
    } else {
      log.info({
        'reason': 'Setting verification options',
        'canDeleteCookiesBeforeVerificationStarts': options.canClearWebStorage,
        'canUseAttestorAuthenticationRequest':
            options.attestorAuthenticationRequest != null,
        'claimCreationType': options.claimCreationType,
      });
      _reclaimVerificationOptions = options;
    }
  }

  Future<ReclaimApiVerificationResponse> _startVerification(
    ReclaimVerificationRequest request,
    String requestSessionId,
  ) async {
    try {
      preWarm();

      final response = await _reclaim.startVerification(
        request: request,
        options: _reclaimVerificationOptions,
      );
      return ReclaimApiVerificationResponse(
        sessionId: SessionIdentity.latest?.sessionId ?? requestSessionId,
        didSubmitManualVerification: false,
        proofs: (json.decode(json.encode(response.proofs)) as List)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
        exception: null,
      );
    } catch (e, s) {
      _logger.severe('Failed verification response', e, s);
      return ReclaimApiVerificationResponse(
        sessionId: SessionIdentity.latest?.sessionId ?? requestSessionId,
        didSubmitManualVerification:
            e is ReclaimVerificationManualReviewException,
        proofs: const [],
        exception: e is ReclaimException
            ? e
            : ReclaimVerificationCancelledException(e.toString()),
      );
    }
  }

  Future<ReclaimApiVerificationResponse> startVerification(
      ReclaimVerificationRequest request) async {
    return _startVerification(request, SessionIdentity.latest?.sessionId ?? '');
  }

  Future<ReclaimApiVerificationResponse> startVerificationFromUrl(String url) {
    final request = ClientSdkVerificationRequest.fromUrl(url);
    return _startVerification(
        ReclaimVerificationRequest.fromSdkRequest(request),
        request.sessionId ?? '');
  }

  Future<ReclaimApiVerificationResponse> startVerificationFromJson(
      Map<dynamic, dynamic> template) {
    final request = ClientSdkVerificationRequest.fromJson(<String, dynamic>{
      for (final entry in template.entries)
        (entry.key?.toString() ?? ''): entry.value,
    });
    return _startVerification(
        ReclaimVerificationRequest.fromSdkRequest(request),
        request.sessionId ?? '');
  }

  Future<void> clearAllOverrides() async {
    ReclaimOverride.clearAll();
  }

  Future<bool> canUseCapability(String capabilityName) async {
    final capabilityAccessVerifier = CapabilityAccessVerifier();

    if (await capabilityAccessVerifier.canUse(capabilityName)) {
      return true;
    }

    throw ReclaimCapabilityException(
        'Unauthorized use of capability: $capabilityName');
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
      ReclaimOverride.set(
        CapabilityAccessToken.import(
            capabilityAccessToken, _CAPABILITY_ACCESS_TOKEN_VERIFICATION_KEY),
      );
    }

    if (feature?.attestorBrowserRpcUrl != null ||
        provider != null ||
        logConsumer?.canSdkPrintLogs == true ||
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
          canUseAiFlow: feature.isAIFlowEnabled ?? false,
          manualReviewMessage: feature.manualReviewMessage,
          loginPromptMessage: feature.loginPromptMessage,
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
                  throw ReclaimVerificationProviderLoadException(
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
              throw ReclaimVerificationProviderLoadException(
                  'Failed to fetch provider information due to $e');
            }

            try {
              return HttpProvider.fromJson(providerInformation);
            } catch (e, s) {
              _logger.severe('Failed to parse provider information', e, s);
              throw ReclaimVerificationProviderLoadException(
                  'Failed to parse provider information: ${e.toString()}');
            }
          },
        ),
      if (logConsumer != null)
        LogConsumerOverride(
          // Setting this to true will print logs from reclaim_flutter_sdk to the console.
          canPrintLogs: logConsumer.canSdkPrintLogs == true,
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
            required String providerVersion,
          }) async {
            assert(overridesHandlerApi != null,
                'ReclaimInAppSdk.setOverrides(overridesHandlerApi:) is required');
            return overridesHandlerApi!.createSession(
              appId: appId,
              providerId: providerId,
              timestamp: timestamp,
              signature: signature,
              providerVersion: providerVersion,
            );
          },
          updateSession: (sessionId, status, metadata) async {
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
