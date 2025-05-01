import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_flutter_sdk/data/providers.dart';

void main() {
  group('data provider request computed hash test', () {
    test('test with known hash', () {
      expect(
        DataProviderRequest.fromJson({
          'url': 'https://xargs.org/',
          'responseMatches': [
            {
              'type': 'regex',
              'value':
                  '<title.*?(?<name>Aiken &amp; Driscoll &amp; Webb)<\\/title>',
            },
          ],
          'method': 'GET',
          'responseRedactions': [
            {'xPath': './html/head/title'},
          ],
          'geoLocation': 'US',
        }).requestIdentifier,
        equals(
          '0xc1a613e7b12ca29900e8fc524bd1f1b866297626fd27d84c1ac81e6152b3e4d4',
        ),
      );
    });

    test('should return the same hash for the same request', () {
      final request1 = DataProviderRequest(
        url: 'https://example.com',
        urlType: UrlType.CONSTANT,
        method: RequestMethodType.GET,
        responseMatches: [
          ResponseMatch(
            value: "{{FullName}}",
            type: "contains",
            invert: false,
            description: "",
          ),
        ],
        responseRedactions: [
          ResponseRedaction(
            xPath: "",
            jsonPath: r"$.email",
            regex: "\"email\": \"(?\u003Cemail\u003E.*)\"",
            hash: "oprf",
            matchType: MatchType.GREEDY,
          ),
        ],
        bodySniff: BodySniff(enabled: false, template: ""),
        expectedPageUrl: "https://example.org",
      );
      final request2 = DataProviderRequest(
        url: 'https://example.com',
        urlType: UrlType.CONSTANT,
        method: RequestMethodType.GET,
        responseMatches: [
          ResponseMatch(
            value: "{{FullName}}",
            type: "contains",
            invert: false,
            description: "",
          ),
        ],
        responseRedactions: [
          ResponseRedaction(
            xPath: "",
            jsonPath: r"$.email",
            regex: "\"email\": \"(?\u003Cemail\u003E.*)\"",
            hash: "oprf",
            matchType: MatchType.GREEDY,
          ),
        ],
        bodySniff: BodySniff(enabled: false, template: ""),
        expectedPageUrl: "https://example.org",
      );
      // ensure that objects are different
      expect(identical(request1, request2), isFalse);
      // check computed hash
      expect(request1.requestIdentifier, equals(request2.requestIdentifier));
      final request3 = DataProviderRequest(
        url: 'https://{{name}}.example.com',
        urlType: UrlType.TEMPLATE,
        method: RequestMethodType.POST,
        responseMatches: [
          ResponseMatch(
            value: "{{DateOfBirth}}",
            type: "contains",
            invert: false,
            description: "",
          ),
        ],
        responseRedactions: [
          ResponseRedaction(
            xPath: "",
            jsonPath: r"$.dob",
            regex: "\"dob\": \"(?\u003Cdob\u003E.*)\"",
            matchType: MatchType.LAZY,
          ),
        ],
        bodySniff: BodySniff(enabled: true, template: ""),
        requestHash:
            "0xbf6b73c24e3f3c080063601d55fdbfc7062a1b9898c0043b69f44bdf669b8b2f",
        expectedPageUrl: "https://example.com",
      );
      expect(
        request1.requestIdentifier,
        isNot(equals(request3.requestIdentifier)),
      );
    });
  });
}
