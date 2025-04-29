import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logging/logging.dart';

bool isLoginUrl(
    String
        url) {
  final lowercaseUrl =
      url.toLowerCase();
  if (lowercaseUrl.contains('login') ||
      lowercaseUrl.contains('signin')) {
    return true;
  } else {
    return false;
  }
}

String normalizeUrl(
    String
        url) {
  if (url.endsWith(
      '/')) {
    url = url.substring(
        0,
        url.length - 1);
  }
  return Uri.parse(url)
      .replace(
          queryParameters: const {},
          scheme: '')
      .removeFragment()
      .toString();
}

bool isUrlsEqual(
    String
        url,
    String?
        otherUrl) {
  if (otherUrl ==
      null) {
    return false;
  }
  if (url ==
      otherUrl) {
    return true;
  }
  try {
    return normalizeUrl(url) ==
        normalizeUrl(otherUrl);
  } catch (_) {
    // url parsing may have failed.
    return false;
  }
}

void safeLaunchUrl(
    String
        url) async {
  final logger =
      logging.child('utils.safeLaunchUrl');
  final uri =
      Uri.parse(url);
  if (await canLaunchUrl(
      uri)) {
    await launchUrl(
        uri);
  } else {
    logger.severe(
        'The URL $url cannot be launched by the app',
        'Error: Could not launch $url',
        StackTrace.current);
  }
}

String extractHost(
    String
        url) {
  return Uri.parse(url).host.replaceAll(
      'www.',
      '');
}

Future<String>
    getCookieString(
        WebUri url) async {
  CookieManager
      cookieManager =
      CookieManager.instance();
  List<Cookie>
      cookies =
      await cookieManager.getCookies(url: url);
  String cookieString = cookies
      .map((e) =>
          '${e.name}=${e.value}')
      .join(';');
  return cookieString;
}

/// Returns url formatted as per https://httpwg.org/specs/rfc9110.html#field.referer for use as referer.
String? createRefererUrl(
    String
        url) {
  return Uri.tryParse(url)
      ?.removeFragment()
      .replace(userInfo: '')
      .toString();
}
