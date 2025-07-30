import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

typedef FromEncodable<T, R extends Object> = T Function(R? value);
typedef ToEncodable<T, R extends Object> = R? Function(T value);

T _noFromTransform<T, R extends Object>(R? value) => value as T;
R? _noToTransform<T, R extends Object>(T value) => value as R?;

class ValueTransformer<T, R extends Object> {
  final FromEncodable<T, R> fromEncodable;
  final ToEncodable<T, R> toEncodable;

  const ValueTransformer({required this.fromEncodable, required this.toEncodable});

  const ValueTransformer.none() : fromEncodable = _noFromTransform, toEncodable = _noToTransform;
}

class Preference<T, R extends Object> {
  final String key;
  final FutureOr<SharedPreferences> _sharedPreferences;
  final ValueTransformer<T, R> transformer;

  Preference({required this.key, SharedPreferences? sharedPreferences, ValueTransformer<T, R>? transformer})
    : transformer = transformer ?? ValueTransformer<T, R>.none(),
      _sharedPreferences = sharedPreferences ?? SharedPreferences.getInstance();

  Future<T> get value async {
    final prefs = await _sharedPreferences;
    final rawValue = prefs.get(key);
    assert(
      rawValue is R || rawValue == null,
      'Raw value for "$key" is not of type $R, it is actually ${rawValue.runtimeType}',
    );
    return transformer.fromEncodable(rawValue is R ? rawValue : null);
  }

  Future<bool> setValue(T value) async {
    final rawValue = transformer.toEncodable(value);
    final prefs = await _sharedPreferences;
    if (rawValue == null) {
      return await prefs.remove(key);
    } else if (rawValue is String) {
      return await prefs.setString(key, rawValue);
    } else if (rawValue is bool) {
      return await prefs.setBool(key, rawValue);
    } else if (rawValue is int) {
      return await prefs.setInt(key, rawValue);
    } else if (rawValue is double) {
      return await prefs.setDouble(key, rawValue);
    }
    throw UnsupportedError('Unsupported value type: ${rawValue.runtimeType} encoded from $T');
  }
}
