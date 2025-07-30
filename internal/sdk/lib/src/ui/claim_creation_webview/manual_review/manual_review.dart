import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../reclaim_inapp_sdk.dart';
import '../../../controller.dart';
import '../../../data/http_request_log.dart';
import '../../../data/manual_review.dart';
import '../../../logging/logging.dart';
import '../../../repository/feature_flags.dart';
import '../../../services/network_logs.dart';
import '../../../usecase/login_detection.dart';
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

  ManualReviewActionData? __manualReviewMessage;
  ManualReviewActionData? get manualReviewMessage => __manualReviewMessage;
  void setManualReviewMessage(ManualReviewActionData value) {
    __manualReviewMessage = value;
  }

  void onCustomizationFromJSHandler(ManualReviewActionData? value) {
    __manualReviewMessage = value;
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
  final List<StreamSubscription> _subscriptions = [];
  Timer? _showRequestShareConsentPromptTimer;

  @override
  void initState() {
    super.initState();
    setupRequestLogging();
    widget.controller.showRequestShareConsentPrompt = () =>
        _showRequestShareConsentPrompt('controller.showRequestShareConsentPrompt');
    final webViewModel = ClaimCreationWebClientViewModel.readOf(context);
    _subscriptions.add(webViewModel.changesStream.listen(onWebViewModelValueChanged));
    _subscriptions.add(
      VerificationReviewController.readOf(context).changesStream.listen(_onVerificationReviewControllerChanges),
    );
  }

  void _showRequestShareConsentDelayedWhenNotTimeout(String debugReason) {
    logger.fine('invoknig _showRequestShareConsentDelayedWhenNotTimeout');

    _showRequestShareConsentPromptTimer?.cancel();
    final manualReviewMessage = widget.controller.manualReviewMessage;
    if (manualReviewMessage == null) {
      logger.info('manualReviewMessage is null, skipping');
      return;
    }
    Duration delayDuration = Duration.zero;
    switch (manualReviewMessage.rule) {
      case ManualReviewPromptDisplayRule.NOT_LOGIN:
        delayDuration = Duration(seconds: 2);
        break;
      case ManualReviewPromptDisplayRule.IMMEDIATELY:
        break;
      case ManualReviewPromptDisplayRule.TIMEOUT:
        if (_wasShownByTimer) {
          // if the prompt was shown by the timer, then we should show it again
          break;
        }
        logger.info('${manualReviewMessage.rule} $_wasShownByTimer, skipping');
        return;
    }
    _showRequestShareConsentPromptTimer = Timer(delayDuration, () {
      logger.info('[_showRequestShareConsentDelayedWhenNotTimeout] timer.callback');
      return _showRequestShareConsentPrompt(
        'with rule ${manualReviewMessage.rule} _wasShownByTimer: $_wasShownByTimer may show request share consent prompt after delay: $delayDuration. reason: $debugReason',
      );
    });
  }

  void onWebViewModelValueChanged(ChangedValues<ClaimCreationWebState> changes) {
    if (changes.oldValue?.lastLoadStopTime != changes.value.lastLoadStopTime &&
        changes.value.lastLoadStopTime != null) {
      _showRequestShareConsentDelayedWhenNotTimeout('onWebViewModelValueChanged: ${changes.value.lastLoadStopTime}');
    }
  }

  void _onVerificationReviewControllerChanges(ChangedValues<VerificationReviewState> changes) async {
    if (!mounted) return;
    final (oldValue, value) = changes.record;
    if (oldValue?.isVisible != value.isVisible && !value.isVisible) {
      final log = logger.child('_onVerificationReviewControllerChanges');
      log.info('Verification review controller changed to hidden');
      if (!mounted) return;
      _showRequestShareConsentDelayedWhenNotTimeout('onVerificationReviewControllerChanges ${value.isVisible}');
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
    for (final s in _subscriptions) {
      s.cancel();
    }
    _requestConsentTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  bool _didConsentToShareRequests = false;

  void setupRequestLogging() async {
    final log = logger.child('setupRequestLogging');
    log.info('Setting up request logging');

    final featureFlagProvider = await FeatureFlagsProvider.readAfterSessionStartedOf(context);
    try {
      final canUseAiFlow = await featureFlagProvider.get(FeatureFlag.canUseAiFlow);
      log.info('canUseAiFlow: $canUseAiFlow');
      if (canUseAiFlow) {
        if (!mounted) return;
        final claimCreationController = ClaimCreationController.of(context, listen: false);
        log.info('setting up manualReviewMessage');
        final value = await featureFlagProvider.get(FeatureFlag.manualReviewMessage);
        final data = ManualReviewActionData.fromString(value);
        log.info('manualReviewMessage has feature flag value: ${data != null}, value: $value');
        if (data != null) {
          widget.controller.setManualReviewMessage(data);
        }
        log.info(
          'canUseAiFlow is true, so setting up request logging, manualReviewMessage: ${widget.controller.manualReviewMessage}',
        );
        if (widget.controller.manualReviewMessage?.rule == ManualReviewPromptDisplayRule.IMMEDIATELY) {
          Future.microtask(() => _showRequestShareConsentPrompt('setup request logging immediately'));
        }
        claimCreationController.addListener(_showRequestShareConsentPromptIfError);
        final timeout = await featureFlagProvider.get(FeatureFlag.sessionTimeoutForManualVerificationTrigger);
        _requestConsentTimer = Timer(Duration(seconds: timeout), () {
          log.info('[_requestConsentTimer] timer.callback');
          _showRequestShareConsentPrompt('setup request logging timeout $timeout');
        });
        return;
      } else {
        log.info('canUseAiFlow is false, so not setting up request logging');
      }
    } catch (e, s) {
      log.severe('Failed to get canUseAiFlow', e, s);
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
      _showRequestShareConsentPrompt('error');
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

  ActionBarController? manualReviewConsentPromptController;
  bool _wasShownByTimer = false;

  void _showRequestShareConsentPrompt(String debugReason) async {
    final log = logger.child('_showRequestShareConsentPrompt');
    log.info('Asking for permission to dump requests now');
    if (kDebugMode) {
      log.shout('source: $debugReason', null, StackTrace.current);
    }

    if (!mounted) return;

    if (_didConsentToShareRequests) {
      // we already have the consent, so we don't need to show the request share consent prompt
      log.info('Already consented to share requests, skipping');
      return;
    }

    final claimCreationController = ClaimCreationController.of(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
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

    final manualReviewMessage = widget.controller.manualReviewMessage;
    log.info('manualReviewMessage: $manualReviewMessage');
    final message = manualReviewMessage?.message;
    final submitLabel = manualReviewMessage?.submitLabel;
    final canSubmit = manualReviewMessage?.canSubmit ?? true;
    final displayRule = manualReviewMessage?.rule;

    final vm = ClaimCreationWebClientViewModel.readOf(context);
    final reviewController = VerificationReviewController.readOf(context);
    final loginDetection = LoginDetection.readOf(context);
    final idleTimeThreshold = await featureFlagProvider.get(FeatureFlag.idleTimeThresholdForManualVerificationTrigger);
    log.info('displayRule: $displayRule');
    log.info('idleTimeThreshold: $idleTimeThreshold');
    if (displayRule == ManualReviewPromptDisplayRule.NOT_LOGIN) {
      if (await vm.maybeCurrentPageRequiresLogin(loginDetection)) {
        log.info('Current page is login page, skipping request share consent prompt');
        if (manualReviewConsentPromptController != null) {
          log.info('loginConsentPromptController is not null, removing');
          manualReviewConsentPromptController?.remove();
          manualReviewConsentPromptController = null;
          messenger.removeCurrentSnackBar();
          messenger.clearSnackBars();
        } else {
          log.info('loginConsentPromptController is null, skipping');
        }
        return;
      } else {
        log.info('Current page is not login page');
      }
    }

    late ActionBarController ctrl;

    void onSharePressed() async {
      final verification = VerificationController.readOf(context);
      final response = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(manualReviewMessage?.confirmationDialogTitle ?? 'Share requests'),
            content: Text(
              manualReviewMessage?.confirmationDialogMessage ??
                  'Are you sure you see all the data that needs verification?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(MaterialLocalizations.of(context).shareButtonLabel),
              ),
            ],
          );
        },
      );
      if (response != true) {
        log.info('User did not consent to share requests, skipping');
        _rescheduleRequestShareConsentPromptWithIdleTimeThreshold(idleTimeThreshold);
        return;
      }
      _didConsentToShareRequests = true;
      _sendRequestsForDiagnosisPeriodic();
      verification.onManualVerificationRequestSubmitted();
      ctrl.close();
    }

    log.info('Showing request share consent prompt');

    _wasShownByTimer = manualReviewMessage?.rule == ManualReviewPromptDisplayRule.TIMEOUT;

    if (manualReviewConsentPromptController != null && manualReviewConsentPromptController?.value.reason == null) {
      log.info('loginConsentPromptController is already visible, skipping');
      return;
    }

    reviewController.setIsVisible(false);
    ctrl = actionBarMessenger!.show(
      ActionBarMessage(
        label: Text.rich(
          message != null
              ? TextSpan(text: message)
              : TextSpan(
                  children: [
                    TextSpan(text: 'Tap '),
                    TextSpan(
                      text: 'Share',
                      style: TextStyle(color: reclaimTheme?.primary, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: ' to send data for manual review'),
                  ],
                ),
          style: TextStyle(color: Colors.black),
        ),
        action: !canSubmit ? null : ActionBarAction(label: submitLabel ?? 'Share', onActionPressed: onSharePressed),
      ),
    );
    manualReviewConsentPromptController = ctrl;

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
      _requestConsentTimer = Timer(
        Duration(seconds: idleTimeThresholdInSeconds ?? 5),
        () => _showRequestShareConsentPrompt('rescheduled'),
      );
    }
  }
}
