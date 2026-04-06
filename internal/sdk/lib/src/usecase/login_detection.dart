// ignore_for_file: unused_field

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../controller.dart';
import '../data/identity.dart';
import '../logging/logging.dart';
import '../utils/url.dart';
import 'session_manager.dart';

final _log = logging.child('LoginDetection');

enum _DetectionResult {
  // We don't see anything that signals whether user needs to login
  LOGIN_INDICATORS_NOT_FOUND,
  // User needs to login
  LOGIN_INDICATORS_FOUND,
}

class LoginDetection {
  final SessionIdentity identity;
  final SessionManager sessionManager;

  LoginDetection(this.identity, {SessionManager? sessionManager})
    : sessionManager = sessionManager ?? const SessionManager();

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
    _detectionResults.clear();
    _detectionResults[simplifyUrl(url)] = result;
  }

  bool _hasDetectionResultChanged(String url, _DetectionResult result) {
    final previous = _detectionResults[simplifyUrl(url)];
    if (previous == null) return true;
    return previous != result;
  }

  // Possible values: url, element, none, error
  Future<String> getLoginRequirementReason(InAppWebViewController controller) async {
    final log = _log.child('getLoginRequirementReason');
    try {
      final reason = await controller
          .evaluateJavascript(source: 'window.__maybeRequiresLoginInteraction()')
          .timeout(const Duration(seconds: 10));
      return reason ?? 'none';
    } catch (e, s) {
      log.warning(
        'Warning: evaluating login detection script. Page could be loading or not responding. Returning error.',
        e,
        s,
      );
      return 'error';
    }
  }

  Future<bool> maybeRequiresLoginInteraction(String? currentUrl, InAppWebViewController controller) async {
    final log = _log.child('maybeRequiresLoginInteraction');
    log.finest('checking whether requires login interaction: $currentUrl');
    if (currentUrl == null) {
      return false;
    }
    final reason = await getLoginRequirementReason(controller);
    log.fine('maybeRequiresLoginInteraction reason: reason=$reason url=$currentUrl');
    if (reason != 'none') {
      unawaited(onLoginRequiredDetected(url: currentUrl, indicator: reason));
      return true;
    } else {
      unawaited(onLoginDetected(url: currentUrl, indicator: reason));
      return false;
    }
  }

  Future<void> onLoginDetected({required String url, required String indicator}) async {
    const detectionResult = _DetectionResult.LOGIN_INDICATORS_NOT_FOUND;
    if (!_hasDetectionResultChanged(url, detectionResult)) {
      return;
    }
    _setLastDetectionResult(url, detectionResult);
    try {
      await sessionManager.onLoginDetected(
        applicationId: identity.appId,
        sessionId: identity.sessionId,
        providerId: identity.providerId,
        indicator: indicator,
        url: url,
      );
    } catch (e, s) {
      _log.severe('Failed to send login detected log', e, s);
    }
  }

  Future<void> onLoginRequiredDetected({required String url, required String indicator}) async {
    const detectionResult = _DetectionResult.LOGIN_INDICATORS_FOUND;
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
        indicator: indicator,
      );
    } catch (e, s) {
      _log.severe('Failed to send login required detected log', e, s);
    }
  }
}
