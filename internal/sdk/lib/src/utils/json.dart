import 'dart:convert';
import 'dart:typed_data';

Object? bytesToBase64Json(Uint8List bytes) {
  final base64String = base64.encode(bytes);
  return {'type': 'uint8array', 'value': base64String};
}
