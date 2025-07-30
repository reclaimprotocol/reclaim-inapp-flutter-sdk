import 'dart:async';

import 'operator.dart';

/// {@template ComputeProofForAttestorCallback}
/// A callback that will be used by the [AttestorWebViewClient] to compute proof.
///
/// If this is null, the default prover is used.
/// {@endtemplate}
typedef ComputeProofForAttestorCallback =
    FutureOr<String> Function(
      String fnName,
      List<dynamic> args,
      OnZKComputePerformanceReportCallback onPerformanceReport,
    );

typedef IsSupportedByAttestorCallback = FutureOr<bool> Function(String fnName, Object? args);
typedef IsPlatformSupportedCallback = FutureOr<bool> Function();

class AttestorZkOperatorWithCallback implements AttestorZkOperator {
  final ComputeProofForAttestorCallback _onComputeProof;
  final IsSupportedByAttestorCallback _onIsSupported;
  final IsPlatformSupportedCallback _isPlatformSupported;

  const AttestorZkOperatorWithCallback({
    required ComputeProofForAttestorCallback onComputeProof,
    required IsSupportedByAttestorCallback onIsSupported,
    required IsPlatformSupportedCallback isPlatformSupported,
  }) : _onIsSupported = onIsSupported,
       _onComputeProof = onComputeProof,
       _isPlatformSupported = isPlatformSupported;

  @override
  FutureOr<String> compute(String fnName, List args, OnZKComputePerformanceReportCallback onPerformanceReport) {
    return _onComputeProof(fnName, args, onPerformanceReport);
  }

  @override
  FutureOr<bool> isSupported(String fnName, Object? args) {
    return _onIsSupported(fnName, args);
  }

  factory AttestorZkOperatorWithCallback.withReclaimZKOperator({
    required ComputeProofForAttestorCallback onComputeProof,
    required IsPlatformSupportedCallback isPlatformSupported,
  }) {
    return AttestorZkOperatorWithCallback(
      onComputeProof: onComputeProof,
      onIsSupported: (fnName, _) {
        const supportedFunctions = {'groth16Prove', 'finaliseOPRF', 'generateOPRFRequestData'};
        return supportedFunctions.contains(fnName);
      },
      isPlatformSupported: isPlatformSupported,
    );
  }

  @override
  Future<bool> isPlatformSupported() async {
    return _isPlatformSupported();
  }
}
