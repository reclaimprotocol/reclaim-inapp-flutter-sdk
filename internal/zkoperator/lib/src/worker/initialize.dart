part of '../../reclaim_gnark_zkoperator.dart';

class InitAlgorithmWorker {
  final SendPort _commands;
  final ReceivePort _responses;
  final String? _httpCacheDirName;

  static const _debugLabel = '_InitAlgorithmWorker';

  InitAlgorithmWorker._(this._commands, this._responses, this._httpCacheDirName) {
    _responses.listen(_handleResponsesFromIsolate);
  }

  final Map<int, Completer<Object?>> _activeRequests = {};
  int _idCounter = 0;

  Future<bool> initializeAlgorithmInBackground(
    ProverAlgorithmType algorithm,
    List<String> keyAssetUrls,
    List<String> r1csAssetUrls,
  ) async {
    if (_closed) throw StateError('$_debugLabel is disposed');

    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    _commands.send((id, algorithm, keyAssetUrls, r1csAssetUrls, _httpCacheDirName));

    return await completer.future as bool;
  }

  // Only for use on master isolate
  static final _httpCacheDirInUseByIsolates = <String>{};

  static Future<InitAlgorithmWorker> spawn([String? perIsolateHttpCacheDirName]) async {
    if (perIsolateHttpCacheDirName != null) {
      if (_httpCacheDirInUseByIsolates.contains(perIsolateHttpCacheDirName)) {
        throw ArgumentError('Http cache dir $perIsolateHttpCacheDirName is already in use');
      }
      _httpCacheDirInUseByIsolates.add(perIsolateHttpCacheDirName);
    }
    // Create a receive port and add its initial message handler
    final initPort = RawReceivePort(null, _debugLabel);
    final connection = Completer<(ReceivePort, SendPort)>.sync();
    initPort.handler = (initialMessage) {
      final commandPort = initialMessage as SendPort;
      connection.complete((ReceivePort.fromRawReceivePort(initPort), commandPort));
    };
    // Spawn the isolate.
    try {
      final rootToken = RootIsolateToken.instance!;
      await Isolate.spawn(_startRemoteIsolate, (rootToken, initPort.sendPort), debugName: _debugLabel);
    } on Object {
      initPort.close();
      rethrow;
    }

    final (ReceivePort receivePort, SendPort sendPort) = await connection.future;

    return InitAlgorithmWorker._(sendPort, receivePort, perIsolateHttpCacheDirName);
  }

