import 'dart:convert';
import 'dart:typed_data';
// ignore: implementation_imports
import 'package:pointycastle/src/utils.dart'
    as p_utils;

class JwkValueEncoder extends Converter<
    BigInt,
    String> {
  const JwkValueEncoder();

  Uint8List
      toBigEndianUint8List(BigInt bigInt) {
    return p_utils
        .encodeBigIntAsUnsigned(bigInt);
  }

  String removeBase64Padding(
      String
          input) {
    // '=' is a padding character. Replace all if atleast one is present at the end.
    if (input
        .endsWith('=')) {
      return input.replaceAll('=',
          '');
    }
    return input;
  }

  @override
  String convert(
      BigInt
          input) {
    return removeBase64Padding(
        base64Url.encode(toBigEndianUint8List(input)));
  }
}

class JwkValueDecoder extends Converter<
    String,
    BigInt> {
  const JwkValueDecoder();

  BigInt toBigIntFromBigEndianBytes(
      Uint8List
          bytes) {
    return p_utils.decodeBigIntWithSign(
        1,
        bytes);
  }

  String addBase64Padding(
      String
          input) {
    if (input
        .endsWith('=')) {
      return input;
    }
    final length =
        input.length;
    final padding =
        4 - (length % 4);
    if (padding ==
        4) {
      return input;
    }
    return '$input${'=' * padding}';
  }

  @override
  BigInt convert(
      String
          input) {
    final characters =
        addBase64Padding(input);
    final bytes =
        base64Url.decode(characters);
    return toBigIntFromBigEndianBytes(
        bytes);
  }
}

/// Converts between JWK value and its string representation as per https://datatracker.ietf.org/doc/html/rfc7517#appendix-A.1
class JwkValueCodec extends Codec<
    BigInt,
    String> {
  const JwkValueCodec();

  @override
  JwkValueDecoder
      get decoder =>
          const JwkValueDecoder();

  @override
  JwkValueEncoder
      get encoder =>
          const JwkValueEncoder();
}

const jwkValueCodec =
    JwkValueCodec();
const jwkValueEncoder =
    JwkValueEncoder();
const jwkValueDecoder =
    JwkValueDecoder();
