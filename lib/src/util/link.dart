import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:reclaim_inapp_sdk/reclaim_inapp_sdk.dart';

final _followLinkClient = ReclaimHttpClient();

final _logger = Logger(
  'reclaim_flutter_sdk.reclaim_verifier_module.followLink',
);

Future<String?> followLink(
  String url,
  int followDepth, {
  http.Client? client,
}) async {
  if (followDepth > 5) {
    // Too many redirects, bail out
    _logger.warning('Too many redirects, bail out');
    return null;
  }

  _logger.info('Attempting to follow link: $url, followDepth: $followDepth');

  try {
    final template = ClientSdkVerificationRequest.parseTemplateFromUrl(url);

    if (template.isNotEmpty) {
      _logger.warning('Template found, bail out');
      return null;
    }
  } on FormatException {
    // url could be a short/redirect link
  } catch (e, s) {
    _logger.warning('Error parsing url for unknown reason', e, s);
    return null;
  }

  final uri = Uri.parse(url);

  final effectiveClient = client ?? _followLinkClient;

  final response = await effectiveClient.send(
    http.Request('GET', uri)..followRedirects = false,
  );
  if (![301, 302, 303, 307, 308].contains(response.statusCode)) {
    _logger.warning(
      'Not a redirect with status code ${response.statusCode}, bail out',
    );
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

  _logger.info(
    'Redirect found, following link: $location, followDepth: $followDepth',
  );
  return location;
}

String? _blankAsNull(String? value) {
  return (value == null || value.trim().isEmpty) ? null : value;
}
