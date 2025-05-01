import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';
import 'package:reclaim_flutter_sdk/src/utils/bytes.dart';
import 'package:reclaim_flutter_sdk/utils/crypto/jwk_codec.dart';
// ignore: implementation_imports
import 'package:pointycastle/src/utils.dart' as p_utils;
import 'package:uuid/uuid.dart';

/// Utility to use dart:math's Random class to generate numbers used by
/// pointycastle.
class _DartSecureRandom implements SecureRandom {
  const _DartSecureRandom();

  Random get dartRandom => Random.secure();

  @override
  String get algorithmName => 'DartRandom';

  static BigInt bytesToUnsignedInt(Uint8List bytes) {
    return p_utils.decodeBigIntWithSign(1, bytes);
  }

  @override
  BigInt nextBigInteger(int bitLength) {
    final fullBytes = bitLength ~/ 8;
    final remainingBits = bitLength % 8;

    // Generate a number from the full bytes. Then, prepend a smaller number
    // covering the remaining bits.
    final main = bytesToUnsignedInt(nextBytes(fullBytes));
    final additional = dartRandom.nextInt(1 << remainingBits);
    return main + (BigInt.from(additional) << (fullBytes * 8));
  }

  @override
  Uint8List nextBytes(int count) {
    final list = Uint8List(count);

    for (var i = 0; i < list.length; i++) {
      list[i] = nextUint8();
    }

    return list;
  }

  @override
  int nextUint16() => dartRandom.nextInt(1 << 16);

  @override
  int nextUint32() {
    // this is 2^32. We can't write 1 << 32 because that evaluates to 0 on js
    return dartRandom.nextInt(4294967296);
  }

  @override
  int nextUint8() => dartRandom.nextInt(1 << 8);

  @override
  void seed(CipherParameters params) {
    // ignore, dartRandom will already be seeded if wanted
  }
}

// NIST P-256
class NistP256CurveInfo {
  final domainParameters = ECCurve_secp256r1();

  final String curveName = 'P-256';

  Map<String, dynamic> exportPrivateKey(
    String kid,
    ECPrivateKey privateKey,
    ECPublicKey publicKey,
  ) {
    final x = publicKey.Q?.x?.toBigInteger();
    final y = publicKey.Q?.y?.toBigInteger();

    return {
      'kid': kid,
      'key_ops': ['sign'],
      'ext': true,
      'kty': 'EC',
      'x': x != null ? jwkValueCodec.encode(x) : null,
      'y': y != null ? jwkValueCodec.encode(y) : null,
      'crv': curveName,
      'd': privateKey.d != null ? jwkValueCodec.encode(privateKey.d!) : null,
    };
  }

  Map<String, dynamic> exportPublicKey(String kid, ECPublicKey publicKey) {
    final x = publicKey.Q?.x?.toBigInteger();
    final y = publicKey.Q?.y?.toBigInteger();

    return {
      'kid': kid,
      'key_ops': ['verify'],
      'ext': true,
      'kty': 'EC',
      'x': x != null ? jwkValueCodec.encode(x) : null,
      'y': y != null ? jwkValueCodec.encode(y) : null,
      'crv': curveName,
    };
  }

  ECPrivateKey importPrivateKeyFromJwk(Map<String, dynamic> jwk) {
    final d = jwkValueCodec.decode(jwk['d']);
    return ECPrivateKey(d, domainParameters);
  }

  ECPublicKey importPublicKeyFromJwk(Map<String, dynamic> jwk) {
    final x = jwkValueCodec.decode(jwk['x']);
    final y = jwkValueCodec.decode(jwk['y']);
    final point = domainParameters.curve.createPoint(x, y);
    return ECPublicKey(point, domainParameters);
  }
}

/// A JS window.crypto.subtle compatible ECDSA signature implementation.
///
/// ```
/// {
///     name: 'ECDSA',
///     namedCurve: 'P-256',
///     hash: 'SHA-256',
/// }
/// ```
class NistP256ECDSASigner {
  const NistP256ECDSASigner({required this.kid, required this.keyPair, required this.curveInfo});

