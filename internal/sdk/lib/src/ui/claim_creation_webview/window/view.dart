import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../controller.dart';
import '../../../logging/logging.dart';
import '../../../utils/webview_state_mixin.dart';
import '../../../widgets/reclaim_appbar.dart';
import '../../../widgets/reclaim_theme_provider.dart';
import '../../../widgets/verification_review/controller.dart';
import '../../../widgets/webview_bottom.dart';

class WebViewWindowParameters {
  final InAppWebViewSettings webViewSettings;
  final CreateWindowAction action;

  const WebViewWindowParameters({required this.webViewSettings, required this.action});
}

class WebViewWindow extends StatefulWidget {
  const WebViewWindow({super.key, required this.parameters});

  final WebViewWindowParameters parameters;

  static Future<void> open({required BuildContext context, required WebViewWindowParameters parameters}) async {
    final vm = VerificationController.readOf(context);
    final verificationReviewController = VerificationReviewController.readOf(context);

    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) {
          return vm.wrap(
            child: verificationReviewController.wrap(
              child: ReclaimThemeProvider(child: WebViewWindow(parameters: parameters)),
            ),
          );
        },
      ),
    );
  }

  @override
  State<WebViewWindow> createState() => _WebViewWindowState();
}

class _WebViewWindowState extends State<WebViewWindow> with WebViewCompanionMixin<WebViewWindow> {
  final appBarController = ReclaimAppBarController();

  @override
  void dispose() {
    appBarController.dispose();
    super.dispose();
  }

  bool _didWindowClose = false;

  InAppWebViewController? _controller;

  final logger = logging.child('WebViewWindow');

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (!_didWindowClose) {
          _didWindowClose = true;
          try {
            await _controller?.evaluateJavascript(source: 'window.close()');
          } catch (e, s) {
            logging.severe('Error closing window', e, s);
          }
        }
      },
      child: Scaffold(
        appBar: ReclaimAppBar(controller: appBarController, onPressed: null, isCloseButtonVisible: true),
        body: InAppWebView(
          gestureRecognizers: gestureRecognizers,
          onGeolocationPermissionsShowPrompt: onGeolocationPermissionsShowPrompt,
          onPermissionRequest: onPermissionRequestedFromWeb,
          initialSettings: widget.parameters.webViewSettings,
          windowId: widget.parameters.action.windowId,
          onWebViewCreated: (controller) {
            _controller = controller;
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
          onCloseWindow: (controller) {
            _didWindowClose = true;
            // handle manual pop
            Navigator.of(context).pop();
          },
          onCreateWindow: onCreateWindowAction,
          shouldOverrideUrlLoading: shouldOverrideUrlLoading,
        ),
        bottomNavigationBar: WebviewBottomBar(),
      ),
    );
  }
}
