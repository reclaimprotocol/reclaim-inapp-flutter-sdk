import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:measure_performance/measure_performance.dart';
import 'package:reclaim_tee_operator_flutter/src/common/libreclaim/libreclaim.dart';

import 'isolate_worker/isolate_worker.dart';

final _logger = Logger('reclaim_flutter_sdk.reclaim_tee_operator.worker.prover');

typedef ProofResult = (String, PerformanceReport);

class ProveRunnable extends Runnable<Uint8List, ProofResult> {
  const ProveRunnable();

  @override
  Future<ProofResult> call(
    Uint8List input, {

    required String debugLabel,
    required ReceivePort receivePort,
    required SendPort sendPort,
  }) {
    return _onProveInIsolate(debugLabel, input);
  }

  static Future<ProofResult> _onProveInIsolate(
    // we'll use this to identify proof in logs
    String id,
    Uint8List inputBytes,
  ) async {
    final bindings = ReclaimBindings.instance;
    final inputBytesGoPointer = GoSliceExtension.fromUint8List(inputBytes);

    _logger.finest('[$id] Running prove for input of size ${inputBytes.lengthInBytes} bytes');
    final measure = MeasurePerformance();
    measure.start();
    final proof = bindings.prove(inputBytesGoPointer.ref);
    measure.stop();
    _logger.finest('[$id] Prove completed');

    // freeing up memory for inputBytesGoPointer
    calloc.free(inputBytesGoPointer.ref.data);
    calloc.free(inputBytesGoPointer);

    final proofStr = String.fromCharCodes(proof.r0.cast<Uint8>().asTypedList(proof.r1));

    // freeing up memory for proof
    bindings.free(proof.r0);

    if (!proofStr.startsWith('{')) {
      _logger.severe('received invalid proof: $proofStr');
      throw Exception('Invalid proof: $proofStr');
    }

    if (kDebugMode) {
      print('proof: $proofStr');
    }

    // returning the json string response
    return (proofStr, measure.getReport());
  }
}
