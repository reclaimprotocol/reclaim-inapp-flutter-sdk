import 'dart:collection';
import 'dart:math'
    as math;

import 'package:flutter/material.dart';
import '../../logging/logging.dart';
import '../../reclaim_flutter_sdk.dart';
import '../../utils/chains/me_chain.dart';
import '../../utils/params.dart';
import 'claim_creation.dart';

class ClaimCreationErrorDetails {
  final Object?
      error;
  final StackTrace?
      stackTrace;
  final String?
      reason;
  final String?
      humanReadableReason;

  const ClaimCreationErrorDetails({
    this.error,
    this.stackTrace,
    this.reason,
    this.humanReadableReason,
  });
}

class ClaimStatus {
  final ClaimCreationRequest
      request;
  final ClaimCreationErrorDetails?
      error;
  final Map?
      stepInformation;
  final List<CreateClaimOutput>?
      proofs;
  final ProviderRequestPerformanceReport?
      performanceReports;
  final ClaimStatus?
      previousStatus;
  final DateTime
      creationDate;
  final double
      attestorLoadingProgress;

  const ClaimStatus({
    required this.request,
    required this.error,
    required this.stepInformation,
    required this.proofs,
    required this.performanceReports,
    required this.previousStatus,
    required this.creationDate,
    required this.attestorLoadingProgress,
  });

  ClaimStatus.create(
      this.request)
      : error = null,
        stepInformation = null,
        proofs = null,
        performanceReports = null,
        previousStatus = null,
        creationDate = DateTime.now(),
        attestorLoadingProgress = 0.0;

  ClaimStatus
      createNext({
    ClaimCreationErrorDetails?
        error,
    Map?
        stepInformation,
    List<CreateClaimOutput>?
        proofs,
    ProviderRequestPerformanceReport?
        performanceReports,
    double?
        attestorLoadingProgress,
  }) {
    return ClaimStatus(
      request:
          request,
      creationDate:
          creationDate,
      previousStatus:
          this,
      error:
          error ?? this.error,
      stepInformation:
          stepInformation ?? this.stepInformation,
      proofs:
          proofs ?? this.proofs,
      performanceReports:
          performanceReports ?? this.performanceReports,
      attestorLoadingProgress: (stepInformation != null && stepInformation.isNotEmpty)
          ? 1.0
          : attestorLoadingProgress ?? this.attestorLoadingProgress,
    );
  }

  ClaimRequestIdentifier get requestIdentifier => request
      .requestData
      .requestIdentifier;

  bool
      get isComputingProofs {
    if (proofs !=
        null)
      return false;

    final step =
        stepInformation;
    return step != null &&
        step.isNotEmpty;
  }

  double?
      get _currentStepProgress {
    final step =
        stepInformation?['step'];
    if (step ==
        null)
      return null;
    if (isMeChainStep(
        step['type'])) {
      return getMeChainProgress(step['type']);
    }
    final stepName =
        step?["name"];
    if (stepName !=
        'witness-progress')
      return null;
    final info =
        step?['step'];
    final infoName =
        info?['name'];
    switch (
        infoName) {
      case 'connecting':
        return 0.04;
      case 'sending-request-data':
        return 0.08;
      case 'waiting-for-response':
        return 0.16;
      case 'generating-zk-proofs':
        try {
          final done = info?['proofsDone'] ?? 0;
          final total = info?['proofsTotal'] ?? 10;
          final progress = done / total;
          return Tween<double>(begin: 0.3, end: 0.9).transform(progress);
        } catch (e, s) {
          logging.child('ClaimStatus.currentProgress').severe('Failed to compute progress', e, s);
          return null;
        }
      case 'waiting-for-verification':
        return 0.95;
      default:
        return null;
    }
  }

  double
      get _currentProgress {
    final stepProgress = _currentStepProgress ??
        previousStatus?._currentStepProgress ??
        0.0;
    final attestorProgress =
        attestorLoadingProgress;

    return (stepProgress * 0.9) +
        (attestorProgress * 0.1);
  }

  /// The progress of the proof computation.
  /// If this is null, that means proof computation hasn't started
  double
      get progress {
    final effectiveProgress =
        _currentProgress;
    assert(
        () {
      if (effectiveProgress <=
          0.2) {
        final logger = logging.child('ClaimStatus.progress');
        logger.info({
          'reason': 'effectiveProgress is less than 0.2',
          'stepInformation': stepInformation,
        });
      }
      return true;
    }());

    return effectiveProgress;
  }

  ClaimStatus
      copyWith({
    ClaimCreationRequest?
        request,
    ClaimCreationErrorDetails?
        error,
    Map<dynamic, dynamic>?
        stepInformation,
    List<CreateClaimOutput>?
        proofs,
    ClaimStatus?
        previousStatus,
    double?
        attestorLoadingProgress,
    ProviderRequestPerformanceReport?
        performanceReports,
  }) {
    return ClaimStatus(
      request:
          request ?? this.request,
      error:
          error ?? this.error,
      stepInformation:
          stepInformation ?? this.stepInformation,
      proofs:
          proofs ?? this.proofs,
      previousStatus:
          previousStatus ?? this.previousStatus,
      creationDate:
          creationDate,
      attestorLoadingProgress:
          attestorLoadingProgress ?? this.attestorLoadingProgress,
      performanceReports:
          performanceReports ?? this.performanceReports,
    );
  }
}

typedef ClaimRequestIdentifier
    = String;

