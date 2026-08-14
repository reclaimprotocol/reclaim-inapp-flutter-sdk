import 'dart:ffi';
import 'dart:io';

import 'package:reclaim_tee_operator_flutter/src/common/logger.dart';

import '../libreclaim/libreclaim.dart';
import 'isolate_worker/isolate_worker.dart';

import 'package:ffi/ffi.dart';

// This struct acts as our synchronous communication channel
// If this doesn't work, refer:
// - lib/src/common/worker/isolate_worker/mailbox.dart
final class SyncSignal extends Struct {
  // 0 = pending, 1 = completed
  @Uint8()
  external int isDone;

  // 0 = false, 1 = true
  @Uint8()
  external int result;
}

typedef InitializeAlgorithmRequest = ({int algorithmId, int syncSignalMemoryAddress});

class LazyAlgorithmInitializerRunnable extends Runnable<void, void> {
  LazyAlgorithmInitializerRunnable();

  static late SendPort _sendPort;

  static bool _isInitialized = false;

  late NativeCallable<ZKInitCallback>? _ensureAlgorithmInitializedNativeCallback;

  @override
  Future<void> call(
    void input, {
    required String debugLabel,
    required ReceivePort receivePort,
    required SendPort sendPort,
  }) async {
    if (_isInitialized) return;

    _sendPort = sendPort;

    final bindings = ReclaimBindings.instance;
    _logger.info('Adding listener for ZKInitCallback');

    // See if this can be moved to root isolate without affecting performance
    final nativeCallback = NativeCallable<ZKInitCallback>.listener(_ensureAlgorithmInitializedById);
    _ensureAlgorithmInitializedNativeCallback = nativeCallback;
    bindings.setZKInitCallback(nativeCallback.nativeFunction);

    _isInitialized = true;
  }

  @override
  void close() {
    _ensureAlgorithmInitializedNativeCallback?.close();
    _ensureAlgorithmInitializedNativeCallback = null;
    _isInitialized = false;
  }
}

final _logger = sdkLogger.child('worker.lazy_initialize');

void _ensureAlgorithmInitializedById(int algorithmId) {
  _logger.info('Operator library requested algorithm initialization for algorithm $algorithmId');

  final sendPort = LazyAlgorithmInitializerRunnable._sendPort;

  // 1. Allocate shared memory for the signal
  final Pointer<SyncSignal> signal = calloc<SyncSignal>();

  try {
    _logger.info('algorithm $algorithmId is not initialized, requesting parent isolate to initialize it');

    // Initialize flags
    signal.ref.isDone = 0;
    signal.ref.result = 0;

    final InitializeAlgorithmRequest message = (algorithmId: algorithmId, syncSignalMemoryAddress: signal.address);

    // 2. Send the Request: [Data, Memory Address]
    // We send signal.address (int) because raw Pointers cannot be sent via SendPort
    sendPort.send(MessageForOwner(message));

    // 3. BLOCKING WAIT
    // We loop until the Main Isolate flips the 'isDone' flag.
    while (signal.ref.isDone == 0) {
      // sleep() blocks the OS thread, yielding CPU.
      // 1ms is usually sufficient responsiveness for this pattern.
      sleep(const Duration(milliseconds: 1));
    }

    // 4. Read the result
    final result = signal.ref.result == 1;

    _logger.info('algorithm $algorithmId initialization result: $result');

    ReclaimBindings.instance.markZKInitComplete(algorithmId, result);
    return;
  } finally {
    // 5. Cleanup memory
    calloc.free(signal);
  }
}
