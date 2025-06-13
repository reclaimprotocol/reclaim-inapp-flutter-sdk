import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../reclaim_inapp_sdk.dart';
import '../../../controller.dart';
import '../../../data/http_request_log.dart';
import '../../../data/manual_review.dart';
import '../../../logging/logging.dart';
import '../../../repository/feature_flags.dart';
import '../../../services/network_logs.dart';
import '../../../utils/observable_notifier.dart';
import '../../../widgets/action_bar.dart';
import '../../../widgets/claim_creation/claim_creation.dart';
import '../../../widgets/feature_flags.dart';
import '../../../widgets/verification_review/controller.dart';
import '../view_model.dart';

class ManualReviewController {
  List<RequestLog>? _requestBuffer = [];

  List<RequestLog>? get requestBuffer => _requestBuffer;

  void addRequest(RequestLog request) {
    // stream this data wherever needed
    // don't store logs if the `_requestBuffer` is null.
    // this can happen when canUseAiFlow is false
    _requestBuffer?.add(request);
  }

  VoidCallback? _showRequestShareConsentPrompt;

  VoidCallback? get showRequestShareConsentPrompt {
    final fn = _showRequestShareConsentPrompt;
    if (fn == null) {
      throw FlutterError('Controller is not attached to a ManualReviewObserver');
    }
    return fn;
  }

  set showRequestShareConsentPrompt(VoidCallback? value) {
    _showRequestShareConsentPrompt = value;
  }

  ManualReviewActionData? _manualReviewMessage;

  void onCustomizationFromJSHandler(ManualReviewActionData? value) {
    _manualReviewMessage = value;
    if (value != null && value.rule != ManualReviewPromptDisplayRule.TIMEOUT) {
      _showRequestShareConsentPrompt?.call();
    }
  }

  void dispose() {}
}

class ManualReviewObserver extends StatefulWidget {
  const ManualReviewObserver({super.key, required this.controller, required this.child});

  final ManualReviewController controller;
  final Widget child;

  @override
  State<ManualReviewObserver> createState() => _ManualReviewObserverState();
}

class _ManualReviewObserverState extends State<ManualReviewObserver> {
  final logger = logging.child('ManualReviewObserver');
  StreamSubscription? webViewModelValueChangesSubscription;
  @override
  void initState() {
    super.initState();
    setupRequestLogging();
    widget.controller.showRequestShareConsentPrompt = _showRequestShareConsentPrompt;
    final webViewModel = ClaimCreationWebClientViewModel.readOf(context);
    webViewModelValueChangesSubscription = webViewModel.changesStream.listen(onWebViewModelValueChanged);
  }

  void onWebViewModelValueChanged(ChangedValues<ClaimCreationWebState> changes) {
    if (changes.oldValue?.lastLoadStopTime != changes.value.lastLoadStopTime &&
        changes.value.lastLoadStopTime != null) {
      if (widget.controller._manualReviewMessage?.rule == ManualReviewPromptDisplayRule.NOT_LOGIN) {
        _showRequestShareConsentPrompt();
      }
    }
  }

