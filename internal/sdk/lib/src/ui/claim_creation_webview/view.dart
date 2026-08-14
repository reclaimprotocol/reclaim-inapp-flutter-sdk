import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:material_ui/material_ui.dart';
import 'package:retry/retry.dart';

import '../../../attestor.dart';
import '../../controller.dart';
import '../../data/providers.dart';
import '../../exception/exception.dart';
import '../../logging/logging.dart';
import '../../repository/feature_flags.dart';
import '../../services/ai_services/ai_client_services.dart';
import '../../services/cookie_service.dart';
import '../../services/hybrid_screenshot_service.dart';
import '../../services/request_matcher.dart';
import '../../usecase/ai_flow/ai_action_controller.dart';
import '../../usecase/login_detection.dart';
import '../../utils/detection/login.dart';
import '../../utils/location.dart';
import '../../utils/observable_notifier.dart';
import '../../utils/sanitize.dart';
import '../../utils/single_work.dart';
import '../../utils/url.dart';
import '../../utils/webview_state_mixin.dart';
import '../../widgets/action_bar.dart';
import '../../widgets/ai_flow_coordinator_widget.dart';
import '../../widgets/claim_creation/claim_creation.dart';
import '../../widgets/feature_flags.dart';
import '../../widgets/verification_review/controller.dart';
import '../../widgets/verification_review/verification_review.dart';
import '../dev/dev.dart';
import 'manual_review/manual_review.dart';
import 'user_interaction_handler.dart';
import 'view_model.dart';
import 'webview_handler_manager.dart';
import 'window/controller.dart';

// wait for a few moments before automatically continuing to capture any claim triggers on this same page
const _waitForClaimAfterPageLoadDuration = Duration(milliseconds: 1400);

/// A widget that displays a web view that interacts with the user and emits events to the claim creation controller.
class ClaimCreationWebClient extends StatefulWidget {
  const ClaimCreationWebClient({super.key});

  @override
  State<ClaimCreationWebClient> createState() => _ClaimCreationWebClientState();
}

