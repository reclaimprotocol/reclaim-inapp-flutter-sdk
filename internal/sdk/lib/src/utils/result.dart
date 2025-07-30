sealed class Optional<T> {
  const factory Optional.value(T? value) = _OptionalValue<T>;
  const factory Optional.none() = _OptionalNone<T>;

  bool get hasValue;

  R map<R>({required R Function(T?) value, required R Function() none});
}

final class _OptionalValue<T> implements Optional<T> {
  final T? value;

  const _OptionalValue(this.value);

  @override
  bool get hasValue => true;

  @override
  R map<R>({required R Function(T?) value, required R Function() none}) {
    return value(this.value);
  }
}

final class _OptionalNone<T> implements Optional<T> {
  const _OptionalNone();

  @override
  bool get hasValue => false;

  @override
  R map<R>({required R Function(T?) value, required R Function() none}) {
    return none();
  }
}
