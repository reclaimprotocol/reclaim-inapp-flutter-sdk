import 'dart:async';
import 'dart:math';

import '../../logging/logging.dart';
import '../data/process.dart';
import 'base.dart';

class AttestorRpcProcessManager<REQUEST, RESPONSE> {
  final StreamController<Map<String, Object?>> updatesController;
  final Sink<Map<String, Object?>> emitUpdate;
  final AttestorProcess<REQUEST, RESPONSE> process;
  final Completer<Object?> completer;
  final void Function() onCancel;

  const AttestorRpcProcessManager({
    required this.updatesController,
    required this.process,
    required this.emitUpdate,
    required this.completer,
    required this.onCancel,
  });

  factory AttestorRpcProcessManager.create({
    required String requestType,
    required REQUEST request,
    required AttestorResponseTransformer<RESPONSE> transformer,
  }) {
    final log = logging.child('AttestorRpcProcessManager.create');
    final requestId = generateRequestId();
    final completer = Completer<Object?>();
    final updateStream = StreamController<Map<String, Object?>>.broadcast();

    void closeUpdateStream() {
      log.finest('closing update stream');
      if (!updateStream.isClosed) {
        updateStream.close();
      }
    }

    Future<RESPONSE> handleFuture(Future<dynamic> future) async {
      try {
        final value = await future;
        closeUpdateStream();
        return await transformer(value);
      } catch (_) {
        closeUpdateStream();
        rethrow;
      }
    }

    return AttestorRpcProcessManager(
      process: AttestorProcess(
        id: requestId,
        type: requestType,
        request: request,
        response: handleFuture(completer.future),
        updateStream: updateStream.stream,
      ),
      emitUpdate: updateStream.sink,
      completer: completer,
      updatesController: updateStream,
      onCancel: () {
        if (completer.isCompleted) return;
        completer.completeError(const AttestorRequestCancelledException());
      },
    );
  }

  static String generateRequestId() {
    final random = Random.secure();
    final randomNumber = random.nextDouble();
    final hexString = randomNumber.toStringAsFixed(16).substring(2);
    return hexString;
  }
}
