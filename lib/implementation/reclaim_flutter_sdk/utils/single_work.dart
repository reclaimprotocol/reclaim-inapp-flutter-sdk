import 'dart:async';

class WorkCanceledException
    implements
        Exception {
  const WorkCanceledException();

  @override
  String
      toString() {
    return 'WorkCanceledException: Task already completed by a previous worker';
  }
}

/// Provides a lock which can be used to only do one async work at a time and only
/// allows another if the previous workers have failed to complete task.
/// If a task completes successfully, all subsequent **pending** works are cancelled.
class SingleWorkScope<
    T> {
  final List<Future<T>>
      _pending =
      [];

  int get pendingCount =>
      _pending.length;

  void _addAsPending(
      Future<T>
          future) async {
    _pending
        .add(future);
    try {
      await future;
    } catch (_) {}
    // Removing completed future from the pending.
    // This will allow us to reuse the same scope when all pending works are completed (with result, error or cancellation).
    _pending
        .remove(future);
  }

  /// Returns a Completer which can be used to indicate the completion of a task
  /// when no previous tasks for this scope [SingleWorkScope] completed successfully.
  ///
  /// If any previous task has completed successfully for this scope [SingleWorkScope], then this will throw a [WorkCanceledException].
  Future<Completer<T>>
      acquireWorkCompleter() async {
    final previous =
        [
      ..._pending
    ];
    final completer =
        Completer<T>();

    _addAsPending(
        completer.future);

    for (final future
        in previous) {
      bool
          didComplete =
          false;
      try {
        await future;
        didComplete = true;
      } catch (_) {
        // This future failed, we'll try the next one.
        continue;
      }
      if (didComplete) {
        completer.completeError(const WorkCanceledException());
        // waiting for the future from the same completer which will 100%
        // throw an error. This is necessary to make sure the future
        // from completer gets handled.
        await completer.future;
      }
    }
    // No previous work or all previous work failed, we can do this one.
    return completer;
  }

  /// Runs the given [work] and ensures that no other work is running in parallel.
  ///
  /// If any previous work has completed successfully for this scope [SingleWorkScope], then this will throw a [WorkCanceledException].
  Future<T>
      runGuarded(Future<T> Function() work) async {
    final completer =
        await acquireWorkCompleter();

    void
        runWorkAndInformCompletion() async {
      try {
        final result = await work();
        completer.complete(result);
      } catch (e, s) {
        completer.completeError(e, s);
      }
    }

    // Starting the work and informing completion when it's done. Not awaiting
    // in this block to let the event loop prefer caller of this function to get awaited result first.
    runWorkAndInformCompletion();

    return completer
        .future;
  }
}
