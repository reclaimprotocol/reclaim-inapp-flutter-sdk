import 'dart:async';
import 'dart:typed_data';

import 'package:measure_performance/measure_performance.dart';
import 'package:reclaim_tee_operator_flutter/src/common/exceptions.dart';

import '../common/utils/platform.dart' as platform;

import '../tee/models/claim.dart';
import '../tee/models/client_options.dart';
import '../tee/models/request_data.dart';
import 'algorithm/algorithm.dart';

typedef OnProofPerformanceReportCallback = void Function(PerformanceReport);

/// {@template reclaim_tee_operator.BaseOperator}
/// Base interface for Operators that defines minimal required functionality.
///
/// This interface is implemented by both GNARK (proxy mode) and TEE (native mode) operators.
/// Each operator may provide different levels of functionality based on their mode.
/// {@endtemplate}
abstract class BaseOperator {
  /// {@template reclaim_tee_operator.BaseOperator.isPlatformSupported}
  /// Checks if the platform is supported for the ZK Operator.
  /// {@endtemplate}
  bool isPlatformSupported() {
    return platform.isPlatformSupported();
  }
}

/// {@template reclaim_tee_operator.ZkOperator}
/// Extended ZK Operator interface for proxy mode operations (GNARK).
///
/// This interface includes OPRF and proof computation methods required
/// for proxy mode attestation. TEE operators don't need these methods
/// as the native library handles them internally.
/// {@endtemplate}
abstract class ReclaimProxyOperatorBase extends BaseOperator {
  /// {@template reclaim_tee_operator.ZkOperator.computeAttestorProof}
  /// Computes an attestor proof for the given zk or oprf functions by name and arguments.
  ///
  /// The function name must be one of the following:
  /// - `groth16Prove`
  /// - `finaliseOPRF`
  /// - `generateOPRFRequestData`
  ///
  /// This method is primarily used in proxy mode (GNARK operator).
  /// {@endtemplate}
  Future<String> computeAttestorProof(
    String fnName,
    List<dynamic> args, {
    void Function(ProverAlgorithmType?, PerformanceReport)? onPerformanceReport,
  });

  /// {@template reclaim_tee_operator.ZkOperator.getAlgorithmFromOperationRequest}
  /// Gets the algorithm type required for the operation if it can be identified from the operation request.
  /// {@endtemplate}
  ProverAlgorithmType? getAlgorithmFromOperationRequest(String fnName, List<dynamic> args);

  /// {@template reclaim_tee_operator.ZkOperator.groth16Prove}
  /// Computes a Groth16 proof for the given bytes.
  ///
  /// This method is used in proxy mode (GNARK operator).
  /// {@endtemplate}
  Future<String> groth16Prove(Uint8List bytes, {OnProofPerformanceReportCallback? onPerformanceReport});

  /// {@template reclaim_tee_operator.ZkOperator.finaliseOPRF}
  /// Finalises an OPRF request for the given bytes.
  ///
  /// This method is used in proxy mode (GNARK operator).
  /// {@endtemplate}
  Future<String> finaliseOPRF(Uint8List bytes);

  /// {@template reclaim_tee_operator.ZkOperator.generateOPRFRequestData}
  /// Generates an OPRF request data for the given bytes.
  ///
  /// This method is used in proxy mode (GNARK operator).
  /// {@endtemplate}
  Future<String> generateOPRFRequestData(Uint8List bytes);
}

abstract class ReclaimTEEOperatorBase extends BaseOperator {
  /// Get the library version
  /// Uses background worker to avoid blocking main thread
  Future<String> getVersion();

  /// Execute a complete HTTP request using the TEE protocol and get a claim
  /// Uses background worker to avoid blocking main thread
  ///
  /// Throws [ReclaimProofGenerationException] if proof generation fails
  /// Throws [ReclaimNetworkException] if network communication fails
  /// Throws [ReclaimOperatorException] for other TEE operation errors
  Future<TEEExecutionResult> executeRequest(
    ReclaimRequestData requestData,
    ClaimCreationClientOptions? clientOptions, {
    String? requestId,
  });

  /// Extract JSON value indexes using TEE operator
  Future<List<Map<String, int>>> extractJSONValueIndexes(String jsonString, String jsonPath);

  /// Extract HTML element indexes using TEE operator
  Future<List<Map<String, int>>> extractHTMLElementIndexes(String html, String xpath, {bool contentsOnly = false});
}

/// Result of successful TEE execution
/// Contains the generated claim, signatures, and performance metrics
class TEEExecutionResult {
  final ReclaimClaim claim;
  final List<Map<String, String>> signatures;
  final PerformanceReport? performanceReport;

  const TEEExecutionResult({required this.claim, required this.signatures, this.performanceReport});
}
