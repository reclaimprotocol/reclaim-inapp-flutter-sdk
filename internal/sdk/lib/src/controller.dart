import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../attestor.dart';
import 'data/app_info.dart';
import 'data/create_claim.dart';
import 'data/identity.dart';
import 'data/providers.dart';
import 'data/verification/options.dart';
import 'data/verification/request.dart';
import 'data/verification/result.dart';
import 'exception/exception.dart';
import 'logging/logging.dart';
import 'repository/feature_flags.dart';
import 'ui/claim_creation_webview/view_model.dart';
import 'usecase/session_manager.dart';
import 'usecase/verification.dart';
import 'usecase/version_information.dart';
import 'usecase/zkoperator.dart';
import 'utils/observable_notifier.dart';
import 'web_scripts/hawkeye/interception_method.dart';
import 'webview_utils.dart';
import 'widgets/feature_flags.dart';

@immutable
class VerificationState with EquatableMixin {
  VerificationState({
    this.requestedProvider,
    this.provider,
    this.exception,
    this.attestorAuthenticationRequest,
    this.userScripts,
    this.result,
    this.providerVersion,
    this.matchableDevtoolProviderRequests,
  });

  /// The provider that was initial requested when verification flow started
  final HttpProvider? requestedProvider;
  final HttpProvider? provider;
  final ProviderVersionExact? providerVersion;
  final ReclaimException? exception;
  final AttestorAuthenticationRequest? attestorAuthenticationRequest;
  final UnmodifiableListView<UserScript>? userScripts;
  final ReclaimVerificationResult? result;
  final Iterable<InjectionRequest>? matchableDevtoolProviderRequests;

  // note: keep progress between 0.0 and 0.1
  double get initializationProgress {
    // Can load webview with the scripts
    // 1
    if (provider == null) return 0.02;
    // 4
    if (userScripts != null) return 0.1;
    // 3
    if (attestorAuthenticationRequest != null) return 0.085;
    // 2
    return 0.07;
  }

  VerificationState copyWith({
    HttpProvider? provider,
    ReclaimException? exception,
    AttestorAuthenticationRequest? attestorAuthenticationRequest,
    UnmodifiableListView<UserScript>? userScripts,
    ReclaimVerificationResult? result,
    ProviderVersionExact? providerVersion,
    Iterable<InjectionRequest>? matchableDevtoolProviderRequests,
  }) {
    return VerificationState(
      // requestedProvider cannot be changed once assigned
      requestedProvider: requestedProvider ?? provider,
      provider: provider ?? this.provider,
      exception: exception ?? this.exception,
      attestorAuthenticationRequest: attestorAuthenticationRequest ?? this.attestorAuthenticationRequest,
      userScripts: userScripts ?? this.userScripts,
      result: result ?? this.result,
      providerVersion: providerVersion ?? this.providerVersion,
      matchableDevtoolProviderRequests: matchableDevtoolProviderRequests ?? this.matchableDevtoolProviderRequests,
    );
  }

  @override
  List<Object?> get props => [
    requestedProvider,
    provider,
    exception,
    attestorAuthenticationRequest,
    userScripts,
    result,
    providerVersion,
  ];
}

class VerificationController extends ObservableNotifier<VerificationState> {
  final ReclaimVerificationRequest request;
  final ReclaimVerificationOptions options;

  VerificationController({required this.request, required this.options}) : super(VerificationState()) {
    _log.config('VerificationController created');
  }

  late final _log = logging.child('VerificationController.$hashCode');

  final _responseCompleter = Completer<ReclaimVerificationResult>();

  bool get isCompleted => _responseCompleter.isCompleted;

  Future<ReclaimVerificationResult> get response => _responseCompleter.future;

  @override
  void didChangeValues(VerificationState? oldValue, VerificationState value) {
    super.didChangeValues(oldValue, value);

    if (!_responseCompleter.isCompleted) {
      final exception = value.exception;
      if (exception != null) {
        _responseCompleter.completeError(exception);
      }
      final result = value.result;
      if (result != null) {
        _responseCompleter.complete(result);
      }
    }
  }

