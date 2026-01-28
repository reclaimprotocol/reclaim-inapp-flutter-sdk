// ignore_for_file: deprecated_consistency

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    input: 'pigeon/schema.dart',
    dartOut: 'lib/src/pigeon/messages.pigeon.dart',
    // dartTestOut: 'test/pigeon/messages_test.g.dart',
    kotlinOptions: KotlinOptions(package: 'org.reclaimprotocol.inapp_sdk'),
    kotlinOut: 'generated/android/src/main/java/org/reclaimprotocol/inapp_sdk/Messages.kt',
    swiftOut: 'generated/ios/Sources/ReclaimInAppSdk/Messages.swift',
    objcHeaderOut: 'generated/ios/Sources/ReclaimInAppSdk/Messages.h',
    objcSourceOut: 'generated/ios/Sources/ReclaimInAppSdk/Messages.m',
    copyrightHeader: 'pigeon/copyright.txt',
  ),
)
class ReclaimApiVerificationRequest {
  const ReclaimApiVerificationRequest({
    required this.appId,
    required this.providerId,
    required this.secret,
    required this.signature,
    required this.timestamp,
    required this.context,
    required this.sessionId,
    required this.parameters,
    required this.providerVersion,
  });
  final String appId;
  final String providerId;
  final String secret;
  final String signature;
  final String? timestamp;
  final String context;
  final String sessionId;
  final Map<String, String> parameters;
  final ProviderVersionApi? providerVersion;
}

enum ReclaimApiVerificationExceptionType {
  unknown,
  sessionExpired,
  verificationDismissed,
  verificationFailed,
  verificationCancelled,
}

class ReclaimApiVerificationException {
  const ReclaimApiVerificationException({required this.message, required this.stackTraceAsString, required this.type});
  final String message;
  final String stackTraceAsString;
  final ReclaimApiVerificationExceptionType type;
}

class ReclaimApiVerificationResponse {
  const ReclaimApiVerificationResponse({
    required this.sessionId,
    required this.didSubmitManualVerification,
    required this.proofs,
    required this.exception,
  });
  final String sessionId;
  final bool didSubmitManualVerification;
  final List<Map<String, dynamic>> proofs;
  final ReclaimApiVerificationException? exception;
}

class ClientProviderInformationOverride {
  const ClientProviderInformationOverride({
    this.providerInformationUrl,
    this.providerInformationJsonString,
    this.canFetchProviderInformationFromHost = false,
  });
  final String? providerInformationUrl;
  final String? providerInformationJsonString;
  final bool canFetchProviderInformationFromHost;
}

class ClientFeatureOverrides {
  const ClientFeatureOverrides({
    this.cookiePersist,
    // false
    this.singleReclaimRequest,
    // 2
    this.idleTimeThresholdForManualVerificationTrigger,
    // 180
    this.sessionTimeoutForManualVerificationTrigger,
    // https://attestor.reclaimprotocol.org:444/browser-rpc
    this.attestorBrowserRpcUrl,
    // false
    this.isAIFlowEnabled,
    // null
    this.manualReviewMessage,
    // null
    this.loginPromptMessage,
    // null
    this.useTEE,
    // null
    this.interceptorOptions,
    // null
    this.claimCreationTimeoutDurationInMins,
    // null
    this.sessionNoActivityTimeoutDurationInMins,
    // null
    this.aiProviderNoActivityTimeoutDurationInSecs,
    // null
    this.pageLoadedCompletedDebounceTimeoutMs,
    // null
    this.potentialLoginTimeoutS,
    // null
    this.screenshotCaptureIntervalSeconds,
    // null
    this.teeUrls,
  });

  final bool? cookiePersist;
  final bool? singleReclaimRequest;
  final String? attestorBrowserRpcUrl;
  final int? idleTimeThresholdForManualVerificationTrigger;
  final int? sessionTimeoutForManualVerificationTrigger;
  final bool? isAIFlowEnabled;
  final String? manualReviewMessage;
  final String? loginPromptMessage;
  final bool? useTEE;
  final String? interceptorOptions;
  final int? claimCreationTimeoutDurationInMins;
  final int? sessionNoActivityTimeoutDurationInMins;
  final int? aiProviderNoActivityTimeoutDurationInSecs;
  final int? pageLoadedCompletedDebounceTimeoutMs;
  final int? potentialLoginTimeoutS;
  final int? screenshotCaptureIntervalSeconds;
  final String? teeUrls;
}

class ClientLogConsumerOverride {
  const ClientLogConsumerOverride({
    this.enableLogHandler = true,
    this.canSdkCollectTelemetry = true,
    this.canSdkPrintLogs = false,
  });
  // true
  final bool enableLogHandler;
  // true
  final bool canSdkCollectTelemetry;
  // false
  final bool? canSdkPrintLogs;
}

class ClientReclaimSessionManagementOverride {
  const ClientReclaimSessionManagementOverride({this.enableSdkSessionManagement = true});
  // true
  final bool enableSdkSessionManagement;
}

class ClientReclaimAppInfoOverride {
  const ClientReclaimAppInfoOverride({
    required this.appName,
    required this.appImageUrl,
    required this.isRecurring,
    required this.theme,
  });
  final String appName;
  final String appImageUrl;
  // false
  final bool isRecurring;
  final String? theme;
}

