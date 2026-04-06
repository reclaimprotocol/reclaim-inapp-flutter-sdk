import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../data/app_events.dart';
import '../../data/http_request_log.dart';
import '../../data/manual_review.dart';
import '../../logging/logging.dart';
import '../../widgets/ai_flow_coordinator_widget.dart';
import '../../widgets/claim_creation/claim_creation.dart';
import 'manual_review/manual_review.dart';

/// Manages JavaScript handlers for InAppWebView instances.
/// This allows handlers to be registered on any webview controller (main or popup)
/// while routing events to the same underlying controllers and state.
class WebViewJSHandlerManager {
  final BuildContext context;
  final ManualReviewController manualReviewController;
  final VoidCallback onActivity;
  final Future<void> Function(List<dynamic>, InAppWebViewController) handleUserInteraction;
  final ValueChanged<List<dynamic>> onProofData;
  final ValueChanged<List<dynamic>> onExtractedData;
  final ValueChanged<String?> onAllowAppLinkRequest;
  final void Function(InAppWebViewController, String?) onUpdateUserAgent;

  WebViewJSHandlerManager({
    required this.context,
    required this.manualReviewController,
    required this.onActivity,
    required this.handleUserInteraction,
    required this.onAllowAppLinkRequest,
    required this.onProofData,
    required this.onExtractedData,
    required this.onUpdateUserAgent,
  });

  final logger = logging.child('WebViewJSHandlerManager');

  /// Registers all JavaScript handlers on the given webview controller
  void registerHandlers(InAppWebViewController controller) {
    _registerPublicDataHandler(controller);
    _registerCanExpectManyClaimsHandler(controller);
    _registerReportProviderErrorHandler(controller);
    _registerRequestLogsHandler(controller);
    _registerCustomizeManualReviewMessageHandler(controller);
    _registerUserInteractionHandler(controller);
    _registerDebugLogsHandler(controller);
    _registerProofDataHandler(controller);
    _registerExtractedDataHandler(controller);
    _registerErrorLogsHandler(controller);
    _registerLocationChangedHandler(controller);
    _registerPageLoadCompleteHandler(controller);
    _registerRequiresUserInteractionHandler(controller);
    _registerSetAllowedAppLinksCallback(controller);
    _registerUpdateUserAgentCallback(controller);
  }

