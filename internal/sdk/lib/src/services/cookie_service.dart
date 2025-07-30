import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../data/providers.dart';
import '../logging/logging.dart';

class CookieService {
  Future<void> clearCookies() async {
    final cookieManager = CookieManager.instance();
    await cookieManager.deleteAllCookies();
  }

  final _log = logging.child('CookieService');

  Future<String> getCookieString(WebUri url, {required WebCredentialsType credentials}) async {
    final cookieManager = CookieManager.instance();
    final urlHost = url.host;
    final cookies = await cookieManager.getCookies(url: url);
    _log.info('Getting cookies (${cookies.length}) for ($urlHost) $url with credentials $credentials');
    final String cookieString = cookies
        .where((e) {
          _log.finest('cookie: $e');
          switch (credentials) {
            case WebCredentialsType.OMIT:
              return false;
            case WebCredentialsType.SAME_ORIGIN:
              return e.domain == urlHost || e.domain == '.$urlHost';
            case WebCredentialsType.INCLUDE:
              return true;
          }
        })
        .map((e) => '${e.name}=${e.value}')
        .join(';');
    return cookieString;
  }
}