enum ReclaimSessionStatus {
  USER_STARTED_VERIFICATION,
  USER_INIT_VERIFICATION,
  PROOF_GENERATION_STARTED,
  PROOF_GENERATION_RETRY,
  PROOF_GENERATION_SUCCESS,
  PROOF_GENERATION_FAILED,
  PROOF_SUBMITTED,
  PROOF_SUBMISSION_FAILED,
  PROOF_MANUAL_VERIFICATION_SUBMITTED,
  AI_PROOF_SUBMITTED,
}

/// Identification information of a session.
class ReclaimSessionIdentityUpdate {
  const ReclaimSessionIdentityUpdate({required this.appId, required this.providerId, required this.sessionId});

  /// The application id.
  final String appId;

  /// The provider id.
  final String providerId;

  /// The session id.
  final String sessionId;
}

enum ClaimCreationTypeApi { standalone, meChain }

class ReclaimApiVerificationOptions {
  const ReclaimApiVerificationOptions({
    this.canDeleteCookiesBeforeVerificationStarts = true,
    this.canUseAttestorAuthenticationRequest = false,
    this.claimCreationType = ClaimCreationTypeApi.standalone,
    this.canAutoSubmit = true,
    this.isCloseButtonVisible = true,
    this.locale,
    this.useTeeOperator,
  });

  /// Whether to delete cookies before user journey starts in the client web view.
  /// Defaults to true.
  @Deprecated('Replace with canClearWebStorage')
  final bool canDeleteCookiesBeforeVerificationStarts;

  /// Whether module can use a callback to host that returns an authentication request when a Reclaim HTTP provider is provided.
  /// Defaults to false.
  /// {@macro CreateClaimOptions.attestorAuthenticationRequest}
  final bool canUseAttestorAuthenticationRequest;

  final ClaimCreationTypeApi claimCreationType;

  /// Whether module can auto submit the claim.
  /// Defaults to true.
  final bool canAutoSubmit;

  /// Whether the close button is visible.
  /// Defaults to true.
  final bool isCloseButtonVisible;

  /// A language code & Country code for localization that should be enforced in the verification flow.
  final String? locale;

  /// Enables use of Reclaim's TEE+MPC protocol for HTTP Request claim verification and
  /// attestation.
  ///
  /// When set to `true`, the verification will use Trusted Execution Environment
  /// (TEE) with Multi-Party Computation (MPC) for enhanced security.
  ///
  /// When set to `false`, the standard Reclaim's proxy attestor verification flow is used.
  ///
  /// When `null` (default), the backend decides whether to use TEE based on
  /// a feature flag (currently in staged rollout).
  final bool? useTeeOperator;
}

class ProviderVersionApi {
  const ProviderVersionApi({this.versionExpression, this.resolvedVersion});

  final String? versionExpression;
  final String? resolvedVersion;
}

class SessionInitResponseApi {
  const SessionInitResponseApi({required this.sessionId, required this.resolvedProviderVersion});

  final String sessionId;
  final String? resolvedProviderVersion;
}

class LogEntryApi {
  const LogEntryApi({
    required this.message,
    required this.level,
    required this.dateTimeIso,
    required this.source,
    required this.error,
    required this.stackTraceAsString,
    required this.sessionId,
  });

  final String? sessionId;
  final String message;
  final int level;
  final String dateTimeIso;
  final String source;
  final String? error;
  final String? stackTraceAsString;
}

/// Apis implemented by the Reclaim module for use by the host.
@FlutterApi()
abstract class ReclaimModuleApi {
  @async
  ReclaimApiVerificationResponse startVerification(ReclaimApiVerificationRequest request);
  @async
  ReclaimApiVerificationResponse startVerificationFromUrl(String url);
  @async
  ReclaimApiVerificationResponse startVerificationFromJson(Map<dynamic, dynamic> template);
  @async
  void setOverrides(
    ClientProviderInformationOverride? provider,
    ClientFeatureOverrides? feature,
    ClientLogConsumerOverride? logConsumer,
    ClientReclaimSessionManagementOverride? sessionManagement,
    ClientReclaimAppInfoOverride? appInfo,
    String? capabilityAccessToken,
  );
  @async
  void clearAllOverrides();
  @async
  void setVerificationOptions(ReclaimApiVerificationOptions? options);
  @async
  bool sendLog(LogEntryApi entry);
  @async
  void setConsoleLogging(bool enabled);
  @async
  bool ping();
}

/// Apis implemented by the host using the Reclaim module.
@HostApi()
abstract class ReclaimHostOverridesApi {
  @async
  void onLogs(String logJsonString);
  @async
  SessionInitResponseApi createSession({
    required String appId,
    required String providerId,
    required String timestamp,
    required String signature,
    required String providerVersion,
  });
  @async
  bool updateSession({
    required String sessionId,
    required ReclaimSessionStatus status,
    required Map<String, Object?>? metadata,
  });
  @async
  void logSession({
    required String appId,
    required String providerId,
    required String sessionId,
    required String logType,
    Map<String, dynamic>? metadata,
  });
  @async
  void onSessionIdentityUpdate(ReclaimSessionIdentityUpdate? update);
  @async
  String fetchProviderInformation({
    required String appId,
    required String providerId,
    required String sessionId,
    required String signature,
    required String timestamp,
    required String resolvedVersion,
  });
}

@HostApi()
abstract class ReclaimHostVerificationApi {
  @async
  String fetchAttestorAuthenticationRequest(Map<dynamic, dynamic> reclaimHttpProvider);
}
