import 'dart:async';

import 'package:flutter/foundation.dart';

import '../logging/logging.dart';

class ChangedValues<T> {
  final T? oldValue;
  final T value;

  const ChangedValues({required this.oldValue, required this.value});

  (T? oldValue, T value) get record => (oldValue, value);
}

class ObservableNotifier<T> implements ValueListenable<T> {
  /// Creates a [ValueListenable] that wraps this value.
  ObservableNotifier(this._value);

  /// The current value stored in this notifier.
  ///
  /// When the value is replaced with something that is not equal to the old
  /// value as evaluated by the equality operator ==, this class notifies its
  /// listeners.
  @override
  T get value => _value;
  T? get oldValue => _oldValue;

  T _value;
  T? _oldValue;

  late final _controller = StreamController<T>.broadcast();

  @protected
  set value(T newValue) {
    if (isDisposed) {
      final error = StateError('ObservableNotifier is disposed');
      logging.child('ObservableNotifier').warning(error.message, error, StackTrace.current);
      return;
    }

    if (identical(_value, newValue)) return;
    if (_value == newValue) {
      return;
    }

    _oldValue = value;
    _value = newValue;

    didChangeValues(_oldValue, _value);
  }

  bool get isDisposed => _controller.isClosed;

  @mustCallSuper
  void dispose() {
    if (isDisposed) return;
    _controller.close();
  }

  Stream<T> get stream => _controller.stream;

  Stream<ChangedValues<T>> get changesStream {
    T? previousData = value;
    return stream.map((data) {
      final event = ChangedValues(oldValue: previousData, value: data);
      previousData = data;
      return event;
    });
  }

  final _listenerRemover = <VoidCallback, StreamSubscription<T>>{};

  /// Register a closure to be called when the object notifies its listeners.
  @override
  void addListener(VoidCallback listener) {
    // subscription will be cancelled when listener is removed
    // ignore: cancel_subscriptions
    final subscription = _controller.stream.listen((_) => listener());

    _listenerRemover[listener] = subscription;
  }

  /// Remove a previously registered closure from the list of closures that the
  /// object notifies.
  @override
  void removeListener(VoidCallback listener) {
    final subscription = _listenerRemover[listener];
    if (subscription != null) {
      subscription.cancel();
      _listenerRemover.remove(listener);
    }
  }

  @protected
  @mustCallSuper
  void didChangeValues(T? oldValue, T value) {
    // Override in subclass to handle changes.
    _controller.add(value);
  }

  @override
  String toString() => '${describeIdentity(this)}($value)';
}