  void _registerPublicDataHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'publicData',
      callback: (args) async {
        final log = logger.child('proof_generation_events');
        try {
          onActivity();
          final publicData = json.decode(args[0]);
          log.info('Received public data');
          final claimCreationController = ClaimCreationController.of(context, listen: false);
          claimCreationController.setPublicData(publicData);
        } catch (e, s) {
          log.severe('failed to update public data', e, s);
        }
      },
    );
  }

  void _registerCanExpectManyClaimsHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'canExpectManyClaims',
      callback: (args) async {
        final log = logger.child('canExpectManyClaims');
        onActivity();
        log.info('received canExpectManyClaims, args: $args');
        final data = json.decode(args[0]);
        if (data is! Map) {
          log.severe('Received canExpectManyClaims is not a map', data);
          return;
        }
        final canExpectManyClaims = data['value'];
        if (canExpectManyClaims is! bool) {
          log.severe('Received canExpectManyClaims.value is not a boolean', data);
          return;
        }
        final claimCreationController = ClaimCreationController.of(context, listen: false);
        claimCreationController.canExpectManyClaims(canExpectManyClaims);
      },
    );
  }

  void _registerReportProviderErrorHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'reportProviderError',
      callback: (args) async {
        final log = logger.child('reportProviderError');
        log.info('received provider error, args: $args');
        final errorMessage = json.decode(args[0]);
        if (errorMessage is! Map) {
          log.severe('Received error is not a map', errorMessage);
          return;
        }
        final claimCreationController = ClaimCreationController.of(context, listen: false);
        claimCreationController.setProviderError(errorMessage.cast<String, dynamic>());
      },
    );
  }

  void _registerRequestLogsHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'requestLogs',
      callback: (args) async {
        final log = logger.child('request_logs');
        try {
          final requestData = json.decode(args[0]);
          final requestLog = RequestLog.fromJson(requestData);
          log.info('url : ${requestLog.url}, method : ${requestLog.method}');

          manualReviewController.addRequest(requestLog);
          // push the request log to the ai flow coordinator service
          AIFlowCoordinatorWidget.pushEvent(NetworkRequestEvent(requestLog: requestLog));
        } catch (e, s) {
          logger.severe('Failed to add request log', e, s);
          logger.finer({'requestLogFailed': args});
        }
      },
    );
  }

  void _registerCustomizeManualReviewMessageHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'customizeManualReviewMessage',
      callback: (args) async {
        final log = logger.child('manual_review_message');
        try {
          log.info({'customizeManualReviewMessage': args[0]});
          onActivity();
          final data = ManualReviewActionData.fromString(args[0]);
          manualReviewController.onCustomizationFromJSHandler(data);
        } catch (e, s) {
          log.severe('Failed to set manual review action data', e, s);
        }
      },
    );
  }

  void _registerUserInteractionHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'userInteraction',
      callback: (args) async => await handleUserInteraction(args, controller),
    );
  }

  void _registerDebugLogsHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'debugLogs',
      callback: (args) {
        logger.child('debug_logs').info(args);
      },
    );
  }

  void _registerProofDataHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'proofData',
      callback: (args) async {
        onProofData(args);
      },
    );
  }

  void _registerExtractedDataHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'extractedData',
      callback: (args) async {
        onExtractedData(args);
      },
    );
  }

  void _registerErrorLogsHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'errorLogs',
      callback: (args) {
        logging.child('handleWebviewErrorLogs').severe({"errorLogs.args": args});
      },
    );
  }

  void _registerLocationChangedHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'locationChanged',
      callback: (args) async {
        final newUrl = args[0] as String;
        logger.info('Location changed to: $newUrl');
        // You can add additional handling here if needed
      },
    );
  }

  void _registerPageLoadCompleteHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'pageLoadComplete',
      callback: (args) async {
        final data = json.decode(args[0]);
        final url = data['url'] as String;
        final dom = data['dom'] as String;
        final formData = data['formData'] as String;

        logger.info('Page load complete for URL: $url');

        final pageLoadedEvent = PageLoadedEvent(url: url, renderedDom: dom, formData: formData);
        AIFlowCoordinatorWidget.pushEvent(pageLoadedEvent);
      },
    );
  }

  void _registerRequiresUserInteractionHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'requiresUserInteraction',
      callback: (args) {
        final log = logging.child('requiresUserInteraction');
        onActivity();
        final data = json.decode(args[0]);
        if (data is! Map) {
          log.severe('Received requiresUserInteraction is not a map', data);
          return;
        }
        final isUserInteractionRequired = data['value'];
        if (isUserInteractionRequired is! bool) {
          log.severe('Received requiresUserInteraction.value is not a boolean', data);
          return;
        }
        _requiresUserInteraction(isUserInteractionRequired);
      },
    );
  }

  void _registerSetAllowedAppLinksCallback(InAppWebViewController controller) {
    final log = logger.child('_registerSetAllowedAppLinksCallback');
    controller.addJavaScriptHandler(
      handlerName: 'setAllowedAppLinks',
      callback: (args) async {
        try {
          log.finest({"args": args, 'tag': 'setAllowedAppLinks'});
          final data = json.decode(args[0]);
          if (data is! Map) {
            log.warning('Received setAllowedAppLinks is not a map', data);
            return;
          }
          final allowedAppLinks = data['value'];
          if (allowedAppLinks is String || allowedAppLinks == null) {
            onAllowAppLinkRequest(allowedAppLinks?.toString());
          } else {
            log.warning('Unexpected type of input: $allowedAppLinks');
          }
          onActivity();
        } catch (e, s) {
          log.severe('Failed', e, s);
        }
      },
    );
  }

  void _registerUpdateUserAgentCallback(InAppWebViewController controller) {
    final log = logger.child('_registerUpdateUserAgentCallback');
    controller.addJavaScriptHandler(
      handlerName: 'updateUserAgent',
      callback: (args) async {
        try {
          log.finest({"args": args, 'tag': 'updateUserAgent'});
          final data = json.decode(args[0]);
          if (data is! Map) {
            log.warning('Received updateUserAgent is not a map', data);
            return;
          }
          final userAgent = data['value'];
          if (userAgent is String || userAgent == null) {
            onUpdateUserAgent(controller, userAgent?.toString());
          } else {
            log.warning('Unexpected type of input: $userAgent');
          }
          onActivity();
        } catch (e, s) {
          log.severe('Failed', e, s);
        }
      },
    );
  }

  void _requiresUserInteraction(bool isUserInteractionRequired) {
    final claimCreationController = ClaimCreationController.of(context, listen: false);
    if (isUserInteractionRequired) {
      claimCreationController.value.delegate?.hideReview();
    } else {
      claimCreationController.value.delegate?.showReview();
    }
  }
}
