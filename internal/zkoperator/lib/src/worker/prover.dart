part of '../../reclaim_gnark_zkoperator.dart';

typedef ProofResult = (String, PerformanceReport);
typedef OnProofPerformanceReportCallback = void Function(PerformanceReport);

class ProveRunnable extends Runnable<Uint8List, ProofResult> {
  const ProveRunnable();

  @override
  Future<ProofResult> call(Uint8List input, {required String debugLabel}) {
    return _onProveInIsolate(debugLabel, input);
  }

  static Future<ProofResult> _onProveInIsolate(
    // we'll use this to identify proof in logs
    String id,
    Uint8List inputBytes,
  ) async {
    final inputBytesGoPointer = _GoSliceExtension.fromUint8List(inputBytes);

    _logger.finest('[$id] Running prove for input of size ${inputBytes.lengthInBytes} bytes');
    final measure = MeasurePerformance();
    measure.start();
    final proof = _bindings.Prove(inputBytesGoPointer.ref);
    measure.stop();
    _logger.finest('[$id] Prove completed');

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
      print('proof: $proofStr');
    }

    // returning the json string response
    return (proofStr, measure.getReport());
  }
}
