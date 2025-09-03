part of '../../../reclaim_gnark_zkoperator.dart';

class TOPRFFinalizeRunnable extends Runnable<Uint8List, String> {
  const TOPRFFinalizeRunnable();

  @override
  Future<String> call(Uint8List input, {required String debugLabel}) {
    return _onFinalizeOPRFInIsolate(debugLabel, input);
  }

  static Future<String> _onFinalizeOPRFInIsolate(
    // we'll use this to identify proof in logs
    String id,
    Uint8List inputBytes,
  ) async {
    final inputBytesGoPointer = _GoSliceExtension.fromUint8List(inputBytes);

    _logger.finest('[$id] Running TOPRF finalize for input of size ${inputBytes.lengthInBytes} bytes');
    final stopwatch = Stopwatch()..start();
    final proof = _bindings.TOPRFFinalize(inputBytesGoPointer.ref);
    stopwatch.stop();
    _logger.finest('[$id] TOPRF finalize completed, elapsed ${stopwatch.elapsed}');

    // freeing up memory for inputBytesGoPointer
    calloc.free(inputBytesGoPointer.ref.data);
    calloc.free(inputBytesGoPointer);

    final proofStr = String.fromCharCodes(proof.r0.asTypedList(proof.r1));

    // freeing up memory for proof
    _bindings.Free(proof.r0);

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