  ActionBarMessengerState? actionBarMessenger;
  ReclaimTheme? reclaimTheme;

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
    actionBarMessenger = ActionBarMessenger.of(context);
    reclaimTheme = ReclaimTheme.of(context);
  }

  @override
  void dispose() {
    webViewModelValueChangesSubscription?.cancel();
    _requestConsentTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  bool _didConsentToShareRequests = false;

  void setupRequestLogging() async {
    final featureFlagProvider = await FeatureFlagsProvider.readAfterSessionStartedOf(context);
    try {
      final canUseAiFlow = await featureFlagProvider.get(FeatureFlag.canUseAiFlow);
      if (canUseAiFlow) {
        if (!mounted) return;
        final claimCreationController = ClaimCreationController.of(context, listen: false);
        widget.controller._manualReviewMessage = ManualReviewActionData.fromString(
          await featureFlagProvider.get(FeatureFlag.manualReviewMessage),
        );
        logger.info(
          'canUseAiFlow is true, so setting up request logging, manualReviewMessage: ${widget.controller._manualReviewMessage}',
        );
        if (widget.controller._manualReviewMessage?.rule == ManualReviewPromptDisplayRule.IMMEDIATELY) {
          Future.microtask(_showRequestShareConsentPrompt);
        }
        claimCreationController.addListener(_showRequestShareConsentPromptIfError);
        final timeout = await featureFlagProvider.get(FeatureFlag.sessionTimeoutForManualVerificationTrigger);
        _requestConsentTimer = Timer(Duration(seconds: timeout), _showRequestShareConsentPrompt);
        return;
      } else {
        logger.info('canUseAiFlow is false, so not setting up request logging');
      }
    } catch (e) {
      logger.severe('Failed to get canUseAiFlow', e);
    }
    widget.controller._requestBuffer = null;
  }

  Timer? _requestConsentTimer;

  void _showRequestShareConsentPromptIfError() async {
    if (!mounted) return;
    final claimCreationController = ClaimCreationController.of(context, listen: false);
    final claimState = claimCreationController.value;
    if (claimState.hasError) {
      _requestConsentTimer?.cancel();
      _requestConsentTimer = null;
      claimCreationController.removeListener(_showRequestShareConsentPromptIfError);
      _showRequestShareConsentPrompt();
    } else if (claimState.delegate?.isReviewVisible == true) {
      actionBarMessenger?.clear();
      if (_requestConsentTimer == null || !_requestConsentTimer!.isActive) {
        // app can get stuck after continuation
        final idleTimeThreshold = await FeatureFlagsProvider.readOf(
          context,
        ).get(FeatureFlag.idleTimeThresholdForManualVerificationTrigger);
        _rescheduleRequestShareConsentPromptWithIdleTimeThreshold(idleTimeThreshold);
      }
    }
  }

  void _sendRequestsForDiagnosisPeriodic() {
    logger.info('Sending requests for diagnosis');
    try {
      final logs = widget.controller._requestBuffer;
      if (logs == null || logs.isEmpty) {
        logger.finest('No logs to send for diagnosis');
        return;
      }
      widget.controller._requestBuffer = [];
      final verification = VerificationController.readOf(context);
      // not awaiting result
      NetworkLogsService().addToQueue(verification.sessionInformation.sessionId, verification.request.providerId, logs);
    } catch (e, s) {
      logger.severe('Failed to send requests for diagnosis', e, s);
    } finally {
      if (mounted) {
        Timer(Duration(seconds: 5), _sendRequestsForDiagnosisPeriodic);
      }
    }
  }

  void _showRequestShareConsentPrompt() async {
    final log = logger.child('_showRequestShareConsentPrompt');
    log.info('Asking for permission to dump requests now');

    if (!mounted) return;

    if (_didConsentToShareRequests) {
      // we already have the consent, so we don't need to show the request share consent prompt
      log.info('Already consented to share requests, skipping');
      return;
    }

    final claimCreationController = ClaimCreationController.of(context, listen: false);
    final claimState = claimCreationController.value;
    if (claimState.isFinished) {
      // if the claim is finished, then we don't need to show the request share consent prompt
      log.info('Claim creation is finished, skipping..');
      return;
    }
    if (!claimState.hasError && !claimState.isWaitingForContinuation) {
      // if the claim is not waiting for continuation & has no errors, then we don't need to show the request share consent prompt
      log.info('Claim is not waiting for continuation and has no errors, skipping..');
      return;
    }

    final featureFlagProvider = FeatureFlagsProvider.readOf(context);

    final manualReviewMessage = widget.controller._manualReviewMessage;
    log.info('manualReviewMessage: $manualReviewMessage');
    final message = manualReviewMessage?.message;
    final submitLabel = manualReviewMessage?.submitLabel;
    final canSubmit = manualReviewMessage?.canSubmit ?? true;
    final displayRule = manualReviewMessage?.rule;

    final loginUrl = VerificationController.readOf(context).value.provider?.loginUrl;
    final vm = ClaimCreationWebClientViewModel.readOf(context);
    final reviewController = VerificationReviewController.readOf(context);
    final idleTimeThreshold = await featureFlagProvider.get(FeatureFlag.idleTimeThresholdForManualVerificationTrigger);
    if (displayRule == ManualReviewPromptDisplayRule.NOT_LOGIN) {
      if (await vm.isCurrentPageLogin(loginUrl)) {
        log.info('Current page is login page, skipping request share consent prompt');
        return;
      } else {
        log.info('Current page is not login page, showing request share consent prompt');
      }
    }

    late ActionBarController ctrl;

    void onSharePressed() {
      _didConsentToShareRequests = true;
      _sendRequestsForDiagnosisPeriodic();
      VerificationController.readOf(context).onManualVerificationRequestSubmitted();
      ctrl.close();
    }

    log.info('Showing request share consent prompt');

    reviewController.setIsVisible(false);
    ctrl = actionBarMessenger!.show(
      ActionBarMessage(
        label: Text.rich(
          message != null
              ? TextSpan(text: message)
              : TextSpan(
                children: [
                  TextSpan(text: 'Tap '),
                  TextSpan(text: 'Share', style: TextStyle(color: reclaimTheme?.primary, fontWeight: FontWeight.bold)),
                  TextSpan(text: ' to send data for manual review'),
                ],
              ),
          style: TextStyle(color: Colors.black),
        ),
        action: !canSubmit ? null : ActionBarAction(label: submitLabel ?? 'Share', onActionPressed: onSharePressed),
      ),
    );

    ctrl.closed.then((value) async {
      log.info('Request share consent prompt closed, reason: $value');
      if (value == ActionBarClosedReason.removed) {
        return;
      }
      _rescheduleRequestShareConsentPromptWithIdleTimeThreshold(idleTimeThreshold);
    });
  }

  void _rescheduleRequestShareConsentPromptWithIdleTimeThreshold([int? idleTimeThresholdInSeconds]) {
    // user dismissed for some reason, so we need to show the prompt again if required after idle time threshold
    if (!_didConsentToShareRequests) {
      _requestConsentTimer?.cancel();
      _requestConsentTimer = Timer(Duration(seconds: idleTimeThresholdInSeconds ?? 5), _showRequestShareConsentPrompt);
    }
  }
}
