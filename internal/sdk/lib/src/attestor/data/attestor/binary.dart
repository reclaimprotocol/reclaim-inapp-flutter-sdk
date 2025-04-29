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

  factory AttestorBinaryData.fromJson(Object? json) {
    if (json is Map) {
      if (json['type'] == 'uint8array') {
        final value = json['value'];
        if (value is String) {
          return AttestorBinaryData(value: value);
        } else {
          throw FormatException('Invalid attestor data for type uint8array');
        }
      } else {
        final data = Uint8List(json.length);
        for (final key in json.keys) {
          final index = key is int ? key : int.parse(key);
          final value = json[key];
          if (value is! int) {
            throw FormatException('Invalid attestor data for type uint8array');
          }
          data[index] = value;
        }
        return AttestorBinaryData.fromBytes(data);
      }
    } else if (json is List) {
      return AttestorBinaryData.fromBytes(json.whereType<int>().toList());
    } else {
      throw FormatException('Invalid attestor data');
    }
  }
}
