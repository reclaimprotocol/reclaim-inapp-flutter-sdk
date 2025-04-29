// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_flutter_sdk/overrides/override.dart';
import 'package:reclaim_flutter_sdk/services/capability/access_token.dart';
import 'package:reclaim_flutter_sdk/services/capability/capability.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CapabilityAccessVerifier', () {
    const capabilityAccessVerifier = CapabilityAccessVerifier();
    const channel = MethodChannel('dev.fluttercommunity.plus/package_info');

    setUp(() {
      final now = DateTime.now().copyWith(microsecond: 0);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
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
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    });

    test('isAuthorizedParty', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(
        await capabilityAccessVerifier.isAuthorizedParty(
          Uri.parse('android://org.reclaimprotocol.example'),
        ),
        isTrue,
      );
      expect(
        await capabilityAccessVerifier.isAuthorizedParty(
          Uri.parse('android://org.reclaimprotocol.example.other'),
        ),
        isFalse,
      );

      expect(
        await capabilityAccessVerifier.isAuthorizedParty(
          Uri.parse('ios://org.reclaimprotocol.example'),
        ),
        isFalse,
      );

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(
        await capabilityAccessVerifier.isAuthorizedParty(
          Uri.parse('ios://org.reclaimprotocol.example'),
        ),
        isTrue,
      );

      expect(
        await capabilityAccessVerifier.isAuthorizedParty(
          Uri.parse('ios://org.reclaimprotocol.example.other'),
        ),
        isFalse,
      );
    });

    test('canUse', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(await capabilityAccessVerifier.canUse('hello'), isFalse);
      expect(await capabilityAccessVerifier.canUse('foo'), isFalse);

      // token with correct azp
      ReclaimOverride.set(
        CapabilityAccessToken.import(
          'eyJhbGciOiJFUzI1NiIsImtpZCI6IjY1MzBjNWUwLWE2NWItNGRjMS05YTg5LTQzMjNmYzhjNmEyMSIsInR5cCI6IkpXVCJ9.eyJqdGkiOiJmNTQyYjVmYS05NDdjLTQwOTYtODkzMi1hMTdjMjlmNGY0YTIiLCJpc3MiOiJodHRwczovL2Rldi5yZWNsYWltcHJvdG9jb2wub3JnIiwiYXVkIjoib3JnLnJlY2xhaW1wcm90b2NvbC5pbmFwcF9zZGsiLCJpYXQiOjE3NDA2NjEzMDQsIm5iZiI6MTc0MDY2MTMwNCwiZXhwIjoxNzc1MjIxMzA0LCJzdWIiOiJleGFtcGxlLmNvbSIsInNjb3BlIjoiaGVsbG8gd29ybGQiLCJhenAiOiJhbmRyb2lkOi8vb3JnLnJlY2xhaW1wcm90b2NvbC5leGFtcGxlIGlvczovL29yZy5yZWNsYWltcHJvdG9jb2wuZXhhbXBsZSJ9.GkbkWtDp2KeKIMosmqu_7u9MF9JBlAC-stdCi7_aIr7iAeRFnKR1Gcsalj2XoOMZxpaZ--SGKUtlUcA0bSFC0A',
          'eyJraWQiOiI2NTMwYzVlMC1hNjViLTRkYzEtOWE4OS00MzIzZmM4YzZhMjEiLCJrZXlfb3BzIjpbInZlcmlmeSJdLCJleHQiOnRydWUsImt0eSI6IkVDIiwieCI6Im5pb0RsVjF4YWt4WFlZYnM0cEtFc2ZFN3FXQTk0SVRWdDdrM2VDZDU3S3MiLCJ5IjoiTzlOaTAxMzBzUE5FVUJ3VkY5d0FpaENJUDA0S08xQXZDRmF6Y3dweFJKQSIsImNydiI6IlAtMjU2In0',
        ),
      );
      expect(await capabilityAccessVerifier.canUse('hello'), isTrue);
      expect(await capabilityAccessVerifier.canUse('foo'), isFalse);

      // token without azp
      ReclaimOverride.set(
        CapabilityAccessToken.import(
          'eyJhbGciOiJFUzI1NiIsImtpZCI6IjY1MzBjNWUwLWE2NWItNGRjMS05YTg5LTQzMjNmYzhjNmEyMSIsInR5cCI6IkpXVCJ9.eyJqdGkiOiJmYjg3NWFlNi1iZTI0LTRiZWEtOGMxZS01NzZiY2JlMTE3NWYiLCJpc3MiOiJodHRwczovL2Rldi5yZWNsYWltcHJvdG9jb2wub3JnIiwiYXVkIjoib3JnLnJlY2xhaW1wcm90b2NvbC5pbmFwcF9zZGsiLCJpYXQiOjE3NDA2NjEzODYsIm5iZiI6MTc0MDY2MTM4NiwiZXhwIjoxNzc1MjIxMzg2LCJzdWIiOiJleGFtcGxlLmNvbSIsInNjb3BlIjoiaGVsbG8gd29ybGQifQ.-04sO_2_RLHsZvK7Ebuu94TUJNdXbMuttfQcw89Il4o9tLlsA7DenppUhwOVQio3h39EqOVuCNkxbF-kxYWnDg',
          'eyJraWQiOiI2NTMwYzVlMC1hNjViLTRkYzEtOWE4OS00MzIzZmM4YzZhMjEiLCJrZXlfb3BzIjpbInZlcmlmeSJdLCJleHQiOnRydWUsImt0eSI6IkVDIiwieCI6Im5pb0RsVjF4YWt4WFlZYnM0cEtFc2ZFN3FXQTk0SVRWdDdrM2VDZDU3S3MiLCJ5IjoiTzlOaTAxMzBzUE5FVUJ3VkY5d0FpaENJUDA0S08xQXZDRmF6Y3dweFJKQSIsImNydiI6IlAtMjU2In0',
        ),
      );

      expect(await capabilityAccessVerifier.canUse('hello'), isFalse);
      expect(await capabilityAccessVerifier.canUse('foo'), isFalse);
    });
  });
}
