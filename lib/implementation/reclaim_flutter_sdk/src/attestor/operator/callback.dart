import 'dart:async';

import 'operator.dart';

/// {@template ComputeProofForAttestorCallback}
/// A callback that will be used by the [AttestorWebViewClient] to compute proof.
///
/// If this is null, the default prover is used.
/// {@endtemplate}
typedef ComputeProofForAttestorCallback
    = FutureOr<String>
        Function(
  String
      fnName,
  List<dynamic>
      args,
  OnZKComputePerformanceReportCallback
      onPerformanceReport,
);

typedef IsReadyForAttestorCallback = FutureOr<bool> Function(
    String
        fnName,
    List<dynamic>
        args);
typedef IsSupportedByAttestorCallback = FutureOr<bool> Function(
    String
        fnName,
    Object?
        args);

class CallbackAttestorZkOperator
    implements
        AttestorZkOperator {
  final ComputeProofForAttestorCallback
      _onComputeProof;
  final IsSupportedByAttestorCallback
      _onIsSupported;

  const CallbackAttestorZkOperator({
    required ComputeProofForAttestorCallback
        onComputeProof,
    required IsSupportedByAttestorCallback
        onIsSupported,
  })  : _onIsSupported = onIsSupported,
        _onComputeProof = onComputeProof;

  @override
  FutureOr<String>
      compute(
    String
        fnName,
    List
        args,
    OnZKComputePerformanceReportCallback
        onPerformanceReport,
  ) {
    return _onComputeProof(
        fnName,
        args,
        onPerformanceReport);
  }

  @override
  FutureOr<bool> isSupported(
      String
          fnName,
      Object?
          args) {
    return _onIsSupported(
        fnName,
        args);
  }

  factory CallbackAttestorZkOperator.withComputeProof(
    ComputeProofForAttestorCallback
        onComputeProof,
  ) {
    return CallbackAttestorZkOperator(
      onComputeProof:
          onComputeProof,
      onIsSupported:
          (fnName, _) {
        const supportedFunctions = {
          'groth16Prove',
          'finaliseOPRF',
          'generateOPRFRequestData',
        };
        return supportedFunctions.contains(fnName);
      },
    );
  }
}
