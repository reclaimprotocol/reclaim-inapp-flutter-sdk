import 'dart:async';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

part 'log.dart';

typedef _IsolateWorkerStartCommand<INPUT_TYPE, OUTPUT_TYPE> =
    (RootIsolateToken rootToken, SendPort sendPort, String debugLabel, Runnable<INPUT_TYPE, OUTPUT_TYPE> runnable);

const _isolateWorkerShutdownMessage = 'shutdown';

typedef _IsolateWorkerInput<INPUT_TYPE> = (int taskId, INPUT_TYPE input);

abstract class Runnable<INPUT_TYPE, OUTPUT_TYPE> {
  const Runnable();

  Future<OUTPUT_TYPE> call(INPUT_TYPE input, {required String debugLabel});
}

class WorkerManager<INPUT_TYPE, OUTPUT_TYPE> {
  final Runnable<INPUT_TYPE, OUTPUT_TYPE> runnable;

  const WorkerManager(this.runnable);

  Future<BackgroundWorker<INPUT_TYPE, OUTPUT_TYPE>> createWorker({String? debugLabel}) async {
    return BackgroundWorker._spawn(runnable: runnable, debugLabel: debugLabel);
  }
}

class BackgroundWorker<INPUT_TYPE, OUTPUT_TYPE> {
  final SendPort _commands;
  final ReceivePort _responses;

  final String debugLabel;

  BackgroundWorker._(this._commands, this._responses, this.debugLabel) {
    _responses.listen(_handleResponsesFromIsolate);
  }

  final Map<int, Completer<Object?>> _activeRequests = {};
  int _idCounter = 0;

  Future<OUTPUT_TYPE> executeInBackground(INPUT_TYPE input) async {
    if (_closed) throw StateError('$debugLabel is disposed');

    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    _commands.send((id, input));

    return await completer.future as OUTPUT_TYPE;
  }

  static Future<BackgroundWorker<INPUT_TYPE, OUTPUT_TYPE>> _spawn<INPUT_TYPE, OUTPUT_TYPE>({
    String? debugLabel,
    required Runnable<INPUT_TYPE, OUTPUT_TYPE> runnable,
  }) async {
    final effectiveDebugLabel = debugLabel ?? Object().hashCode.toString();

    // Create a receive port and add its initial message handler
    final initPort = RawReceivePort(null, effectiveDebugLabel);
    final connection = Completer<(ReceivePort, SendPort)>.sync();
    initPort.handler = (initialMessage) {
      final commandPort = initialMessage as SendPort;
      connection.complete((ReceivePort.fromRawReceivePort(initPort), commandPort));
    };
    // Spawn the isolate.
    try {
      final rootToken = RootIsolateToken.instance!;
      await Isolate.spawn(_startRemoteIsolate, (
        rootToken,
        initPort.sendPort,
        effectiveDebugLabel,
        runnable,
      ), debugName: effectiveDebugLabel);

      final (ReceivePort receivePort, SendPort sendPort) = await connection.future;

      return BackgroundWorker._(sendPort, receivePort, effectiveDebugLabel);
    } on Object {
      initPort.close();
      rethrow;
    }
  }

  void _handleResponsesFromIsolate(dynamic message) {
    if (message is _LogRecordIsolateMessage) {
      _LogRecordIsolateMessage.log(message, debugLabel);
      return;
    }

    final (int id, Object? response) = message as (int, Object?);
    final completer = _activeRequests.remove(id)!;

    if (response is RemoteError) {
      completer.completeError(response);
    } else {
      completer.complete(response);
    }
  }

  static void _handleCommandsToIsolate<INPUT_TYPE, OUTPUT_TYPE>(
    ReceivePort receivePort,
    SendPort sendPort,
    String debugLabel,
    Runnable<INPUT_TYPE, OUTPUT_TYPE> runnable,
  ) async {
    receivePort.listen((message) async {
      if (message == _isolateWorkerShutdownMessage) {
        receivePort.close();
        Isolate.current.kill(priority: Isolate.immediate);
        return;
      }
      final (id, input) = message as _IsolateWorkerInput<INPUT_TYPE>;
      try {
        final response = await runnable.call(input, debugLabel: debugLabel);
        sendPort.send((id, response));
      } catch (e, s) {
        sendPort.send((id, RemoteError(e.toString(), s.toString())));
      }
    });
  }

  static void _startRemoteIsolate(_IsolateWorkerStartCommand args) {
    final (rootToken, sendPort, debugLabel, runnable) = args;
    BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);
    final receivePort = ReceivePort(debugLabel);
    sendPort.send(receivePort.sendPort);
    _LogRecordIsolateMessage.setup(sendPort.send);
    _handleCommandsToIsolate(receivePort, sendPort, debugLabel, runnable);
  }

  bool _closed = false;

  bool close() {
    if (!_closed) {
      _closed = true;
      _commands.send(_isolateWorkerShutdownMessage);
      if (_activeRequests.isEmpty) {
        _responses.close();
      }
      return true;
    }
    return true;
  }
}
