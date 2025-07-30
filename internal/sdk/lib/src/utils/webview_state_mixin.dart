import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../logging/logging.dart';
import '../services/permission.dart';
import '../ui/claim_creation_webview/window/view.dart';

final defaultWebViewSettings = InAppWebViewSettings(
  javaScriptCanOpenWindowsAutomatically: true,
  supportMultipleWindows: true,
  isInspectable: false,
  incognito: false,
);

mixin WebViewCompanionMixin<T extends StatefulWidget> implements State<T> {
  static final _logger = logging.child('WebViewCompanionMixin');

  @protected
  final gestureRecognizers = {Factory(() => EagerGestureRecognizer())};

  @protected
  Future<GeolocationPermissionShowPromptResponse> onGeolocationPermissionsShowPrompt(
    InAppWebViewController controller,
    String origin,
  ) async {
    final log = _logger.child('_onGeolocationPermissionsShowPrompt');
    final messenger = ScaffoldMessenger.of(context);
    final ps = PermissionService();
    final isGranted = await ps.requestGeolocationPermission();
    if (!isGranted) {
      log.warning('Location permission denied');
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Website requires location permissions. Please grant location permission in settings'),
        ),
      );
      ps.openAppLocationSettings();
    }
    return GeolocationPermissionShowPromptResponse(allow: true, origin: origin, retain: true);
  }

  @protected
  Future<PermissionResponse?> onPermissionRequestedFromWeb(
    InAppWebViewController controller,
    PermissionRequest request,
  ) async {
    final ps = PermissionService();
    for (final resource in request.resources) {
      if (resource == PermissionResourceType.CAMERA) {
        await ps.requestCameraPermission();
      } else if (resource == PermissionResourceType.CAMERA_AND_MICROPHONE) {
        await ps.requestCameraAndMicrophonePermission();
      } else if (resource == PermissionResourceType.MICROPHONE) {
        await ps.requestMicrophonePermission();
      } else if (resource == PermissionResourceType.GEOLOCATION) {
        await ps.requestGeolocationPermission();
      } else {
        // do nothing
      }
    }
    return PermissionResponse(action: PermissionResponseAction.PROMPT, resources: request.resources);
  }

  Future<bool> onCreateWindowAction(InAppWebViewController controller, CreateWindowAction createWindowAction) async {
    final settings = await controller.getSettings() ?? defaultWebViewSettings;
    if (!mounted) return false;

    await WebViewWindow.open(
      context: context,
      parameters: WebViewWindowParameters(webViewSettings: settings, action: createWindowAction),
    );

    return true;
  }
}
