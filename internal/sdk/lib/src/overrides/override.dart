abstract class ReclaimOverride<T extends ReclaimOverride<T>> {
  /// Enable const constructor for subclasses.
  const ReclaimOverride();

  /// The override's type.
  Object get type => T;

  /// Creates a copy of this override with the given fields
  /// replaced by the non-null parameter values.
  ReclaimOverride<T> copyWith();

  static Map<Object, ReclaimOverride<dynamic>> _overrides = const {};

  static void clearAll() {
    _overrides = const {};
  }

  static T? get<T extends ReclaimOverride<T>>() {
    return _overrides[T] as T?;
  }

  static void set(ReclaimOverride<dynamic> override) {
    _overrides = _overridesIterableToMap({..._overrides.values, override});
  }

  static void setAll(Iterable<ReclaimOverride<dynamic>> overrides) {
    _overrides = _overridesIterableToMap({..._overrides.values, ...overrides});
  }

  /// Convert the [overridesIterable] passed to [ThemeData.new] or [copyWith]
  /// to the stored [extensions] map, where each entry's key consists of the extension's type.
  static Map<Object, ReclaimOverride<dynamic>> _overridesIterableToMap(
    Iterable<ReclaimOverride<dynamic>> overridesIterable,
  ) {
    return Map<Object, ReclaimOverride<dynamic>>.unmodifiable(<Object, ReclaimOverride<dynamic>>{
      // Strangely, the cast is necessary for tests to run.
      for (final ReclaimOverride<dynamic> override in overridesIterable)
        override.type: override as ReclaimOverride<ReclaimOverride<dynamic>>,
    });
  }
}
