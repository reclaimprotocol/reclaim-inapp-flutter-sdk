import 'package:flutter/foundation.dart';
import '../../logging/logging.dart';

class _CancellationNotifier
    extends ChangeNotifier {
  void
      notify() {
    notifyListeners();
  }
}

abstract class ReclaimCancellable {
  static final _pendingCancellations =
      <ReclaimCancellable>{};

  @protected
  void
      onStart() {
    // cancel all others
    for (int i = _pendingCancellations.length - 1;
        i >= 0;
        i--) {
      final session =
          _pendingCancellations.elementAt(i);
      session.cancel();
    }

    _pendingCancellations
        .add(this);
  }

  final _notifier =
      _CancellationNotifier();

  VoidCallback
      addCancellationListener(VoidCallback listener) {
    final logger =
        logging.child('ReclaimCancellable');
    if (_isFinished) {
      logger.warning('Cannot add cancellation listener to finished cancellable - $hashCode');

      return () =>
          {};
    }
    _notifier
        .addListener(listener);
    return () =>
        _notifier.removeListener(listener);
  }

  bool
      _isFinished =
      false;

  void
      cancel() {
    if (_isFinished) {
      return;
    }
    logging
        .finest('[ReclaimCancellable] cancellation - $hashCode');

    _notifier
        .notify();
    onFinished();
  }

  @protected
  void
      onFinished() {
    if (_isFinished) {
      return;
    }

    _isFinished =
        true;
    logging
        .finest('[ReclaimCancellable] onFinished - $hashCode');
    _notifier
        .dispose();
    _pendingCancellations
        .remove(this);
  }
}
