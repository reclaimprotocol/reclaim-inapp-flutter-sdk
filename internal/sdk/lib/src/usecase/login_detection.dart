import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../controller.dart';
import '../data/identity.dart';
import '../logging/logging.dart';
import '../utils/url.dart';
import '../web_scripts/scripts/login.dart';
import 'session_manager.dart';

final _log = logging.child('LoginDetection');

enum _DetectionResult { loginDetected, loginRequiredDetected }

class LoginDetection {
  final SessionIdentity identity;
  final SessionManager sessionManager;

  LoginDetection(this.identity, {SessionManager? sessionManager}) : sessionManager = sessionManager ?? SessionManager();

  static Future<LoginDetection> readAfterSessionStartedOf(BuildContext context) async {
    final controller = VerificationController.readOf(context);
    final session = await controller.sessionStartFuture;
    return LoginDetection(session.identity);
  }

  factory LoginDetection.readOf(BuildContext context) {
    final controller = VerificationController.readOf(context);
    return LoginDetection(controller.identity);
  }

  static final Map<String, _DetectionResult> _detectionResults = {};

  void _setLastDetectionResult(String url, _DetectionResult result) {
    _detectionResults[simplifyUrl(url)] = result;
  }

  bool _hasDetectionResultChanged(String url, _DetectionResult result) {
    final previous = _detectionResults[simplifyUrl(url)];
    if (previous == null) return true;
    return previous != result;
  }

  Future<bool> maybeRequiresLoginInteraction(String? currentUrl, InAppWebViewController controller) async {
    final log = _log.child('maybeRequiresLoginInteraction');
    log.finest('checking whether requires login interaction: $currentUrl');
    if (currentUrl == null) {
      return false;
    }
    if (isLoginUrl(currentUrl)) {
      log.finest('login url detected: $currentUrl');
      unawaited(
        onLoginRequiredDetected(url: currentUrl, hasLoginRelatedTokenInUrl: true, hasLoginRelatedElementInPage: null),
      );
      return true;
    }
    if (await hasLoginButtonInPage(controller)) {
      log.finest('login button detected in page: $currentUrl');
      unawaited(
        onLoginRequiredDetected(url: currentUrl, hasLoginRelatedTokenInUrl: false, hasLoginRelatedElementInPage: true),
      );
      return true;
    } else {
      unawaited(onLoginDetected(url: currentUrl));
      return false;
    }
  }

  Future<void> onLoginDetected({required String url}) async {
    const detectionResult = _DetectionResult.loginDetected;
    if (!_hasDetectionResultChanged(url, detectionResult)) {
      return;
    }
    _setLastDetectionResult(url, detectionResult);
    try {
      await sessionManager.onLoginDetected(
        applicationId: identity.appId,
        sessionId: identity.sessionId,
        providerId: identity.providerId,
        url: url,
      );
    } catch (e, s) {
      _log.severe('Failed to send login detected log', e, s);
    }
  }

  Future<void> onLoginRequiredDetected({
    required String url,
    required bool hasLoginRelatedTokenInUrl,
    required bool? hasLoginRelatedElementInPage,
  }) async {
    const detectionResult = _DetectionResult.loginRequiredDetected;
    if (!_hasDetectionResultChanged(url, detectionResult)) {
      return;
    }
    _setLastDetectionResult(url, detectionResult);
    try {
      await sessionManager.onLoginRequiredDetected(
        applicationId: identity.appId,
        sessionId: identity.sessionId,
        providerId: identity.providerId,
        url: url,
        hasLoginRelatedTokenInUrl: hasLoginRelatedTokenInUrl,
        hasLoginRelatedElementInPage: hasLoginRelatedElementInPage,
      );
    } catch (e, s) {
      _log.severe('Failed to send login required detected log', e, s);
    }
  }
}
