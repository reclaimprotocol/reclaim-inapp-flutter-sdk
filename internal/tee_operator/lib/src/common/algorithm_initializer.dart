import 'dart:async';
import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:reclaim_tee_operator_flutter/src/common/logger.dart';
import 'algorithm/assets.dart';

import 'algorithm/algorithm.dart';
import 'worker/initialize.dart';
import 'worker/isolate_worker/isolate_worker.dart';
import 'worker/lazy_initialize.dart';

class KeyAlgorithmAssetUrls {
  /// URL of the key asset
  final List<String> keyAssetUrls;

  /// URL of the rank-1 constraint system (r1cs) circuit
  final List<String> r1csAssetUrls;

  KeyAlgorithmAssetUrls(String keyAssetUrl, String r1csAssetUrl) : this.mirrors([keyAssetUrl], [r1csAssetUrl]);
  const KeyAlgorithmAssetUrls.mirrors(this.keyAssetUrls, this.r1csAssetUrls);
}

typedef ProverAlgorithmAssetUrlsProvider = KeyAlgorithmAssetUrls Function(ProverAlgorithmType algorithm);

/// A cache to store the initialization status of different key algorithm types.
/// The key is the [ProverAlgorithmType] and the value is a boolean indicating
/// whether the initialization was successful.
final _algorithmInitializerFutureCache = <ProverAlgorithmType, Future<bool>?>{};
final _initAlgorithmWorkerFuture = const WorkerManager(
  InitAlgorithmRunnable(httpCacheDirName: 'prover_http_cache'),
).createWorker();
final _lazyAlgorithmInitializerWorkerFuture = WorkerManager(
  LazyAlgorithmInitializerRunnable(),
).createWorker(onMessageFromBackground: _onBackgroundRequestedAlgorithmInitialization);

final _initializerLog = Logger('reclaim_flutter_sdk.reclaim_tee_operator.gnark_initializer');

final _initializedAlgorithms = ValueNotifier<Set<ProverAlgorithmType>>({});

/// For letting consumers get some information about the initialization status.
ValueListenable<Set<ProverAlgorithmType>> get initializedAlgorithmsNotifier {
  return _initializedAlgorithms;
}

bool get hasAllAlgorithmsInitialized => _initializedAlgorithms.value.length == ProverAlgorithmType.values.length;

Future<bool> _initialize(ProverAlgorithmType algorithm, ProverAlgorithmAssetUrlsProvider getAssetUrls) async {
  if (_algorithmInitializerFutureCache[algorithm] == null) {
    final completer = Completer<bool>();
    _algorithmInitializerFutureCache[algorithm] = completer.future;

    try {
      final worker = await _initAlgorithmWorkerFuture;
      final assetUrls = getAssetUrls(algorithm);
      final stopwatch = Stopwatch();
      stopwatch.start();
      _initializerLog.info('Initializing algorithm $algorithm');
      await worker.executeInBackground(
        InitAlgorithmInput(
          algorithm: algorithm,
          keyAssetUrls: assetUrls.keyAssetUrls,
          r1csAssetUrls: assetUrls.r1csAssetUrls,
        ),
      );
      stopwatch.stop();
      _initializerLog.info('Initialized algorithm $algorithm in ${stopwatch.elapsed}');
      completer.complete(true);
      _initializedAlgorithms.value = {..._initializedAlgorithms.value, algorithm};
    } catch (e, s) {
      // If there's an error, explicitly return the future with an error.
      // then set the completer to null so we can retry.
      completer.completeError(e, s);
      final algorithmFuture = completer.future;
      _algorithmInitializerFutureCache[algorithm] = null;
      _initializerLog.severe('Error initializing algorithm $algorithm', e, s);
      return algorithmFuture;
    }
  }
  return _algorithmInitializerFutureCache[algorithm]!;
}

final _logger = sdkLogger.child('ProverAlgorithmInitializer');

class ProverAlgorithmInitializer {
  static KeyAlgorithmAssetUrls defaultProverAlgorithmAssetUrlsProvider(ProverAlgorithmType algorithm) {
    return KeyAlgorithmAssetUrls.mirrors(algorithm.defaultKeyAssetUrls, algorithm.defaultR1CSAssetUrls);
  }

  ProverAlgorithmInitializer._() {
    _setupLazyInitialization();
  }

  ProverAlgorithmAssetUrlsProvider getAssetUrls = defaultProverAlgorithmAssetUrlsProvider;

  static final instance = ProverAlgorithmInitializer._();

  /// {@template reclaim_tee_operator.ProverAlgorithmInitializer.ensureInitialized}
  /// Ensures that the [algorithm] is initialized and completes with `true` if successful.
  ///
  /// For GNARK operators, this downloads and initializes circuit files.
  /// For TEE operators, this is a no-op as circuits are managed by the native library.
  /// {@endtemplate}
  Future<bool> ensureInitialized(ProverAlgorithmType algorithm) {
    return _initialize(algorithm, getAssetUrls);
  }

  void _setupLazyInitialization() async {
    final worker = await _lazyAlgorithmInitializerWorkerFuture;
    worker.executeInBackground(null);
  }

  static Future<bool> _ensureAlgorithmInitializedById(int algorithmId) async {
    try {
      final initializer = ProverAlgorithmInitializer.instance;
      final algorithm = ProverAlgorithmType.findById(algorithmId);
      if (algorithm == null) {
        _initializerLog.severe('Algorithm initialization with unknown id request: $algorithmId');
        return false;
      }
      return initializer.ensureInitialized(algorithm);
    } catch (e, s) {
      _initializerLog.severe('Failed to initialize algorithm', e, s);
      return false;
    }
  }
}

void _onBackgroundRequestedAlgorithmInitialization(dynamic message) async {
  Pointer<SyncSignal>? signal;
  try {
    final request = message as InitializeAlgorithmRequest;
    _logger.info('Initializing algorithm ${request.algorithmId}');
    signal = Pointer.fromAddress(request.syncSignalMemoryAddress);
    final result = await ProverAlgorithmInitializer._ensureAlgorithmInitializedById(request.algorithmId);

    // 2. Reconstruct pointer from address

    // 3. Write result to shared memory
    signal.ref.result = result ? 1 : 0;

    // 4. Mark as done (Unlocks the worker isolate)
    signal.ref.isDone = 1;
  } catch (e, s) {
    _logger.severe('Failed to initialize algorithm', e, s);
    // 3. Write result to shared memory
    signal?.ref.result = 0;
    // 4. Mark as done (Unlocks the worker isolate)
    signal?.ref.isDone = 1;
  }
}
