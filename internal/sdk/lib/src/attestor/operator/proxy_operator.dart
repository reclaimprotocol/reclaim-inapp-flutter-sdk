import 'dart:async';

import 'package:reclaim_tee_operator_flutter/reclaim_tee_operator_flutter.dart';

import '../../utils/provider_performance_report.dart';

typedef OnZKComputePerformanceReportCallback = FutureOr<void> Function(ZKComputePerformanceReport report);

/// Defines an interface for zero-knowledge operations in the attestation process.
///
/// Implementations of this class provide the ability to check support for operations,
/// determine readiness, and compute results for zero-knowledge proofs.
///
/// Unified operator adapter that wraps ReclaimZkOperator (proxy mode)
/// behind the AttestorZkOperator interface.
///
/// Note: TEE mode doesn't use this adapter - it uses the native TEE client directly.
class AttestorReclaimProxyOperator {
  const AttestorReclaimProxyOperator._();

  static const AttestorReclaimProxyOperator instance = AttestorReclaimProxyOperator._();

  /// Checks if the specified function is supported with the given arguments.
  ///
  /// Returns `true` if the function is supported, `false` otherwise.
  FutureOr<bool> isSupported(String fnName, Object? args) {
    // Both operators support the same functions
    const supportedFunctions = {'groth16Prove', 'finaliseOPRF', 'generateOPRFRequestData'};
    return supportedFunctions.contains(fnName);
  }

  /// Computes the result of the specified function with the given arguments.
  ///
  /// Returns a string representation of the computation result.
  FutureOr<String> compute(String fnName, List args, OnZKComputePerformanceReportCallback onPerformanceReport) async {
    // Get algorithm from request if available
    ProverAlgorithmType? algorithm;
    if (fnName == 'groth16Prove' && args.isNotEmpty) {
      algorithm = ReclaimProxyOperator.instance.getAlgorithmFromOperationRequest(fnName, args);
    }

    // Compute with performance tracking
    final result = await ReclaimProxyOperator.instance.computeAttestorProof(
      fnName,
      args,
      onPerformanceReport: algorithm != null
          ? (alg, report) {
              onPerformanceReport(ZKComputePerformanceReport(algorithmName: alg?.name ?? 'unknown', report: report));
            }
          : null,
    );

    return result;
  }

  /// Checks if the runtime platform is supported for the operator.
  ///
  /// Returns `true` if the platform is supported, `false` otherwise.
  Future<bool> isPlatformSupported() async {
    return ReclaimProxyOperator.instance.isPlatformSupported();
  }
}
