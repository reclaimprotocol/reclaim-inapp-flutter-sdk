import 'package:reclaim_flutter_sdk/overrides/override.dart';

class ReclaimFeatureFlagData extends ReclaimOverride<ReclaimFeatureFlagData> {
  final bool? cookiePersist;
  final bool? singleReclaimRequest;
  final int? idleTimeThresholdForManualVerificationTrigger;
  final int? sessionTimeoutForManualVerificationTrigger;
  final String? attestorBrowserRpcUrl;
  final bool isAIFlowEnabled;
  final bool? canUseAiFlow;
  final String? manualReviewMessage;

  const ReclaimFeatureFlagData({
    this.cookiePersist,
    this.singleReclaimRequest,
    this.idleTimeThresholdForManualVerificationTrigger,
    this.sessionTimeoutForManualVerificationTrigger,
    this.attestorBrowserRpcUrl,
    this.isAIFlowEnabled = false,
    this.canUseAiFlow = false,
    this.manualReviewMessage,
  });
  
  @override
  ReclaimFeatureFlagData copyWith({
    bool? cookiePersist,
    bool? singleReclaimRequest,
    int? idleTimeThresholdForManualVerificationTrigger,
    int? sessionTimeoutForManualVerificationTrigger,
    String? attestorBrowserRpcUrl,
    bool? isAIFlowEnabled,
    bool? canUseAiFlow,
    String? manualReviewMessage,
  }) {
    return ReclaimFeatureFlagData(
      cookiePersist: cookiePersist ?? this.cookiePersist,
      singleReclaimRequest: singleReclaimRequest ?? this.singleReclaimRequest,
      idleTimeThresholdForManualVerificationTrigger: idleTimeThresholdForManualVerificationTrigger ?? this.idleTimeThresholdForManualVerificationTrigger,
      sessionTimeoutForManualVerificationTrigger: sessionTimeoutForManualVerificationTrigger ?? this.sessionTimeoutForManualVerificationTrigger,
      attestorBrowserRpcUrl: attestorBrowserRpcUrl ?? this.attestorBrowserRpcUrl,
      isAIFlowEnabled: isAIFlowEnabled ?? this.isAIFlowEnabled,
      canUseAiFlow: canUseAiFlow ?? this.canUseAiFlow,
      manualReviewMessage: manualReviewMessage ?? this.manualReviewMessage,
    );
  }

  @override
  String toString() {
    return 'ReclaimFeatureFlagData(cookiePersist: $cookiePersist, singleReclaimRequest: $singleReclaimRequest, idleTimeThresholdForManualVerificationTrigger: $idleTimeThresholdForManualVerificationTrigger, sessionTimeoutForManualVerificationTrigger: $sessionTimeoutForManualVerificationTrigger, attestorBrowserRpcUrl: $attestorBrowserRpcUrl, isAIFlowEnabled: $isAIFlowEnabled, canUseAiFlow: $canUseAiFlow, manualReviewMessage: $manualReviewMessage)';
  }
}
