import 'dart:convert';

T? fromStringToObject<T>({
  required String content,
  required T Function(Map<String, dynamic>) fromJson,
  required void Function(Object e, StackTrace s) onInvalidContent,
}) {
  try {
    final map = json.decode(content);
    if (map is! Map) {
      onInvalidContent(FormatException('decoded json string wasn\'t a map'), StackTrace.current);
      return null;
    }
    return fromJson(map as Map<String, dynamic>);
  } catch (e, s) {
    onInvalidContent(e, s);
    return null;
  }
}

// Encode to a JSON string and decode to a Map<dynamic, dynamic> to avoid type errors. This causes all nested objects's toJson to be called.
Map<T, Object?>? ensureMap<T>(Map<String, Object?>? map) {
  if (map == null) return null;
  return json.decode(json.encode(map));
}