  final String kid;
  final NistP256CurveInfo curveInfo;
  final AsymmetricKeyPair<ECPublicKey, ECPrivateKey> keyPair;

  factory NistP256ECDSASigner.generate() {
    final curveInfo = NistP256CurveInfo();

    final keyGen = ECKeyGenerator();
    keyGen.init(
      ParametersWithRandom(
        ECKeyGeneratorParameters(
          // NIST P-256
          curveInfo.domainParameters,
        ),
        _DartSecureRandom(),
      ),
    );
    final keyPair = keyGen.generateKeyPair();
    final kid = Uuid().v4().toString();
    return NistP256ECDSASigner(
      kid: kid,
      keyPair: AsymmetricKeyPair(
        keyPair.publicKey as ECPublicKey,
        keyPair.privateKey as ECPrivateKey,
      ),
      curveInfo: curveInfo,
    );
  }

  factory NistP256ECDSASigner.fromJwk(Map<String, dynamic> jwk) {
    final curveInfo = NistP256CurveInfo();
    return NistP256ECDSASigner(
      kid: jwk['kid'] ?? '',
      keyPair: AsymmetricKeyPair(
        curveInfo.importPublicKeyFromJwk(jwk),
        curveInfo.importPrivateKeyFromJwk(jwk),
      ),
      curveInfo: curveInfo,
    );
  }

  Map<String, dynamic> exportPrivateKey() {
    return curveInfo.exportPrivateKey(kid, keyPair.privateKey, keyPair.publicKey);
  }

  Map<String, dynamic> exportPublicKey() {
    return curveInfo.exportPublicKey(kid, keyPair.publicKey);
  }

  Uint8List sign(Uint8List message) {
    final messageHash = Uint8List.fromList(sha256.convert(message).bytes);
    final signer = ECDSASigner();
    signer.init(
      true,
      ParametersWithRandom(PrivateKeyParameter(keyPair.privateKey), _DartSecureRandom()),
    );
    final signature = signer.generateSignature(messageHash) as ECSignature;
    signature.normalize(curveInfo.domainParameters);
    final signatureBytes = Uint8List(64);
    setValuesInRange(signatureBytes, 0, 32, jwkValueEncoder.toBigEndianUint8List(signature.r));
    setValuesInRange(signatureBytes, 32, 64, jwkValueEncoder.toBigEndianUint8List(signature.s));
    return signatureBytes;
  }
}

/// A JS window.crypto.subtle compatible ECDSA signature verification implementation.
///
/// ```
/// {
///     name: 'ECDSA',
///     namedCurve: 'P-256',
///     hash: 'SHA-256',
/// }
/// ```
class NistP256ECDSAVerifier {
  final String kid;

  const NistP256ECDSAVerifier({
    required this.kid,
    required this.publicKey,
    required this.curveInfo,
  });

  final NistP256CurveInfo curveInfo;
  final ECPublicKey publicKey;

  factory NistP256ECDSAVerifier.fromJwk(Map<String, dynamic> jwk) {
    final curveInfo = NistP256CurveInfo();
    return NistP256ECDSAVerifier(
      kid: jwk['kid'] ?? '',
      publicKey: curveInfo.importPublicKeyFromJwk(jwk),
      curveInfo: curveInfo,
    );
  }

  bool verify(Uint8List message, Uint8List signature) {
    final messageHash = Uint8List.fromList(sha256.convert(message).bytes);
    final verifier = ECDSASigner();
    verifier.init(false, PublicKeyParameter(publicKey));
    final ecSignature = ECSignature(
      jwkValueDecoder.toBigIntFromBigEndianBytes(signature.sublist(0, 32)),
      jwkValueDecoder.toBigIntFromBigEndianBytes(signature.sublist(32, 64)),
    );
    return verifier.verifySignature(messageHash, ecSignature);
  }

  Map<String, dynamic> exportPublicKey() {
    return curveInfo.exportPublicKey(kid, publicKey);
  }
}
