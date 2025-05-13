import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:reclaim_flutter_sdk/attestor.dart';
import 'package:reclaim_flutter_sdk/constants.dart';
import 'package:reclaim_flutter_sdk/data/providers.dart';
import 'package:reclaim_flutter_sdk/exception/exception.dart';
import 'package:reclaim_flutter_sdk/logging/logging.dart';
import 'package:reclaim_flutter_sdk/src/utils/provider_performance_report.dart';
import 'package:reclaim_flutter_sdk/utils/keys.dart';
import 'package:reclaim_flutter_sdk/types/create_claim.dart';
import 'package:reclaim_flutter_sdk/utils/future.dart';
import 'package:reclaim_flutter_sdk/utils/session.dart';
import 'package:reclaim_flutter_sdk/utils/single_work.dart';
import 'package:reclaim_flutter_sdk/webview_utils.dart';
import 'package:reclaim_flutter_sdk/widgets/claim_creation/bottom_sheet.dart';

import 'inherited_provider.dart';
import 'request.dart';
import 'state.dart';
import 'status.dart';
import 'trigger_indicator.dart' show ClaimTriggerIndicatorController;

export 'request.dart';
export 'inherited_provider.dart';
export 'status.dart';
export 'state.dart';

part 'delegate.dart';

const _claimCreationTimeoutDuration = Duration(minutes: 15);