  StreamSubscription<String>? _attestorUrlUpdatesSubscription;

  SessionIdentity? _identity;

  SessionIdentity? get maybeIdentity {
    return _identity;
  }

  /// Use if you are sure that session has started. Otherwise use [sessionStartFuture].
  SessionIdentity get identity {
    final i = maybeIdentity;
    if (i == null) {
      _log.severe('Session not started but identity requested', null, StackTrace.current);
      throw StateError('Session not started');
    }
    return i;
  }

  ReclaimSessionInformation? _sessionInformation;

  /// Use if you are sure that session has started. Otherwise use [sessionStartFuture].
  ReclaimSessionInformation get sessionInformation {
    if (_identity == null) {
      _log.severe('Session not started but identity requested', null, StackTrace.current);
      throw StateError('Session not started');
    }
    return _sessionInformation!;
  }

  /// Use this to wait for the session to start before accessing [sessionInformation], [identity].
  Future<SessionStartResponse> get sessionStartFuture => _startingSession;

  late Future<SessionStartResponse> _startingSession;

  Future<void> initialize() async {
    try {
      final sessionManager = const SessionManager();

      _startingSession = sessionManager.startSession(
        request.applicationId,
        request.providerId,
        request.sessionProvider,
      );
      final response = await _startingSession;
      final appInfoFuture = AppInfo.fromAppId(request.applicationId);
      _identity = response.identity;
      final sessionInformation = response.sessionInformation;
      _sessionInformation = sessionInformation;
      value = value.copyWith(providerVersion: sessionInformation.version);

      _log.info('Session started: ${sessionInformation.sessionId}');

      await SDKVersionInformation().verifyUpdateRequirement();

      final verificationFlowManager = VerificationFlowManager();

      _attestorUrlUpdatesSubscription = verificationFlowManager.startAttestorUrlUpdates(identity);

      _log.info('Fetching provider ${request.providerId} with version: ${sessionInformation.version}');
      final provider = await verificationFlowManager.fetchRequestedProvider(
        applicationId: request.applicationId,
        providerId: request.providerId,
        sessionInformation: sessionInformation,
        version: sessionInformation.version,
      );
      _log.info('Provider fetched with version: ${provider.version}');
      // Dumping provider information as JSON for debugging
      // Useful for consumers that override provider
      _log.info(json.encode(provider));

      final providerUsesOprfMpc = ZkOperatorManager().providerUsesOprfMpc(provider);
      await ZkOperatorManager().setupZkOperator(
        identity,
        // oprf-mpc is only supported in TEE Mode
        explicitUseTeeOperator: providerUsesOprfMpc ? true : options.useTeeOperator,
      );

      await const SessionManager().onRequestedProvidersFetched(
        applicationId: request.applicationId,
        providerId: request.providerId,
        sessionId: sessionInformation.sessionId,
        useTEE: Attestor.instance.useTeeOperator,
      );

      final clearingWebStorage = verificationFlowManager.clearWebStorageIfRequired(
        identity,
        appInfoFuture,
        options.canClearWebStorage,
        provider.isAIProvider,
      );

      final canContinueVerificationCallback = options.canContinueVerification;

      if (canContinueVerificationCallback != null) {
        try {
          final canContinue = await canContinueVerificationCallback(provider, sessionInformation);
          if (!canContinue) {
            // Verification must be cancelled
            _log.event(
              Level.INFO.withEvent(LogEventType.RECLAIM_VERIFICATION_SKIPPED),
              'canContinueVerificationCallback returned false, cancelling verification',
            );
            updateException(const ReclaimVerificationSkippedException());
            return;
          }
        } catch (e, s) {
          _log.severe('Error in canContinueVerificationCallback', e, s);
          // ignoring because there could be a problem with the callback and its provided by the consumer of the inapp sdk
        }
      }

      value = value.copyWith(provider: provider);

      _log.info('Fetching attestor authentication request');

      await _onFetchAttestorAuthenticationRequest(provider);

      _log.info('Waiting for web storage to be cleared');

      await clearingWebStorage;

      _log.info('Loading user scripts');

      await _loadUserScripts(provider, response.identity);

      _log.info('User scripts loaded');

      // Allow the webpage to load before preparing the Protocol Operator
      Future.delayed(const Duration(seconds: 2)).then((_) async {
        try {
          await ZkOperatorManager().prepareOperatorForAlgorithmWithHints(provider);
        } catch (e, s) {
          _log.severe('Error preparing ZK operator', e, s);
        }
      });
    } on ReclaimException catch (e, s) {
      updateException(e, s);
    } catch (e, s) {
      _log.event(
        Level.SEVERE.withEvent(LogEventType.RECLAIM_VERIFICATION_PROVIDER_LOAD_EXCEPTION),
        'Error fetching provider',
        e,
        s,
      );
      updateException(const ReclaimVerificationProviderLoadException('Error loading provider'));
    }
  }

