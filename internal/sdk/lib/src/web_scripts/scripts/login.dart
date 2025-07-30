import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../logging/logging.dart';

const _loginButtonFinderScript = r"""
(() => {
    function hasElementByXPath(
        // type: string
        xpath,
    ) {
        // Evaluate the XPath and return true if an element is found
        return !!document.evaluate(xpath, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue;
    };

    function hasElementByPhrase(
        // Define the list of phrases to match
        // type: string[]
        phrases,
    ) {
        // Dynamically build the XPath conditions from the list
        const conditions = phrases.map(e => e.toLowerCase())
            .map(phrase => `translate(normalize-space(text()), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') = '${phrase}'`)
            .join(' or ');

        // Construct the final XPath
        const xpath = `//*[${conditions}]`;

        const valueConditions = phrases.map(e => e.toLowerCase())
            .map(phrase => `translate(normalize-space(@value), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') = '${phrase}'`)
            .join(' or ');

        // Construct the final XPath for value
        const valueXpath = `//*[${valueConditions}]`;

        // Evaluate the XPath and return true if an element is found
        return hasElementByXPath(xpath) || hasElementByXPath(valueXpath);
    };

    function hasElementByPropertyValue(
        // type: string
        valueType,
        // Define the list of tokens to match
        // type: string[]
        tokens,
        elementType,
    ) {
        const valueConditions = tokens.map(e => e.toLowerCase())
            .map(token => `@${valueType} = '${token}'`)
            .join(' or ');

        // Construct the final XPath for value
        const valueXpath = `//${elementType || '*'}[${valueConditions}]`;

        // Evaluate the XPath and return true if an element is found
        return hasElementByXPath(valueXpath);
    };

    // Define the list of phrases to match
    const loginPhrases = [
        'sign in',
        'log in with',
        'sign in with',
        'login with',
        'signin with',
        'signin',
        'log in',
        'login',
        'sign up',
        'signup',
        'resend',
        'sign up now',
        'sign in now',
        'create account',
        'create an account',
        'sign up or sign in',
        'sign in or create an account',
        'sign in or create account',
        'log in or create an account',
        'log in or create account',
        'sign in or sign up',
        'log in or sign up',
        'login or signup',
        'already have an account? sign in',
        'already have an account? signin',
        'already have an account? log in',
        'already have an account? login',
        'forgot password',
        'forgot password?',
        'forgotten password?',
        'forgotten password',
        'forgotten your password?',
        'forgotten your password',
        'reset password',
        'reset password?',
        'reset your password',
        'reset your password?',
        'recover password?',
        'recover password',
        'recover your password?',
        'recover your password',
    ];

    // known false positive example: https://github.com/settings/emails (pages that lets user update their profile information)
    // reference: https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/input#input_types
    const inputTypeTokens = [
        'email',
        'password',
        'tel',
    ];

    // reference: https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Attributes/autocomplete#value
    const inputAutocompleteTokens = [
        'email',
        'password',
        'username',
        'mobile',
        'tel',
        'tel-national',
        'one-time-code',
    ];

    return hasElementByPhrase(loginPhrases) || hasElementByPropertyValue('type', inputTypeTokens, 'input') || hasElementByPropertyValue('autocomplete', inputAutocompleteTokens, 'input');
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
    _log.warning(
      'Warning: evaluating login button finder script. Page could be loading or not responding. Returning false.',
      e,
      s,
    );
    return false;
  }
}
