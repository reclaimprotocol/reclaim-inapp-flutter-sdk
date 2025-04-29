import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:convert';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:measure_performance/measure_performance.dart';

import 'src/algorithm/algorithm.dart';
import 'src/algorithm/assets.dart';
import 'src/algorithm/utils.dart';
import 'src/download/download.dart';
import 'src/generated_bindings.dart';
import 'src/zk_operator.dart';

export 'src/algorithm/algorithm.dart';
export 'src/algorithm/assets.dart';
export 'src/zk_operator.dart';

part 'src/algorithm/initializer.dart';
part 'src/part/bindings.dart';
part 'src/part/bytes.dart';
part 'src/part/json.dart';

part 'src/worker/initialize.dart';
part 'src/worker/log.dart';
part 'src/worker/oprf/generate_request.dart';
part 'src/worker/oprf/finalize.dart';
part 'src/worker/prover.dart';

// The logger for reclaim_gnark_zkoperator package. Using 'reclaim_flutter_sdk' as parent logger name to allow
// logs from this package to be listened from reclaim_flutter_sdk if sdk is filtering sdk only logs under reclaim_flutter_sdk.
final _logger = Logger('reclaim_flutter_sdk.reclaim_gnark_zkoperator');

/// {@macro reclaim_gnark_zkoperator.ZkOperator}
///
/// The main class for interacting with the Gnark prover and Reclaim Attestor Browser RPC.
/// This class provides methods to initialize the prover and compute witness proofs.
///
/// This class extends [ZkOperator] and implements the methods defined in the [ZkOperator] interface.
class ReclaimZkOperator extends ZkOperator {
  static final _cachedInstances = <ProverAlgorithmAssetUrlsProvider, ReclaimZkOperator>{};

  /// Returns a singleton instance of [ReclaimZkOperator].
  ///
  /// If the instance is not yet created, it creates a new one and initializes it.
  /// Running this for the first time will initialize the prover, and this initialization
  /// **can take a while**.
  ///
  /// It is recommended to call this method once in your application's lifecycle, in advance of its usage.
  /// For example, you can call it in your application's `main` function or a widget's `initState` method
  /// without awaiting the result.
  ///
  /// Running this method more than once is safe.
  ///
  /// To update an algorithm [ProverAlgorithmType]'s key and r1cs assets, you can call
  /// [ReclaimZkOperator._initializeAllAlgorithms] and use [ReclaimZkOperator] later when [_initializeAllAlgorithms] completes.
  static Future<ReclaimZkOperator> getInstance([
    ProverAlgorithmAssetUrlsProvider getAssetUrls = defaultProverAlgorithmAssetUrlsProvider,
    ProverAlgorithmInitializationPriority priority = ProverAlgorithmInitializationPriority.nonOprfFirst,
  ]) async {
    if (_cachedInstances[getAssetUrls] == null) {
      _cachedInstances[getAssetUrls] = ReclaimZkOperator._(ProverAlgorithmInitializer(getAssetUrls, priority));
    }
    return _cachedInstances[getAssetUrls]!;
  }

  static KeyAlgorithmAssetUrls defaultProverAlgorithmAssetUrlsProvider(ProverAlgorithmType algorithm) {
    return KeyAlgorithmAssetUrls(algorithm.defaultKeyAssetUrl, algorithm.defaultR1CSAssetUrl);
  }

  final ProverAlgorithmInitializer initializer;

  ReclaimZkOperator._(this.initializer);

  Future<_ProveWorker>? _proveWorkerFuture;