  void _handleResponsesFromIsolate(dynamic message) {
    if (message is _LogRecordIsolateMessage) {
      _LogRecordIsolateMessage.log(message, _debugLabel);
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

  static Future<Uint8List?> downloadWithMirrors({
    required List<String> mirrors,
    required String assetNameDebug,
    required String assetTypeDebug,
    required String? httpCacheDirName,
  }) async {
    final log = Logger('${_logger.fullName}.downloadWithMirrors');
    log.fine('Downloading $assetTypeDebug asset for $assetNameDebug');
    final stopwatch = Stopwatch()..start();
    for (final downloadUrl in mirrors) {
      try {
        log.fine('Downloading $assetTypeDebug asset for $assetNameDebug from $downloadUrl');
        final asset = await downloadWithHttp(downloadUrl, cacheDirName: httpCacheDirName);
        if (asset == null) continue;
        stopwatch.stop();
        log.info(
          'Downloaded $assetTypeDebug asset for $assetNameDebug from $downloadUrl, elapsed ${stopwatch.elapsed}',
        );
        return asset;
      } catch (e, s) {
        log.warning('Failed to download $assetTypeDebug asset for $assetNameDebug from $downloadUrl', e, s);
      }
    }
    stopwatch.stop();
    log.info('Failed to download $assetTypeDebug asset for $assetNameDebug, elapsed ${stopwatch.elapsed}');
    return null;
  }

  static Future<bool> initializeAlgorithm(
    ProverAlgorithmType algorithm,
    List<String> keyAssetUrls,
    List<String> r1csAssetUrls,
    String? httpCacheDirName,
  ) async {
    final provingKeyFuture = downloadWithMirrors(
      mirrors: keyAssetUrls,
      assetNameDebug: algorithm.name,
      assetTypeDebug: 'key',
      httpCacheDirName: httpCacheDirName,
    );
    final r1csFuture = downloadWithMirrors(
      mirrors: r1csAssetUrls,
      assetNameDebug: algorithm.name,
      assetTypeDebug: 'r1cs',
      httpCacheDirName: httpCacheDirName,
    );

    await Future.wait([provingKeyFuture, r1csFuture]);

    final provingKey = await provingKeyFuture;
    final r1cs = await r1csFuture;

    if (provingKey == null || r1cs == null) {
      _logger.warning({
        'reason': 'Failed to download key or r1cs for ${algorithm.name}',
        'provingKey.length': provingKey?.length,
        'r1cs.length': r1cs?.length,
      });
      return false;
    }

    Pointer<GoSlice>? provingKeyPointer;
    Pointer<GoSlice>? r1csPointer;
    try {
      provingKeyPointer = _GoSliceExtension.fromUint8List(provingKey);
      r1csPointer = _GoSliceExtension.fromUint8List(r1cs);

      const canInitializeInIsolate = bool.fromEnvironment(
        'org.reclaimprotocol.gnark_zkoperator.CAN_INITIALIZE_PROVER_IN_ISOLATE',
        // Disabled by default because this was causing oom problems with aggressive os applied optimizations
        defaultValue: true,
      );

      int result = 0;

      _logger.fine('Running InitAlgorithm new for ${algorithm.name}');
      final stopwatch = Stopwatch()..start();
      if (canInitializeInIsolate) {
        // Sharing pointer address between isolates because native allocated memory can be accessed by other isolates
        // Direct sharing of pointers accross isolate boundaries is not supported in some versions of Dart.
        // See: https://github.com/dart-lang/sdk/commit/eba0e68e1a9a6e81acb84de8e60ca299335ec24b
        final provingKeyAddress = provingKeyPointer.address;
        final r1csAddress = r1csPointer.address;
        result = await Isolate.run(() {
          return _bindings.InitAlgorithm(
            algorithm.id,
            Pointer.fromAddress(provingKeyAddress).cast<GoSlice>().ref,
            Pointer.fromAddress(r1csAddress).cast<GoSlice>().ref,
          );
        });
      } else {
        result = _bindings.InitAlgorithm(algorithm.id, provingKeyPointer.ref, provingKeyPointer.ref);
      }

      stopwatch.stop();
      _logger.info('Init complete for ${algorithm.name}, elapsed ${stopwatch.elapsed}');

      _logger.finest({
        'func': 'InitAlgorithm',
        'args': {
          'algorithm': {'name': algorithm.name, 'id': algorithm.id},
          'provingKey.length': provingKey.length,
          'r1cs.length': r1cs.length,
        },
        'return': result,
      });

      return result == 1;
    } finally {
      if (provingKeyPointer != null) {
        calloc.free(provingKeyPointer.ref.data);
        calloc.free(provingKeyPointer);
      }
      if (r1csPointer != null) {
        calloc.free(r1csPointer.ref.data);
        calloc.free(r1csPointer);
      }
    }
  }

  static void _handleCommandsToIsolate(ReceivePort receivePort, SendPort sendPort) async {
    receivePort.listen((message) async {
      if (message == 'shutdown') {
        receivePort.close();
        return;
      }
      final (id, algorithm, keyAssetUrls, r1csAssetUrls, httpCacheDirName) =
          message as (int, ProverAlgorithmType, List<String>, List<String>, String?);
      try {
        final initResponse = await initializeAlgorithm(algorithm, keyAssetUrls, r1csAssetUrls, httpCacheDirName);
        sendPort.send((id, initResponse));
      } catch (e) {
        sendPort.send((id, RemoteError(e.toString(), '')));
      }
    });
  }

  static void _startRemoteIsolate((RootIsolateToken, SendPort) args) {
    final (rootToken, sendPort) = args;
    BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);
    final receivePort = ReceivePort(_debugLabel);
    sendPort.send(receivePort.sendPort);
    _LogRecordIsolateMessage.setup(sendPort.send);
    _handleCommandsToIsolate(receivePort, sendPort);
  }

  bool _closed = false;

  bool close() {
    if (!_closed) {
      _closed = true;
      _commands.send('shutdown');
      if (_activeRequests.isEmpty) _responses.close();
      _httpCacheDirInUseByIsolates.remove(_httpCacheDirName);
      return true;
    }
    return true;
  }
}
