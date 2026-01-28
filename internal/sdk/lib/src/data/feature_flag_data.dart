import 'dart:convert';

import '../overrides/override.dart';

class ReclaimFeatureFlagData extends ReclaimOverride<ReclaimFeatureFlagData> {
  const ReclaimFeatureFlagData({
    this.cookiePersist,
    this.singleReclaimRequest,
    this.attestor3BrowserRpcUrl,
    this.idleTimeThresholdForManualVerificationTrigger,
    this.sessionTimeoutForManualVerificationTrigger,
    this.canUseAiFlow,
    this.manualReviewMessage,
    this.loginPromptMessage,
    this.useTEE,
    this.interceptorOptions,
    this.claimCreationTimeoutDurationInMins,
    this.sessionNoActivityTimeoutDurationInMins,
    this.aiProviderNoActivityTimeoutDurationInSecs,
    this.pageLoadedCompletedDebounceTimeoutMs,
    this.potentialLoginTimeoutS,
    this.screenshotCaptureIntervalSeconds,
    this.teeUrls,
  });

  final bool? cookiePersist;
  final bool? singleReclaimRequest;
  final String? attestor3BrowserRpcUrl;
  final int? idleTimeThresholdForManualVerificationTrigger;
  final int? sessionTimeoutForManualVerificationTrigger;
  final bool? canUseAiFlow;
  final String? manualReviewMessage;
  final String? loginPromptMessage;
  final bool? useTEE;
  // JSON type:  HawkeyeInterceptionOptions
  final String? interceptorOptions;
  final int? claimCreationTimeoutDurationInMins;
  final int? sessionNoActivityTimeoutDurationInMins;
  final int? aiProviderNoActivityTimeoutDurationInSecs;
  final int? pageLoadedCompletedDebounceTimeoutMs;
  final int? potentialLoginTimeoutS;
  final int? screenshotCaptureIntervalSeconds;
  final String? teeUrls;

  @override
  ReclaimFeatureFlagData copyWith({
    bool? cookiePersist,
    bool? singleReclaimRequest,
    String? attestor3BrowserRpcUrl,
    int? idleTimeThresholdForManualVerificationTrigger,
    int? sessionTimeoutForManualVerificationTrigger,
    bool? canUseAiFlow,
    String? manualReviewMessage,
    String? loginPromptMessage,
    bool? useTEE,
    String? interceptorOptions,
    int? claimCreationTimeoutDurationInMins,
    int? sessionNoActivityTimeoutDurationInMins,
    int? aiProviderNoActivityTimeoutDurationInSecs,
    int? pageLoadedCompletedDebounceTimeoutMs,
    int? potentialLoginTimeoutS,
    int? screenshotCaptureIntervalSeconds,
    String? teeUrls,
  }) {
    return ReclaimFeatureFlagData(
      cookiePersist: cookiePersist ?? this.cookiePersist,
      singleReclaimRequest: singleReclaimRequest ?? this.singleReclaimRequest,
      attestor3BrowserRpcUrl: attestor3BrowserRpcUrl ?? this.attestor3BrowserRpcUrl,
      idleTimeThresholdForManualVerificationTrigger:
          idleTimeThresholdForManualVerificationTrigger ?? this.idleTimeThresholdForManualVerificationTrigger,
      sessionTimeoutForManualVerificationTrigger:
          sessionTimeoutForManualVerificationTrigger ?? this.sessionTimeoutForManualVerificationTrigger,
      canUseAiFlow: canUseAiFlow ?? this.canUseAiFlow,
      manualReviewMessage: manualReviewMessage ?? this.manualReviewMessage,
      loginPromptMessage: loginPromptMessage ?? this.loginPromptMessage,
      useTEE: useTEE ?? this.useTEE,
      interceptorOptions: interceptorOptions ?? this.interceptorOptions,
      claimCreationTimeoutDurationInMins: claimCreationTimeoutDurationInMins ?? this.claimCreationTimeoutDurationInMins,
      sessionNoActivityTimeoutDurationInMins:
          sessionNoActivityTimeoutDurationInMins ?? this.sessionNoActivityTimeoutDurationInMins,
      aiProviderNoActivityTimeoutDurationInSecs:
          aiProviderNoActivityTimeoutDurationInSecs ?? this.aiProviderNoActivityTimeoutDurationInSecs,
      pageLoadedCompletedDebounceTimeoutMs:
          pageLoadedCompletedDebounceTimeoutMs ?? this.pageLoadedCompletedDebounceTimeoutMs,
      potentialLoginTimeoutS: potentialLoginTimeoutS ?? this.potentialLoginTimeoutS,
      screenshotCaptureIntervalSeconds: screenshotCaptureIntervalSeconds ?? this.screenshotCaptureIntervalSeconds,
      teeUrls: teeUrls ?? this.teeUrls,
    );
  }