  /// Computes the witness proof for the given bytes.
  ///
  /// The `fnName` parameter should be the name of the zk or oprf functions supported by the prover.
  /// The `args` parameter should be the arguments for the function.
  ///
  /// When using this with `reclaim_flutter_sdk`, this function can be utilized as follows when creating a ReclaimVerification object:
  /// ```dart
  /// final reclaimVerification = ReclaimVerification(
  ///   buildContext: context,
  ///   appId: appId,
  ///   providerId: providerId,
  ///   secret: appSecret,
  ///   context: '',
  ///   parameters: {},
  ///   // Pass the computeAttestorProof callback to the sdk. This can be optionally used to compute the witness proof externally.
  ///   // For example, we can use the Reclaim ZK Operator to compute the witness proof locally.
  ///   computeAttestorProof: (fnName, args) async {
  ///     // Get Reclaim ZK Operator instance and compute the witness proof.
  ///     return (await ReclaimZkOperator.getInstance())
  ///         .computeAttestorProof(fnName, args);
  ///   },
  ///   hideLanding: true,
  /// );
  /// ```
  ///
  /// Note: Use of `computeAttestorProof` could be disabled by default in the reclaim_flutter_sdk as this is still experimental.
  /// Read more about it in reclaim_flutter_sdk's README and reclaim_flutter_sdk/example's README.md.
  @override
  Future<String> computeAttestorProof(
    String fnName,
    List<dynamic> args, {
    void Function(ProverAlgorithmType?, PerformanceReport)? onPerformanceReport,
  }) async {
    final logger = Logger('reclaim_flutter_sdk.reclaim_gnark_zkoperator.computeAttestorProof.$fnName');

    final String response = await () async {
      switch (fnName) {
        case 'groth16Prove':
          final bytesInput = base64.decode(args[0]['value']);
          ProverAlgorithmType? algorithm;
          if (!_hasAllAlgorithmsInitialized) {
            algorithm = identifyAlgorithmFromZKOperationRequest(bytesInput);
            if (algorithm != null) {
              logger.finest('ensuring prover algorithm "$algorithm" is ready');
              // ensure algorithm is initialized
              await initializer.ensureInitialized(algorithm);
              logger.finest('prover algorithm "$algorithm" is ready');
            } else {
              logger.finest('no algorithm found in the zk operation request');
            }
          } else {
            logger.finest('all prover algorithms should be ready');
          }
          return groth16Prove(
            bytesInput,
            onPerformanceReport:
                onPerformanceReport == null
                    ? null
                    : (report) {
                      algorithm ??= identifyAlgorithmFromZKOperationRequest(bytesInput);
                      onPerformanceReport(algorithm, report);
                    },
          );
        case 'finaliseOPRF':
          final [serverPublicKey, request, responses] = args;
          final jsonString = json.encode(
            _replaceBase64Json({'serverPublicKey': serverPublicKey, 'request': request, 'responses': responses}),
          );
          final Uint8List bytesInput = utf8.encode(jsonString);
          final response = await finaliseOPRF(bytesInput);
          return json.encode(json.decode(response)['output']);
        case 'generateOPRFRequestData':
          final [data, domainSeparator] = args;
          final jsonString = json.encode(_replaceBase64Json({'data': data, 'domainSeparator': domainSeparator}));
          final Uint8List bytesInput = utf8.encode(jsonString);
          final response = await generateOPRFRequestData(bytesInput);
          return response;
        default:
          throw UnimplementedError('Function $fnName not implemented');
      }
    }();
    return _reformatJsonStringForRPC(response);
  }

  @override
  Future<String> groth16Prove(Uint8List bytes, {OnProofPerformanceReportCallback? onPerformanceReport}) async {
    final proveWorkerFuture = _proveWorkerFuture ??= _ProveWorker.spawn();
    final worker = await proveWorkerFuture;
    return worker.prove(bytes, onPerformanceReport: onPerformanceReport);
  }

  Future<_TOPRFFinalizeWorker>? _toprfFinalizeWorkerFuture;

  @override
  Future<String> finaliseOPRF(Uint8List bytes) async {
    final workerFuture = _toprfFinalizeWorkerFuture ??= _TOPRFFinalizeWorker.spawn();
    final worker = await workerFuture;
    return worker.toprfFinalize(bytes);
  }

  Future<_GenerateOPRFRequestDataWorker>? _generateOPRFRequestDataWorkerFuture;

  @override
  Future<String> generateOPRFRequestData(Uint8List bytes) async {
    final workerFuture = _generateOPRFRequestDataWorkerFuture ??= _GenerateOPRFRequestDataWorker.spawn();
    final worker = await workerFuture;
    return worker.generateOPRFRequestData(bytes);
  }

  @override
  Future<void> close() async {
    final proverWorkerFuture = _proveWorkerFuture;
    if (proverWorkerFuture != null) {
      (await proverWorkerFuture).close();
    }
  }
}