  Future<void> _loadUserScripts(HttpProvider provider, SessionIdentity identity) async {
    final featureFlagsProvider = FeatureFlagsProvider(identity);

    final HawkeyeInterceptionOptions interceptorOptions = await featureFlagsProvider
        .get(FeatureFlag.interceptionOptions)
        .then(HawkeyeInterceptionOptions.fromString);
    final pageLoadedCompletedDebounceTimeoutMs = await featureFlagsProvider
        .get(FeatureFlag.pageLoadedCompletedDebounceTimeoutMs)
        .then((value) => value.toInt());

    final userScripts = await VerificationFlowManager().loadUserScripts(
      provider: provider,
      parameters: request.parameters,
      options: interceptorOptions,
      pageLoadedCompletedDebounceTimeoutMs: pageLoadedCompletedDebounceTimeoutMs,
    );
    final injectionRequests = InjectionRequest.fromDataRequests(provider.requestData, request.parameters);
    value = value.copyWith(userScripts: userScripts, matchableDevtoolProviderRequests: injectionRequests);
  }

  Future<void> _onFetchAttestorAuthenticationRequest(HttpProvider requestedProvider) async {
    final callback = options.attestorAuthenticationRequest;
    if (callback == null) return;

    final attestorAuthenticationRequest = await VerificationFlowManager().fetchAttestorAuthenticationRequest(
      provider: requestedProvider,
      callback: callback,
    );
    value = value.copyWith(attestorAuthenticationRequest: attestorAuthenticationRequest);
  }

  void cancelVerification(String message) {
    logging.event(
      Level.INFO.withEvent(LogEventType.RECLAIM_VERIFICATION_CANCELLED_EXCEPTION),
      'Verification cancelled because: $message',
    );
    updateException(ReclaimVerificationCancelledException(message));
  }

  void dismissVerification() {
    if (isCompleted) {
      logging.config("don't dismiss verification after it is completed");
      return;
    }
    logging.event(Level.INFO.withEvent(LogEventType.RECLAIM_VERIFICATION_DISMISSED), 'Verification dismissed by user');
    updateException(const ReclaimVerificationDismissedException());
  }

  Future<void> updateProvider(String versionNumber, ClaimCreationWebClientViewModel controller) async {
    final provider = await VerificationFlowManager().fetchProvider(
      applicationId: request.applicationId,
      providerId: request.providerId,
      sessionInformation: sessionInformation,
      version: ProviderVersionExact(versionNumber),
    );

    final currentUrl = await controller.getCurrentWebPageUrl();

    // If currentUrl isn't null, modify the provider to replace the loginUrl with currentUrl
    final finalProvider = provider.copyWithLoginUrl(currentUrl ?? provider.loginUrl);

    final featureFlagsProvider = FeatureFlagsProvider(identity);

    final HawkeyeInterceptionOptions interceptorOptions = await featureFlagsProvider
        .get(FeatureFlag.interceptionOptions)
        .then(HawkeyeInterceptionOptions.fromString);

    final pageLoadedCompletedDebounceTimeoutMs = await featureFlagsProvider
        .get(FeatureFlag.pageLoadedCompletedDebounceTimeoutMs)
        .then((value) => value.toInt());

    final userScripts = await VerificationFlowManager().loadUserScripts(
      provider: finalProvider,
      parameters: request.parameters,
      options: interceptorOptions,
      pageLoadedCompletedDebounceTimeoutMs: pageLoadedCompletedDebounceTimeoutMs,
    );

    final injectionRequests = InjectionRequest.fromDataRequests(provider.requestData, request.parameters);
    value = value.copyWith(
      provider: finalProvider,
      userScripts: userScripts,
      matchableDevtoolProviderRequests: injectionRequests,
    );
  }

