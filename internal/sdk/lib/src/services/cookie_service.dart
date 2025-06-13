import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class CookieService {
  Future<void> clearCookies() async {
    final cookieManager = CookieManager.instance();
    await cookieManager.deleteAllCookies();
  }

  Future<String> getCookieString(WebUri url) async {
    CookieManager cookieManager = CookieManager.instance();
    List<Cookie> cookies = await cookieManager.getCookies(url: url);
    String cookieString = cookies.map((e) => '${e.name}=${e.value}').join(';');
    return cookieString;
  }
}
