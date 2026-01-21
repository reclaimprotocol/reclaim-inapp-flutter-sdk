import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../attestor.dart';
import '../../data/create_claim.dart';
import '../../data/providers.dart';
import '../../exception/exception.dart';
import '../../logging/logging.dart';
import '../../services/reclaim_owner_keys.dart';
import '../../services/session.dart';
import '../../ui/dev/dev.dart';
import '../../utils/future.dart';
import '../../utils/list.dart';
import '../../utils/observable_notifier.dart';
import '../../utils/provider_performance_report.dart';
import '../../utils/result.dart';
import '../../utils/single_work.dart';
import '../../webview_utils.dart';
import '../action_bar.dart';
import '../ai_flow_coordinator_widget.dart';
import '../verification_review/controller.dart';
import 'request.dart';
import 'state.dart';
import 'status.dart';

export 'request.dart';
export 'state.dart';
export 'status.dart';

part 'delegate.dart';

class ClaimCreationCancelledException implements Exception {
  const ClaimCreationCancelledException({this.message = 'Claim creation cancelled'});

  final String message;

  @override
  String toString() => 'ClaimCreationCancelledException: $message';
}

/// A controller that manages the state of the claim creation process.
class ClaimCreationController extends ObservableNotifier<ClaimCreationControllerState> {
  static ClaimCreationController? _lastInstance;

  static ClaimCreationController? get lastInstance => _lastInstance;

  ClaimCreationController() : super(const ClaimCreationControllerState()) {
    _lastInstance = this;
  }

