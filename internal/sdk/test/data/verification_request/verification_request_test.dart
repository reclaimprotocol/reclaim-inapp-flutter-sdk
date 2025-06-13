import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_inapp_sdk/src/data/verification/request.dart';

void main() {
  group('ClientSdkVerificationRequest', () {
    test('can be parsed from url', () {
      expect(
        ClientSdkVerificationRequest.fromUrl(
          // the deeplink url that's incorrectly adding params as a path
          'reclaimverifier://requestedproofs/template=%7B%22sessionId%22%3A%22a8302956b5%22%2C%22providerId%22%3A%226d3f6753-7ee6-49ee-a545-62f1b1822ae5%22%2C%22applicationId%22%3A%220x486dD3B9C8DF7c9b263C75713c79EC1cf8F592F2%22%2C%22signature%22%3A%220x1e905989b8eb5fa8cb994ddd2532a46285ca0938ee517d6bea2bd4a61c09bdbc4d3e5a553365da213f6f82d67c1bf87939dac05c7269a390a5903c1e87b372181c%22%2C%22timestamp%22%3A%221745363629091%22%2C%22callbackUrl%22%3A%22https%3A%2F%2Fapi.reclaimprotocol.org%2Fapi%2Fsdk%2Fcallback%3FcallbackId%3Da8302956b5%22%2C%22context%22%3A%22%7B%5C%22contextAddress%5C%22%3A%5C%220x0%5C%22%2C%5C%22contextMessage%5C%22%3A%5C%22sample%20context%5C%22%7D%22%2C%22parameters%22%3A%7B%7D%2C%22redirectUrl%22%3A%22https%3A%2F%2Fdemo.reclaimprotocol.org%2Fsession%2Fa8302956b5%22%2C%22acceptAiProviders%22%3Atrue%2C%22sdkVersion%22%3A%22js-2.3.3%22%2C%22jsonProofResponse%22%3Afalse%7D',
        ),
        isA<ClientSdkVerificationRequest>(),
      );
      expect(
        ClientSdkVerificationRequest.fromUrl(
          'reclaimverifier://requestedproofs/?template=%7B%22sessionId%22%3A%22a8302956b5%22%2C%22providerId%22%3A%226d3f6753-7ee6-49ee-a545-62f1b1822ae5%22%2C%22applicationId%22%3A%220x486dD3B9C8DF7c9b263C75713c79EC1cf8F592F2%22%2C%22signature%22%3A%220x1e905989b8eb5fa8cb994ddd2532a46285ca0938ee517d6bea2bd4a61c09bdbc4d3e5a553365da213f6f82d67c1bf87939dac05c7269a390a5903c1e87b372181c%22%2C%22timestamp%22%3A%221745363629091%22%2C%22callbackUrl%22%3A%22https%3A%2F%2Fapi.reclaimprotocol.org%2Fapi%2Fsdk%2Fcallback%3FcallbackId%3Da8302956b5%22%2C%22context%22%3A%22%7B%5C%22contextAddress%5C%22%3A%5C%220x0%5C%22%2C%5C%22contextMessage%5C%22%3A%5C%22sample%20context%5C%22%7D%22%2C%22parameters%22%3A%7B%7D%2C%22redirectUrl%22%3A%22https%3A%2F%2Fdemo.reclaimprotocol.org%2Fsession%2Fa8302956b5%22%2C%22acceptAiProviders%22%3Atrue%2C%22sdkVersion%22%3A%22js-2.3.3%22%2C%22jsonProofResponse%22%3Afalse%7D',
        ),
        isA<ClientSdkVerificationRequest>(),
      );
      expect(
        ClientSdkVerificationRequest.fromUrl(
          'https://share.reclaimprotocol.org/verify/?template=%7B%22sessionId%22%3A%22a8302956b5%22%2C%22providerId%22%3A%226d3f6753-7ee6-49ee-a545-62f1b1822ae5%22%2C%22applicationId%22%3A%220x486dD3B9C8DF7c9b263C75713c79EC1cf8F592F2%22%2C%22signature%22%3A%220x1e905989b8eb5fa8cb994ddd2532a46285ca0938ee517d6bea2bd4a61c09bdbc4d3e5a553365da213f6f82d67c1bf87939dac05c7269a390a5903c1e87b372181c%22%2C%22timestamp%22%3A%221745363629091%22%2C%22callbackUrl%22%3A%22https%3A%2F%2Fapi.reclaimprotocol.org%2Fapi%2Fsdk%2Fcallback%3FcallbackId%3Da8302956b5%22%2C%22context%22%3A%22%7B%5C%22contextAddress%5C%22%3A%5C%220x0%5C%22%2C%5C%22contextMessage%5C%22%3A%5C%22sample%20context%5C%22%7D%22%2C%22parameters%22%3A%7B%7D%2C%22redirectUrl%22%3A%22https%3A%2F%2Fdemo.reclaimprotocol.org%2Fsession%2Fa8302956b5%22%2C%22acceptAiProviders%22%3Atrue%2C%22sdkVersion%22%3A%22js-2.3.3%22%2C%22jsonProofResponse%22%3Afalse%7D',
        ),
        isA<ClientSdkVerificationRequest>(),
      );
      expect(
        ClientSdkVerificationRequest.fromUrl(
          'https://appclip.apple.com/id?p=org.reclaimprotocol.app.clip&template=%7B%22sessionId%22%3A%22a8302956b5%22%2C%22providerId%22%3A%226d3f6753-7ee6-49ee-a545-62f1b1822ae5%22%2C%22applicationId%22%3A%220x486dD3B9C8DF7c9b263C75713c79EC1cf8F592F2%22%2C%22signature%22%3A%220x1e905989b8eb5fa8cb994ddd2532a46285ca0938ee517d6bea2bd4a61c09bdbc4d3e5a553365da213f6f82d67c1bf87939dac05c7269a390a5903c1e87b372181c%22%2C%22timestamp%22%3A%221745363629091%22%2C%22callbackUrl%22%3A%22https%3A%2F%2Fapi.reclaimprotocol.org%2Fapi%2Fsdk%2Fcallback%3FcallbackId%3Da8302956b5%22%2C%22context%22%3A%22%7B%5C%22contextAddress%5C%22%3A%5C%220x0%5C%22%2C%5C%22contextMessage%5C%22%3A%5C%22sample%20context%5C%22%7D%22%2C%22parameters%22%3A%7B%7D%2C%22redirectUrl%22%3A%22https%3A%2F%2Fdemo.reclaimprotocol.org%2Fsession%2Fa8302956b5%22%2C%22acceptAiProviders%22%3Atrue%2C%22sdkVersion%22%3A%22js-2.3.3%22%2C%22jsonProofResponse%22%3Afalse%7D',
        ),
        isA<ClientSdkVerificationRequest>(),
      );
      expect(
        ClientSdkVerificationRequest.fromUrl(
          'x-safari-https://share.reclaimprotocol.org/verify/?template=%7B%22sessionId%22%3A%22a8302956b5%22%2C%22providerId%22%3A%226d3f6753-7ee6-49ee-a545-62f1b1822ae5%22%2C%22applicationId%22%3A%220x486dD3B9C8DF7c9b263C75713c79EC1cf8F592F2%22%2C%22signature%22%3A%220x1e905989b8eb5fa8cb994ddd2532a46285ca0938ee517d6bea2bd4a61c09bdbc4d3e5a553365da213f6f82d67c1bf87939dac05c7269a390a5903c1e87b372181c%22%2C%22timestamp%22%3A%221745363629091%22%2C%22callbackUrl%22%3A%22https%3A%2F%2Fapi.reclaimprotocol.org%2Fapi%2Fsdk%2Fcallback%3FcallbackId%3Da8302956b5%22%2C%22context%22%3A%22%7B%5C%22contextAddress%5C%22%3A%5C%220x0%5C%22%2C%5C%22contextMessage%5C%22%3A%5C%22sample%20context%5C%22%7D%22%2C%22parameters%22%3A%7B%7D%2C%22redirectUrl%22%3A%22https%3A%2F%2Fdemo.reclaimprotocol.org%2Fsession%2Fa8302956b5%22%2C%22acceptAiProviders%22%3Atrue%2C%22sdkVersion%22%3A%22js-2.3.3%22%2C%22jsonProofResponse%22%3Afalse%7D',
        ),
        isA<ClientSdkVerificationRequest>(),
      );
      expect(
        ClientSdkVerificationRequest.fromUrl(
          'x-safari-https://share.reclaimprotocol.org/verifier/?template=%7B%22sessionId%22%3A%22a8302956b5%22%2C%22providerId%22%3A%226d3f6753-7ee6-49ee-a545-62f1b1822ae5%22%2C%22applicationId%22%3A%220x486dD3B9C8DF7c9b263C75713c79EC1cf8F592F2%22%2C%22signature%22%3A%220x1e905989b8eb5fa8cb994ddd2532a46285ca0938ee517d6bea2bd4a61c09bdbc4d3e5a553365da213f6f82d67c1bf87939dac05c7269a390a5903c1e87b372181c%22%2C%22timestamp%22%3A%221745363629091%22%2C%22callbackUrl%22%3A%22https%3A%2F%2Fapi.reclaimprotocol.org%2Fapi%2Fsdk%2Fcallback%3FcallbackId%3Da8302956b5%22%2C%22context%22%3A%22%7B%5C%22contextAddress%5C%22%3A%5C%220x0%5C%22%2C%5C%22contextMessage%5C%22%3A%5C%22sample%20context%5C%22%7D%22%2C%22parameters%22%3A%7B%7D%2C%22redirectUrl%22%3A%22https%3A%2F%2Fdemo.reclaimprotocol.org%2Fsession%2Fa8302956b5%22%2C%22acceptAiProviders%22%3Atrue%2C%22sdkVersion%22%3A%22js-2.3.3%22%2C%22jsonProofResponse%22%3Afalse%7D',
        ),
        isA<ClientSdkVerificationRequest>(),
      );
      expect(
        ClientSdkVerificationRequest.fromUrl(
          'https://share.reclaimprotocol.org/verify/?template=%7B%22sessionId%22%3A%22b8f607537b%22%2C%22providerId%22%3A%2262019efe-a839-4aca-a56e-e92263a54131%22%2C%22applicationId%22%3A%220x18e14659BAF54208F8EE04BEbA8A8d3Fb487eF06%22%2C%22signature%22%3A%220xf8eebf5489130449a2f07870da9cdca9680b13c1a5c3bcfa2137f428ab77930307edf6cd12ea621b21772c360b9113a898aafe379d7afa93fdfdbb30e5dbc97d1c%22%2C%22timestamp%22%3A%221748418591230%22%2C%22callbackUrl%22%3A%22https%3A%2F%2Fapi.staging.reclaimprotocol.org%2Fapi%2Fsdk%2Fcallback%3FcallbackId%3Db8f607537b%22%2C%22context%22%3A%22%7B%5C%22contextAddress%5C%22%3A%5C%220x00000000000%5C%22%2C%5C%22contextMessage%5C%22%3A%5C%22Example%20context%20message%5C%22%7D%22%2C%22parameters%22%3A%7B%7D%2C%22providerVersion%22%3A%22%22%2C%22allowAiVersions%22%3Afalse%2C%22redirectUrl%22%3A%22%22%2C%22acceptAiProviders%22%3Afalse%2C%22sdkVersion%22%3A%22js-3.0.3%22%2C%22jsonProofResponse%22%3Afalse%7D',
        ),
        isA<ClientSdkVerificationRequest>(),
      );
    });
  });
}