  Future<void> onManualVerificationRequestSubmitted() async {
    const SessionManager().onManualVerificationRequestSubmitted(
      applicationId: request.applicationId,
      sessionId: sessionInformation.sessionId,
      providerId: request.providerId,
    );
    updateException(const ReclaimVerificationManualReviewException());
  }

  void onSubmitProofs(Iterable<CreateClaimOutput> proofs) {
    if (isCompleted) {
      final error = StateError('onSubmitProofs called after verification is completed');
      logging.warning(error.message, error, StackTrace.current);
      return;
    }

    final result = ReclaimVerificationResult(
      provider: value.provider!,
      exactProviderVersion: value.providerVersion!.resolvedVersion,
      proofs: proofs.toList(),
    );
    value = value.copyWith(result: result);
    logging.event(Level.INFO.withEvent(LogEventType.RESULT_RECEIVED), 'Sending result');
  }

  ReclaimException? _lastReportedException;

  void reportException(ReclaimException exception, [StackTrace? stackTrace]) {
    if (_lastReportedException == exception) {
      // don't report the same exception twice
      return;
    }

    _log.info({'tag': 'reportException', 'exception': exception.toString(), 'stackTrace': StackTrace.current});

    _lastReportedException = exception;

    const SessionManager().onReclaimException(
      applicationId: request.applicationId,
      sessionId: _sessionInformation?.sessionId ?? '',
      providerId: request.providerId,
      exception: exception,
      errorCallbackUrl: options.errorCallbackUrl,
    );
  }

  void updateException(ReclaimException exception, [StackTrace? stackTrace]) {
    if (isCompleted) {
      final error = StateError('An exception occurred after verification is completed');
      logging.warning(error.message, exception, StackTrace.current);
      return;
    }

    reportException(exception, stackTrace);

    if (exception is ReclaimVerificationRequirementException) {
      // Requirement for verification could not be met. We can ignore this error.
      return;
    }

    if (value.exception != null) {
      _log.info('Ignoring new exception because there is already an existing exception: ${value.exception}');
      return;
    }

    value = value.copyWith(exception: exception);
  }

  @override
  void dispose() {
    _attestorUrlUpdatesSubscription?.cancel();
    _attestorUrlUpdatesSubscription = null;
    super.dispose();
  }

  Widget wrap({required Widget child}) {
    return _Provider(notifier: this, child: child);
  }

  static VerificationController readOf(BuildContext context) {
    final widget = context.getInheritedWidgetOfExactType<_Provider>();
    assert(
      widget != null,
      'No VerificationController provider found in the widget tree. Ensure you are using [VerificationController.wrap] in an ancestor to provider the [VerificationController].',
    );
    return widget!.notifier!;
  }

  static VerificationController of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<_Provider>();
    assert(
      widget != null,
      'No VerificationController provider found in the widget tree. Ensure you are using [VerificationController.wrap] in an ancestor to provider the [VerificationController].',
    );
    return widget!.notifier!;
  }
}

class _Provider extends InheritedNotifier<VerificationController> {
  const _Provider({required super.child, required VerificationController super.notifier});

  @override
  bool updateShouldNotify(covariant _Provider oldWidget) {
    return oldWidget.notifier?.value != notifier?.value;
  }
}
