import 'dart:convert';

import '../data/providers.dart';
import '../logging/logging.dart';
import '../webview_utils.dart';

class RequestMatcher {
  final Iterable<InjectionRequest> injectionRequests;

  const RequestMatcher({required this.injectionRequests});

  static final _logger = logging.child('RequestMatcher');

  Map<String, dynamic> normalizeRequest(Map<String, dynamic> request) {
    final url = request['url'];
    final requestBody = request['requestBody'];
    final response = request['response'];
    return {
      ...request,
      'url': url is String ? url : (url is Map && url['url'] is String ? url['url'].toString() : ''),
      'requestBody': requestBody is Map ? json.encode(requestBody) : requestBody,
      'response': response is Map ? json.encode(response) : response,
    };
  }

  bool isRegexMatch(Map data, String key, String regex) {
    final value = data[key];
    if (value == null || value is! String) {
      if (value is! String) {
        _logger.warning('Expected value of $key to be a string, but got ${value.runtimeType}');
        _logger.finer(() => {'key': key, 'value': value, 'regex': regex});
      }
      return false;
    }
    return RegExp(regex.replaceAll('\\\\', '\\')).hasMatch(value) || RegExp(regex).hasMatch(value);
  }

  bool isRequestMethodMatch(Map data, String key, RequestMethodType expectedMethod) {
    final value = data[key];

    if (value == null) return true;
    if (value is! String) return true;

    return expectedMethod.name.toLowerCase().trim() == value.toLowerCase().trim();
  }

  Iterable<InjectionRequest> findMatch(Map request) sync* {
    for (final injectedRequest in injectionRequests) {
      final bodySniffRegex = injectedRequest.bodySniffRegex;
      if (isRegexMatch(request, 'url', injectedRequest.urlRegex) &&
          isRequestMethodMatch(request, 'method', injectedRequest.dataRequest.method) &&
          (bodySniffRegex == null || isRegexMatch(request, 'requestBody', bodySniffRegex))) {
        _logger.finest(() => ({'request': json.encode(request), 'injectedRequest': json.encode(injectedRequest)}));
        yield injectedRequest;
      }
    }
  }
}
