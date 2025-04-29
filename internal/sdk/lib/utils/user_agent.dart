import 'dart:io';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:reclaim_flutter_sdk/data/providers.dart';

class WebViewUserAgentUtil {
  const WebViewUserAgentUtil._();

  static bool get _isPlatformDarwin => Platform.isIOS || Platform.isMacOS;

  static Future<String> getDefaultUserAgent() async {
    final defaultUserAgent = await InAppWebViewController.getDefaultUserAgent();
    if (_isPlatformDarwin) {
      return "$defaultUserAgent Safari/604.1";
    }
    return defaultUserAgent.replaceFirst("; wv)", ")");
  }

  static Future<String> getEffectiveUserAgent(
    UserAgentSettings? reclaimUserAgentSettings,
  ) async {
    final userAgent = _isPlatformDarwin
        ? reclaimUserAgentSettings?.ios
        : reclaimUserAgentSettings?.android;

    if (userAgent != null && userAgent.trim().isNotEmpty) {
      return userAgent;
    }

    return getDefaultUserAgent();
  }

  static Future<String> setEffectiveUserAgent(
    InAppWebViewController controller,
    UserAgentSettings? reclaimUserAgentSettings,
  ) async {
    final previousSettings = await controller.getSettings();
    final settings = previousSettings?.copy() ?? InAppWebViewSettings();
    final userAgent = await getEffectiveUserAgent(reclaimUserAgentSettings);
    settings.userAgent = userAgent;
    await controller.setSettings(settings: settings);
    return userAgent;
  }
}
