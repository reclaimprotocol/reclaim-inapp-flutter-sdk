import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../data/providers.dart';

class WebViewUserAgentUtil {
  const WebViewUserAgentUtil._();

  static bool get _isPlatformDarwin => Platform.isIOS || Platform.isMacOS;

  static String _getSafariVersionFromIOSVersion(String iosVersion) {
    final parts = iosVersion.split('.');
    if (parts.isEmpty) return "17.2";

    final majorVersion = parts[0];
    final minorVersion = parts.length > 1 ? parts[1] : "0";

    return "$majorVersion.$minorVersion";
  }

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

  static Future<String> _generateSafariUserAgent() async {
    final deviceInfo = DeviceInfoPlugin();
    final iosInfo = await deviceInfo.iosInfo;

    // Get iOS version and format it (e.g., "17.2.1" -> "17_2_1")
    final iosVersion = iosInfo.systemVersion;
    final iosVersionFormatted = iosVersion.replaceAll('.', '_');

    // Get Safari version (matches iOS version)
    final safariVersion = _getSafariVersionFromIOSVersion(iosVersion);

    final deviceModel = iosInfo.model.contains("iPad") ? "iPad" : "iPhone";
    final cpuPrefix = deviceModel == "iPad" ? "OS" : "iPhone OS";

    return "Mozilla/5.0 ($deviceModel; CPU $cpuPrefix $iosVersionFormatted like Mac OS X) "
        "AppleWebKit/605.1.15 (KHTML, like Gecko) "
        "Version/$safariVersion Mobile/15E148 Safari/604.1";
  }

  static Future<String> getDefaultUserAgent() async {
    if (_isPlatformDarwin) {
      if (Platform.isIOS) {
        final userAgent = await _generateSafariUserAgent();
        return userAgent;
      } else {
        final defaultUserAgent = await InAppWebViewController.getDefaultUserAgent();
        return "$defaultUserAgent Safari/604.1";
      }
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
