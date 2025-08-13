import 'dart:async';

import 'package:flutter/material.dart';

import '../../controller.dart';
import '../../data/ai_response.dart';
import '../../logging/logging.dart';
import '../../repository/ai_response_puller.dart';
import '../../services/ai_services/ai_client_services.dart';
import '../../services/ai_services/job_status_manager.dart';
import '../../ui/claim_creation_webview/view_model.dart';
import '../../widgets/action_bar.dart';
import '../../widgets/ai/recommendation_text.dart';
import '../../widgets/ai_flow_coordinator_widget.dart';
import '../../widgets/claim_creation/claim_creation.dart';
import '../../widgets/verification_review/controller.dart';

class AIActionController {
  final BuildContext context;
  final AiResponsePuller _aiResponsePuller;
  final JobStatusManager _jobStatusManager;
  final AiServiceClient aiClient;
  final logger = logging.child('AIActionController');
  StreamSubscription? _responseSubscription;

  // Map to store the last action of each type
  final Map<String, ActionHistory> _actionHistory = {};

  AIActionController(this.context, this.aiClient)
    : _aiResponsePuller = AiResponsePuller(aiClient),
      _jobStatusManager = JobStatusManager();

  void start() {
    _aiResponsePuller.start();
    _responseSubscription = _aiResponsePuller.responseStream.listen(_handleAIResponse);
  }

  void stop() {
    _aiResponsePuller.stop();
    _responseSubscription?.cancel();
    _jobStatusManager.clear();
    _responseSubscription = null;
  }

  void pause() {
    _aiResponsePuller.stop();
    _responseSubscription?.cancel();
    _responseSubscription = null;
    logger.info('AI response puller paused');
  }

  void resume() {
    _aiResponsePuller.start();
    _responseSubscription = _aiResponsePuller.responseStream.listen(_handleAIResponse);
    logger.info('AI response puller resumed');
  }

  void _handleAIResponse(AIResponse response) {
    if (response.jobs.isEmpty) {
      return;
    }
    for (final job in response.jobs) {
      if (job.status != 'completed') {
        continue;
      }
      if (!_jobStatusManager.isJobConsumed(job.jobId)) {
        for (final action in job.actions) {
          _handleAIAction(action);
        }
        _jobStatusManager.markJobAsConsumed(job.jobId);
      }
    }
  }

  bool _isActionRecentlyExecuted(AIAction action) {
    final now = DateTime.now();
    final lastAction = _actionHistory[action.type];

    if (lastAction == null) {
      return false;
    }

    final difference = now.difference(lastAction.timestamp);
    if (difference.inSeconds >= 10) {
      return false;
    }

    return lastAction.action == action;
  }

  void _recordActionExecution(AIAction action) {
    _actionHistory[action.type] = ActionHistory(action, DateTime.now());
  }

  void _handleAIAction(AIAction action) {
    if (action is NoAction) return;

    if (_isActionRecentlyExecuted(action)) {
      logger.info('Skipping duplicate action of type: ${action.type}');
      return;
    }

    switch (action) {
      case NoAction():
        return;
      case ShowInfoAction(text: final text):
        _handleShowInfo(text);
        break;
      case RecommendationAction(text: final text):
        _handleRecommendation(text);
        break;
      case NavigationAction(url: final url):
        _handleNavigation(url);
        break;
      case ProviderVersionUpdateAction(versionNumber: final versionNumber):
        _handleProviderVersionUpdate(versionNumber);
        break;
      case ButtonClickAction(jsSelector: final jsSelector):
        _handleButtonClick(jsSelector);
        break;
      case GoBackAction():
        _handleGoBack();
        break;
    }

    _recordActionExecution(action);
  }

  void _handleRecommendation(String text) {
    logger.info('AI Recommendation: $text');
    VerificationReviewController.readOf(context).setIsVisible(false);
    final messenger = ActionBarMessenger.of(context);
    messenger.show(
      ActionBarMessage(
        type: ActionMessageType.message,
        label: RecommendationText(text: text),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _handleShowInfo(String text) {
    logger.info('AI Show Info: $text');
    final webContext = AIFlowCoordinatorWidget.of(context).webContext;
    webContext.setInfoText(text);

    if (text.toLowerCase().startsWith("you're logged in")) {
      logger.info('setting the user as logged in: $text');
      webContext.setMarkedLoggedInByAI();
    }
    ClaimCreationController.of(context, listen: false).value.delegate?.showReview();
  }

  void _handleNavigation(String url) {
    logger.info('AI Navigation: $url');
    final vm = ClaimCreationWebClientViewModel.readOf(context);
    vm.navigateToUrl(url);
  }

  void _handleProviderVersionUpdate(String versionNumber) {
    logger.info('AI suggested provider version update: $versionNumber');

    final webContext = AIFlowCoordinatorWidget.of(context).webContext;
    webContext.setAiFlowDone();

    final controller = ClaimCreationWebClientViewModel.readOf(context);

    final verification = VerificationController.readOf(context);
    verification.updateProvider(versionNumber, controller);

    pause();
  }

  void _handleButtonClick(String jsSelector) {
    logger.info('AI suggested button click: $jsSelector');
    final vm = ClaimCreationWebClientViewModel.readOf(context);

    final script = '$jsSelector.click();';

    vm.evaluateJavascript(script);
  }

  void _handleGoBack() {
    logger.info('AI suggested go back');
    final vm = ClaimCreationWebClientViewModel.readOf(context);
    vm.goBack();
  }
}
