import 'dart:convert';

import '../overrides/override.dart';
import '../web_scripts/hawkeye/interception_method.dart';

class ReclaimFeatureFlagData extends ReclaimOverride<ReclaimFeatureFlagData> {
  const ReclaimFeatureFlagData({
    this.cookiePersist,
    this.singleReclaimRequest,
    this.attestorBrowserRpcUrl,
    this.idleTimeThresholdForManualVerificationTrigger,
    this.sessionTimeoutForManualVerificationTrigger,
    this.canUseAiFlow,
    this.manualReviewMessage,
    this.loginPromptMessage,
    this.hawkeyeInterceptionMethod,
    this.claimCreationTimeoutDurationInMins,
    this.sessionNoActivityTimeoutDurationInMins,
  });

  final bool? cookiePersist;
  final bool? singleReclaimRequest;
  final String? attestorBrowserRpcUrl;
  final int? idleTimeThresholdForManualVerificationTrigger;
  final int? sessionTimeoutForManualVerificationTrigger;
  final bool? canUseAiFlow;
  final String? manualReviewMessage;
  final String? loginPromptMessage;
  final HawkeyeInterceptionMethod? hawkeyeInterceptionMethod;
  final int? claimCreationTimeoutDurationInMins;
  final int? sessionNoActivityTimeoutDurationInMins;

  @override
  ReclaimFeatureFlagData copyWith({
    bool? cookiePersist,
    bool? singleReclaimRequest,
    String? attestorBrowserRpcUrl,
    int? idleTimeThresholdForManualVerificationTrigger,
    int? sessionTimeoutForManualVerificationTrigger,
    bool? canUseAiFlow,
    String? manualReviewMessage,
    String? loginPromptMessage,
    HawkeyeInterceptionMethod? hawkeyeInterceptionMethod,
    int? claimCreationTimeoutDurationInMins,
    int? sessionNoActivityTimeoutDurationInMins,
  }) {
    return ReclaimFeatureFlagData(
      cookiePersist: cookiePersist ?? this.cookiePersist,
      singleReclaimRequest: singleReclaimRequest ?? this.singleReclaimRequest,
      attestorBrowserRpcUrl: attestorBrowserRpcUrl ?? this.attestorBrowserRpcUrl,
      idleTimeThresholdForManualVerificationTrigger:
          idleTimeThresholdForManualVerificationTrigger ?? this.idleTimeThresholdForManualVerificationTrigger,
      sessionTimeoutForManualVerificationTrigger:
          sessionTimeoutForManualVerificationTrigger ?? this.sessionTimeoutForManualVerificationTrigger,
      canUseAiFlow: canUseAiFlow ?? this.canUseAiFlow,
      manualReviewMessage: manualReviewMessage ?? this.manualReviewMessage,
      loginPromptMessage: loginPromptMessage ?? this.loginPromptMessage,
      hawkeyeInterceptionMethod: hawkeyeInterceptionMethod ?? this.hawkeyeInterceptionMethod,
      claimCreationTimeoutDurationInMins: claimCreationTimeoutDurationInMins ?? this.claimCreationTimeoutDurationInMins,
      sessionNoActivityTimeoutDurationInMins:
          sessionNoActivityTimeoutDurationInMins ?? this.sessionNoActivityTimeoutDurationInMins,
    );
  }

  static ReclaimFeatureFlagData fromJson(Map<String, Object?> json) {
    return ReclaimFeatureFlagData(
      cookiePersist: json['cookiePersist'] as bool?,
      singleReclaimRequest: json['singleReclaimRequest'] as bool?,
      attestorBrowserRpcUrl: json['attestorBrowserRpcUrl'] as String?,
      idleTimeThresholdForManualVerificationTrigger: json['idleTimeThresholdForManualVerificationTrigger'] as int?,
      sessionTimeoutForManualVerificationTrigger: json['sessionTimeoutForManualVerificationTrigger'] as int?,
      canUseAiFlow: json['canUseAiFlow'] as bool?,
      manualReviewMessage: json['manualReviewMessage'] as String?,
      loginPromptMessage: json['loginPromptMessage'] as String?,
      hawkeyeInterceptionMethod: HawkeyeInterceptionMethod.fromString(json['hawkeyeInterceptionMethod'] as String?),
      claimCreationTimeoutDurationInMins: json['claimCreationTimeoutDurationInMins'] as int?,
      sessionNoActivityTimeoutDurationInMins: json['sessionNoActivityTimeoutDurationInMins'] as int?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'cookiePersist': cookiePersist,
      'singleReclaimRequest': singleReclaimRequest,
      'attestorBrowserRpcUrl': attestorBrowserRpcUrl,
      'idleTimeThresholdForManualVerificationTrigger': idleTimeThresholdForManualVerificationTrigger,
      'sessionTimeoutForManualVerificationTrigger': sessionTimeoutForManualVerificationTrigger,
      'canUseAiFlow': canUseAiFlow,
      'manualReviewMessage': manualReviewMessage,
      'loginPromptMessage': loginPromptMessage,
      'hawkeyeInterceptionMethod': hawkeyeInterceptionMethod?.name,
      'claimCreationTimeoutDurationInMins': claimCreationTimeoutDurationInMins,
      'sessionNoActivityTimeoutDurationInMins': sessionNoActivityTimeoutDurationInMins,
    };
  }

  @override
  String toString() {
    return 'ReclaimFeatureFlagData(${json.encode(this)})';
  }
}