@immutable
class ClaimCreationControllerState {
  final ClaimCreationUIDelegate?
      delegate;
  final Map<
      ClaimRequestIdentifier,
      ClaimStatus> claimsByRequest;
  final Object?
      publicData;
  final HttpProvider
      httpProvider;
  final ClaimCreationStatus
      status;
  final bool
      hasRequestedRetry;
  final bool
      didNotifySessionAsRetry;
  final bool
      canExpectManyClaims;
  final ReclaimVerificationProviderException?
      providerError;

  const ClaimCreationControllerState({
    required this.httpProvider,
    this.delegate,
    this.publicData,
    this.claimsByRequest =
        const {},
    this.status =
        ClaimCreationStatus.ready,
    this.hasRequestedRetry =
        false,
    this.didNotifySessionAsRetry =
        false,
    this.providerError,
    this.canExpectManyClaims =
        false,
  });

  int get _maxExpectedClaims {
    return math
        .max(
      // Expect atleast 1 claim.
      // Http provider requests can be empty if all claims may be triggered by other means like provider script requests.
      1,
      httpProvider.requestData.length,
    );
  }

  Iterable<ClaimStatus> get claims => claimsByRequest
      .values
      .toList()
    ..sort((a, b) => a
        .creationDate
        .compareTo(b.creationDate));

  bool get isIdle =>
      claimsByRequest.isEmpty;

  bool
      get isIncomplete {
    if (canExpectManyClaims)
      return true;
    return _maxExpectedClaims >
        claimsByRequest.length;
  }

  bool
      get isWaitingForContinuation {
    return !isComputingProofs &&
        isIncomplete;
  }

  bool
      get isComputingProofs {
    return claimsByRequest
        .values
        .any((status) {
      return status.isComputingProofs;
    });
  }

  bool
      get hasVerifiedAtleastOneClaim {
    return claimsByRequest.values.any((status) =>
        status.proofs !=
        null);
  }

  bool
      get isFinished {
    return claimsByRequest.values.every((status) => status.proofs != null) &&
        !isIncomplete;
  }

  bool
      get hasError {
    if (providerError !=
        null) {
      return true;
    }
    return claimsByRequest
        .values
        .any((status) {
      return status.error !=
          null;
    });
  }

  double?
      get progress {
    if (isIdle)
      return null;
    if (isFinished)
      return 1.0;
    final progressSum = claimsByRequest.values.fold(
        0.0,
        (a, b) {
      return a +
          b.progress;
    });

    return progressSum /
        claimsByRequest.length;
  }

  Map<String,
          double>
      get paramsProgress {
    return claimsByRequest.values.map((status) {
          final paramNames = paramNamesFromRequestData([
            status.request.requestData,
          ]);
          final progress = status.progress;
          return attachProgressToParams(paramNames, progress);
        }).fold(<String, double>{}, (prev, next) {
          return {
            ...?prev,
            ...next
          };
        }) ??
        {};
  }

  Iterable<ClaimStatus>
      get finishedRequests {
    return claimsByRequest.values.where((status) =>
        status.proofs !=
        null);
  }

  bool isCompleted(
      ClaimRequestIdentifier
          requestIdentifier) {
    final completedRequestIdentifiers = finishedRequests
        .map((e) => e.requestIdentifier)
        .toSet();
    return completedRequestIdentifiers
        .contains(requestIdentifier);
  }

  ClaimStatus?
      getCompletedRequestBy(ClaimRequestIdentifier requestIdentifier) {
    for (final request
        in finishedRequests) {
      if (request.requestIdentifier ==
          requestIdentifier) {
        return request;
      }
    }
    return null;
  }

  Iterable<ClaimStatus>
      get erroredRequests {
    return claimsByRequest.values.where((status) =>
        status.error !=
        null);
  }

  int get totalCount {
    return claimsByRequest
        .length;
  }

  ClaimStatus?
      maybeGet(ClaimRequestIdentifier requestIdentifier) {
    return claimsByRequest[
        requestIdentifier];
  }

  ClaimStatus
      get(ClaimRequestIdentifier requestIdentifier) {
    return maybeGet(
        requestIdentifier)!;
  }

  ClaimCreationControllerState
      copyWithStatus(ClaimStatus status) {
    return copyWith(
      claimsByRequest:
          UnmodifiableMapView({
        ...claimsByRequest,
        status.requestIdentifier: status,
      }),
    );
  }

  bool get inProgressOrCompleted =>
      isComputingProofs ||
      isFinished;

  ClaimCreationControllerState
      copyWith({
    HttpProvider?
        httpProvider,
    ClaimCreationUIDelegate?
        delegate,
    Map<ClaimRequestIdentifier, ClaimStatus>?
        claimsByRequest,
    ClaimCreationStatus?
        status,
    Object?
        publicData,
    bool?
        didNotifySessionAsRetry,
    bool?
        canExpectManyClaims,
    ReclaimVerificationProviderException?
        providerError,
  }) {
    return ClaimCreationControllerState(
      httpProvider:
          httpProvider ?? this.httpProvider,
      delegate:
          delegate ?? this.delegate,
      claimsByRequest:
          claimsByRequest ?? this.claimsByRequest,
      status:
          status ?? this.status,
      publicData:
          publicData ?? this.publicData,
      // once status is set to retryRequested, then hasRequestedRetry should always be true afterwards for any other status changes
      hasRequestedRetry:
          hasRequestedRetry || status == ClaimCreationStatus.retryRequested,
      didNotifySessionAsRetry:
          didNotifySessionAsRetry ?? this.didNotifySessionAsRetry,
      canExpectManyClaims:
          canExpectManyClaims ?? this.canExpectManyClaims,
      providerError:
          providerError ?? this.providerError,
    );
  }
}
