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

bool isUrlAllowedToLaunch(Uri url, String allowedAppLinkPattern) {
  if (!['http', 'https'].contains(url.scheme) && allowedAppLinkPattern == '*') {
    return true;
  }
  final urlString = url.toString();
  if (allowedAppLinkPattern == urlString) {
    return true;
  }
  if (allowedAppLinkPattern == '*') return false;
  return RegExp(allowedAppLinkPattern).hasMatch(urlString);
}
