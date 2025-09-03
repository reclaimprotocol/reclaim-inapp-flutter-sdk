import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:xxh3/xxh3.dart';

import 'crypto/ethers.dart';

Object _canoncalize(Object object) {
  if (object is Map) {
    return SplayTreeMap.from(object);
  } else if (object is Iterable) {
    return [...object]..sort();
  }
  return object;
}

enum IdentifierHashingAlgorithm {
  keccak256,
  xxh3;

  static const defaultAlgorithm = IdentifierHashingAlgorithm.xxh3;
}

String createRestorationIdentifierFromBytes(
  Uint8List bytes, {
  String? prefix,
  IdentifierHashingAlgorithm algorithm = IdentifierHashingAlgorithm.defaultAlgorithm,
}) {
  final hash = switch (algorithm) {
    IdentifierHashingAlgorithm.xxh3 => xxh3String(bytes),
    IdentifierHashingAlgorithm.keccak256 => keccak256(bytes).map((byte) {
      return byte.toRadixString(16).padLeft(2, '0');
    }).join(),
  };
  if (prefix == null) {
    return hash;
  }
  return '$prefix$hash';
}

String createRestorationIdentifier(Object restorable, {String? prefix}) {
  final bytes = utf8.encode(json.encode(_canoncalize(restorable)));
  return createRestorationIdentifierFromBytes(bytes, prefix: prefix);
}
