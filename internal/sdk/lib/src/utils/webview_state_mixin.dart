import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../logging/logging.dart';
import '../services/permission.dart';
import '../ui/claim_creation_webview/window/view.dart';
import '../widgets/permission.dart';

final defaultWebViewSettings = InAppWebViewSettings(
  javaScriptCanOpenWindowsAutomatically: true,
  supportMultipleWindows: true,
  isInspectable: false,
  incognito: false,
);

/// ref: https://github.com/WebKit/WebKit/blob/995f6b1595611c934e742a4f3a9af2e678bc6b8d/Source/WebKit/UIProcess/API/Cocoa/WKNavigationDelegatePrivate.h#L61
class WKNavigationActionPolicyAllowWithoutTryingAppLink implements NavigationActionPolicy {
  @override
  int toNativeValue() {
    return NavigationActionPolicy.ALLOW.toNativeValue() + 2;
  }

  @override
  int toValue() {
    return toNativeValue();
  }

  @override
  // ignore: override_on_non_overriding_member
  String name() {
    return 'ALLOW_WITHOUT_TRYING_APP_LINK';
  }
}

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
    log.info('onGeolocationPermissionsShowPrompt: origin: $origin');
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
    final log = _logger.child('onPermissionRequestedFromWeb');
    log.info('onPermissionRequestedFromWeb: request: ${json.encode(request)}');
    final ps = PermissionService();
    for (final resource in request.resources) {
      log.info('onPermissionRequestedFromWeb: resource: $resource');

      if (resource == PermissionResourceType.CAMERA) {
        log.info('onPermissionRequestedFromWeb: requesting camera permission');
        await ps.requestCameraPermission();
      } else if (resource == PermissionResourceType.CAMERA_AND_MICROPHONE) {
        log.info('onPermissionRequestedFromWeb: requesting camera and microphone permission');
        await ps.requestCameraAndMicrophonePermission();
      } else if (resource == PermissionResourceType.MICROPHONE) {
        log.info('onPermissionRequestedFromWeb: requesting microphone permission');
        await ps.requestMicrophonePermission();
      } else if (resource == PermissionResourceType.GEOLOCATION) {
        log.info('onPermissionRequestedFromWeb: requesting geolocation permission');
        await ps.requestGeolocationPermission();
      } else {
        log.warning('onPermissionRequestedFromWeb: unknown resource: $resource');
      }
    }
    log.info('onPermissionRequestedFromWeb: returning PermissionResponse');

    if (!mounted) return null;

    final bool response = await PermissionDialog.show(context: context, request: request);

    return PermissionResponse(
      action: response ? PermissionResponseAction.GRANT : PermissionResponseAction.PROMPT,
      resources: request.resources,
    );
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

  Future<NavigationActionPolicy?> shouldOverrideUrlLoading(
    InAppWebViewController controller,
    NavigationAction action,
  ) async {
    final log = _logger.child('shouldOverrideUrlLoading');
    log.finest('shouldOverrideUrlLoading: action: ${json.encode(action)}');
    if (Platform.isMacOS || Platform.isIOS) {
      return WKNavigationActionPolicyAllowWithoutTryingAppLink();
    }
    return NavigationActionPolicy.ALLOW;
  }
}
