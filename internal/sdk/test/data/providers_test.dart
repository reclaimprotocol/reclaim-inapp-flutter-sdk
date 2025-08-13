import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_inapp_sdk/src/data/providers.dart';

void main() {
  group('data provider request computed hash test', () {
    test('test with known hash', () {
      expect(
        DataProviderRequest.fromJson({
          'url': 'https://xargs.org/',
          'responseMatches': [
            {'type': 'regex', 'value': '<title.*?(?<name>Aiken &amp; Driscoll &amp; Webb)<\\/title>'},
          ],
          'method': 'GET',
          'responseRedactions': [
            {'xPath': './html/head/title'},
          ],
          'geoLocation': 'US',
        }).requestIdentifier,
        equals('0x88a2c863deeb7bd690e48112b8268b89231efb0a27441df50bce2c77a6836f8a'),
      );
    });

    test('test with known generated hash from devtool', () {
      void testIntegrity(DataProviderRequest request, String expectedHash) {
        expect(
          request.requestIdentifier,
          equals(expectedHash),
          reason: "Failed to match request: ${base64.encode(utf8.encode(request.requestIdentifierParams))}",
        );
      }

      testIntegrity(
        DataProviderRequest.fromJson({
          "url": "https://example.org/",
          "expectedPageUrl": "https://example.org",
          "urlType": "TEMPLATE",
          "method": "GET",
          "responseMatches": [
            {"value": "{{pageTitle}}", "type": "contains", "invert": false, "description": null, "order": 0},
            {
              "value": "\u003Ca href={{ianaLinkUrl}}\u003EMore information...\u003C/a\u003E",
              "type": "contains",
              "invert": false,
              "description": "",
              "order": null,
            },
          ],
          "responseRedactions": [
            {"xPath": "//title/text()", "jsonPath": "", "regex": "(.*)", "hash": ""},
            {
              "xPath": "/html/body/div[1]/p[2]/a",
              "jsonPath": "",
              "regex": "\u003Ca href=(.*)\u003EMore information...\u003C/a\u003E",
              "hash": null,
            },
          ],
          "bodySniff": {"enabled": false, "template": ""},
          "requestHash": "0xf0671406185377e01a1d5d7cc248d1a828c55887b195ffbc180680f7d068365d",
          "additionalClientOptions": null,
        }),
        '0x2ac3761ef83f7b36c649eb36a73aabcce84350f91b61110c06d9a3a8fc63ca78',
      );
      testIntegrity(
        DataProviderRequest.fromJson({
          "url": "https://example.com/",
          "expectedPageUrl": "https://example.com",
          "urlType": "TEMPLATE",
          "method": "GET",
          "responseMatches": [
            {"value": "{{pageTitle}}", "type": "contains", "invert": false, "description": "", "order": null},
            {
              "value": "\u003Ca href={{ianaLinkUrl}}\u003EMore information...\u003C/a\u003E",
              "type": "contains",
              "invert": false,
              "description": "",
              "order": null,
            },
          ],
          "responseRedactions": [
            {"xPath": "//title/text()", "jsonPath": "", "regex": "(.*)", "hash": null},
            {
              "xPath": "/html/body/div[1]/p[2]/a",
              "jsonPath": "",
              "regex": "\u003Ca href=(.*)\u003EMore information...\u003C/a\u003E",
              "hash": null,
            },
          ],
          "bodySniff": {"enabled": false, "template": ""},
          "requestHash": "0x8d7f90574f96e103f2354fd089ad8545ecaf521c822aca776f9a84ab025f05b2",
          "additionalClientOptions": null,
        }),
        '0x5de00a6f92154d939b613b60e0d7b2e1615714e170190e859395e4da29ae3c14',
      );
      testIntegrity(
        DataProviderRequest.fromJson(
          json.decode(
            utf8.decode(
              base64.decode(
                'eyJ1cmwiOiJodHRwczovL2pzb25wbGFjZWhvbGRlci50eXBpY29kZS5jb20vdXNlcnMvMSIsImV4cGVjdGVkUGFnZVVybCI6Imh0dHBzOi8vanNvbnBsYWNlaG9sZGVyLnR5cGljb2RlLmNvbS91c2Vycy8xIiwidXJsVHlwZSI6IlRFTVBMQVRFIiwibWV0aG9kIjoiR0VUIiwicmVzcG9uc2VNYXRjaGVzIjpbeyJ2YWx1ZSI6Int7RnVsbE5hbWV9fSIsInR5cGUiOiJjb250YWlucyIsImludmVydCI6ZmFsc2UsImRlc2NyaXB0aW9uIjoiIiwib3JkZXIiOm51bGx9LHsidmFsdWUiOiJ7e1VzZXJOYW1lfX0iLCJ0eXBlIjoiY29udGFpbnMiLCJpbnZlcnQiOmZhbHNlLCJkZXNjcmlwdGlvbiI6IiIsIm9yZGVyIjpudWxsfSx7InZhbHVlIjoie3tFbWFpbH19IiwidHlwZSI6ImNvbnRhaW5zIiwiaW52ZXJ0IjpmYWxzZSwiZGVzY3JpcHRpb24iOiIiLCJvcmRlciI6bnVsbH1dLCJyZXNwb25zZVJlZGFjdGlvbnMiOlt7InhQYXRoIjoiIiwianNvblBhdGgiOiIkLm5hbWUiLCJyZWdleCI6IlwibmFtZVwiOiBcIiguKilcIiIsImhhc2giOm51bGx9LHsieFBhdGgiOiIiLCJqc29uUGF0aCI6IiQudXNlcm5hbWUiLCJyZWdleCI6IlwidXNlcm5hbWVcIjogXCIoPzx1c2VybmFtZT4uKilcIiIsImhhc2giOm51bGx9LHsieFBhdGgiOiIiLCJqc29uUGF0aCI6IiQuZW1haWwiLCJyZWdleCI6IlwiZW1haWxcIjogXCIoPzxlbWFpbD4uKilcIiIsImhhc2giOiJvcHJmIn1dLCJib2R5U25pZmYiOnsiZW5hYmxlZCI6ZmFsc2UsInRlbXBsYXRlIjoiIn0sInJlcXVlc3RIYXNoIjoiMHhiZjZiNzNjMjRlM2YzYzA4MDA2MzYwMWQ1NWZkYmZjNzA2MmExYjk4OThjMDA0M2I2OWY0NGJkZjY2OWI4YmYyIiwiYWRkaXRpb25hbENsaWVudE9wdGlvbnMiOm51bGx9',
              ),
            ),
          ),
        ),
        '0x7091f9aeeed62d14c3717e059c470f2127f0d9c4a8a4e622f5b268b3e9e29850',
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
            type: ResponseMatchType.contains,
            invert: false,
            description: "",
            isOptional: false,
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
        credentials: WebCredentialsType.INCLUDE,
      );
      final request2 = DataProviderRequest(
        url: 'https://example.com',
        urlType: UrlType.CONSTANT,
        method: RequestMethodType.GET,
        responseMatches: [
          ResponseMatch(
            value: "{{FullName}}",
            type: ResponseMatchType.contains,
            invert: false,
            description: "",
            isOptional: false,
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
        credentials: WebCredentialsType.INCLUDE,
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
            type: ResponseMatchType.contains,
            invert: false,
            description: "",
            isOptional: false,
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
        requestHash: "0xbf6b73c24e3f3c080063601d55fdbfc7062a1b9898c0043b69f44bdf669b8b2f",
        expectedPageUrl: "https://example.com",
        credentials: WebCredentialsType.INCLUDE,
      );
      expect(request1.requestIdentifier, isNot(equals(request3.requestIdentifier)));
    });
  });

  group('WebCredentialsType', () {
    test('fromString', () {
      expect(WebCredentialsType.fromString('omit'), equals(WebCredentialsType.OMIT));
      expect(WebCredentialsType.fromString('same-origin'), equals(WebCredentialsType.SAME_ORIGIN));
      expect(WebCredentialsType.fromString('include'), equals(WebCredentialsType.INCLUDE));
      expect(WebCredentialsType.fromString('OMIT'), equals(WebCredentialsType.OMIT));
      expect(WebCredentialsType.fromString('SAME_ORIGIN'), equals(WebCredentialsType.SAME_ORIGIN));
      expect(WebCredentialsType.fromString('INCLUDE'), equals(WebCredentialsType.INCLUDE));
      expect(WebCredentialsType.fromString(null), equals(WebCredentialsType.INCLUDE));
      expect(WebCredentialsType.fromString(''), equals(WebCredentialsType.INCLUDE));
      expect(() => WebCredentialsType.fromString('x'), throwsA(isA<ArgumentError>()));
    });
  });
}