class _ClaimCreationWebClientState extends State<ClaimCreationWebClient>
    with WebViewCompanionMixin<ClaimCreationWebClient> {
  final List<StreamSubscription> _subscriptions = [];
  late final ManualReviewController _manualReviewController = ManualReviewController();
  AIActionController? _aiActionController;
  HybridScreenshotService? _screenshotService;
  AiServiceClient? _aiServiceClientRef;
  String? _sessionIdRef;
  late ClaimCreationController _claimCreationController;
  final GlobalKey _appRepaintBoundaryKey = GlobalKey();
  bool _hasContinueSucceeded = false;
  late VerificationController _verificationController;
  late VerificationReviewController _verificationReviewController;
  InAppWebViewController? _mainWebViewController;
  late WebViewJSHandlerManager _handlerManager;

  @override
  HybridScreenshotService? get screenshotService => _screenshotService;

  @override
  InAppWebViewController? get mainWebViewController => _mainWebViewController;

  @override
  WebViewJSHandlerManager get handlerManager => _handlerManager;

  @override
  ClaimCreationWebClientViewModel get viewModel => ClaimCreationWebClientViewModel.readOf(context);

  @override
  UnmodifiableListView<UserScript> get userScripts =>
      VerificationController.readOf(context).value.userScripts ?? UnmodifiableListView([]);

  @override
  PopupWindowController? get popupWindowController {
    try {
      return PopupWindowController.readOf(context);
    } catch (e) {
      logger.warning('PopupWindowController not found in widget tree: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    logger.fine('Initializing claim creation webview');
    _claimCreationController = ClaimCreationController.of(context, listen: false);
    _verificationController = VerificationController.readOf(context);
    _verificationReviewController = VerificationReviewController.readOf(context);
    _verificationReviewController.onExtendNoActivity = _onActivity;

    _handlerManager = WebViewJSHandlerManager(
      context: context,
      manualReviewController: _manualReviewController,
      onActivity: _onActivity,
      handleUserInteraction: handleUserInteraction,
      onProofData: onInterceptedRequest,
      onExtractedData: _onExtractedDataReceived,
      onAllowAppLinkRequest: setAllowedAppLink,
      onUpdateUserAgent: setUserAgent,
    );

    // VerificationController.identity can throw StateError in the beginning, the future that completes with it is [startingSession].
    FeatureFlagsProvider.readAfterSessionStartedOf(context).then((featureFlagProvider) async {
      featureFlagProvider.checkAndClearExpiredFlags();
      _subscriptions.add(featureFlagProvider.stream(FeatureFlag.isWebInspectable).listen(_onWebViewInspectableChanged));
      featureFlagProvider.get(FeatureFlag.isWebInspectable).then(_onWebViewInspectableChanged);
      final sessionDuration = await featureFlagProvider.get(FeatureFlag.sessionNoActivityTimeoutDurationInMins);
      final aiProviderDuration = await featureFlagProvider.get(FeatureFlag.aiProviderNoActivityTimeoutDurationInSecs);
      _startNoActivityObserver(sessionDuration, aiProviderDuration);
    });
    _subscriptions.add(_claimCreationController.subscribe(_onClaimCreationControllerChanges));
    final vm = ClaimCreationWebClientViewModel.readOf(context);
    vm.onUpdateWebView = _onUpdateWebView;
    _initializeAIActionController();
    AIFlowCoordinatorWidget.readOf(context)?.webContext.setHideReviewSheetCallback(() async {
      if (!mounted) return;
      final vm = ClaimCreationWebClientViewModel.readOf(context);
      final controller = vm.getController();
      return _hideReviewSheetIfRequired(controller, await controller.getUrl());
    });
  }

  late GlobalKey _webviewKey = GlobalKey();

  Future<void> _onUpdateWebView() async {
    final log = logger.child('onUpdateWebView');
    log.info('updating webview key');
    if (!mounted) {
      log.info('not updating webview key because not mounted');
      return;
    }
    setState(() {
      _wasInitializedWithIncognito = null;
      _webviewKey = GlobalKey();
    });
  }

  Future<void> _initializeAIActionController() async {
    final verification = VerificationController.readOf(context);
    final session = await verification.sessionStartFuture;
    if (!mounted) return;
    final aiServiceClient = AiServiceClient(
      session.sessionInformation.sessionId,
      session.identity.providerId,
      sessionToken: session.sessionInformation.sessionToken,
    );
    _aiServiceClientRef = aiServiceClient;
    _sessionIdRef = session.sessionInformation.sessionId;
    _aiActionController = AIActionController(context, aiServiceClient);

    _setupAIActionController(verification);
    // Initialize screenshot service for AI providers
    if (verification.value.provider?.isAIProvider == true) {
      _initializeScreenshotService(aiServiceClient, session.sessionInformation.sessionId);
    }
  }

  void _initializeScreenshotService(AiServiceClient aiServiceClient, String sessionId) {
    logger.info('Initializing hybrid screenshot service for AI provider');
    final verification = VerificationController.readOf(context);
    _screenshotService = HybridScreenshotService(
      aiServiceClient: aiServiceClient,
      sessionId: sessionId,
      providerId: verification.identity.providerId,
    );
  }

  void _setupAIActionController(VerificationController verification) {
    if (verification.value.provider == null) {
      _subscriptions.add(
        verification.subscribe((change) {
          final (oldValue, value) = change.record;
          if (value.provider != null && value.provider?.isAIProvider == true) {
            _aiActionController?.start();
            if (_screenshotService == null && _aiServiceClientRef != null && _sessionIdRef != null) {
              logger.info('Initializing hybrid screenshot service (late) for AI provider');
              _initializeScreenshotService(_aiServiceClientRef!, _sessionIdRef!);
            }
          }
        }),
      );
    } else if (verification.value.provider?.isAIProvider == true) {
      _aiActionController?.start();
      if (_screenshotService == null && _aiServiceClientRef != null && _sessionIdRef != null) {
        logger.info('Initializing hybrid screenshot service (immediate) for AI provider');
        _initializeScreenshotService(_aiServiceClientRef!, _sessionIdRef!);
      }
    }
  }

  @override
  void dispose() {
    logger.info('Disposing claim creation webview');
    _sessionNoActivityObserverTimer?.cancel();
    _sessionNoActivityObserverTimer = null;
    for (final s in _subscriptions) {
      s.cancel();
    }
    _aiActionController?.stop();
    _screenshotService?.dispose();
    _manualReviewController.dispose();
    super.dispose();
  }

  bool? isInspectablePreference;

  void _onWebViewInspectableChanged(bool isInspectable) async {
    if (mounted) {
      setState(() {
        isInspectablePreference = isInspectable;
      });

      ClaimCreationWebClientViewModel.readOf(context).setWebViewSettings((settings) {
        if (settings.isInspectable != isInspectable) {
          settings.isInspectable = isInspectable;
          return settings;
        }
        return null;
      });
    }
  }

  Timer? _continueTimer;

  void _onClaimCreationControllerChanges(ChangedValues<ClaimCreationControllerState> changes) {
    if (changes.oldValue?.isWaitingForContinuation != changes.value.isWaitingForContinuation &&
        changes.value.isWaitingForContinuation) {
      _continueTimer?.cancel();
      _continueTimer = Timer(_waitForClaimAfterPageLoadDuration, _onContinueAutomatically);
    }
    if (changes.oldValue?.status != changes.value.status &&
        changes.value.status == ClaimCreationStatus.retryRequested) {
      _continueTimer?.cancel();
    }
  }

  void _onContinueAutomatically() async {
    final log = logger.child('_onContinueAutomatically');
    try {
      if (!mounted) return;

      final options = ClaimCreationUIDelegateOptions.of(context, listen: false);
      final controller = ClaimCreationController.of(context, listen: false);

      final nextLocation = controller.getNextLocation();
      if (nextLocation == null) {
        log.finest('No next location found');
        // do nothing
        // If bottomsheet is open, it may show a button to continue
        return;
      }

      log.finest('onContinueAutomatically: $nextLocation');

      // wait for continuation to complete
      try {
        final didContinue = await options?.onContinue(nextLocation).timeout(const Duration(seconds: 10));
        if (didContinue != true) {
          log.finest('onContinueAutomatically [$didContinue]: $nextLocation');
        }
      } on TimeoutException {
        // do nothing
      }
    } catch (e, s) {
      log.severe('Failed to continue automatically', e, s);
    }
  }

  final logger = logging.child('ClaimCreationWebView');

  // methods related to claim creation - webview configuration

  void _onLoad(InAppWebViewController controller, WebUri? uri) async {
    logger.log(
      Level.INFO.withEvent(LogEventType.PAGE_LOADING_STARTED),
      'page loading started on ${logging.wrapPIIUri(uri)}',
    );
    _hideToken = Object();
    final vm = ClaimCreationWebClientViewModel.readOf(context);
    final webContext = AIFlowCoordinatorWidget.of(context).webContext;
    final url = uri?.toString();
    if (url == null || url == 'about:blank') {
      return;
    }

    vm.setDisplayUrl(url.toString());
    vm.setDisplayProgress(0.05);
    vm.onLoadStart();
    webContext.setCurrentWebPageUrl(url);
    _claimCreationController.value.delegate?.showReview();
  }

  void _onLoadStop(InAppWebViewController controller, WebUri? uri) {
    logger.log(
      Level.INFO.withEvent(LogEventType.PAGE_LOADING_STOPPED),
      'page loading stopped on ${logging.wrapPIIUri(uri)}',
    );
    final vm = ClaimCreationWebClientViewModel.readOf(context);
    if (uri != null) vm.setDisplayUrl(uri.toString());
    vm.setDisplayProgress(1);
    vm.onLoadStop();
    if (uri?.toString().isNotEmpty == true) {
      evaluateIfNavigationToExpectedPageIsRequired();
    }
    _hideReviewSheetIfRequired(controller, uri);
  }

  static bool _hasWaitedForZKOperatorInitWithLongDuration = false;

  int _estimateZKOperatorInitDuration() {
    if (!_hasWaitedForZKOperatorInitWithLongDuration) {
      _hasWaitedForZKOperatorInitWithLongDuration = true;
      // estimate time took to complete download + init on physical device
      const estimateZKOperatorInitDuration = 4;

      return estimateZKOperatorInitDuration;
    } else {
      return 2;
    }
  }

  bool _wasPreviouslyLoggedIn = false;

  Object? _hideToken;
  void _hideReviewSheetIfRequired(InAppWebViewController controller, WebUri? uri) async {
    if (_verificationController.value.provider?.isAIProvider == true) {
      _hideReviewSheetIfRequiredRemoteDetection(controller, uri);
    } else {
      _hideReviewSheetIfRequiredLocalDetection(controller, uri);
    }
  }

  void _hideReviewSheetIfRequiredLocalDetection(InAppWebViewController controller, WebUri? uri) async {
    final log = logger.child('_hideReviewSheetIfRequiredLocalDetection');
    if (!mounted) return;
    final token = Object();
    _hideToken = token;
    final claimCreationController = ClaimCreationController.of(context, listen: false);
    final vm = ClaimCreationWebClientViewModel.readOf(context);
    final loginDetection = LoginDetection.readOf(context);
    final url = (uri ?? await controller.getUrl())?.toString();
    log.fine({'url': url, 'isWaitingForContinuation': claimCreationController.value.isWaitingForContinuation});
    if (!claimCreationController.value.isWaitingForContinuation) return;

    // Wait for page to render elements
    await Future.delayed(const Duration(milliseconds: 500));

    if (vm.value.isLoading) {
      log.fine('not hiding review sheet because webview is loading');
      return;
    }

    if (url != null && (await loginDetection.maybeRequiresLoginInteraction(url, controller))) {
      // Another _hideReviewSheetIfRequired call had been made
      if (_hideToken != token) return;
      log.finest('Closing review sheet because login page');
      requiresUserInteraction(true);
      _wasPreviouslyLoggedIn = false;
    } else {
      if (!_wasPreviouslyLoggedIn) {
        _onActivity();
      }
      _wasPreviouslyLoggedIn = true;
      // TODO: hide if user interaction is required (from ai suggestion) even if zk operator is not initialized yet
      if (claimCreationController.value.isIdle) {
        // Wait for a few seconds to let any proof generation or js injection activity
        await Future.delayed(const Duration(seconds: 4));
      } else {
        for (var i = 0; i < 3; i++) {
          await Future.delayed(Duration(seconds: _estimateZKOperatorInitDuration()));
          // exit if proof generation has started
          if (!claimCreationController.value.isWaitingForContinuation) return;
        }
      }
      // The amount of time we take to wait here should be less than the time (6+ seconds) it takes for continue automatically to appear from review sheet.
      final nextLocation = claimCreationController.getNextLocation();
      if (nextLocation != null) {
        final fullExpectedUrl = createUrlFromLocation(nextLocation, url);
        final canContinue = url == null ? true : !isUrlsEqual(url, fullExpectedUrl);
        if (canContinue) return;
      }

      if (!mounted) return;
      if (await controller.isLoading()) return;
      if (!claimCreationController.value.isWaitingForContinuation) return;

      log.fine(
        'Checking if review sheet can be closed (no proof generation started). can hide: ${_hideToken == token}',
      );

      // Another _hideReviewSheetIfRequired call had been made
      if (_hideToken != token) return;

      log.finest('Closing review sheet because no proof generation started');
      requiresUserInteraction(true);
    }
  }

  void _hideReviewSheetIfRequiredRemoteDetection(InAppWebViewController controller, WebUri? uri) async {
    final log = logger.child('_hideReviewSheetIfRequiredRemoteDetection');
    if (!mounted) return;
    final token = Object();
    _hideToken = token;
    final claimCreationController = ClaimCreationController.of(context, listen: false);
    final vm = ClaimCreationWebClientViewModel.readOf(context);
    final webContext = AIFlowCoordinatorWidget.of(context).webContext;
    final url = (uri ?? await controller.getUrl())?.toString();
    log.fine({'url': url, 'isWaitingForContinuation': claimCreationController.value.isWaitingForContinuation});
    if (!claimCreationController.value.isWaitingForContinuation) return;

    // Wait for page to render elements
    await Future.delayed(const Duration(milliseconds: 500));

    if (vm.value.isLoading) {
      log.fine('not hiding review sheet because webview is loading');
      return;
    }

    if (url != null && requiresLoginInteraction(webContext) && !potentiallyLoggedIn(webContext, url)) {
      // Another _hideReviewSheetIfRequired call had been made
      if (_hideToken != token) return;
      log.finest('Closing review sheet because login page');
      requiresUserInteraction(true);
    } else {
      // The amount of time we take to wait here should be less than the time (6+ seconds) it takes for continue automatically to appear from review sheet.
      for (var i = 0; i < 3; i++) {
        final nextLocation = claimCreationController.getNextLocation();
        if (nextLocation != null) {
          final fullExpectedUrl = createUrlFromLocation(nextLocation, url);
          final canContinue = url == null ? true : !isUrlsEqual(url, fullExpectedUrl);
          if (canContinue) return;
        }

        await Future.delayed(
          Duration(seconds: claimCreationController.value.isIdle ? _estimateZKOperatorInitDuration() : 4),
        );

        if (!mounted) return;
        if (await controller.isLoading()) return;
        if (!claimCreationController.value.isWaitingForContinuation) return;
      }

      log.fine(
        'Checking if review sheet can be closed (no proof generation started). can hide: ${_hideToken == token}',
      );

      // Another _hideReviewSheetIfRequired call had been made
      if (_hideToken != token) return;

      log.info(
        'Checking if review sheet can be closed (ai did not respond recently). ai responded recently: ${webContext.aiRespondedRecently()}, isLoggedIn: ${webContext.isLoggedIn}',
      );

      // If the ai flow responded recently and the user is logged in, we don't want to close the review sheet
      if (webContext.aiRespondedRecently() && webContext.isLoggedIn) return;

      log.finest('Closing review sheet because no proof generation started and ai did not respond recently');
      requiresUserInteraction(true);
    }
  }

  void _onWebViewCreated(InAppWebViewController controller) async {
    try {
      logger.fine('onWebViewCreated');
      final vm = ClaimCreationWebClientViewModel.readOf(context);
      _handlerManager.registerHandlers(controller);
      vm.setController(controller);

      _mainWebViewController = controller;

      // Start hybrid screenshot capturing if this is an AI provider
      if (_screenshotService != null) {
        logger.info('Starting hybrid screenshot capture for AI provider');
        final intervalSeconds = await FeatureFlagsProvider.readOf(context)
            .get(FeatureFlag.screenshotCaptureIntervalSeconds);
        _screenshotService!.startCapturing(
          webViewController: controller,
          appKey: _appRepaintBoundaryKey,
          interval: Duration(seconds: intervalSeconds),
        );
      }
    } catch (e, s) {
      logger.severe('Failed to set controller', e, s);
    }
  }

  void evaluateIfNavigationToExpectedPageIsRequired() async {
    final log = logger.child('evaluateUrlOnLoadStop');

    final verification = VerificationController.readOf(context);
    final isAIProvider = verification.value.provider?.isAIProvider == true;
    if (!isAIProvider) {
      log.info('Skipping evaluation because provider is not AI');
      return;
    }

    final claimCreationController = ClaimCreationController.of(context, listen: false);

    final nextLocation = claimCreationController.getNextLocation();
    if (nextLocation == null) {
      // Do nothing, wait for user to press the continue button
      return;
    }

    log.info('evaluateIfNavigationToExpectedPageIsRequired: $nextLocation');

    // If onContinue has already succeeded once, don't call it again
    if (_hasContinueSucceeded) {
      log.info('onContinue has already succeeded, skipping call');
      return;
    }

    final vm = ClaimCreationWebClientViewModel.readOf(context);
    final webContext = AIFlowCoordinatorWidget.of(context).webContext;
    final loginDetection = LoginDetection.readOf(context);

    final didContinue = await vm.onContinue(webContext, loginDetection, nextLocation, isAIProvider);
    if (didContinue) {
      _hasContinueSucceeded = true;
      log.info('onContinue succeeded, setting _hasContinueSucceeded to true');
    }
  }

  late final _webviewInitializationDelay = Future.delayed(const Duration(milliseconds: 100));

  bool? _wasInitializedWithIncognito;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _appRepaintBoundaryKey,
      child: ManualReviewObserver(
        controller: _manualReviewController,
        child: VerificationReview(
          onExtendNoActivity: _onActivity,
          child: FutureBuilder(
            // This delay is to ensure that the webview plugin is ready before it makes android surface call.
            // without this, the webview crashes on react native inapp sdk.
            future: _webviewInitializationDelay,
            builder: (context, asyncSnapshot) {
              final settings = defaultWebViewSettings.copy();
              final controller = VerificationController.of(context);
              final provider = controller.value.provider;

              // keep showing blank until the webview init delay has passed.
              if (asyncSnapshot.connectionState != ConnectionState.done || provider == null) {
                return const SizedBox.shrink();
              }

              final incognito = provider.useIncognitoWebview;
              settings.incognito = incognito;
              settings.isInspectable = isInspectablePreference ?? kDebugMode;

              final value = incognito;
              if (_wasInitializedWithIncognito == null) {
                logger.info('setting _wasInitializedWithIncognito to $value');
                _wasInitializedWithIncognito = value;
              }

              return InAppWebView(
                key: _webviewKey,
                onUpdateVisitedHistory: (controller, uri, isReloaded) {
                  final vm = ClaimCreationWebClientViewModel.readOf(context);
                  if (uri != null) {
                    vm.setDisplayUrl(uri.toString());
                  }
                },
                gestureRecognizers: gestureRecognizers,
                onGeolocationPermissionsShowPrompt: onGeolocationPermissionsShowPrompt,
                onPermissionRequest: onPermissionRequestedFromWeb,
                onWebViewCreated: _onWebViewCreated,
                onRenderProcessGone: (controller, details) async {
                  logger.severe('os murdered foreground webview', details);
                  if (!mounted) return;

                  try {
                    _onUpdateWebView();

                    await Future.delayed(const Duration(seconds: 1));

                    if (!context.mounted) return;

                    final value = VerificationController.readOf(context).value;
                    final provider = value.provider;
                    final userScripts = value.userScripts;
                    if (provider != null && userScripts != null) {
                      ClaimCreationWebClientViewModel.readOf(context)
                          .load(provider: provider, userScripts: userScripts)
                          .catchError((e, s) {
                            if (context.mounted) {
                              logger.severe('Failed to load client web', e, s);
                              VerificationController.readOf(context).updateException(
                                const ReclaimVerificationProviderLoadException('Failed to load scripts'),
                              );
                            }
                          });
                    }
                  } catch (e, s) {
                    logger.severe('Failed to load client web after render process gone', e, s);
                  }
                },
                onLoadStart: _onLoad,
                initialSettings: settings,
                onProgressChanged: (controller, progress) {
                  final vm = ClaimCreationWebClientViewModel.readOf(context);
                  vm.setDisplayProgress(progress / 100);
                },
                onLoadStop: _onLoadStop,
                onCreateWindow: onCreateWindowAction,
                shouldOverrideUrlLoading: shouldOverrideUrlLoading,
                onReceivedServerTrustAuthRequest: onReceivedServerTrustAuthRequest,
                onReceivedHttpError: onReceivedHttpError,
              );
            },
          ),
        ),
      ),
    );
  }

  void requiresUserInteraction(bool isUserInteractionRequired) {
    if (isUserInteractionRequired) {
      _claimCreationController.value.delegate?.hideReview();
    } else {
      _claimCreationController.value.delegate?.showReview();
    }
  }

  Timer? _sessionNoActivityObserverTimer;
  DateTime lastActivityDetectedAt = DateTime.now();

  void _startNoActivityObserver(int sessionDurationInMins, int aiProviderDurationInSecs) {
    logger.info('Starting no activity observer');

    void removeNoActivityError() {
      if (!mounted) {
        return;
      }
      if (_claimCreationController.value.clientError is ReclaimVerificationNoActivityDetectedException) {
        _claimCreationController.setClientError(null);
      }
    }

    _sessionNoActivityObserverTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final provider = _claimCreationController.value.httpProvider;

      if (_claimCreationController.value.canExpectManyClaims) {
        logger.finest('No activity detection skipped because canExpectManyClaims is enabled');
        _onActivity();
        removeNoActivityError();
        return;
      }
      if (_claimCreationController.value.isFinished) {
        logger.finest('No activity detection stopped because verification is finished');
        if (_claimCreationController.value.isFinished) {
          _sessionNoActivityObserverTimer?.cancel();
          _sessionNoActivityObserverTimer = null;
        }
        removeNoActivityError();
        return;
      }
      if (_claimCreationController.value.hasError) {
        if (_claimCreationController.value.clientError is! ReclaimVerificationNoActivityDetectedException) {
          logger.finest('No activity detection skipped because of error');
          logger.finest('Error was: ${_claimCreationController.value.debugErrorDetails()}');
        }
        return;
      }
      if (provider?.isAIProvider == true && _claimCreationController.value.isComputingProofs) {
        logger.finest('No activity detection skipped because provider is AI and isComputingProofs is true');
        return;
      }

      final durationSinceLastActivity = DateTime.now().difference(lastActivityDetectedAt).abs();
      final noActivityDuration = _getNoActivityDuration(sessionDurationInMins, aiProviderDurationInSecs, provider);
      if (durationSinceLastActivity >= noActivityDuration) {
        logger.event(
          Level.INFO.withEvent(LogEventType.RECLAIM_VERIFICATION_NO_ACTIVITY_DETECTED_EXCEPTION),
          'Reporting no activity detected for duration $durationSinceLastActivity',
        );
        _claimCreationController.setClientError(
          // This may show a different message in UI
          const ReclaimVerificationNoActivityDetectedException('The verification timed out'),
        );
        return;
      }
    });
  }

  void _onActivity() {
    lastActivityDetectedAt = DateTime.now();
    if (mounted) {
      _claimCreationController.removeClientError();
    }
  }

  Duration _getNoActivityDuration(int sessionDurationInMins, int aiProviderDurationInSecs, HttpProvider? provider) {
    if (provider?.isAIProvider == true) {
      if (provider?.requestData.isEmpty == true) {
        // If the provider is AI and the request data is empty, it means the provider is not yet ready to start the verification.
        return Duration(minutes: sessionDurationInMins * 2);
      }
      // If the provider is AI and the request data is not empty, it means the provider is ready to start the verification.
      return Duration(seconds: aiProviderDurationInSecs);
    }
    return Duration(minutes: sessionDurationInMins);
  }

  Future<Duration> _getClaimCreationTimeoutDuration() async {
    final timeoutDuration = await () async {
      try {
        final timeoutDurationInMins = await FeatureFlagsProvider.readOf(context)
            .get(FeatureFlag.claimCreationTimeoutDurationInMins)
            .timeout(const Duration(seconds: 5));
        return Duration(minutes: timeoutDurationInMins);
      } catch (e, s) {
        logger.severe('Failed to get claim creation timeout duration', e, s);
        return const Duration(minutes: 2);
      }
    }();
    logger.info('Using claim creation timeout duration: $timeoutDuration');
    return timeoutDuration;
  }

  bool _canIntercept = false;

  void onInterceptedRequest(List<dynamic> args) {
    if (!mounted) return;

    if (!_canIntercept) {
      _canIntercept = true;
      logger.event(Level.INFO.withEvent(LogEventType.REQUEST_INTERCEPTED), 'Request interceptor working');
    }

    final request = json.decode(args[0]);

    final verification = VerificationController.readOf(context);
    final devtoolProviderRequests = verification.value.matchableDevtoolProviderRequests ?? const [];

    if (devtoolProviderRequests.isEmpty) {
      logger.info('A request was received but there were no requests declared in provider. skipping.');
      return;
    }

    final matcher = RequestMatcher(devtoolProviderRequests: devtoolProviderRequests);

    final normalizedRequest = matcher.normalizeRequest(request);
    final matchedRequests = matcher.findMatch(normalizedRequest);

    if (matchedRequests.isNotEmpty) {
      for (final it in matchedRequests) {
        logger.event(
          Level.INFO.withEvent(LogEventType.REQUEST_MATCHED),
          'Request matched with internal claim request id ${it.dataRequest.requestIdentifier}',
        );
        onProofDataReceived(normalizedRequest, it.dataRequest);
      }
    }
  }

  void onProofDataReceived(Map proofData, DataProviderRequest requestData) async {
    final logger = logging.child('webview_screen.onProofDataReceived.${Object().hashCode}');
    logger.info('Completed request matching to start proof generation from webview');

    _onActivity();

    final vm = ClaimCreationWebClientViewModel.readOf(context);
    final messenger = ActionBarMessenger.of(context);
    final claimCreationController = ClaimCreationController.of(context, listen: false);
    final verification = VerificationController.readOf(context);

    final claimCreationTimeoutDurationFuture = _getClaimCreationTimeoutDuration();

    final userAgent = await vm.getWebViewUserAgent();
    final actionControl = messenger.show(const ActionBarMessage(type: ActionMessageType.claim));
    try {
      _aiActionController?.pause();

      DevController.shared.push('matchedRequest', proofData);

      final url = WebUri(proofData['url']);

      DevController.shared.push('DataProviderRequest', requestData);

      if (claimCreationController.value.isCompleted(requestData.requestIdentifier)) {
        logger.info(
          'Claim creation request by hash ${requestData.requestHash} was received but it is already completed. skipping.',
        );
        return;
      }
      logger.event(
        Level.INFO.withEvent(LogEventType.PREPARING_CLAIM),
        'Matched claim creation request with hash ${requestData.requestHash}, evaluating this with id ${requestData.requestIdentifier}',
      );

      final cs = CookieService();
      final String cookieString = await cs.getCookieString(url, credentials: requestData.credentials);

      final headersFromProof = proofData['headers'] as Map;

      logger.debug({'headers': json.encode(headersFromProof)});

      final Map<String, String> headers = Map<String, String>.from({
        for (final entry in headersFromProof.entries) entry.key.toString(): entry.value.toString(),
      });

      final refererUrl = await vm.getCurrentRefererUrl(verification.value.provider?.loginUrl ?? '');

      headers['Referer'] ??= refererUrl;
      headers['User-Agent'] = userAgent;
      headers['Sec-Fetch-Mode'] ??= 'same-origin';
      headers['Sec-Fetch-Site'] ??= 'same-origin';
      final geoLocation = await getUserLocation(verification.value.provider?.geoLocation);

      if (!mounted) {
        logger.info('Claim creation cannot be started because the page is closed');
        return;
      }
      logger.info('Claim creation process is starting..');

      final isSingleClaimRequest = await FeatureFlagsProvider.readOf(context).get(FeatureFlag.isSingleClaimRequest);

      var request = ClaimCreationRequest(
        httpProviderId: verification.request.providerId,
        appId: verification.request.applicationId,
        claimContext: verification.request.contextString ?? '',
        sessionId: verification.sessionInformation.sessionId,
        proofData: proofData,
        providerData: verification.value.provider!,
        headers: headers,
        initialWitnessParams: verification.request.parameters,
        cookieString: cookieString,
        useSingleRequest: isSingleClaimRequest,
        requestData: requestData,
        geoLocation: geoLocation,
        createClaimOptions: AttestorClaimOptions(
          attestorAuthenticationRequest: verification.value.attestorAuthenticationRequest,
          claimCreationType: verification.options.claimCreationType,
        ),
        claimCreationTimeoutDuration: await claimCreationTimeoutDurationFuture,
      );

      logger.info(
        isSingleClaimRequest
            ? 'Single request feature using claim creation is enabled'
            : 'Single request feature using claim creation is disabled',
      );

      if (!isSingleClaimRequest) {
        logger.event(
          Level.INFO.withEvent(LogEventType.VALIDATING_CLAIM_PARAMETERS),
          'Validating claim request parameters',
        );
        // update request with extracted data here with response redactions
        request = await retry(
          () async {
            return await claimCreationController.validateClaim(proofData['response'], request);
          },
          retryIf: (e) {
            logger.warning('failed to create request with updated provider params, checking if we can retry', e);
            return e is AttestorClientNotReadyException || e is TimeoutException;
          },
        );
      }

      logger.info('Starting claim creation');
      await claimCreationController.startClaimCreation(request);
      logger.info('Claim creation finished');
      _onActivity();
    } on ClaimCreationCancelledException {
      logger.info('claim creation was canceled');
    } on WorkCanceledException {
      logger.info('Claim creation stopped because the work was canceled (could be duplicate)');
    } on ReclaimException catch (e, s) {
      logger.severe('Claim creation stopped due to a reclaim exception', e, s);
      verification.updateException(e);
    } catch (e, s) {
      logger.severe('Claim creation stopped due to an unexpected error', e, s);
    } finally {
      actionControl.close();
    }
  }

  Future<void> _onExtractedDataReceived(List<dynamic> args) async {
    final logger = logging.child('webview_screen.extractedData.${Object().hashCode}');
    logger.event(
      Level.INFO.withEvent(LogEventType.PROVIDER_SCRIPT_REQUESTED_CLAIM),
      'Received claim request start proof generation from provider script running in webview',
    );

    _onActivity();

    final vm = ClaimCreationWebClientViewModel.readOf(context);
    final messenger = ActionBarMessenger.of(context);
    final claimCreationController = ClaimCreationController.of(context, listen: false);

    // Discard any new claim creation if there is a provider script error
    if (claimCreationController.value.hasProviderScriptError) return;

    final verification = VerificationController.readOf(context);

    final claimCreationTimeoutDurationFuture = _getClaimCreationTimeoutDuration();

    final userAgent = await vm.getWebViewUserAgent();
    final actionControl = messenger.show(const ActionBarMessage(type: ActionMessageType.claim));
    try {
      _aiActionController?.pause();

      if (args[0] == 'onboarding:exit_webview') {
        logger.info('Exiting webview because of exit webview');
        return;
      }

      final extractData = json.decode(args[0]);

      DevController.shared.push('requestedClaim', extractData);

      final requestData = DataProviderRequest.fromScriptInvocation(extractData);

      DevController.shared.push('DataProviderRequest', requestData);

      if (claimCreationController.value.isCompleted(requestData.requestIdentifier)) {
        logger.info('Request by id ${requestData.requestIdentifier} is already completed. skipping.');
        return;
      }

      logger.event(
        Level.INFO.withEvent(LogEventType.PREPARING_CLAIM),
        'evaluating request by id ${requestData.requestIdentifier}',
      );

      final url = WebUri(extractData['url']);
      final cs = CookieService();
      final String cookieString = await cs.getCookieString(url, credentials: requestData.credentials);

      final Map<String, String> headers =
          (extractData['headers'] is Map ? ensureMap<String, String>(extractData['headers']) : null) ??
          <String, String>{};
      final refererUrl = await vm.getCurrentRefererUrl(verification.value.provider?.loginUrl ?? '');
      headers['Referer'] = refererUrl;
      headers['User-Agent'] = userAgent;
      headers['Sec-Fetch-Mode'] = 'same-origin';
      extractData['witnessParameters'] = Map<String, String>.from({
        ...?ensureMap<String, String>(extractData['witnessParameters']),
        ...?ensureMap<String, String>(extractData['extractedParams']),
      });
      if (!mounted) {
        logger.info('Claim creation cannot be started because the Webview has been disposed');
        return;
      }
      logger.info('Claim creation is starting.. opening claim creation bottom sheet on extractedData');

      final Map<String, String>? extractedDataWitnessParameters = extractData['witnessParameters'];

      final Map<String, String> initialWitnessParams = {
        ...verification.request.parameters,
        ...?extractedDataWitnessParameters,
      };

      final geoLocation = await getUserLocation(extractData['geoLocation']);

      var request = ClaimCreationRequest(
        httpProviderId: verification.request.providerId,
        appId: verification.request.applicationId,
        claimContext: verification.request.contextString ?? '',
        sessionId: verification.sessionInformation.sessionId,
        proofData: extractData,
        providerData: verification.value.provider!,
        headers: headers,
        initialWitnessParams: initialWitnessParams,
        cookieString: cookieString,
        useSingleRequest: false,
        requestData: requestData,
        createClaimOptions: AttestorClaimOptions(
          attestorAuthenticationRequest: verification.value.attestorAuthenticationRequest,
          claimCreationType: verification.options.claimCreationType,
        ),
        geoLocation: geoLocation,
        isRequestFromProviderScript: true,
        claimCreationTimeoutDuration: await claimCreationTimeoutDurationFuture,
      );

      logger.info('Starting claim creation');
      await claimCreationController.startClaimCreation(request);
      logger.info('Claim creation bottom sheet closed');
      _onActivity();
    } on ReclaimException catch (e, s) {
      logger.severe('Claim creation stopped due to a reclaim exception', e, s);
      verification.updateException(e);
    } on ClaimCreationCancelledException {
      logger.info('claim creation was canceled');
    } on WorkCanceledException {
      logger.info('Claim creation stopped because the work was canceled');
    } catch (e, s) {
      logger.severe('Claim creation stopped due to an error', e, s);
    } finally {
      actionControl.close();
    }
  }
}