  void setHttpProvider(HttpProvider httpProvider) {
    value = value.copyWith(httpProvider: httpProvider);
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
  static ClaimCreationController? maybeOf(BuildContext context, {bool listen = true}) {
    if (listen) {
      return context.dependOnInheritedWidgetOfExactType<_Provider>()?.notifier;
    }
    return context.getInheritedWidgetOfExactType<_Provider>()?.notifier;
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
  static ClaimCreationController of(BuildContext context, {bool listen = true}) {
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

  static ClaimCreationController readOf(BuildContext context) {
    return of(context, listen: false);
  }

  void setPublicData(Object? publicData) {
    logging.fine('publicData: $publicData');
    value = value.copyWith(publicData: Optional.value(publicData));
  }

  void setAIProofs(List<CreateClaimOutput>? aiProofs) {
    logging.fine('Setting AI proofs: ${aiProofs?.length} proofs');
    value = value.copyWith(aiProofs: aiProofs);
  }

  void canExpectManyClaims(bool canExpectManyClaims) {
    value = value.copyWith(canExpectManyClaims: canExpectManyClaims);
  }

  /// Checks if AI proofs should be shown instead of an error
  /// This is used in AI flow only, if the provider fails for any reason
  bool tryShowAIProofsInsteadOfError() {
    logging.info('trying to show AI proofs instead of error');
    final hasAiProofs = value.aiProofs != null && value.aiProofs!.isNotEmpty;
    logging.info('hasAiProofs: $hasAiProofs');
    if (hasAiProofs) {
      final httpProvider = value.httpProvider;

      final isAiProvider = httpProvider?.verificationType == 'AI';
      logging.info('isAiProvider: $isAiProvider');
      if (isAiProvider) {
        logging.info('showing AI proofs directly');
        showAIProofsDirectly(value.aiProofs!);
        return true;
      }
    }
    logging.info('not showing AI proofs directly');
    return false;
  }

  void setProviderError(Map<String, dynamic> error) {
    value = value.copyWith(
      providerError: ReclaimVerificationProviderScriptException(error['message'] ?? 'Verification failed', error),
    );
  }

  void setClientError(ReclaimException? clientError) {
    value = value.copyWith(clientError: Optional.value(clientError));
  }

  void removeClientError() {
    value = value.copyWith(clientError: const Optional.value(null));
  }

  void _setDelegate(ClaimCreationUIScopeState? delegate) {
    if (value.delegate == delegate) return;

    value = value.copyWith(delegate: delegate);
  }

  void requestRetry() {
    // Clear cumulative metrics when retry is requested (Try Again button clicked)
    try {
      logging.info('Cleared cumulative metrics - retry requested');
    } catch (e) {
      logging.fine('Failed to clear cumulative metrics: $e');
    }

    value = value.copyWith(status: ClaimCreationStatus.retryRequested, claimsByRequest: const {});
    value = value.copyWith(status: ClaimCreationStatus.ready);
  }

  Future<void> _onProofGenerationStarted(String sessionId) async {
    final isFirstClaim = value.totalCount <= 1;
    if (isFirstClaim) {
      if (value.hasRequestedRetry) {
        if (!value.didNotifySessionAsRetry) {
          unawaitedSequence([ReclaimSession.updateSession(sessionId, SessionStatus.PROOF_GENERATION_RETRY)]);
          value = value.copyWith(didNotifySessionAsRetry: true);
        }
      } else {
        unawaitedSequence([ReclaimSession.updateSession(sessionId, SessionStatus.PROOF_GENERATION_STARTED)]);
      }
    }
  }

  Future<void> _onProofGenerated(
    List<CreateClaimOutput> generatedProof,
    ClaimCreationRequest proofRequest,
    ProviderRequestPerformanceReport performanceReports,
  ) async {
    final logger = logging.child('ClaimCreationController._onProofGenerated');
    final sessionId = proofRequest.sessionId;
    final httpProviderId = proofRequest.httpProviderId;

    final claimStatus = value
        .maybeGet(proofRequest.requestData.requestIdentifier)
        ?.createNext(proofs: generatedProof, performanceReports: performanceReports, error: const Optional.value(null));

    if (claimStatus != null) {
      value = value.copyWithStatus(claimStatus);
    } else {
      logger.severe('No claim status found for request id: ${proofRequest.requestData.requestIdentifier}');
    }

    if (value.isFinished) {
      if (kDebugMode) {
        logger.info({'proofs': json.encode(value.claims.map((e) => e.proofs).toList())});
      }

      if (AIFlowCoordinatorWidget.isAiProviderEnabled) {
        final aiClient = AIFlowCoordinatorWidget.aiClient;
        if (aiClient != null) {
          aiClient.createTimelineEvent.proofGeneratedSuccess(
            'Proof generated successfully for provider: $httpProviderId',
          );
        }
      }

      unawaitedSequence([
        ReclaimSession.sendLogs(
          appId: proofRequest.appId,
          sessionId: sessionId,
          providerId: httpProviderId,
          logType: 'PROOF_GENERATED',
          metadata: ProviderRequestPerformanceMeasurements(
            reports: value.claims.map((e) => e.performanceReports).whereType<ProviderRequestPerformanceReport>(),
          ).toJson(),
        ),
        ReclaimSession.updateSession(sessionId, SessionStatus.PROOF_GENERATION_SUCCESS),
      ]);
    }

    logger.info({'generatedProof': generatedProof});
  }

  Future<void> _onProofGenerationFailed(
    Object e,
    StackTrace s,
    ClaimCreationRequest proofRequest,
    ProviderRequestPerformanceReport performanceReport,
  ) async {
    final logger = logging.child('ClaimCreationController._onProofGenerationFailed');
    final sessionId = proofRequest.sessionId;
    final httpProviderId = proofRequest.httpProviderId;

    if (AIFlowCoordinatorWidget.isAiProviderEnabled) {
      final aiClient = AIFlowCoordinatorWidget.aiClient;
      if (aiClient != null) {
        aiClient.createTimelineEvent.proofGenerationFailed(
          'Proof generation failed for provider: $httpProviderId - ${e.toString()}',
        );
      }
    }

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
          'report': () {
            try {
              return ProviderRequestPerformanceMeasurements(reports: [performanceReport]).toJson();
            } catch (e, s) {
              logger.severe('Failed to get performance report', e, s);
              return null;
            }
          }(),
        },
      ),
    ]);
    logger.severe('proof generation failed error at ${StackTrace.current}', e, s);
    final claimStatus = value
        .maybeGet(proofRequest.requestData.requestIdentifier)
        ?.createNext(
          error: Optional.value(ClaimCreationErrorDetails(error: e, stackTrace: s)),
        );
    value = value.copyWith(
      // need to notify session as retry when proof generation fails
      didNotifySessionAsRetry: false,
    );
    if (claimStatus != null) {
      value = value.copyWithStatus(claimStatus);
    } else {
      logger.severe('No claim status found for request id: ${proofRequest.requestData.requestIdentifier}');
    }
    // final claimCreationFailedEvent = ClaimCreationFailedEvent(
    //   errorMessage: e.toString(),
    //   stackTrace: s.toString(),
    //   requestHash: proofRequest.requestData.requestHash ?? '',
    // );
    // AIFlowCoordinatorWidget.pushEvent(claimCreationFailedEvent);
  }

  Future<ClaimCreationRequest> validateClaim(String response, ClaimCreationRequest request) async {
    // final responseSelections = request.providerData.responseSelections;
    // a copy of witnessParams to avoid mutating the original
    final params = {...request.witnessParams};

    final log = logging.child(
      'ClaimCreationController.createRequestWithUpdatedProviderParams.${request.requestData.requestIdentifier}',
    );
    final List<ResponseMatch> responseMatches = [...request.requestData.responseMatches];
    final List<ResponseRedaction> responseRedactions = [...request.requestData.responseRedactions];
    final args = <String, String>{...request.initialWitnessParams, ...request.witnessParams};

    log.info(
      'starting request validation and parameter extraction from request. These parameters will be used in claim creation provider request that is sent to attestor.',
    );

    final selectionLength = math.max(responseRedactions.length, responseMatches.length);

    final markedForRemovalResponseMatch = <ResponseMatch>{};
    final markedForRemovalResponseRedaction = <ResponseRedaction>{};

    void markForRemoval(ResponseRedaction? responseRedaction, ResponseMatch? responseMatch) {
      if (responseRedaction != null) {
        markedForRemovalResponseRedaction.add(responseRedaction);
      }
      if (responseMatch != null) {
        markedForRemovalResponseMatch.add(responseMatch);
      }
    }

    log.info('Trying to extract parameters from a part of response body using $selectionLength selections');
    await Future.wait(
      List.generate(selectionLength, (index) async {
        final logger = log.child('selection.$index');
        logger.info('Selecting a part of response body as element using xpath/jsonpath');

        final responseRedactionI = maybeGetAtIndex(responseRedactions, index);
        final responseMatchI = maybeGetAtIndex(responseMatches, index);
        final isFieldOptional = responseMatchI?.isOptional == true;
        String element = response;
        final responseSelectionXPath = responseRedactionI?.xPath;
        if (responseSelectionXPath != null && responseSelectionXPath.isNotEmpty) {
          logger.info('evaluating xml to get element for selection using xpath: $responseSelectionXPath');
          try {
            element = await Attestor.instance.extractHtmlElement(
              element,
              interpolateTemplateWithValues(responseSelectionXPath, args),
            );
            logger.info('did extract xml element: ${element.isNotEmpty ? "YES" : "<EMPTY STRING RECEIVED>"}');
          } catch (e, s) {
            logger.event(
              Level.SEVERE.withEvent(LogEventType.X_PATH_MATCH_REQUIREMENT_FAILED),
              'Could not extract xpath for $responseSelectionXPath',
              e,
              s,
            );
            if (e.toString().contains('Failed to find') || e.toString().contains('not found')) {
              if (isFieldOptional) {
                logger.info('skipping optional response match because xpath not found: $responseMatchI');
                markForRemoval(responseRedactionI, responseMatchI);
                return;
              }
              logger.event(
                Level.SEVERE.withEvent(LogEventType.CLAIM_PARAMETER_VALIDATION_FAILED_EXCEPTION),
                'Verification requirement failed',
              );
              throw const ReclaimVerificationRequirementException();
            } else {
              rethrow;
            }
          }
        } else {
          logger.info('xpath was not provided for selecting element from a part of response body, skipping');
        }
        final responseSelectionJsonPath = responseRedactionI?.jsonPath;
        if (responseSelectionJsonPath != null && responseSelectionJsonPath.isNotEmpty) {
          logger.info('evaluating json to get element for selection using jsonpath: $responseSelectionJsonPath');
          try {
            element = await Attestor.instance.extractJSONValueIndex(
              element,
              interpolateTemplateWithValues(responseSelectionJsonPath, args),
            );
            logger.info('did extract json value: ${element.isNotEmpty ? "YES" : "<EMPTY STRING RECEIVED>"}');
          } catch (e, s) {
            logger.event(
              Level.SEVERE.withEvent(LogEventType.JSON_PATH_MATCH_REQUIREMENT_FAILED),
              'Could not extract jsonpath for $responseSelectionJsonPath',
              e,
              s,
            );

            if (e.toString().contains('Failed to find') || e.toString().contains('not found')) {
              if (isFieldOptional) {
                logger.info('skipping optional response match because xpath not found: $responseMatchI');
                markForRemoval(responseRedactionI, responseMatchI);
                return;
              }
              logger.event(
                Level.SEVERE.withEvent(LogEventType.CLAIM_PARAMETER_VALIDATION_FAILED_EXCEPTION),
                'Verification requirement failed',
              );
              throw const ReclaimVerificationRequirementException();
            } else {
              rethrow;
            }
          }
        } else {
          logger.info('jsonpath was not provided for selecting element from a part of response body, skipping');
        }

        if ((responseSelectionXPath == null || responseSelectionXPath.isEmpty) &&
            (responseSelectionJsonPath == null || responseSelectionJsonPath.isEmpty)) {
          logger.info(
            'No xpath or jsonpath was provided for selecting element from a part of response body, using the whole response body as selected element',
          );
        }

        logger.info('starting parameter extraction from selected element');

        final isRegexResponseMatch = responseMatchI?.type == ResponseMatchType.regex;

        logger.info('response match type: ${responseMatchI?.type?.name}');

        final responseMatchParamKeys = isRegexResponseMatch
            ? getRegexTemplateVariables(responseMatchI?.value ?? '')
            : getTemplateVariables(responseMatchI?.value ?? '');
        logger.info(
          'Found following parameter names from response match: (${responseMatchParamKeys.length}) $responseMatchParamKeys',
        );
        logger.info('Will use regex expression as selection regex to find values of these parameters');

        String? paramSelectionRegex = responseRedactionI?.regex;
        if (paramSelectionRegex == null) {
          logger.info('No regex provided in response redaction, trying to get it from response match');
          if (isRegexResponseMatch) {
            logger.info('response match is of type regex, will use responseMatch.value as regex expression');
            paramSelectionRegex = responseMatchI?.value ?? '';
          } else {
            logger.info(
              'response match is not of type regex, will try to convert responseMatch.value, that has template variable placeholder with parameter names, to regex expression',
            );

            // if regex is not provided, we need to fallback by converting template to regex template
            // This may not be needed if all providers have regex in responseMatch post migration
            final (regex, _, _) = convertTemplateToRegex(
              template: responseMatchI?.value ?? '',
              parameters: request.initialWitnessParams,
              matchTypeOverride: responseRedactionI?.matchType,
            );
            paramSelectionRegex = regex;
          }
        }

        logger.info(
          'evaluating the element that was obtained after xpath/json path evaluation with selection regex: $paramSelectionRegex',
        );

        final responseSelectionParamRegexMatch = RegExp(paramSelectionRegex, dotAll: true).firstMatch(element);
        logger.info(
          'Count of groups found by finding first match of element with selection regex: ${responseSelectionParamRegexMatch?.groupCount}',
        );
        final List<String?>? responseSelectionParamValue = responseSelectionParamRegexMatch?.groups(
          // generate list of indices from 1 to length of responseMatchParamKeys
          List<int>.generate(responseMatchParamKeys.length, (i) => i + 1),
        );
        logger.info(
          'count of parameter values that can be obtained from matched groups: ${responseSelectionParamValue?.length}',
        );
        if (responseSelectionParamValue == null || responseSelectionParamValue.isEmpty) {
          if (responseSelectionParamRegexMatch == null || responseSelectionParamRegexMatch.groupCount == 0) {
            // This cannot be ignored even if the case is regex. Because attestor needs regex in response match to have params.

            logger.event(
              Level.WARNING.withEvent(LogEventType.REGEX_MATCH_REQUIREMENT_FAILED),
              'No regex matches in element for `$paramSelectionRegex`',
            );
            logger.debug({'reason': 'element', 'element': json.encode(element)});
          }
          if (responseSelectionParamValue == null || responseSelectionParamValue.isEmpty) {
            logger.event(
              Level.WARNING.withEvent(LogEventType.NO_PARAMETERS_FOUND),
              'No parameter values found for parameter names $responseMatchParamKeys from the first regex match of element by regex $paramSelectionRegex',
            );
          }
          logger.finer({
            'Regex used for finding parameter values in element': paramSelectionRegex,
            'element': element,
            'parameter names': responseMatchParamKeys,
          });
          if (isFieldOptional) {
            logger.info(
              'skipping because no parameter values found this selection and this selection was marked optional. It will not be included claim creation provider request.',
            );
            markForRemoval(responseRedactionI, responseMatchI);
            return;
          }
          logger.event(
            Level.SEVERE.withEvent(LogEventType.CLAIM_PARAMETER_VALIDATION_FAILED_EXCEPTION),
            'Verification requirement failed',
          );
          throw const ReclaimVerificationRequirementException();
        }
        logger.info('Assigning expected values to parameters from matched selection');
        for (var i = 0; i < responseMatchParamKeys.length; i++) {
          final paramName = responseMatchParamKeys.elementAt(i);
          final paramValue = maybeGetAtIndex(responseSelectionParamValue, i);
          if (paramValue == null) {
            logger.info('No parameter value available for `$paramName`');
            continue;
          }
          // For non regex response matches, we can directly set the param value
          // For regex response matches, the values may differ when the request is actually made by the attestor
          params[paramName] = paramValue;
        }
        if (responseRedactionI?.regex != paramSelectionRegex) {
          logger.info('Updating response redaction\'s regex expression to $paramSelectionRegex');
        }
        if (responseRedactionI != null) {
          responseRedactions[index] = ResponseRedaction(
            xPath: responseRedactionI.xPath,
            jsonPath: responseRedactionI.jsonPath,
            hash: responseRedactionI.hash,
            matchType: responseRedactionI.matchType,
            regex: paramSelectionRegex,
          );
        }
      }),
      eagerError: true,
    );

    for (final match in markedForRemovalResponseMatch) {
      responseMatches.remove(match);
    }
    for (final redaction in markedForRemovalResponseRedaction) {
      responseRedactions.remove(redaction);
    }

    log.info({
      'old response matches': request.requestData.responseMatches.map((e) => e.toJson()).toList(),
      'old response redactions': request.requestData.responseRedactions.map((e) => e.toJson()).toList(),
      'new response matches': responseMatches.map((e) => e.toJson()).toList(),
      'new response redactions': responseRedactions.map((e) => e.toJson()).toList(),
    });

    if (responseMatches.isEmpty) {
      log.event(
        Level.WARNING.withEvent(LogEventType.NO_RESPONSE_MATCH_WARNING),
        'Atleast one response match is required for claim creation. Because none is going to be used in claim creation for this request, claim creation will likely fail.',
      );
    }

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
    final requestIdentifier = _requestHashByAttestorRequestId[attestorClaimCreationRequestId];
    if (requestIdentifier == null) {
      throw StateError('No request identifier for attestor request id $attestorClaimCreationRequestId');
    }
    final claimStatus = value.maybeGet(requestIdentifier);
    if (claimStatus == null) {
      throw StateError(
        'No claim status found for request id: $requestIdentifier by attestor request id $attestorClaimCreationRequestId',
      );
    }

    final updatedClaimCreationRequest = await validateClaim(response, claimStatus.request);

    value = value.copyWithStatus(claimStatus.copyWith(request: updatedClaimCreationRequest));

    return updatedClaimCreationRequest;
  }

  final Map<String, ClaimRequestIdentifier> _requestHashByAttestorRequestId = {};

  Future<List<CreateClaimOutput>> _onCreateClaim(
    ClaimCreationRequest proofRequest, {
    required Map<String, Object?> Function(Map<String, Object?>) updateAdditionalClientOptions,
  }) async {
    final requestIdentifier = proofRequest.requestData.requestIdentifier;
    final log = logging.child('ClaimCreationController._onCreateClaim.$requestIdentifier');

    value = value.copyWithStatus(ClaimStatus.create(proofRequest));

    final sessionId = proofRequest.sessionId;
    final httpProviderId = proofRequest.httpProviderId;
    final useSingleRequest = proofRequest.useSingleRequest;
    final ownerPrivateKey = await ReclaimOwnerKeys().getReclaimPrivateKeyOfOwner();

    await _onProofGenerationStarted(sessionId);

    final requestMeasurePerformance = MeasurePerformance();

    try {
      log.event(
        Level.INFO.withEvent(LogEventType.CLAIM_CREATION_STARTED),
        'Starting claim proof generation for providerId: $httpProviderId updateProviderParams: $useSingleRequest',
      );
      final Map<String, dynamic> createClaimInput = {
        "name": 'http',
        "params": proofRequest.getHttpParams(updateAdditionalClientOptions),
        "secretParams": proofRequest.secretParams,
        "sessionId": sessionId,
        "context": proofRequest.claimContext,
        "ownerPrivateKey": ownerPrivateKey,
        "updateProviderParams": useSingleRequest,
        //Analyziz part for delete after release
        "httpProviderId": httpProviderId,
        "providerName": value.httpProvider?.name ?? httpProviderId,
      };

      log.finest({
        'reason': 'createClaim input (${proofRequest.requestData.requestIdentifier})',
        'createClaimInput': json.encode(createClaimInput),
        'createClaimOptions': proofRequest.createClaimOptions,
      });

      DevController.shared.push('createClaimInput', createClaimInput);

      final List<Future> delegateCallbackFutures = [];

      Iterable<ZKComputePerformanceReport>? requestPerformanceReports;

      requestMeasurePerformance.start();

      log.info('Starting attestor claim creation');

      final attestorRequest = await Attestor.instance.createClaim(
        createClaimInput,
        options: proofRequest.createClaimOptions,
        onInitializationProgress: (progress) {
          _onAttestorInitializationProgress(requestIdentifier, progress);
        },
        onPerformanceReports: (Iterable<ZKComputePerformanceReport> performanceReports) {
          requestPerformanceReports = performanceReports;
        },
        timeoutAfter: proofRequest.claimCreationTimeoutDuration,
      );

      log.info('Started attestor claim creation, request id: $requestIdentifier');

      _requestHashByAttestorRequestId[attestorRequest.id] = requestIdentifier;

      const responseWaitDuration = Duration(seconds: 10);
      Timer? responseWaitTimer = Timer(responseWaitDuration, () {
        log.event(
          Level.WARNING.withEvent(LogEventType.ATTESTOR_NOT_RESPONDING),
          'No response received from attestor for id ${attestorRequest.id} in $responseWaitDuration since claim creation started',
        );
      });

      attestorRequest.updateStream.listen((data) {
        final logger = log.child('update-create-claim');
        logger.finest({'update-create-claim': data});
        responseWaitTimer?.cancel();
        responseWaitTimer = null;
        _onStep(requestIdentifier, data);
        final delegate = value.delegate;
        if (delegate == null) {
          logger.severe('No delegate set for claim creation');
          return;
        }
        // one of the delegate claim update callbacks could open the bottom sheet
        // we'll await all of them in the end
        delegateCallbackFutures.add(delegate._onClaimUpdate(data, requestIdentifier));
      });

      attestorRequest.updateSink?.add({
        'step': {
          "type": "update",
          "name": "attestor-progress",
          "step": {"name": "connecting"},
        },
      });

      log.info('attestor request created ${attestorRequest.id}');

      final proofs = await attestorRequest.response;

      log.info('attestor request response received ${attestorRequest.id}');

      requestMeasurePerformance.stop();

      for (final p in proofs) {
        p.providerRequest = proofRequest.requestData;
      }

      log.info('attestor proof generation completed');

      if (isDisposed) {
        log.event(
          Level.WARNING.withEvent(LogEventType.CLAIM_CREATION_CANCELLED_EXCEPTION),
          'Proof generated but result will be ignored because ClaimCreationController is disposed',
        );
        return throw const ClaimCreationCancelledException();
      }
      //Analyziz part for delete after release
      // Get performance report for storage
      final performanceReport = requestMeasurePerformance.getReport();

      await _onProofGenerated(
        proofs,
        proofRequest,
        ProviderRequestPerformanceReport(
          requestReport: performanceReport,
          proofs: requestPerformanceReports ?? const <ZKComputePerformanceReport>[],
        ),
      );

      log.event(Level.INFO.withEvent(LogEventType.PROOF_GENERATED), {
        'reason': 'Proof Generated for providerId: $httpProviderId',
        'proofs': json.encode(proofs),
      });

      // The proof generated is for only single claim request.
      // All proofs are stored in the [controller.value.claims[].proof]
      // and shared when _SuccessWidget._onShared() is called which
      // uses [ClaimCreationUIDelegateOptions.of(context).onSubmitProofs] for
      // sharing all proofs.
      return proofs;
    } on ClaimCreationCancelledException {
      // ignore the cancellation exception. We don't want to mark this as an error.
      // Sometimes user may have mistakenly started the same claim creation again.
      rethrow;
    } catch (e, s) {
      log.event(
        Level.SEVERE.withEvent(LogEventType.PROOF_GENERATION_FAILED_EXCEPTION),
        'Failed to start claim creation, providerData.httpProviderId: $httpProviderId',
        e,
        s,
      );
      requestMeasurePerformance.stop();
      final performanceReport = requestMeasurePerformance.getReport();
      await _onProofGenerationFailed(
        e,
        s,
        proofRequest,
        ProviderRequestPerformanceReport(
          requestReport: performanceReport,
          proofs: const <ZKComputePerformanceReport>[],
        ),
      );
      rethrow;
    }
  }

  void _onStep(ClaimRequestIdentifier requestIdentifier, Map? step) {
    if (isDisposed) return;

    final logger = logging.child('ClaimCreationController._onStep');
    final status = value.maybeGet(requestIdentifier);
    if (status == null) {
      logger.info('[ALERT] No status found for requestIdentifier: $requestIdentifier with step: ${json.encode(step)}');
      return;
    }
    value = value.copyWithStatus(status.createNext(stepInformation: step));
  }

  void _onAttestorInitializationProgress(ClaimRequestIdentifier requestIdentifier, double progress) {
    final logger = logging.child('ClaimCreationController._onAttestorInitializationProgress');
    final status = value.maybeGet(requestIdentifier);
    if (status == null) {
      logger.warning('No status found for request id: $requestIdentifier to report attestor initialization progress');
      return;
    }
    value = value.copyWithStatus(status.createNext(attestorLoadingProgress: progress));
  }

  final Map<ClaimRequestIdentifier, SingleWorkScope<List<CreateClaimOutput>>> _singleWorkScopesByRequest = {};

  SingleWorkScope<List<CreateClaimOutput>> _getSingleWorkScope(DataProviderRequest request) {
    final log = logging.child('ClaimCreationController._getSingleWorkScope');
    final ClaimRequestIdentifier key = request.requestIdentifier;
    final scope = _singleWorkScopesByRequest.putIfAbsent(key, () => SingleWorkScope());
    log.config('GET SingleWorkScope with hashCode ${scope.hashCode} for key $key');
    return scope;
  }

  Future<List<CreateClaimOutput>> _onCreateClaimWithRetries(ClaimCreationRequest proofRequest) async {
    final requestIdentifier = proofRequest.requestData.requestIdentifier;
    final log = logging.child(
      'ClaimCreationController.startClaimCreation.$requestIdentifier._onCreateClaimWithRetries',
    );
    final originalClientOptions = proofRequest.additionalClientOptions;
    try {
      return await _onCreateClaim(proofRequest, updateAdditionalClientOptions: (options) => options);
    } catch (e, s) {
      final bool canRetry = () {
        if (originalClientOptions.isNotEmpty) {
          final supportedProtocolVersions = originalClientOptions['supportedProtocolVersions'];
          if (supportedProtocolVersions != null &&
              supportedProtocolVersions is List &&
              supportedProtocolVersions.length == 1 &&
              supportedProtocolVersions.contains('TLS1_2')) {
            return false;
          }
        }
        return true;
      }();
      if (canRetry) {
        log.severe('Failed creating claim', e, s);
        await Future.microtask(() => null);
        log.warning('Using tls 1.2 as fallback and retrying claim');
        try {
          final claimStatus = value
              .maybeGet(proofRequest.requestData.requestIdentifier)
              ?.createNext(error: const Optional.value(null));

          if (claimStatus != null) {
            value = value.copyWithStatus(claimStatus);
          }

          return await _onCreateClaim(
            proofRequest,
            updateAdditionalClientOptions: (options) {
              return {
                ...options,
                "supportedProtocolVersions": ["TLS1_2"],
              };
            },
          );
        } catch (newE, newS) {
          log.severe('Failed creating claim', newE, newS);
          // relogging e, s so that the reason for original logs isn't lost by log viewers
          log.severe('Failed creating claim before this attempt', e, s);
        }
      }
      rethrow;
    }
  }

  Future<List<CreateClaimOutput>> startClaimCreation(ClaimCreationRequest proofRequest) async {
    if (isDisposed) throw StateError('ClaimCreationController is disposed');

    final requestIdentifier = proofRequest.requestData.requestIdentifier;
    final log = logging.child('ClaimCreationController.startClaimCreation.$requestIdentifier');
    final completedRequestProofs = value.getCompletedRequestBy(requestIdentifier)?.proofs;
    if (completedRequestProofs != null) {
      log.info('Request id $requestIdentifier is already completed. Sharing same proof.');
      return completedRequestProofs;
    }
    log.event(Level.INFO.withEvent(LogEventType.STARTING_CLAIM_CREATION), 'starting claim creation inside controller');

    value = value.copyWithStatus(ClaimStatus.create(proofRequest));

    log.info('creating claim');

    // Note: Adding more work when a previous work had already completed will throw [WorkCanceledException].
    try {
      final scope = _getSingleWorkScope(proofRequest.requestData);

      return scope.runGuarded(() => _onCreateClaimWithRetries(proofRequest));
    } on WorkCanceledException catch (e, s) {
      log.severe('work cancelled', e, s);
      log.info({
        'providerRequestHash': proofRequest.requestData.requestHash,
        'providerRequestIdentifier': proofRequest.requestData.requestIdentifier,
        'providerRequestComputedHash': proofRequest.requestData.requestIdentifier,
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
    final requests = value.httpProvider?.requestData;

    if (requests == null) return null;

    for (final request in requests) {
      final requestIdentifier = request.requestIdentifier;
      if (!value.isCompleted(requestIdentifier)) {
        final url = request.expectedPageUrl?.trim();
        if (url != null && url.isNotEmpty) return url;
      }
    }

    return null;
  }

  /// Shows the verification review directly with AI-generated proofs,
  /// bypassing the normal claim creation flow
  void showAIProofsDirectly(List<CreateClaimOutput> aiProofs) {
    final logger = logging.child('ClaimCreationController.showAIProofsDirectly');
    logger.info('Showing AI proofs directly in verification review');

    if (aiProofs.isEmpty) {
      logger.warning('No AI proofs provided');
      return;
    }

    final Map<ClaimRequestIdentifier, ClaimStatus> claimsByRequest = {};

    final currentProvider = value.httpProvider;

    for (int i = 0; i < aiProofs.length; i++) {
      final proof = aiProofs[i];
      final requestIdentifier = 'ai_proof_$i';

      // Create a minimal DataProviderRequest if the proof doesn't have one
      final providerRequest =
          proof.providerRequest ??
          DataProviderRequest(
            url: 'https://ai-generated.example.com',
            method: RequestMethodType.GET,
            responseMatches: const [],
            responseRedactions: const [],
            credentials: WebCredentialsType.INCLUDE,
          );

      proof.providerRequest = providerRequest;

      // Create a minimal ClaimStatus that holds the proof
      final claimStatus = ClaimStatus(
        request: ClaimCreationRequest(
          appId: '',
          httpProviderId: 'ai_generated',
          claimContext: 'ai_verification',
          sessionId: '',
          proofData: {'url': providerRequest.url ?? ''},
          providerData:
              currentProvider ??
              const HttpProvider(
                logoUrl: 'https://example.com/ai.png',
                requestData: [], // Empty request data as mentioned
                useIncognitoWebview: false,
              ),
          headers: const {},
          initialWitnessParams: const {},
          cookieString: '',
          createClaimOptions: const AttestorClaimOptions(),
          useSingleRequest: true,
          requestData: providerRequest,
          claimCreationTimeoutDuration: const Duration(minutes: 5),
        ),
        proofs: [proof],
        error: null,
        stepInformation: null,
        performanceReports: null,
        previousStatus: null,
        creationDate: DateTime.now(),
        attestorLoadingProgress: 1.0,
      );

      claimsByRequest[requestIdentifier] = claimStatus;
    }

    // Update the controller state with the AI proofs
    value = value.copyWith(
      claimsByRequest: claimsByRequest,
      status: ClaimCreationStatus.ready,
      clientError: const Optional.value(null),
    );

    logger.info('AI proofs set for verification review: ${aiProofs.length} proofs');
  }

  Widget wrap({required Widget child}) {
    return _Provider(notifier: this, child: child);
  }
}

class _Provider extends InheritedNotifier<ClaimCreationController> {
  const _Provider({required super.child, required ClaimCreationController super.notifier});

  @override
  bool updateShouldNotify(covariant _Provider oldWidget) {
    return oldWidget.notifier?.value != notifier?.value;
  }
}
