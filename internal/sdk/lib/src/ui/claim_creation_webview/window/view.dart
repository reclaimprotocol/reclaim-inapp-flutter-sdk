import 'dart:collection';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../logging/logging.dart';
import '../../../services/hybrid_screenshot_service.dart';
import '../../../utils/webview_state_mixin.dart';
import '../../../widgets/reclaim_appbar.dart';
import '../../../widgets/webview_bottom.dart';
import '../view_model.dart';
import '../webview_handler_manager.dart';

class WebViewWindowParameters {
  final InAppWebViewSettings webViewSettings;
  final CreateWindowAction action;
  final HybridScreenshotService? screenshotService;
  final InAppWebViewController? mainWebViewController;
  final WebViewJSHandlerManager handlerManager;
  final ClaimCreationWebClientViewModel viewModel;
  final UnmodifiableListView<UserScript> userScripts;
  final VoidCallback? onClose;

  const WebViewWindowParameters({
    required this.webViewSettings,
    required this.action,
    required this.handlerManager,
    required this.viewModel,
    required this.userScripts,
    this.screenshotService,
    this.mainWebViewController,
    this.onClose,
  });
}

class WebViewWindow extends StatefulWidget {
  const WebViewWindow({super.key, required this.parameters});

  final WebViewWindowParameters parameters;

  @override
  State<WebViewWindow> createState() => _WebViewWindowState();
}

class _WebViewWindowState extends State<WebViewWindow> with WebViewCompanionMixin<WebViewWindow> {
  final appBarController = ReclaimAppBarController();

  @override
  WebViewJSHandlerManager get handlerManager => widget.parameters.handlerManager;

  @override
  ClaimCreationWebClientViewModel get viewModel => widget.parameters.viewModel;

  @override
  UnmodifiableListView<UserScript> get userScripts => widget.parameters.userScripts;

  @override
  void dispose() {
    appBarController.dispose();
    super.dispose();
  }

  bool _didWindowClose = false;

  InAppWebViewController? _controller;

  final logger = logging.child('WebViewWindow');

  List<UserScript> _buildInitialUserScripts() {
    logger.info('Preparing ${widget.parameters.userScripts.length} user scripts for popup webview');
    return widget.parameters.userScripts.toList();
  }

  void _onWebViewCreated(InAppWebViewController controller) {
    try {
      logger.info('Registering full JS handlers on popup webview');
      widget.parameters.handlerManager.registerHandlers(controller);

      logger.info('Switching view model controller to popup webview');
      widget.parameters.viewModel.setController(controller);

      if (widget.parameters.screenshotService != null) {
        logger.info('Switching screenshot service to popup webview controller');
        widget.parameters.screenshotService!.updateWebViewController(controller);
      }
    } catch (e, s) {
      logger.severe('Error setting up popup webview', e, s);
    }
  }

  void _closeWindow() {
    if (_didWindowClose) return;

    _didWindowClose = true;

    try {
      _controller?.evaluateJavascript(source: 'window.close()');
    } catch (e, s) {
      logger.severe('Error closing window', e, s);
    }

    if (widget.parameters.mainWebViewController != null) {
      logger.info('Restoring view model controller to main webview');
      widget.parameters.viewModel.setController(widget.parameters.mainWebViewController!);
    }

    if (widget.parameters.screenshotService != null && widget.parameters.mainWebViewController != null) {
      logger.info('Restoring screenshot service to main webview controller');
      widget.parameters.screenshotService!.updateWebViewController(widget.parameters.mainWebViewController);
    }

    widget.parameters.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    return HeroControllerScope(
      controller: MaterialApp.createMaterialHeroController(),
      child: Scaffold(
        appBar: ReclaimAppBar(controller: appBarController, onPressed: _closeWindow, isCloseButtonVisible: true),
        body: InAppWebView(
          gestureRecognizers: gestureRecognizers,
          onGeolocationPermissionsShowPrompt: onGeolocationPermissionsShowPrompt,
          onPermissionRequest: onPermissionRequestedFromWeb,
          initialSettings: widget.parameters.webViewSettings,
          initialUserScripts: UnmodifiableListView(_buildInitialUserScripts()),
          windowId: widget.parameters.action.windowId,
          onWebViewCreated: (controller) {
            _controller = controller;
            _onWebViewCreated(controller);
          },
          onUpdateVisitedHistory: (controller, url, isReloaded) {
            if (url != null) {
              appBarController.updateUrl(url.toString());
            }
          },
          onLoadStart: (controller, url) {
            appBarController.updateUrl(url.toString());
            appBarController.updateProgress(0);
          },
          onProgressChanged: (controller, progress) {
            appBarController.updateProgress(progress / 100);
          },
          onLoadStop: (controller, url) {
            appBarController.updateProgress(1);
          },
          onRenderProcessGone: (controller, details) async {
            logger.severe('Popup webview render process gone', details);
            // Close the popup window if render process dies
            if (mounted) {
              _closeWindow();
            }
          },
          onCloseWindow: (controller) {
            final log = logger.child('_WebViewWindowState.onCloseWindow');
            log.info('closing window for url: ${widget.parameters.action.request.url}');
            _closeWindow();
            log.finest(() => {'type': 'onCloseWindow', 'data': json.encode(widget.parameters.action.toJson())});
          },
          onCreateWindow: onCreateWindowAction,
          shouldOverrideUrlLoading: shouldOverrideUrlLoading,
          onReceivedServerTrustAuthRequest: onReceivedServerTrustAuthRequest,
          onReceivedHttpError: onReceivedHttpError,
        ),
        bottomNavigationBar: Builder(
          builder: (context) {
            final padding = MediaQuery.paddingOf(context);
            return Padding(
              padding: EdgeInsets.only(bottom: padding.bottom),
              child: const WebviewBottomBar(),
            );
          },
        ),
      ),
    );
  }
}
