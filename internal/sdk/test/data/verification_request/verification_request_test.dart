import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:reclaim_inapp_sdk/src/data/verification/request.dart';

void main() {
  group('ClientSdkVerificationRequest', () {
    test('can be parsed from url', () async {
      expect(
        await ClientSdkVerificationRequest.fromUrl(
          // the deeplink url that's incorrectly adding params as a path
          'reclaimverifier://requestedproofs/template=%7B%22sessionId%22%3A%22a8302956b5%22%2C%22providerId%22%3A%226d3f6753-7ee6-49ee-a545-62f1b1822ae5%22%2C%22applicationId%22%3A%220x486dD3B9C8DF7c9b263C75713c79EC1cf8F592F2%22%2C%22signature%22%3A%220x1e905989b8eb5fa8cb994ddd2532a46285ca0938ee517d6bea2bd4a61c09bdbc4d3e5a553365da213f6f82d67c1bf87939dac05c7269a390a5903c1e87b372181c%22%2C%22timestamp%22%3A%221745363629091%22%2C%22callbackUrl%22%3A%22https%3A%2F%2Fapi.reclaimprotocol.org%2Fapi%2Fsdk%2Fcallback%3FcallbackId%3Da8302956b5%22%2C%22context%22%3A%22%7B%5C%22contextAddress%5C%22%3A%5C%220x0%5C%22%2C%5C%22contextMessage%5C%22%3A%5C%22sample%20context%5C%22%7D%22%2C%22parameters%22%3A%7B%7D%2C%22redirectUrl%22%3A%22https%3A%2F%2Fdemo.reclaimprotocol.org%2Fsession%2Fa8302956b5%22%2C%22acceptAiProviders%22%3Atrue%2C%22sdkVersion%22%3A%22js-2.3.3%22%2C%22jsonProofResponse%22%3Afalse%7D',
        ),
        isA<ClientSdkVerificationRequest>(),
      );
      expect(
        await ClientSdkVerificationRequest.fromUrl(
          'reclaimverifier://requestedproofs/?template=%7B%22sessionId%22%3A%22a8302956b5%22%2C%22providerId%22%3A%226d3f6753-7ee6-49ee-a545-62f1b1822ae5%22%2C%22applicationId%22%3A%220x486dD3B9C8DF7c9b263C75713c79EC1cf8F592F2%22%2C%22signature%22%3A%220x1e905989b8eb5fa8cb994ddd2532a46285ca0938ee517d6bea2bd4a61c09bdbc4d3e5a553365da213f6f82d67c1bf87939dac05c7269a390a5903c1e87b372181c%22%2C%22timestamp%22%3A%221745363629091%22%2C%22callbackUrl%22%3A%22https%3A%2F%2Fapi.reclaimprotocol.org%2Fapi%2Fsdk%2Fcallback%3FcallbackId%3Da8302956b5%22%2C%22context%22%3A%22%7B%5C%22contextAddress%5C%22%3A%5C%220x0%5C%22%2C%5C%22contextMessage%5C%22%3A%5C%22sample%20context%5C%22%7D%22%2C%22parameters%22%3A%7B%7D%2C%22redirectUrl%22%3A%22https%3A%2F%2Fdemo.reclaimprotocol.org%2Fsession%2Fa8302956b5%22%2C%22acceptAiProviders%22%3Atrue%2C%22sdkVersion%22%3A%22js-2.3.3%22%2C%22jsonProofResponse%22%3Afalse%7D',
        ),
        isA<ClientSdkVerificationRequest>(),
      );
      expect(
        await ClientSdkVerificationRequest.fromUrl(
          'https://share.reclaimprotocol.org/verify/?template=%7B%22sessionId%22%3A%22a8302956b5%22%2C%22providerId%22%3A%226d3f6753-7ee6-49ee-a545-62f1b1822ae5%22%2C%22applicationId%22%3A%220x486dD3B9C8DF7c9b263C75713c79EC1cf8F592F2%22%2C%22signature%22%3A%220x1e905989b8eb5fa8cb994ddd2532a46285ca0938ee517d6bea2bd4a61c09bdbc4d3e5a553365da213f6f82d67c1bf87939dac05c7269a390a5903c1e87b372181c%22%2C%22timestamp%22%3A%221745363629091%22%2C%22callbackUrl%22%3A%22https%3A%2F%2Fapi.reclaimprotocol.org%2Fapi%2Fsdk%2Fcallback%3FcallbackId%3Da8302956b5%22%2C%22context%22%3A%22%7B%5C%22contextAddress%5C%22%3A%5C%220x0%5C%22%2C%5C%22contextMessage%5C%22%3A%5C%22sample%20context%5C%22%7D%22%2C%22parameters%22%3A%7B%7D%2C%22redirectUrl%22%3A%22https%3A%2F%2Fdemo.reclaimprotocol.org%2Fsession%2Fa8302956b5%22%2C%22acceptAiProviders%22%3Atrue%2C%22sdkVersion%22%3A%22js-2.3.3%22%2C%22jsonProofResponse%22%3Afalse%7D',
        ),
        isA<ClientSdkVerificationRequest>(),
      );
      expect(
        await ClientSdkVerificationRequest.fromUrl(
          'https://appclip.apple.com/id?p=org.reclaimprotocol.app.clip&template=%7B%22sessionId%22%3A%22a8302956b5%22%2C%22providerId%22%3A%226d3f6753-7ee6-49ee-a545-62f1b1822ae5%22%2C%22applicationId%22%3A%220x486dD3B9C8DF7c9b263C75713c79EC1cf8F592F2%22%2C%22signature%22%3A%220x1e905989b8eb5fa8cb994ddd2532a46285ca0938ee517d6bea2bd4a61c09bdbc4d3e5a553365da213f6f82d67c1bf87939dac05c7269a390a5903c1e87b372181c%22%2C%22timestamp%22%3A%221745363629091%22%2C%22callbackUrl%22%3A%22https%3A%2F%2Fapi.reclaimprotocol.org%2Fapi%2Fsdk%2Fcallback%3FcallbackId%3Da8302956b5%22%2C%22context%22%3A%22%7B%5C%22contextAddress%5C%22%3A%5C%220x0%5C%22%2C%5C%22contextMessage%5C%22%3A%5C%22sample%20context%5C%22%7D%22%2C%22parameters%22%3A%7B%7D%2C%22redirectUrl%22%3A%22https%3A%2F%2Fdemo.reclaimprotocol.org%2Fsession%2Fa8302956b5%22%2C%22acceptAiProviders%22%3Atrue%2C%22sdkVersion%22%3A%22js-2.3.3%22%2C%22jsonProofResponse%22%3Afalse%7D',
        ),
        isA<ClientSdkVerificationRequest>(),
      );
      expect(
        await ClientSdkVerificationRequest.fromUrl(
          'x-safari-https://share.reclaimprotocol.org/verify/?template=%7B%22sessionId%22%3A%22a8302956b5%22%2C%22providerId%22%3A%226d3f6753-7ee6-49ee-a545-62f1b1822ae5%22%2C%22applicationId%22%3A%220x486dD3B9C8DF7c9b263C75713c79EC1cf8F592F2%22%2C%22signature%22%3A%220x1e905989b8eb5fa8cb994ddd2532a46285ca0938ee517d6bea2bd4a61c09bdbc4d3e5a553365da213f6f82d67c1bf87939dac05c7269a390a5903c1e87b372181c%22%2C%22timestamp%22%3A%221745363629091%22%2C%22callbackUrl%22%3A%22https%3A%2F%2Fapi.reclaimprotocol.org%2Fapi%2Fsdk%2Fcallback%3FcallbackId%3Da8302956b5%22%2C%22context%22%3A%22%7B%5C%22contextAddress%5C%22%3A%5C%220x0%5C%22%2C%5C%22contextMessage%5C%22%3A%5C%22sample%20context%5C%22%7D%22%2C%22parameters%22%3A%7B%7D%2C%22redirectUrl%22%3A%22https%3A%2F%2Fdemo.reclaimprotocol.org%2Fsession%2Fa8302956b5%22%2C%22acceptAiProviders%22%3Atrue%2C%22sdkVersion%22%3A%22js-2.3.3%22%2C%22jsonProofResponse%22%3Afalse%7D',
        ),
        isA<ClientSdkVerificationRequest>(),
      );
      expect(
        await ClientSdkVerificationRequest.fromUrl(
          'x-safari-https://share.reclaimprotocol.org/verifier/?template=%7B%22sessionId%22%3A%22a8302956b5%22%2C%22providerId%22%3A%226d3f6753-7ee6-49ee-a545-62f1b1822ae5%22%2C%22applicationId%22%3A%220x486dD3B9C8DF7c9b263C75713c79EC1cf8F592F2%22%2C%22signature%22%3A%220x1e905989b8eb5fa8cb994ddd2532a46285ca0938ee517d6bea2bd4a61c09bdbc4d3e5a553365da213f6f82d67c1bf87939dac05c7269a390a5903c1e87b372181c%22%2C%22timestamp%22%3A%221745363629091%22%2C%22callbackUrl%22%3A%22https%3A%2F%2Fapi.reclaimprotocol.org%2Fapi%2Fsdk%2Fcallback%3FcallbackId%3Da8302956b5%22%2C%22context%22%3A%22%7B%5C%22contextAddress%5C%22%3A%5C%220x0%5C%22%2C%5C%22contextMessage%5C%22%3A%5C%22sample%20context%5C%22%7D%22%2C%22parameters%22%3A%7B%7D%2C%22redirectUrl%22%3A%22https%3A%2F%2Fdemo.reclaimprotocol.org%2Fsession%2Fa8302956b5%22%2C%22acceptAiProviders%22%3Atrue%2C%22sdkVersion%22%3A%22js-2.3.3%22%2C%22jsonProofResponse%22%3Afalse%7D',
        ),
        isA<ClientSdkVerificationRequest>(),
      );
      expect(
        await ClientSdkVerificationRequest.fromUrl(
          'https://share.reclaimprotocol.org/verify/?template=%7B%22sessionId%22%3A%22b8f607537b%22%2C%22providerId%22%3A%2262019efe-a839-4aca-a56e-e92263a54131%22%2C%22applicationId%22%3A%220x18e14659BAF54208F8EE04BEbA8A8d3Fb487eF06%22%2C%22signature%22%3A%220xf8eebf5489130449a2f07870da9cdca9680b13c1a5c3bcfa2137f428ab77930307edf6cd12ea621b21772c360b9113a898aafe379d7afa93fdfdbb30e5dbc97d1c%22%2C%22timestamp%22%3A%221748418591230%22%2C%22callbackUrl%22%3A%22https%3A%2F%2Fapi.staging.reclaimprotocol.org%2Fapi%2Fsdk%2Fcallback%3FcallbackId%3Db8f607537b%22%2C%22context%22%3A%22%7B%5C%22contextAddress%5C%22%3A%5C%220x00000000000%5C%22%2C%5C%22contextMessage%5C%22%3A%5C%22Example%20context%20message%5C%22%7D%22%2C%22parameters%22%3A%7B%7D%2C%22providerVersion%22%3A%22%22%2C%22allowAiVersions%22%3Afalse%2C%22redirectUrl%22%3A%22%22%2C%22acceptAiProviders%22%3Afalse%2C%22sdkVersion%22%3A%22js-3.0.3%22%2C%22jsonProofResponse%22%3Afalse%7D',
        ),
        isA<ClientSdkVerificationRequest>(),
      );
      expect(
        await ClientSdkVerificationRequest.fromUrl(
          'https://portal.reclaimprotocol.org/kernel/?template=%7B%22sessionId%22%3A%22a3b1ed8d2b%22%2C%22providerId%22%3A%22example%22%2C%22applicationId%22%3A%220x896501a5e799038f7526eAb1950c2A6996601B30%22%2C%22signature%22%3A%220x49624268fd10c00e442b999b0c1a56b9054b214e62a9358e35a75f7df229c1022b46b397adf4527f622b59bff51b5cc9761728a711601797ef389d43131039641b%22%2C%22timestamp%22%3A%221774544142961%22%2C%22callbackUrl%22%3A%22https%3A%2F%2Fapi.reclaimprotocol.org%2Fapi%2Fsdk%2Fcallback%3FcallbackId%3Da3b1ed8d2b%22%2C%22context%22%3A%22%7B%5C%22contextAddress%5C%22%3A%5C%220x0%5C%22%2C%5C%22contextMessage%5C%22%3A%5C%22sample%20context%5C%22%2C%5C%22reclaimSessionId%5C%22%3A%5C%22a3b1ed8d2b%5C%22%7D%22%2C%22providerVersion%22%3A%22%22%2C%22resolvedProviderVersion%22%3A%223.0.0%22%2C%22parameters%22%3A%7B%7D%2C%22redirectUrl%22%3A%22https%3A%2F%2Fgoogle.com%2Fsearch%3Fq%3Dsuccess%22%2C%22redirectUrlOptions%22%3A%7B%22method%22%3A%22POST%22%2C%22body%22%3A%5B%7B%22name%22%3A%22string%22%2C%22value%22%3A%22string%22%7D%5D%7D%2C%22cancelCallbackUrl%22%3A%22https%3A%2F%2Fapi.reclaimprotocol.org%2Fapi%2Fsdk%2Ferror-callback%3FcallbackId%3Da3b1ed8d2b%22%2C%22cancelRedirectUrl%22%3A%22https%3A%2F%2Fgoogle.com%2Fsearch%3Fq%3Dfailure%22%2C%22cancelRedirectUrlOptions%22%3A%7B%22method%22%3A%22POST%22%2C%22body%22%3A%5B%7B%22name%22%3A%22string%22%2C%22value%22%3A%22string%22%7D%5D%7D%2C%22acceptAiProviders%22%3Afalse%2C%22sdkVersion%22%3A%22js-5.0.0-dev.3%22%2C%22jsonProofResponse%22%3Afalse%2C%22log%22%3Afalse%2C%22canAutoSubmit%22%3Atrue%7D',
        ),
        isA<ClientSdkVerificationRequest>(),
      );
    });

    test('can be parsed from url with redirects', () async {
      const expectedLocation =
          'https://share.example.org/verifier/?template=%7B%22sessionId%22%3A%22c740929dd5%22%2C%22providerId%22%3A%22example%22%2C%22applicationId%22%3A%220x486dD3B9C8DF7c9b263C75713c79EC1cf8F592F2%22%2C%22signature%22%3A%220x39d9a560859265affd58ef25bba444228ac1ab90a32fd7d0374fa8c20e55fd444da7d0b54d5b90de023d325dc07e0ebe9dcb1b97ea903f2cf48bc93e45651efb1c%22%2C%22timestamp%22%3A%221755040406984%22%2C%22callbackUrl%22%3A%22https%3A%2F%2Fapi.reclaimprotocol.org%2Fapi%2Fsdk%2Fcallback%3FcallbackId%3Dc740929dd5%22%2C%22context%22%3A%22%7B%5C%22contextAddress%5C%22%3A%5C%220x0%5C%22%2C%5C%22contextMessage%5C%22%3A%5C%22sample%20context%5C%22%7D%22%2C%22parameters%22%3A%7B%7D%2C%22redirectUrl%22%3A%22%22%2C%22acceptAiProviders%22%3Afalse%2C%22sdkVersion%22%3A%22js-2.3.3%22%2C%22jsonProofResponse%22%3Afalse%7D';

      expect(
        await ClientSdkVerificationRequest.fromUrl(
          'https://api.example.org/api/sdk/verification-url/8180b0ce-0dd3-4325-84f5-eff0be1f4b53',
          client: http_testing.MockClient((request) {
            return Future.value(http.Response('', 301, headers: <String, String>{'location': expectedLocation}));
          }),
        ),
        isA<ClientSdkVerificationRequest>(),
        reason: 'Should follow link',
      );

      expect(
        () => ClientSdkVerificationRequest.fromUrl(
          'https://api.example.org/api/sdk/verification-url/8180b0ce-0dd3-4325-84f5-eff0be1f4b53',
          client: http_testing.MockClient((request) {
            return Future.value(http.Response('', 200, headers: <String, String>{}));
          }),
        ),
        throwsA(isA<FormatException>()),
        reason: 'Should not follow link',
      );
    });
  });
}
