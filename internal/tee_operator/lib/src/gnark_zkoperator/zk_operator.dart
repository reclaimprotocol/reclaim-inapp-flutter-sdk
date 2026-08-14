import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:measure_performance/measure_performance.dart';

import '../common/algorithm/algorithm.dart';
import '../common/algorithm/utils.dart';
import '../common/operator_interface.dart';
import '../common/worker/isolate_worker/isolate_worker.dart';
import '../common/worker/oprf/finalize.dart';
import '../common/worker/oprf/generate_request.dart';
import '../common/worker/prover.dart';
import '../common/algorithm_initializer.dart';
import 'json_preprocessing.dart';

final _logger = Logger('reclaim_inapp_sdk.reclaim_tee_operator.gnark');

/// {@macro reclaim_tee_operator.ZkOperator}
///
/// The main class for interacting with the GNARK prover and Reclaim Attestor Browser RPC.
/// This class provides methods to initialize the prover and compute witness proofs using GNARK algorithms.
///
/// This operator uses the unified libreclaim.so native library (same as TEE operator) but provides
/// GNARK-style initialization and preprocessing for proxy mode operations.
class ReclaimProxyOperator extends ReclaimProxyOperatorBase {
  ReclaimProxyOperator._() {
    // Ensure prover algorithms is used atleast once to setup lazy initialization.
    ProverAlgorithmInitializer.instance;
  }

  /// Returns a singleton instance of [ReclaimProxyOperator].
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
  /// [ProverAlgorithmInitializer.ensureInitialized] with the algorithm type.
  static ReclaimProxyOperator instance = ReclaimProxyOperator._();

  Future<BackgroundWorker<Uint8List, ProofResult>>? _proveWorkerFuture;

  /// Computes the witness proof for the given bytes.
  ///
  /// The `fnName` parameter should be the name of the zk or oprf functions supported by the prover.
  /// The `args` parameter should be the arguments for the function.
  @override
  Future<String> computeAttestorProof(
    String fnName,
    List<dynamic> args, {
    void Function(ProverAlgorithmType?, PerformanceReport)? onPerformanceReport,
  }) async {
    final logger = Logger('reclaim_inapp_sdk.reclaim_tee_operator.gnark.computeAttestorProof.$fnName');

    final String response = await () async {
      switch (fnName) {
        case 'groth16Prove':
          final bytesInput = base64.decode(args[0]['value']);
          final algorithm = identifyAlgorithmFromZKOperationRequest(bytesInput);
          if (!hasAllAlgorithmsInitialized) {
            if (algorithm != null) {
              logger.info('ensuring prover algorithm "$algorithm" is ready');
              // ensure algorithm is initialized
              await ProverAlgorithmInitializer.instance.ensureInitialized(algorithm);
              logger.info('prover algorithm "$algorithm" is ready');
            } else {
              logger.warning('no algorithm found in the zk operation request');
            }
          } else {
            logger.info('all prover algorithms should be ready');
          }
          logger.info('computing groth16Prove for algorithm "$algorithm"');
          return groth16Prove(
            bytesInput,
            onPerformanceReport: onPerformanceReport == null
                ? null
                : (report) {
                    onPerformanceReport(algorithm, report);
                  },
          );
        case 'finaliseOPRF':
          final [serverPublicKey, request, responses] = args;
          final jsonString = json.encode(
            replaceBase64Json({'serverPublicKey': serverPublicKey, 'request': request, 'responses': responses}),
          );
          final Uint8List bytesInput = utf8.encode(jsonString);
          final response = await finaliseOPRF(bytesInput);
          return json.encode(json.decode(response)['output']);
        case 'generateOPRFRequestData':
          final [data, domainSeparator] = args;
          final jsonString = json.encode(replaceBase64Json({'data': data, 'domainSeparator': domainSeparator}));
          final Uint8List bytesInput = utf8.encode(jsonString);
          final response = await generateOPRFRequestData(bytesInput);
          return response;
        default:
          throw UnimplementedError('Function $fnName not implemented');
      }
    }();
    return reformatJsonStringForRPC(response);
  }

  @override
  ProverAlgorithmType? getAlgorithmFromOperationRequest(String fnName, List<dynamic> args) {
    try {
      switch (fnName) {
        case 'groth16Prove':
          final bytesInput = base64.decode(args[0]['value']);
          return identifyAlgorithmFromZKOperationRequest(bytesInput);
      }
    } catch (e, s) {
      _logger.warning('Failed to get algorithm from operation request', e, s);
    }
    return null;
  }

  @override
  Future<String> groth16Prove(Uint8List bytes, {OnProofPerformanceReportCallback? onPerformanceReport}) async {
    final proveWorkerFuture = _proveWorkerFuture ??= const WorkerManager(ProveRunnable()).createWorker();
    final worker = await proveWorkerFuture;
    final result = await worker.executeInBackground(bytes);
    onPerformanceReport?.call(result.$2);
    return result.$1;
  }

  Future<BackgroundWorker<Uint8List, String>>? _toprfFinalizeWorkerFuture;

  @override
  Future<String> finaliseOPRF(Uint8List bytes) async {
    final workerFuture = _toprfFinalizeWorkerFuture ??= const WorkerManager(TOPRFFinalizeRunnable()).createWorker();
    final worker = await workerFuture;
    return worker.executeInBackground(bytes);
  }

  Future<BackgroundWorker<Uint8List, String>>? _generateOPRFRequestDataWorkerFuture;

  @override
  Future<String> generateOPRFRequestData(Uint8List bytes) async {
    final workerFuture = _generateOPRFRequestDataWorkerFuture ??= const WorkerManager(GenerateOPRFRequestDataRunnable())
        .createWorker();
    final worker = await workerFuture;
    return worker.executeInBackground(bytes);
  }
}
