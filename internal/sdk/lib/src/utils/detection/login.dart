import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../web_scripts/scripts/login.dart';
import '../url.dart';

Future<bool> maybeRequiresLoginInteraction(String currentUrl, InAppWebViewController controller) async {
  if (isLoginUrl(currentUrl)) return true;
  return hasLoginButtonInPage(controller);
}
