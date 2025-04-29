import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:reclaim_flutter_sdk/utils/crypto/signature.dart';
import 'package:reclaim_flutter_sdk/utils/crypto/url_safe_codec.dart';

class JwsHeader {
  final String typ;
  final String alg;
  final String kid;

  const JwsHeader({required this.typ, required this.alg, required this.kid});

  static JwsHeader fromJson(Map<String, dynamic> json) {
    return JwsHeader(typ: json['typ'], alg: json['alg'], kid: json['kid'] ?? '');
  }

  SplayTreeMap<String, dynamic> toJson() {
    // Order matters. Make sure the keys are alphabetically sorted. A canoncalized json string is required because this will be used in the jws.
    // Use of SplayTreeMap ensures that the keys are alphabetically sorted using [String.compareTo].
    return SplayTreeMap.from({'alg': alg, if (kid.isNotEmpty) 'kid': kid, 'typ': typ});
  }
}

class Jws {
  final JwsHeader header;
  final Uint8List payload;
  final Uint8List signature;

  const Jws({required this.header, required this.payload, required this.signature});

  factory Jws.fromString(String input) {
    final parts = input.split('.');
    if (parts.length != 3) {
      throw ArgumentError('Invalid JWS string');
    }

    final header = JwsHeader.fromJson(json.decode(utf8.decode(urlSafeDecode(parts[0]))));
    final payload = urlSafeDecode(parts[1]);
    final signature = urlSafeDecode(parts[2]);
    return Jws(header: header, payload: payload, signature: signature);
  }

  @override
  String toString() {
    return [
      urlSafeEncode(utf8.encode(json.encode(header.toJson()))),
      urlSafeEncode(payload),
      urlSafeEncode(signature),
    ].join('.');
  }

  static Uint8List createSignaturePayload(JwsHeader header, Uint8List payload) {
    final headerString = urlSafeEncode(utf8.encode(json.encode(header.toJson())));
    final payloadString = urlSafeEncode(payload);
    return utf8.encode('$headerString.$payloadString');
  }
}

class ES256Jws extends Jws {
  const ES256Jws._({required super.header, required super.payload, required super.signature});

  factory ES256Jws.create(Uint8List payload, Map<String, dynamic> privateKeyJwk) {
    final header = JwsHeader(typ: 'JWT', alg: 'ES256', kid: privateKeyJwk['kid'] ?? '');
    final signer = NistP256ECDSASigner.fromJwk(privateKeyJwk);
    final signaturePayload = Jws.createSignaturePayload(header, payload);
    final signature = signer.sign(signaturePayload);
    return ES256Jws._(header: header, payload: payload, signature: signature);
  }

  factory ES256Jws.import(String input, Map<String, dynamic> publicKeyJwk) {
    final jws = Jws.fromString(input);
    final verifier = NistP256ECDSAVerifier.fromJwk(publicKeyJwk);
    final signaturePayload = Jws.createSignaturePayload(jws.header, jws.payload);
    final isValid = verifier.verify(signaturePayload, jws.signature);
    if (!isValid) {
      throw ArgumentError('Invalid Signature');
    }
    return ES256Jws._(header: jws.header, payload: jws.payload, signature: jws.signature);
  }
}
