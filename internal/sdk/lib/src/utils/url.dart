/// Returns true if the url is maybe a login url.
///
/// This is a heuristic to determine if the url is a login url.
/// It is not a perfect solution and may return false results. Should be replaced with an another solution in future for better accuracy.
///
/// The url is considered a login url if it contains a token that is in the [maybeLoginPathTokens] or [maybeLoginQueryTokens] list.
///
/// The [maybeLoginPathTokens] and [maybeLoginQueryTokens] lists are not exhaustive and may contain false positives.
///
/// For better confidence when this returns false, use [hasLoginButtonInPage] to page has a login button.
bool isLoginUrl(String url) {
  final uri = Uri.tryParse(url);

  final lowercaseUrlPath = uri?.path.toLowerCase();
  final lowercaseUrlQuery = uri?.query.toLowerCase();
  final lowercaseUrlFragment = uri?.fragment.toLowerCase();

  const loginTokens = ['login', 'log-in', 'signin', 'signup', 'sign-in', 'sign-up', 'sign_in', 'sign_up', 'log_in'];
  const mfaTokens = ['two-factor', 'two_factor', '2-factor', '2fa', 'mfa', 'otp'];
  // user may be redirected to login page that says logout in the url (e.g twitter)
  const logoutTokens = ['logout', 'signout', 'sign_out', 'log_out'];

  const maybeLoginPathTokens = [...loginTokens, ...mfaTokens, 'auth', ...logoutTokens];
  const maybeLoginQueryTokens = [...loginTokens, ...mfaTokens, ...logoutTokens];

  bool isInLoginPath(String token) {
    if (lowercaseUrlPath != null && lowercaseUrlPath.contains(token)) {
      return true;
    }
    if (lowercaseUrlFragment != null && lowercaseUrlFragment.contains(token)) {
      return true;
    }
    return false;
  }

  bool isInLoginQuery(String token) {
    return lowercaseUrlQuery != null && lowercaseUrlQuery.contains(token);
  }

  return maybeLoginPathTokens.any(isInLoginPath) ||
      maybeLoginQueryTokens.any(isInLoginQuery) ||
      (uri == null && maybeLoginPathTokens.any(url.contains));
}

String normalizeUrl(String url) {
  url = simplifyUrl(url);
  return Uri.parse(url).replace(queryParameters: const {}, scheme: '').removeFragment().toString();
}

String simplifyUrl(String url) {
  if (url.endsWith('/')) {
    return url.substring(0, url.length - 1);
  }
  return url;
}

bool isUrlsEqual(String url, String? otherUrl) {
  if (otherUrl == null) {
    return false;
  }
  if (url == otherUrl) {
    return true;
  }
  try {
    return normalizeUrl(url) == normalizeUrl(otherUrl);
  } catch (_) {
    // url parsing may have failed.
    return false;
  }
}

String extractHost(String url) {
  return Uri.parse(url).host.replaceAll('www.', '');
}

/// Returns url formatted as per https://httpwg.org/specs/rfc9110.html#field.referer for use as referer.
String? createRefererUrl(String url) {
  return Uri.tryParse(url)?.removeFragment().replace(userInfo: '').toString();
}

/// Creates a full url from a location that can be a full or relative url format. Another [fullUrl] can be provided whos host can be used incase the [nextLocation] is a relative url and doesn't have a host.
String createUrlFromLocation(String nextLocation, String? fullUrl) {
  final isFullUrl = nextLocation.startsWith('http');
  if (isFullUrl) {
    return nextLocation;
  }
  final urlBuffer = StringBuffer('https://');
  // Path fragments can also have full stop, but we consider the first fragment as host if url doesn't start with '\' in this case
  final isUrlPath = nextLocation.startsWith('/');
  if (isUrlPath) {
    // Get the host from current URL and use it for relative URLs
    final currentHost = fullUrl != null ? Uri.parse(fullUrl).host : '';
    urlBuffer.write(currentHost);
  }
  urlBuffer.write(nextLocation);

  final fullExpectedUrl = urlBuffer.toString();

  return fullExpectedUrl;
}
