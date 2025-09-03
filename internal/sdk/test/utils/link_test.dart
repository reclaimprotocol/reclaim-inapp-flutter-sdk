import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http show Response;
import 'package:http/testing.dart' as http_testing;
import 'package:reclaim_inapp_sdk/src/utils/link.dart';

void main() {
  group('followLink', () {
    test('should follow link', () async {
      const expectedLocation =
          'https://share.example.org/verifier/?template=%7B%22sessionId%22%3A%22c740929dd5%22%2C%22providerId%22%3A%22example%22%2C%22applicationId%22%3A%220x486dD3B9C8DF7c9b263C75713c79EC1cf8F592F2%22%2C%22signature%22%3A%220x39d9a560859265affd58ef25bba444228ac1ab90a32fd7d0374fa8c20e55fd444da7d0b54d5b90de023d325dc07e0ebe9dcb1b97ea903f2cf48bc93e45651efb1c%22%2C%22timestamp%22%3A%221755040406984%22%2C%22callbackUrl%22%3A%22https%3A%2F%2Fapi.reclaimprotocol.org%2Fapi%2Fsdk%2Fcallback%3FcallbackId%3Dc740929dd5%22%2C%22context%22%3A%22%7B%5C%22contextAddress%5C%22%3A%5C%220x0%5C%22%2C%5C%22contextMessage%5C%22%3A%5C%22sample%20context%5C%22%7D%22%2C%22parameters%22%3A%7B%7D%2C%22redirectUrl%22%3A%22%22%2C%22acceptAiProviders%22%3Afalse%2C%22sdkVersion%22%3A%22js-2.3.3%22%2C%22jsonProofResponse%22%3Afalse%7D';

      expect(
        await followUrlRedirects(
          'https://api.example.org/api/sdk/verification-url/8180b0ce-0dd3-4325-84f5-eff0be1f4b53',
          0,
          client: http_testing.MockClient((request) {
            return Future.value(http.Response('', 301, headers: <String, String>{'location': expectedLocation}));
          }),
        ),
        expectedLocation,
        reason: 'Should follow link',
      );

      expect(
        await followUrlRedirects(
          'https://api.example.org/api/sdk/verification-url/8180b0ce-0dd3-4325-84f5-eff0be1f4b53',
          6,
          client: http_testing.MockClient((request) {
            return Future.value(http.Response('', 301, headers: <String, String>{'location': expectedLocation}));
          }),
        ),
        isNull,
        reason: 'Should bail out after 5 redirects',
      );
    });
  });
}
