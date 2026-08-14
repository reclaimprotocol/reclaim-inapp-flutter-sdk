import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_inapp_sdk/overrides.dart';
import 'package:reclaim_inapp_sdk/src/services/capability/access_token.dart';
import 'package:reclaim_inapp_sdk/src/utils/crypto/jws.dart';
import 'package:reclaim_inapp_sdk/src/utils/crypto/url_safe_codec.dart';

const _privateKeyString =
    'eyJraWQiOiI2NTMwYzVlMC1hNjViLTRkYzEtOWE4OS00MzIzZmM4YzZhMjEiLCJrZXlfb3BzIjpbInNpZ24iXSwiZXh0Ijp0cnVlLCJrdHkiOiJFQyIsIngiOiJuaW9EbFYxeGFreFhZWWJzNHBLRXNmRTdxV0E5NElUVnQ3azNlQ2Q1N0tzIiwieSI6Ik85TmkwMTMwc1BORVVCd1ZGOXdBaWhDSVAwNEtPMUF2Q0ZhemN3cHhSSkEiLCJjcnYiOiJQLTI1NiIsImQiOiJXamRWdmFPcmE0VU1zNG9LdGpZeFRhNDFZUV9Jb1JxQWlXZkx3V1ZFMlljIn0';
const _publicKeyString =
    'eyJraWQiOiI2NTMwYzVlMC1hNjViLTRkYzEtOWE4OS00MzIzZmM4YzZhMjEiLCJrZXlfb3BzIjpbInZlcmlmeSJdLCJleHQiOnRydWUsImt0eSI6IkVDIiwieCI6Im5pb0RsVjF4YWt4WFlZYnM0cEtFc2ZFN3FXQTk0SVRWdDdrM2VDZDU3S3MiLCJ5IjoiTzlOaTAxMzBzUE5FVUJ3VkY5d0FpaENJUDA0S08xQXZDRmF6Y3dweFJKQSIsImNydiI6IlAtMjU2In0';

void main() {
  group('CapabilityAccessToken', () {
    test('should be able to create a token', () {
      final scope = {'capability1', 'capability2'};
      final azp = {'android://org.reclaimprotocol.example', 'ios://org.reclaimprotocol.example'};
      final token = CapabilityAccessToken.create(
        _privateKeyString,
        scope,
        azp,
        sub: 'testsub',
        expiresAfter: const Duration(days: 400),
      );
      expect(token.capabilities, containsAll({'capability1', 'capability2'}));
      expect(
        token.authorizedParties.map((e) => e.toString()),
        containsAll({'android://org.reclaimprotocol.example', 'ios://org.reclaimprotocol.example'}),
      );
    });

    test('should be able to verify a token with azp', () {
      final signed = CapabilityAccessToken.create(
        _privateKeyString,
        {'hello', 'world'},
        {'android://org.reclaimprotocol.example', 'ios://org.reclaimprotocol.example'},
        sub: 'example.com',
      );
      ReclaimEnv.CAPABILITY_ACCESS_TOKEN_VERIFICATION_KEY = _publicKeyString;
      final jws = CapabilityAccessToken.import(signed.accessToken.toString());
      expect(jws.capabilities, containsAll({'hello', 'world'}));
      expect(
        jws.authorizedParties.map((e) => e.toString()),
        containsAll({'android://org.reclaimprotocol.example', 'ios://org.reclaimprotocol.example'}),
      );
    });

    test('should be able to verify a token without azp', () {
      final signed = CapabilityAccessToken.create(_privateKeyString, {'hello', 'world'}, const {}, sub: 'example.com');
      ReclaimEnv.CAPABILITY_ACCESS_TOKEN_VERIFICATION_KEY = _publicKeyString;
      final jws = CapabilityAccessToken.import(signed.accessToken.toString());
      expect(jws.capabilities, containsAll({'hello', 'world'}));
      expect(jws.authorizedParties, isEmpty);
    });

    test('should reject an expired token and accept a valid one', () {
      ReclaimEnv.CAPABILITY_ACCESS_TOKEN_VERIFICATION_KEY = _publicKeyString;

      // CapabilityAccessToken.create refuses to mint an already-expired token
      // (the constructor validates exp), so sign the JWS directly with a past
      // exp. This avoids any real-clock race in the test.
      final expiredTokenString = _signTokenWith(
        _privateKeyString,
        iat: DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
        exp: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      );
      final validToken = CapabilityAccessToken.create(
        _privateKeyString,
        {'test_scope'},
        {'android://org.reclaimprotocol.example'},
        sub: 'testsub',
        expiresAfter: const Duration(minutes: 5),
      );

      expect(
        () => CapabilityAccessToken.import(expiredTokenString),
        throwsA(isA<ExpiredCapabilityAccessTokenException>()),
      );
      expect(() => CapabilityAccessToken.import(validToken.accessToken.toString()), returnsNormally);
    });
  });
}

String _signTokenWith(String privateKeyJwk, {required DateTime iat, required DateTime exp}) {
  final iatSec = iat.toUtc().millisecondsSinceEpoch ~/ 1000;
  final expSec = exp.toUtc().millisecondsSinceEpoch ~/ 1000;
  final payload = utf8.encode(
    json.encode({
      'jti': 'test',
      'iss': 'https://dev.reclaimprotocol.org',
      'aud': 'org.reclaimprotocol.inapp_sdk',
      'iat': iatSec,
      'nbf': iatSec,
      'exp': expSec,
      'sub': 'testsub',
      'scope': 'test_scope',
      'azp': 'android://org.reclaimprotocol.example',
    }),
  );
  final privateKey = json.decode(utf8.decode(urlSafeDecode(privateKeyJwk))) as Map<String, dynamic>;
  return ES256Jws.create(payload, privateKey).toString();
}
