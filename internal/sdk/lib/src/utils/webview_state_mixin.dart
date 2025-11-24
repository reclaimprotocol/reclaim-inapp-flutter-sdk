import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../logging/logging.dart';
import '../services/hybrid_screenshot_service.dart';
import '../services/permission.dart';
import '../ui/claim_creation_webview/view_model.dart';
import '../ui/claim_creation_webview/webview_handler_manager.dart';
import '../ui/claim_creation_webview/window/controller.dart';
import '../ui/claim_creation_webview/window/view.dart';
import '../widgets/permission.dart';

final defaultWebViewSettings = InAppWebViewSettings(
  javaScriptCanOpenWindowsAutomatically: true,
  supportMultipleWindows: true,
  isInspectable: false,
  incognito: false,
  mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
  rendererPriorityPolicy: RendererPriorityPolicy(
    waivedWhenNotVisible: false,
    rendererRequestedPriority: RendererPriority.RENDERER_PRIORITY_IMPORTANT,
  ),
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

  HybridScreenshotService? get screenshotService => null;
  InAppWebViewController? get mainWebViewController => null;
  PopupWindowController? get popupWindowController => null;

  WebViewJSHandlerManager get handlerManager;

  ClaimCreationWebClientViewModel get viewModel;

  UnmodifiableListView<UserScript> get userScripts;

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

  static final allowedResourceWhitelist = <PermissionResourceType>{
    PermissionResourceType.AUTOPLAY,
    PermissionResourceType.PROTECTED_MEDIA_ID,
  };

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

    final bool response = request.resources.every(allowedResourceWhitelist.contains)
        ? true
        : await PermissionDialog.show(context: context, request: request);

    return PermissionResponse(
      action: response ? PermissionResponseAction.GRANT : PermissionResponseAction.PROMPT,
      resources: request.resources,
    );
  }

  Future<bool> onCreateWindowAction(InAppWebViewController controller, CreateWindowAction createWindowAction) async {
    final settings = await controller.getSettings() ?? defaultWebViewSettings;
    if (!mounted) return false;

    final log = _logger.child('onCreateWindowAction');
    log.info('creating window for url: ${createWindowAction.request.url}');
    log.finest(() => {'type': 'createWindowAction', 'data': json.encode(createWindowAction.toJson())});

    final popupController = popupWindowController;
    if (popupController == null) {
      _logger.warning('PopupWindowController not available, cannot open popup window');
      return false;
    }

    try {
      popupController.showPopup(
        WebViewWindowParameters(
          webViewSettings: settings,
          action: createWindowAction,
          screenshotService: screenshotService,
          mainWebViewController: mainWebViewController,
          handlerManager: handlerManager,
          viewModel: viewModel,
          userScripts: userScripts,
          onClose: popupController.hidePopup,
        ),
      );
    } catch (e, s) {
      _logger.severe('Error opening popup window', e, s);
      return false;
    }

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
