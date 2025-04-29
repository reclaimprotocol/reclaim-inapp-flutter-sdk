part of '../../reclaim_gnark_zkoperator.dart';

class KeyAlgorithmAssetUrls {
  /// URL of the key asset
  final String keyAssetUrl;

  /// URL of the rank-1 constraint system (r1cs) circuit
  final String r1csAssetUrl;

  const KeyAlgorithmAssetUrls(this.keyAssetUrl, this.r1csAssetUrl);
}

typedef ProverAlgorithmAssetUrlsProvider = KeyAlgorithmAssetUrls Function(ProverAlgorithmType algorithm);

/// A cache to store the initialization status of different key algorithm types.
/// The key is the [ProverAlgorithmType] and the value is a boolean indicating
/// whether the initialization was successful.
final _algorithmInitializerFutureCache = <ProverAlgorithmType, Future<bool>?>{};
final _initAlgorithmWorkerFuture = InitAlgorithmWorker.spawn('prover_http_cache');

final _initializerLog = Logger('reclaim_flutter_sdk.reclaim_gnark_zkoperator.initializer');

final _initializedAlgorithms = ValueNotifier<Set<ProverAlgorithmType>>({});

/// For letting consumers get some information about the initialization status.
ValueListenable<Set<ProverAlgorithmType>> get initializedAlgorithmsNotifier {
  return _initializedAlgorithms;
}

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
      await worker.initializeAlgorithmInBackground(algorithm, assetUrls.keyAssetUrl, assetUrls.r1csAssetUrl);
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

bool _hasAllAlgorithmsInitialized = false;

enum ProverAlgorithmInitializationPriority {
  /// Initialize non-OPRF algorithms first, then OPRF algorithms.
  nonOprfFirst,

  /// Initialize CHACHA20-OPRF with non-OPRF first, then the remaining OPRF Algorithms.
  chachaOprfWithNonOprf,
}

class ProverAlgorithmInitializer {
  final ProverAlgorithmAssetUrlsProvider getAssetUrls;
  final ProverAlgorithmInitializationPriority downloadPriority;

  ProverAlgorithmInitializer(
    this.getAssetUrls, [
    this.downloadPriority = ProverAlgorithmInitializationPriority.nonOprfFirst,
  ]) {
    unawaited(_startAllInitialized());
  }

  Future<bool> ensureInitialized(ProverAlgorithmType algorithm) {
    return _initialize(algorithm, getAssetUrls);
  }

  Future<void> _startAllInitialized() async {
    if (_hasAllAlgorithmsInitialized) return;
    final stopwatch = Stopwatch();
    _initializerLog.info('Initializing all gnark zk operator algorithms');
    stopwatch.start();
    await _initializeAllAlgorithms();
    _hasAllAlgorithmsInitialized = true;
    stopwatch.stop();
    _initializerLog.info('All gnark zk operator algorithms initialized in ${stopwatch.elapsed}');
  }

  /// Initializes the prover by loading the necessary algorithms asynchronously.
  Future<void> _initializeAllAlgorithms() async {
    final canDownloadChachaOprfWithNonOprf =
        downloadPriority == ProverAlgorithmInitializationPriority.chachaOprfWithNonOprf;

    // Download and initialize in order of importance without starving event queue.
    // TODO: Find a better concurrency model to do all parallely without starving event queue.

    await Future.wait(
      [
        ProverAlgorithmType.CHACHA20,
        if (canDownloadChachaOprfWithNonOprf) ProverAlgorithmType.CHACHA20_OPRF,
      ].map(ensureInitialized),
    );

    await Future.wait([ProverAlgorithmType.AES_128, ProverAlgorithmType.AES_256].map(ensureInitialized));

    await ensureInitialized(ProverAlgorithmType.CHACHA20_OPRF);

    await Future.wait([ProverAlgorithmType.AES_128_OPRF, ProverAlgorithmType.AES_256_OPRF].map(ensureInitialized));
  }
}
