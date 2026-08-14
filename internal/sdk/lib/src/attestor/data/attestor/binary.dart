import 'dart:convert';
import 'dart:typed_data';

import 'data.dart';

class AttestorBinaryData extends AttestorData {
  /// Creates a new [AttestorBinaryData] with a base64 encoded string [value].
  const AttestorBinaryData({required super.value}) : super(type: 'uint8array');

  factory AttestorBinaryData.fromBytes(List<int> bytes) {
    final data = base64.encode(bytes);
    return AttestorBinaryData(value: data);
  }

  factory AttestorBinaryData.fromJson(Object? jsonData) {
    if (jsonData is Map) {
      if (jsonData['type'] == 'uint8array') {
        final value = jsonData['value'];
        if (value is String) {
          return AttestorBinaryData(value: value);
        } else {
          throw const FormatException('Invalid attestor data for type uint8array');
        }
      } else {
        final data = Uint8List(jsonData.length);
        for (final key in jsonData.keys) {
          final index = key is int ? key : int.parse(key);
          final value = jsonData[key];
          if (value is! int) {
            throw const FormatException('Invalid attestor data for type uint8array');
          }
          data[index] = value;
        }
        return AttestorBinaryData.fromBytes(data);
      }
    } else if (jsonData is List) {
      return AttestorBinaryData.fromBytes(jsonData.whereType<int>().toList());
    } else if (jsonData is String) {
      return AttestorBinaryData(value: jsonData);
    } else {
      throw const FormatException('Invalid attestor data');
    }
  }
}
