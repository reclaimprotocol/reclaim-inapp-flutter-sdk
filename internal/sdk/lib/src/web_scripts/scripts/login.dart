import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../logging/logging.dart';

const _loginButtonFinderScript = r"""
(() => {
    // Define the list of phrases to match
    const loginPhrases = [
        'sign in',
        'signin',
        'log in',
        'login',
        'sign up',
        'signup',
        'resend',
    ];

    // Dynamically build the XPath conditions from the list
    const conditions = loginPhrases
        .map(phrase => `translate(normalize-space(text()), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') = '${phrase}'`)
        .join(' or ');

    // Construct the final XPath
    const xpath = `//*[${conditions}]`;

    // Evaluate the XPath and return true if an element is found
    return !!document.evaluate(xpath, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue;
})();
""";

final _log = logging.child('hasLoginButtonInPage');

// Always use isLoginUrl to check if the url is a login url before using this function.
Future<bool> hasLoginButtonInPage(InAppWebViewController controller) async {
  try {
    final result = await controller
        .evaluateJavascript(source: _loginButtonFinderScript)
        // shouldn't take this long
        .timeout(Duration(milliseconds: 500));
    _log.fine('has login: $result');
    return result == true || result == 'true' || result == '1';
  } catch (e, s) {
    _log.warning('Error evaluating login button finder script', e, s);
    return false;
  }
}
