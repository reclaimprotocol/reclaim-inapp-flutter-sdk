import 'dart:convert';
import 'dart:typed_data';
import 'jwk_codec.dart';

/// Encodes a UTF-8 encoded binary data to a URL-safe string without Base64 padding
String urlSafeEncode(
    Uint8List
        data) {
  return jwkValueEncoder
      .removeBase64Padding(base64Url.encode(data));
}

/// Decodes a URL-safe string back to UTF-8 encoded binary data
///
/// This function expects input that was encoded with urlSafeEncode
Uint8List urlSafeDecode(
    String
        input) {
  return base64Url
      .decode(jwkValueDecoder.addBase64Padding(input));
}