  static ReclaimFeatureFlagData fromJson(Map<String, Object?> json) {
    return ReclaimFeatureFlagData(
      cookiePersist: json['cookiePersist'] as bool?,
      singleReclaimRequest: json['singleReclaimRequest'] as bool?,
      attestor3BrowserRpcUrl: json['attestor3BrowserRpcUrl'] as String?,
      idleTimeThresholdForManualVerificationTrigger: json['idleTimeThresholdForManualVerificationTrigger'] as int?,
      sessionTimeoutForManualVerificationTrigger: json['sessionTimeoutForManualVerificationTrigger'] as int?,
      canUseAiFlow: json['canUseAiFlow'] as bool?,
      manualReviewMessage: json['manualReviewMessage'] as String?,
      loginPromptMessage: json['loginPromptMessage'] as String?,
      useTEE: json['useTEE'] as bool?,
      interceptorOptions: json['interceptorOptions'] as String?,
      claimCreationTimeoutDurationInMins: json['claimCreationTimeoutDurationInMins'] as int?,
      sessionNoActivityTimeoutDurationInMins: json['sessionNoActivityTimeoutDurationInMins'] as int?,
      aiProviderNoActivityTimeoutDurationInSecs: json['aiProviderNoActivityTimeoutDurationInSecs'] as int?,
      pageLoadedCompletedDebounceTimeoutMs: json['pageLoadedCompletedDebounceTimeoutMs'] as int?,
      potentialLoginTimeoutS: json['potentialLoginTimeoutS'] as int?,
      screenshotCaptureIntervalSeconds: json['screenshotCaptureIntervalSeconds'] as int?,
      teeUrls: json['teeUrls'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'cookiePersist': cookiePersist,
      'singleReclaimRequest': singleReclaimRequest,
      'attestor3BrowserRpcUrl': attestor3BrowserRpcUrl,
      'idleTimeThresholdForManualVerificationTrigger': idleTimeThresholdForManualVerificationTrigger,
      'sessionTimeoutForManualVerificationTrigger': sessionTimeoutForManualVerificationTrigger,
      'canUseAiFlow': canUseAiFlow,
      'manualReviewMessage': manualReviewMessage,
      'loginPromptMessage': loginPromptMessage,
      'useTEE': useTEE,
      'interceptorOptions': interceptorOptions,
      'claimCreationTimeoutDurationInMins': claimCreationTimeoutDurationInMins,
      'sessionNoActivityTimeoutDurationInMins': sessionNoActivityTimeoutDurationInMins,
      'aiProviderNoActivityTimeoutDurationInSecs': aiProviderNoActivityTimeoutDurationInSecs,
      'pageLoadedCompletedDebounceTimeoutMs': pageLoadedCompletedDebounceTimeoutMs,
      'potentialLoginTimeoutS': potentialLoginTimeoutS,
      'screenshotCaptureIntervalSeconds': screenshotCaptureIntervalSeconds,
      'teeUrls': teeUrls,
    };
  }

  @override
  String toString() {
    return 'ReclaimFeatureFlagData(${json.encode(this)})';
  }
}
