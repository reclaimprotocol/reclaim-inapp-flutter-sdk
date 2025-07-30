import '../overrides/override.dart';

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
  });

  final bool? cookiePersist;
  final bool? singleReclaimRequest;
  final String? attestorBrowserRpcUrl;
  final int? idleTimeThresholdForManualVerificationTrigger;
  final int? sessionTimeoutForManualVerificationTrigger;
  final bool? canUseAiFlow;
  final String? manualReviewMessage;
  final String? loginPromptMessage;

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
    };
  }

  @override
  String toString() {
    return 'ReclaimFeatureFlagData(cookiePersist: $cookiePersist, singleReclaimRequest: $singleReclaimRequest, attestorBrowserRpcUrl: $attestorBrowserRpcUrl, idleTimeThresholdForManualVerificationTrigger: $idleTimeThresholdForManualVerificationTrigger, sessionTimeoutForManualVerificationTrigger: $sessionTimeoutForManualVerificationTrigger, canUseAiFlow: $canUseAiFlow, manualReviewMessage: $manualReviewMessage, loginPromptMessage: $loginPromptMessage)';
  }
}
