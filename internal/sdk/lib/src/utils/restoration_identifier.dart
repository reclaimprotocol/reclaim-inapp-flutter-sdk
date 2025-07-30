import 'dart:collection';
import 'dart:convert';

import 'package:xxh3/xxh3.dart';

Object _canoncalize(Object object) {
  if (object is Map) {
    return SplayTreeMap.from(object);
  } else if (object is Iterable) {
    return [...object]..sort();
  }
  return object;
}

String createRestorationIdentifier(String prefix, Object restorable) {
  final bytes = utf8.encode(json.encode(_canoncalize(restorable)));
  final hash = xxh3String(bytes);
  return '$prefix:$hash';
}
