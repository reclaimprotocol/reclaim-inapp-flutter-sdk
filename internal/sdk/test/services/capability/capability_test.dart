// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_inapp_sdk/overrides.dart';
import 'package:reclaim_inapp_sdk/src/services/capability/access_token.dart';
import 'package:reclaim_inapp_sdk/src/services/capability/capability.dart';

const _privateKeyString =
    'eyJraWQiOiI2NTMwYzVlMC1hNjViLTRkYzEtOWE4OS00MzIzZmM4YzZhMjEiLCJrZXlfb3BzIjpbInNpZ24iXSwiZXh0Ijp0cnVlLCJrdHkiOiJFQyIsIngiOiJuaW9EbFYxeGFreFhZWWJzNHBLRXNmRTdxV0E5NElUVnQ3azNlQ2Q1N0tzIiwieSI6Ik85TmkwMTMwc1BORVVCd1ZGOXdBaWhDSVAwNEtPMUF2Q0ZhemN3cHhSSkEiLCJjcnYiOiJQLTI1NiIsImQiOiJXamRWdmFPcmE0VU1zNG9LdGpZeFRhNDFZUV9Jb1JxQWlXZkx3V1ZFMlljIn0';
const _publicKeyString =
    'eyJraWQiOiI2NTMwYzVlMC1hNjViLTRkYzEtOWE4OS00MzIzZmM4YzZhMjEiLCJrZXlfb3BzIjpbInZlcmlmeSJdLCJleHQiOnRydWUsImt0eSI6IkVDIiwieCI6Im5pb0RsVjF4YWt4WFlZYnM0cEtFc2ZFN3FXQTk0SVRWdDdrM2VDZDU3S3MiLCJ5IjoiTzlOaTAxMzBzUE5FVUJ3VkY5d0FpaENJUDA0S08xQXZDRmF6Y3dweFJKQSIsImNydiI6IlAtMjU2In0';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CapabilityAccessVerifier', () {
    const capabilityAccessVerifier = CapabilityAccessVerifier();
    const channel = MethodChannel('dev.fluttercommunity.plus/package_info');

    setUp(() {
      final now = DateTime.now().copyWith(microsecond: 0);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        MethodCall methodCall,
      ) async {
        switch (methodCall.method) {
          case 'getAll':
            return <String, dynamic>{
              'appName': 'package_info_example',
              'buildNumber': '1',
              'packageName': 'org.reclaimprotocol.example',
              'version': '1.0',
              'installerStore': null,
              'installTime': now.millisecondsSinceEpoch.toString(),
            };
          default:
            assert(false);
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    });

    test('isAuthorizedParty', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(
        await capabilityAccessVerifier.isAuthorizedParty(Uri.parse('android://org.reclaimprotocol.example')),
        isTrue,
      );
      expect(
        await capabilityAccessVerifier.isAuthorizedParty(Uri.parse('android://org.reclaimprotocol.example.other')),
        isFalse,
      );

      expect(await capabilityAccessVerifier.isAuthorizedParty(Uri.parse('ios://org.reclaimprotocol.example')), isFalse);

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(await capabilityAccessVerifier.isAuthorizedParty(Uri.parse('ios://org.reclaimprotocol.example')), isTrue);

      expect(
        await capabilityAccessVerifier.isAuthorizedParty(Uri.parse('ios://org.reclaimprotocol.example.other')),
        isFalse,
      );
    });

    test('canUse', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(await capabilityAccessVerifier.canUse('hello'), isFalse);
      expect(await capabilityAccessVerifier.canUse('foo'), isFalse);

      // token with correct azp
      ReclaimEnv.CAPABILITY_ACCESS_TOKEN_VERIFICATION_KEY = _publicKeyString;
      final tokenWithAzp = CapabilityAccessToken.create(
        _privateKeyString,
        {'hello', 'world'},
        {'android://org.reclaimprotocol.example', 'ios://org.reclaimprotocol.example'},
        sub: 'example.com',
      );
      ReclaimOverride.set(CapabilityAccessToken.import(tokenWithAzp.accessToken.toString()));
      expect(await capabilityAccessVerifier.canUse('hello'), isTrue);
      expect(await capabilityAccessVerifier.canUse('foo'), isFalse);

      // token without azp
      ReclaimEnv.CAPABILITY_ACCESS_TOKEN_VERIFICATION_KEY = _publicKeyString;
      final tokenWithoutAzp = CapabilityAccessToken.create(
        _privateKeyString,
        {'hello', 'world'},
        const {},
        sub: 'example.com',
      );
      ReclaimOverride.set(CapabilityAccessToken.import(tokenWithoutAzp.accessToken.toString()));

      expect(await capabilityAccessVerifier.canUse('hello'), isFalse);
      expect(await capabilityAccessVerifier.canUse('foo'), isFalse);
    });
  });
}