class ClaimCreationController
    extends ValueNotifier<ClaimCreationControllerState> {
  static ClaimCreationController? _lastInstance;

  static ClaimCreationController? get lastInstance => _lastInstance;

  ClaimCreationController({required HttpProvider httpProvider})
    : super(ClaimCreationControllerState(httpProvider: httpProvider)) {
    _lastInstance = this;
  }

  /// Returns the nearest [ClaimCreationController] controller to the given context.
  ///
  /// If the context is not a descendant of a [ClaimCreationControllerProvider],
  /// it will return null.
  ///
  /// If the context is a descendant of a [ClaimCreationControllerProvider],
  /// it will return the [ClaimCreationController] controller.
  ///
  /// * [of], which is similar to this function, but will throw an exception if
  ///   it doesn't find a [ClaimCreationController] controller, instead of returning null.
  static ClaimCreationController? maybeOf(
    BuildContext context, {
    bool listen = true,
  }) {
    if (listen) {
      return context
          .dependOnInheritedWidgetOfExactType<ClaimCreationControllerProvider>()
          ?.controller;
    }
    return context
        .getInheritedWidgetOfExactType<ClaimCreationControllerProvider>()
        ?.controller;
  }

  /// Returns the nearest [ClaimCreationController] controller to the given context.
  ///
  /// If the context is not a descendant of a [ClaimCreationControllerProvider],
  /// it will throw an exception.
  ///
  /// If the context is a descendant of a [ClaimCreationControllerProvider],
  /// it will return the [ClaimCreationController] controller.
  ///
  /// * [maybeOf], which is similar to this function, but will return null if
  ///   it doesn't find a [ClaimCreationController] controller.
  static ClaimCreationController of(
    BuildContext context, {
    bool listen = true,
  }) {
    final controller = maybeOf(context, listen: listen);
    assert(() {
      if (controller == null) {
        throw FlutterError(
          'ClaimCreationController.of() was called with a context that does not contain a ClaimCreationControllerProvider widget.\n'
          'No ClaimCreationControllerProvider widget ancestor could be found starting from the context that was passed to '
          'ClaimCreationController.of(). This can happen because you are using a widget that looks for a ClaimCreationController '
          'ancestor, and do not have a ClaimCreationControllerProvider widget descendant in the nearest FocusScope.\n'
          'The context used was:\n'
          '  $context',
        );
      }
      return true;
    }());
    return controller!;
  }

  void setPublicData(Object? publicData) {
    value = value.copyWith(publicData: publicData);
  }

  void canExpectManyClaims(bool canExpectManyClaims) {
    value = value.copyWith(canExpectManyClaims: canExpectManyClaims);
  }

  void setProviderError(Map<String, dynamic> error) {
    value = value.copyWith(
      providerError: ReclaimVerificationProviderException(
        error['message'] ?? 'Verification failed',
        error,
      ),
    );
    value.delegate!._showBottomSheet();
    claimTriggerIndicatorController.notifyError();
  }

  void _setDelegate(ClaimCreationUIDelegate? delegate) {
    value = value.copyWith(delegate: delegate);
  }

  ClaimTriggerIndicatorController get claimTriggerIndicatorController =>
      value.delegate!._claimTriggerIndicatorController;

  void requestRetry() {
    value = value.copyWith(
      status: ClaimCreationStatus.retryRequested,
      claimsByRequest: const {},
    );
    value = value.copyWith(status: ClaimCreationStatus.ready);
  }

  Future<void> _onProofGenerationStarted(String sessionId) async {
    final isFirstClaim = value.totalCount <= 1;
    if (isFirstClaim) {
      if (value.hasRequestedRetry) {
        if (!value.didNotifySessionAsRetry) {
          unawaitedSequence([
            ReclaimSession.updateSession(
              sessionId,
              SessionStatus.PROOF_GENERATION_RETRY,
            ),
          ]);
          value = value.copyWith(didNotifySessionAsRetry: true);
        }
      } else {
        unawaitedSequence([
          ReclaimSession.updateSession(
            sessionId,
            SessionStatus.PROOF_GENERATION_STARTED,
          ),
        ]);
      }
    }
  }

  Future<void> _onProofGenerated(
    List<CreateClaimOutput> generatedProof,
    ClaimCreationRequest proofRequest,
    ProviderRequestPerformanceReport? performanceReports,
  ) async {
    final logger = logging.child('ClaimCreationController._onProofGenerated');
    final sessionId = proofRequest.sessionId;
    final httpProviderId = proofRequest.httpProviderId;

    final claimStatus = value
        .maybeGet(proofRequest.requestData.requestIdentifier)
        ?.createNext(
          proofs: generatedProof,
          performanceReports: performanceReports,
          error: null,
        );

    if (claimStatus != null) {
      value = value.copyWithStatus(claimStatus);
    } else {
      logger.severe(
        'No claim status found for request id: ${proofRequest.requestData.requestIdentifier}',
      );
    }

    if (value.isFinished) {
      if (kDebugMode) {
        logger.info({
          'proofs': json.encode(value.claims.map((e) => e.proofs).toList()),
        });
      }
      unawaitedSequence([
        ReclaimSession.sendLogs(
          appId: proofRequest.appId,
          sessionId: sessionId,
          providerId: httpProviderId,
          logType: 'PROOF_GENERATED',
          metadata:
              ProviderRequestPerformanceMeasurements(
                reports:
                    value.claims
                        .map((e) => e.performanceReports)
                        .whereType<ProviderRequestPerformanceReport>(),
              ).toJson(),
        ),
        ReclaimSession.updateSession(
          sessionId,
          SessionStatus.PROOF_GENERATION_SUCCESS,
        ),
      ]);
    }

    logger.info({'generatedProof': generatedProof});
  }

  Future<void> _onProofGenerationFailed(
    Object e,
    StackTrace s,
    ClaimCreationRequest proofRequest,
  ) async {
    final logger = logging.child(
      'ClaimCreationController._onProofGenerationFailed',
    );
    final sessionId = proofRequest.sessionId;
    final httpProviderId = proofRequest.httpProviderId;

    unawaitedSequence([
      ReclaimSession.sendLogs(
        appId: proofRequest.appId,
        sessionId: sessionId,
        providerId: httpProviderId,
        logType: 'ERROR',
      ),
      ReclaimSession.updateSession(
        sessionId,
        SessionStatus.PROOF_GENERATION_FAILED,
        metadata: {
          'failing_request': proofRequest.requestData.toJson(),
        },
      ),
    ]);
    logger.severe(
      'proof generation failed error at ${StackTrace.current}',
      e,
      s,
    );
    final claimStatus = value
        .maybeGet(proofRequest.requestData.requestIdentifier)
        ?.createNext(error: ClaimCreationErrorDetails(error: e, stackTrace: s));
    value = value.copyWith(
      // need to notify session as retry when proof generation fails
      didNotifySessionAsRetry: false,
    );
    if (claimStatus != null) {
      value = value.copyWithStatus(claimStatus);
    } else {
      logger.severe(
        'No claim status found for request id: ${proofRequest.requestData.requestIdentifier}',
      );
    }
  }

  Future<ClaimCreationRequest> createRequestWithUpdatedProviderParams(
    String response,
    ClaimCreationRequest request,
  ) async {
    // final responseSelections = request.providerData.responseSelections;
    // a copy of witnessParams to avoid mutating the original
    final params = {...request.witnessParams};

    final logger = logging.child(
      'ClaimCreationController.createRequestWithUpdatedProviderParams.${request.requestData.requestIdentifier}',
    );
    final Iterable<ResponseMatch> responseMatches =
        request.requestData.responseMatches ?? const [];
    final List<ResponseRedaction> responseRedactions = [
      ...?request.requestData.responseRedactions,
    ];
    final args = <String, String>{
      ...request.initialWitnessParams,
      ...request.witnessParams,
    };
    await Future.wait(
      List.generate(responseRedactions.length, (index) async {
        final responseRedactionI = responseRedactions.elementAt(index);
        final responseMatchI = responseMatches.elementAt(index);
        String element = response;
        final responseSelectionXPath = responseRedactionI.xPath;
        if (responseSelectionXPath != null &&
            responseSelectionXPath.isNotEmpty) {
          try {
            element = await Attestor.instance.extractHtmlElement(
              element,
              interpolateTemplateWithValues(responseSelectionXPath, args),
            );
          } catch (e) {
            if (e.toString().contains('Failed to find')) {
              throw const ReclaimVerificationRequirementException();
            } else {
              rethrow;
            }
          }
        } else {
          logger
              .child('responseSelection')
              .info('response selection xpath is empty');
        }
        final responseSelectionJsonPath = responseRedactionI.jsonPath;
        if (responseSelectionJsonPath != null &&
            responseSelectionJsonPath.isNotEmpty) {
          try {
            element = await Attestor.instance.extractJSONValueIndex(
              element,
              interpolateTemplateWithValues(responseSelectionJsonPath, args),
            );
          } catch (e) {
            if (e.toString().contains('Failed to find')) {
              throw const ReclaimVerificationRequirementException();
            } else {
              rethrow;
            }
          }
        }
        final responseMatchParamKeys = getTemplateVariables(
          responseMatchI.value ?? '',
        );
        String? responseMatchRegex = responseRedactionI.regex;
        if (responseMatchRegex == null) {
          // if regex is not provided, we need to fallback by converting template to regex template
          // This may not be needed if all providers have regex in responseMatch post migration
          final (regex, _, _) = convertTemplateToRegex(
            template: responseMatchI.value ?? '',
            parameters: request.initialWitnessParams,
            matchTypeOverride: responseRedactionI.matchType,
          );
          responseMatchRegex = regex;
        }

        final responseSelectionParamRegexMatch = RegExp(
          responseMatchRegex,
          dotAll: true,
        ).firstMatch(element);
        final List<String?>?
        responseSelectionParamValue = responseSelectionParamRegexMatch?.groups(
          // generate list of indices from 1 to length of responseMatchParamKeys
          List<int>.generate(responseMatchParamKeys.length, (i) => i + 1),
        );
        if (responseSelectionParamValue == null ||
            responseSelectionParamValue.isEmpty) {
          if (responseSelectionParamRegexMatch == null ||
              responseSelectionParamRegexMatch.groupCount == 0) {
            logger.info('No regex matches for `$responseMatchRegex`');
          }
          if (responseSelectionParamValue == null ||
              responseSelectionParamValue.isEmpty) {
            logger.info(
              'No selections found for $responseMatchParamKeys in $responseMatchRegex',
            );
          }
          logger.fine({
            'responseMatchRegex': responseMatchRegex,
            'element': element,
            'responseMatchParamKeys': responseMatchParamKeys,
          });
          throw const ReclaimVerificationRequirementException();
        }
        for (var i = 0; i < responseMatchParamKeys.length; i++) {
          final value = responseMatchParamKeys.elementAt(i);
          final paramValue = responseSelectionParamValue[i];
          if (paramValue == null) {
            logger.info('No param value for `$value`');
            continue;
          }
          params[value] = paramValue;
        }
        responseRedactions[index] = ResponseRedaction(
          xPath: responseRedactionI.xPath,
          jsonPath: responseRedactionI.jsonPath,
          hash: responseRedactionI.hash,
          matchType: responseRedactionI.matchType,
          regex: responseMatchRegex,
        );
      }),
      eagerError: true,
    );

    logger.info({
      'responseMatches.pre':
          request.requestData.responseMatches?.map((e) => e.toJson()).toList(),
      'responseRedactions.pre':
          request.requestData.responseRedactions
              ?.map((e) => e.toJson())
              .toList(),
      'responseMatches': responseMatches.map((e) => e.toJson()).toList(),
      'responseRedactions': responseRedactions.map((e) => e.toJson()).toList(),
    });

    return request.copyWith(
      witnessParams: params,
      extractedData: request.extractedData.copyWith(
        witnessParams: {...params, ...request.initialWitnessParams},
        // These will be provided to the Witness SDK by the witness webview
        // through RPC.
        responseRedactions: responseRedactions.toList(),
        responseMatches: responseMatches.toList(),
      ),
    );
  }

  Future<ClaimCreationRequest> getUpdatedProviderParams({
    required String attestorClaimCreationRequestId,
    required String response,
  }) async {
    final requestIdentifier =
        _requestHashByAttestorRequestId[attestorClaimCreationRequestId];
    if (requestIdentifier == null) {
      throw StateError(
        'No request identifier for attestor request id $attestorClaimCreationRequestId',
      );
    }
    final claimStatus = value.maybeGet(requestIdentifier);
    if (claimStatus == null) {
      throw StateError(
        'No claim status found for request id: $requestIdentifier by attestor request id $attestorClaimCreationRequestId',
      );
    }

    final updatedClaimCreationRequest =
        await createRequestWithUpdatedProviderParams(
          response,
          claimStatus.request,
        );

    value = value.copyWithStatus(
      claimStatus.copyWith(request: updatedClaimCreationRequest),
    );

    return updatedClaimCreationRequest;
  }

  final Map<String, ClaimRequestIdentifier> _requestHashByAttestorRequestId =
      {};

  Future<List<CreateClaimOutput>> _onCreateClaim(
    ClaimCreationRequest proofRequest,
  ) async {
    final requestIdentifier = proofRequest.requestData.requestIdentifier;
    final log = logging.child(
      'ClaimCreationController._onCreateClaim.$requestIdentifier',
    );

    final sessionId = proofRequest.sessionId;
    final httpProviderId = proofRequest.httpProviderId;
    final useSingleRequest = proofRequest.useSingleRequest;
    final ownerPrivateKey = await getReclaimPrivateKeyOfOwner();

    await _onProofGenerationStarted(sessionId);

    try {
      log.info(
        'Starting claim proof generation for providerId: $httpProviderId updateProviderParams: $useSingleRequest',
      );
      final Map<String, dynamic> createClaimInput = {
        "name": 'http',
        "params": proofRequest.httpParams,
        "secretParams": proofRequest.secretParams,
        "sessionId": sessionId,
        "context": proofRequest.claimContext,
        "ownerPrivateKey": ownerPrivateKey,
        "updateProviderParams": useSingleRequest,
      };

      log.finest({
        'reason':
            'createClaim input (${proofRequest.requestData.requestIdentifier})',
        'createClaimInput': json.encode(createClaimInput),
        'createClaimOptions': proofRequest.createClaimOptions,
      });

      final List<Future> delegateCallbackFutures = [];

      final requestMeasurePerformance = MeasurePerformance();
      Iterable<ZKComputePerformanceReport>? requestPerformanceReports;

      requestMeasurePerformance.start();

      final attestorRequest = await futureWithTimeout(
        Attestor.instance.createClaim(
          createClaimInput,
          options: proofRequest.createClaimOptions,
          onInitializationProgress: (progress) {
            _onAttestorInitializationProgress(requestIdentifier, progress);
          },
          onPerformanceReports: (
            Iterable<ZKComputePerformanceReport> performanceReports,
          ) {
            requestPerformanceReports = performanceReports;
          },
        ),
        timeout: _claimCreationTimeoutDuration,
      );

      _requestHashByAttestorRequestId[attestorRequest.id] = requestIdentifier;

      attestorRequest.updateStream.listen((data) {
        final logger = log.child('update-create-claim');
        _onStep(requestIdentifier, data);
        final delegate = value.delegate;
        if (delegate == null) {
          logger.severe('No delegate set for claim creation');
          return;
        }
        // one of the delegate claim update callbacks could open the bottom sheet
        // we'll await all of them in the end
        delegateCallbackFutures.add(
          delegate._onClaimUpdate(data, requestIdentifier),
        );
      });

      final proofs = await attestorRequest.response;

      requestMeasurePerformance.stop();

      for (final p in proofs) {
        p.publicData = value.publicData;
        p.providerRequest = proofRequest.requestData;
      }

      log.info('attestor proof generation completed');

      await _onProofGenerated(
        proofs,
        proofRequest,
        ProviderRequestPerformanceReport(
          requestReport: requestMeasurePerformance.getReport(),
          proofs:
              requestPerformanceReports ?? const <ZKComputePerformanceReport>[],
        ),
      );

      log.info({
        'reason': 'Proof Generated for providerId: $httpProviderId',
        'proofs': json.encode(proofs),
      });

      // The proof generated is for only single claim request.
      // All proofs are stored in the [controller.value.claims[].proof]
      // and shared when _SuccessWidget._onShared() is called which
      // uses [ClaimCreationUIDelegateOptions.of(context).onSubmitProofs] for
      // sharing all proofs.
      return proofs;
    } catch (e, s) {
      log.severe(
        'Failed to start claim creation, providerData.httpProviderId: $httpProviderId',
        e,
        s,
      );
      await _onProofGenerationFailed(e, s, proofRequest);
      rethrow;
    }
  }

  void _onStep(ClaimRequestIdentifier requestIdentifier, Map? step) {
    final logger = logging.child('ClaimCreationController._onStep');
    final status = value.maybeGet(requestIdentifier);
    if (status == null) {
      logger.info(
        '[ALERT] No status found for requestIdentifier: $requestIdentifier with step: ${json.encode(step)}',
      );
      return;
    }
    value = value.copyWithStatus(status.createNext(stepInformation: step));
  }

  void _onAttestorInitializationProgress(
    ClaimRequestIdentifier requestIdentifier,
    double progress,
  ) {
    final logger = logging.child(
      'ClaimCreationController._onAttestorInitializationProgress',
    );
    final status = value.maybeGet(requestIdentifier);
    if (status == null) {
      logger.warning(
        'No status found for request id: $requestIdentifier to report attestor initialization progress',
      );
      return;
    }
    value = value.copyWithStatus(
      status.createNext(attestorLoadingProgress: progress),
    );
  }

  final Map<ClaimRequestIdentifier, SingleWorkScope<List<CreateClaimOutput>>>
  _singleWorkScopesByRequest = {};

  SingleWorkScope<List<CreateClaimOutput>> _getSingleWorkScope(
    DataProviderRequest request,
  ) {
    final log = logging.child('ClaimCreationController._getSingleWorkScope');
    final ClaimRequestIdentifier key = request.requestIdentifier;
    final scope = _singleWorkScopesByRequest.putIfAbsent(
      key,
      () => SingleWorkScope(),
    );
    log.config(
      'GET SingleWorkScope with hashCode ${scope.hashCode} for key $key',
    );
    return scope;
  }

  Future<List<CreateClaimOutput>> startClaimCreation(
    ClaimCreationRequest proofRequest,
  ) async {
    final requestIdentifier = proofRequest.requestData.requestIdentifier;
    final log = logging.child(
      'ClaimCreationController.startClaimCreation.$requestIdentifier',
    );
    final completedRequestProofs =
        value.getCompletedRequestBy(requestIdentifier)?.proofs;
    if (completedRequestProofs != null) {
      log.info(
        'Request id $requestIdentifier is already completed. Sharing same proof.',
      );
      return completedRequestProofs;
    }

    log.info('starting claim creation inside controller');

    value = value.copyWithStatus(ClaimStatus.create(proofRequest));

    log.info('creating claim');

    // Note: Adding more work when a previous work had already completed will throw [WorkCanceledException].
    try {
      final scope = _getSingleWorkScope(proofRequest.requestData);

      return scope.runGuarded(() => _onCreateClaim(proofRequest));
    } on WorkCanceledException catch (e, s) {
      log.severe('work cancelled', e, s);
      log.info({
        'providerRequestHash': proofRequest.requestData.requestHash,
        'providerRequestIdentifier': proofRequest.requestData.requestIdentifier,
        'providerRequestComputedHash':
            proofRequest.requestData.requestIdentifier,
      });
      rethrow;
    }
  }

  void requestManualVerification() {
    value = value.copyWith(
      // notify listeners that manual verification was requested
      status: ClaimCreationStatus.manualVerificationRequested,
    );
  }

  String? getNextLocation() {
    final requests = value.httpProvider.requestData;

    for (final request in requests) {
      final requestIdentifier = request.requestIdentifier;
      if (!value.isCompleted(requestIdentifier)) {
        final url = request.expectedPageUrl?.trim();
        if (url != null && url.isNotEmpty) return url;
      }
    }

    return null;
  }
}
