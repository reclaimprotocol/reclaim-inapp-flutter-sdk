import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'http/http.dart';

final _followLinkClient = ReclaimHttpClient();

final _logger = Logger('reclaim_inapp_sdk.reclaim_verifier_module.followLink');

Future<String?> followUrlRedirects(String url, int followDepth, {http.Client? client}) async {
  if (followDepth > 5) {
    // Too many redirects, bail out
    _logger.warning('Too many redirects, bail out');
    return null;
  }

  _logger.info('Attempting to follow link: $url, followDepth: $followDepth');

  final uri = Uri.parse(url);

  final effectiveClient = client ?? _followLinkClient;

  try {
    final response = await effectiveClient.send(http.Request('GET', uri)..followRedirects = false);
    if (![301, 302, 303, 307, 308].contains(response.statusCode)) {
      _logger.warning('Not a redirect with status code ${response.statusCode}, bail out');
      return null;
    }

    final location =
        _blankAsNull(response.headers['location']) ??
        _blankAsNull(response.headers['LOCATION']) ??
        _blankAsNull(response.headers['Location']);

    if (location == null) {
      _logger.warning('No location found in redirect, bail out');
      return null;
    }

    _logger.info('Redirect found, following link: $location, followDepth: $followDepth');
    return location;
  } on SocketException catch (e, s) {
    _logger.warning('Socket exception, bail out', e, s);
    return null;
  } on http.ClientException catch (e, s) {
    _logger.warning('Client exception, bail out', e, s);
    return null;
  }
}

String? _blankAsNull(String? value) {
  return (value == null || value.trim().isEmpty) ? null : value;
}
