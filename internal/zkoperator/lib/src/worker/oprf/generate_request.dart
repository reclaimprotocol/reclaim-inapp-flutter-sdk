part of '../../../reclaim_gnark_zkoperator.dart';

class GenerateOPRFRequestDataRunnable extends Runnable<Uint8List, String> {
  const GenerateOPRFRequestDataRunnable();

  @override
  Future<String> call(Uint8List input, {required String debugLabel}) {
    return _onGenerateOPRFRequestDataInIsolate(debugLabel, input);
  }

  static Future<String> _onGenerateOPRFRequestDataInIsolate(
    // we'll use this to identify proof in logs
    String id,
    Uint8List inputBytes,
  ) async {
    final inputBytesGoPointer = _GoSliceExtension.fromUint8List(inputBytes);

    _logger.finest('[$id] Running generate OPRF request data for input of size ${inputBytes.lengthInBytes} bytes');
    final stopwatch = Stopwatch()..start();
    final proof = _bindings.GenerateOPRFRequestData(inputBytesGoPointer.ref);
    stopwatch.stop();
    _logger.finest('[$id] generated OPRF request data completed, elapsed ${stopwatch.elapsed}');

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

    // returning the json string response
    return proofStr;
  }
}
