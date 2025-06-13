import 'dart:typed_data';

import 'algorithm/algorithm.dart';
export 'algorithm/algorithm.dart' show ProverAlgorithmType;

/// {@template reclaim_gnark_zkoperator.ZkOperator}
/// A ZK Operator that can compute proofs and OPRF functions
/// for [Reclaim Protocol's Attestor](https://github.com/reclaimprotocol/attestor-core).
/// {@endtemplate}
abstract class ZkOperator {
  /// {@template reclaim_gnark_zkoperator.ZkOperator.computeAttestorProof}
  /// Computes an attestor proof for the given zk or oprf functions by name and arguments.
  ///
  /// The function name must be one of the following:
  /// - `groth16Prove`
  /// - `finaliseOPRF`
  /// - `generateOPRFRequestData`
  ///
  /// {@endtemplate}
  Future<String> computeAttestorProof(String fnName, List<dynamic> args);

  /// {@template reclaim_gnark_zkoperator.ZkOperator.getAlgorithmFromOperationRequest}
  /// Gets the algorithm type required for the operation if it can be identified from the operation request.
  /// {@endtemplate}
  ProverAlgorithmType? getAlgorithmFromOperationRequest(String fnName, List<dynamic> args);

  /// {@template reclaim_gnark_zkoperator.ZkOperator.ensureInitialized}
  /// Ensures that the [algorithm] is initialized and completes with `true` if successful.
  /// {@endtemplate}
  Future<bool> ensureInitialized(ProverAlgorithmType algorithm);

  /// {@template reclaim_gnark_zkoperator.ZkOperator.groth16Prove}
  /// Computes a Groth16 proof for the given bytes.
  /// {@endtemplate}
  Future<String> groth16Prove(Uint8List bytes);

  /// {@template reclaim_gnark_zkoperator.ZkOperator.finaliseOPRF}
  /// Finalises an OPRF request for the given bytes.
  /// {@endtemplate}
  Future<String> finaliseOPRF(Uint8List bytes);

  /// {@template reclaim_gnark_zkoperator.ZkOperator.generateOPRFRequestData}
  /// Generates an OPRF request data for the given bytes.
  /// {@endtemplate}
  Future<String> generateOPRFRequestData(Uint8List bytes);

  /// {@template reclaim_gnark_zkoperator.ZkOperator.close}
  /// Disposes of the ZK Operator by closing the worker.
  ///
  /// This method should be called when the ZK Operator is no longer needed to free up resources.
  /// {@endtemplate}
  Future<void> close();
}
