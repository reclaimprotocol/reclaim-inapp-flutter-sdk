import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:reclaim_tee_operator_flutter/src/common/libreclaim/libreclaim.dart';

import '../isolate_worker/isolate_worker.dart';

final _logger = Logger('reclaim_inapp_sdk.reclaim_tee_operator.worker.oprf.finalize');

class TOPRFFinalizeRunnable extends Runnable<Uint8List, String> {
  const TOPRFFinalizeRunnable();

  @override
  Future<String> call(
    Uint8List input, {
    required String debugLabel,
    required ReceivePort receivePort,
    required SendPort sendPort,
  }) {
    return _onFinalizeOPRFInIsolate(debugLabel, input);
  }

  static Future<String> _onFinalizeOPRFInIsolate(
    // we'll use this to identify proof in logs
    String id,
    Uint8List inputBytes,
  ) async {
    final bindings = ReclaimBindings.instance;
    final inputBytesGoPointer = GoSliceExtension.fromUint8List(inputBytes);

    _logger.finest('[$id] Running TOPRF finalize for input of size ${inputBytes.lengthInBytes} bytes');
    final stopwatch = Stopwatch()..start();
    final proof = bindings.executeTOPRFFinalize(inputBytesGoPointer.ref);
    stopwatch.stop();
    _logger.finest('[$id] TOPRF finalize completed, elapsed ${stopwatch.elapsed}');

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
      print('TOPRF finalize: $proofStr');
    }

    // returning the json string response
    return proofStr;
  }
}
