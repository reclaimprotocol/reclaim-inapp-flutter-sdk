import 'dart:io';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../data/providers.dart';

class WebViewUserAgentUtil {
  const WebViewUserAgentUtil._();

  static bool get _isPlatformDarwin => Platform.isIOS || Platform.isMacOS;

  // ref https://www.chromium.org/updates/ua-reduction/
  static String generateChromeAndroidUserAgent({int chromeMajorVersion = 136, bool isMobile = true}) {
    if (chromeMajorVersion <= 0) {
      chromeMajorVersion = 135;
    }

    final platform = "(Linux; Android 10; K)";
    final engine = "AppleWebKit/537.36 (KHTML, like Gecko)";
    final chromeVersionString = "Chrome/$chromeMajorVersion.0.0.0";
    final mobileToken = isMobile ? " Mobile" : "";
    final safariCompat = "Safari/537.36";

    return "Mozilla/5.0 $platform $engine $chromeVersionString$mobileToken $safariCompat";
  }

  static Future<String> getDefaultUserAgent() async {
    if (_isPlatformDarwin) {
      final defaultUserAgent = await InAppWebViewController.getDefaultUserAgent();
      return "$defaultUserAgent Safari/604.1";
    }
    return generateChromeAndroidUserAgent(chromeMajorVersion: 135, isMobile: true);
  }

  static Future<String> getEffectiveUserAgent(UserAgentSettings? reclaimUserAgentSettings) async {
    final userAgent = _isPlatformDarwin ? reclaimUserAgentSettings?.ios : reclaimUserAgentSettings?.android;

    if (userAgent != null && userAgent.trim().isNotEmpty) {
      return userAgent;
    }

    return getDefaultUserAgent();
  }
}
