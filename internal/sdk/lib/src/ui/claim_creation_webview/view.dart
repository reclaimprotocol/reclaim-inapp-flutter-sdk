import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../attestor.dart';
import '../../controller.dart';
import '../../data/http_request_log.dart';
import '../../data/login_message.dart';
import '../../data/manual_review.dart';
import '../../data/providers.dart';
import '../../exception/exception.dart';
import '../../logging/logging.dart';
import '../../repository/feature_flags.dart';
import '../../services/cookie_service.dart';
import '../../utils/detection/login.dart';
import '../../utils/location.dart';
import '../../utils/observable_notifier.dart';
import '../../utils/sanitize.dart';
import '../../utils/single_work.dart';
import '../../utils/url.dart';
import '../../utils/webview_state_mixin.dart';
import '../../widgets/action_bar.dart';
import '../../widgets/claim_creation/claim_creation.dart';
import '../../widgets/feature_flags.dart';
import '../../widgets/verification_review/controller.dart';
import '../../widgets/verification_review/verification_review.dart';
import 'manual_review/manual_review.dart';
import 'view_model.dart';

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
  late ManualReviewController _manualReviewController;
  late ClaimCreationController _claimCreationController;

  @override
  void initState() {
    super.initState();
    _manualReviewController = ManualReviewController();
    _claimCreationController = ClaimCreationController.of(context, listen: false);
    // VerificationController.identity can throw StateError in the beginning, the future that completes with it is [startingSession].
    FeatureFlagsProvider.readAfterSessionStartedOf(context).then((featureFlagProvider) {
      _subscriptions.add(featureFlagProvider.stream(FeatureFlag.isWebInspectable).listen(_onWebViewInspectableChanged));
    });
    _subscriptions.add(_claimCreationController.changesStream.listen(_onClaimCreationControllerChanges));
    _subscriptions.add(
      VerificationReviewController.readOf(context).changesStream.listen(_onVerificationReviewControllerChanges),
    );
    _manualReviewController = ManualReviewController();
    final vm = ClaimCreationWebClientViewModel.readOf(context);
    vm.onUpdateWebView = _onUpdateWebView;
  }

  late GlobalKey _webviewKey = GlobalKey();

  void _onUpdateWebView() {
    final log = logger.child('onUpdateWebView');
    log.info('updating webview key');
    setState(() {
      _webviewKey = GlobalKey();
    });
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _manualReviewController.dispose();
    super.dispose();
  }

  void _onWebViewInspectableChanged(bool isInspectable) async {
    ClaimCreationWebClientViewModel.readOf(context).setWebViewSettings((settings) {
      if (settings.isInspectable != isInspectable) {
        settings.isInspectable = isInspectable;
        return settings;
      }
      return null;
    });
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
        final didContinue = await options?.onContinue(nextLocation).timeout(Duration(seconds: 10));
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
    logger.info('page loading started on $uri');
    _hideToken = Object();
    final vm = ClaimCreationWebClientViewModel.readOf(context);
    final url = uri?.toString();
    if (url == null || url == 'about:blank') {
      return;
    }

    vm.setDisplayUrl(url.toString());
    vm.setDisplayProgress(0.05);
    vm.onLoadStart();
    _claimCreationController.value.delegate?.showReview();
  }

  void _onLoadStop(InAppWebViewController controller, WebUri? uri) {
    logger.fine('page loading stopped on $uri');
    final vm = ClaimCreationWebClientViewModel.readOf(context);
    if (uri != null) vm.setDisplayUrl(uri.toString());
    vm.setDisplayProgress(1);
    vm.onLoadStop();
    if (uri?.toString().isNotEmpty == true) {
      evaluateIfNavigationToExpectedPageIsRequired();
    }
    _hideReviewSheetIfRequired(controller, uri);
  }

  bool _hasWaitedForZKOperatorInit = false;

  int _idleWaitDurationInSeconds() {
    if (!_hasWaitedForZKOperatorInit) {
      _hasWaitedForZKOperatorInit = true;
      const estimateZKOperatorInitDuration = 10;

      return estimateZKOperatorInitDuration;
    } else {
      return 4;
    }
  }

  Object? _hideToken;
  void _hideReviewSheetIfRequired(InAppWebViewController controller, WebUri? uri) async {
    final log = logger.child('_hideReviewSheetIfRequired');
    if (!mounted) return;
    final token = Object();
    _hideToken = token;
    final claimCreationController = ClaimCreationController.of(context, listen: false);
    final vm = ClaimCreationWebClientViewModel.readOf(context);
    final url = (uri ?? await controller.getUrl())?.toString();
    log.fine({'url': url, 'isWaitingForContinuation': claimCreationController.value.isWaitingForContinuation});
    if (!claimCreationController.value.isWaitingForContinuation) return;

    // Wait for page to render elements
    await Future.delayed(Duration(milliseconds: 500));

    if (vm.value.isLoading) {
      log.fine('not hiding review sheet because webview is loading');
      return;
    }

    if (url != null && (await maybeRequiresLoginInteraction(url, controller))) {
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

        // TODO: hide if user interaction is required (from ai suggestion) even if zk operator is not initialized yet
        await Future.delayed(
          Duration(seconds: claimCreationController.value.isIdle ? _idleWaitDurationInSeconds() : 5),
        );

        if (!mounted) return;
        if (await controller.isLoading()) return;
        if (!claimCreationController.value.isWaitingForContinuation) return;
      }

      log.fine('Closing review sheet because no proof generation started. can hide: ${_hideToken == token}');

      // Another _hideReviewSheetIfRequired call had been made
      if (_hideToken != token) return;

      log.finest('Closing review sheet because no proof generation started');
      requiresUserInteraction(true);
    }
  }

  void _onVerificationReviewControllerChanges(ChangedValues<VerificationReviewState> changes) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final (oldValue, value) = changes.record;
    if (oldValue?.isVisible != value.isVisible && !value.isVisible) {
      final log = logger.child('_onVerificationReviewControllerChanges');
      log.info('Verification review controller changed to hidden');
      final webViewModel = ClaimCreationWebClientViewModel.readOf(context);
      final isCurrentPageLogin = await webViewModel.isCurrentPageLogin(null);
      if (!mounted) return;
      log.info('isCurrentPageLogin: $isCurrentPageLogin');
      if (isCurrentPageLogin) {
        _showLoginRequest();
      } else {
        messenger.clearSnackBars();
      }
    }
  }

  LoginPromptActionData? _loginPromptMessage;

  void _showLoginRequest() async {
    final logger = logging.child('ClaimCreationDelegate._showLoginRequest');
    if (!mounted) return;
    final actionBarMessenger = ActionBarMessenger.readOf(context);
    logger.info('actionBarMessenger.hasMessages: ${actionBarMessenger.hasMessages}');
    try {
      await Future.delayed(Durations.medium1);
      if (!mounted) return;
      logger.info('actionBarMessenger.hasMessages: ${actionBarMessenger.hasMessages}');

      if (_loginPromptMessage == null) {
        final featureFlags = await FeatureFlagsProvider.readAfterSessionStartedOf(context);
        try {
          logger.info('Getting login prompt message');
          final value = await featureFlags.get(FeatureFlag.loginPromptMessage);
          logger.info('Fetched login prompt message: ${value.runtimeType} $value');
          _loginPromptMessage = LoginPromptActionData.fromString(value);
        } catch (e, s) {
          logger.severe('Failed to get login prompt message', e, s);
        }
      } else {
        logger.info('Login prompt message already fetched: ${_loginPromptMessage?.message}');
      }

      actionBarMessenger.show(
        ActionBarMessage(
          label: Text(
            _loginPromptMessage?.message ??
                'Please login to continue verification. You can check again if you are already logged in.',
          ),
          action: ActionBarAction(
            label: _loginPromptMessage?.ctaLabel ?? "Check Again",
            onActionPressed: checkAgainAndShowReviewIfRequired,
          ),
          rules: const {ActionBarRule.clearAfterLogin},
        ),
      );
    } catch (e, s) {
      logger.severe('Failed to show login request', e, s);
    }
  }

  Future<void> checkAgainAndShowReviewIfRequired() async {
    final verificationReviewController = VerificationReviewController.readOf(context);
    final isReviewVisible = verificationReviewController.value.isVisible;
    if (isReviewVisible) return;
    if (!mounted) return;
    final actionBarMessenger = ActionBarMessenger.readOf(context);
    actionBarMessenger.clear();

    try {
      // incase snackbar is still shown in the ui
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.clearSnackBars();
    } catch (e, s) {
      logging.severe('Failed to clear snack bars', e, s);
    }

    // TODO: This right now doesn't send feedback to ai nor does it uses ai for login detection. Replace when AI can use this to take feedback.
    final isLoginPage = await ClaimCreationWebClientViewModel.readOf(context).isCurrentPageLogin(null);
    if (isLoginPage) {
      _showLoginRequest();
      return;
    }

    verificationReviewController.setIsVisible(true);
  }

  void _onWebViewCreated(InAppWebViewController controller) {
    try {
      final vm = ClaimCreationWebClientViewModel.readOf(context);
      logger.fine('onWebViewCreated');
      _setJSHandlers(controller);
      logger.debug('added js handlers');
      vm.setController(controller);
      logger.debug('set controller');
    } catch (e, s) {
      logger.severe('Failed to set controller', e, s);
    }
  }

  void evaluateIfNavigationToExpectedPageIsRequired() async {
    final log = logger.child('evaluateUrlOnLoadStop');

    final claimCreationController = ClaimCreationController.of(context, listen: false);

    final expectedUrl = claimCreationController.getNextLocation();
    if (expectedUrl == null) {
      // Do nothing, wait for user to press the continue button
      return;
    }

    log.info('evaluateIfNavigationToExpectedPageIsRequired: $expectedUrl. Will not perform any action.');

    // TODO: check whether we should show a hint or navigate forceably to the expected page

    // final vm = ClaimCreationWebViewModel.readOf(context);

    // vm.onContinue(nextLocation);
    // see if we need to go to the expected page automatically without conflicting with the claim creation process and its expected page suggestion

    // if (!await _canContinueWithExpectedUrl(expectedUrl)) return;
    // See if we need to show user a hint to navigate to expected page
  }

  late final _webviewInitializationDelay = Future.delayed(const Duration(milliseconds: 100));

  @override
  Widget build(BuildContext context) {
    return ManualReviewObserver(
      controller: _manualReviewController,
      child: VerificationReview(
        child: FutureBuilder(
          // This delay is to ensure that the webview plugin is ready before it makes android surface call.
          // without this, the webview crashes on react native inapp sdk.
          future: _webviewInitializationDelay,
          builder: (context, asyncSnapshot) {
            // keep showing blank until the webview init delay has passed.
            if (asyncSnapshot.connectionState != ConnectionState.done) return const SizedBox.shrink();

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
              onLoadStart: _onLoad,
              initialSettings: defaultWebViewSettings,
              onProgressChanged: (controller, progress) {
                final vm = ClaimCreationWebClientViewModel.readOf(context);
                vm.setDisplayProgress(progress / 100);
              },
              onLoadStop: _onLoadStop,
              onCreateWindow: onCreateWindowAction,
            );
          },
        ),
      ),
    );
  }

  void _setJSHandlers(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'publicData',
      callback: (args) async {
        final publicData = json.decode(args[0]);
        logger.child('proof_generation_events').info('Received public data ');
        final claimCreationController = ClaimCreationController.of(context, listen: false);
        claimCreationController.setPublicData(publicData);
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'canExpectManyClaims',
      callback: (args) async {
        final log = logger.child('canExpectManyClaims');
        log.info('received canExpectManyClaims, args: $args');
        final data = json.decode(args[0]);
        if (data is! Map) {
          log.severe('Received canExpectManyClaims is not a map', data);
          return;
        }
        final canExpectManyClaims = data['value'];
        if (canExpectManyClaims is! bool) {
          log.severe('Received canExpectManyClaims.value is not a boolean', data);
          return;
        }
        final claimCreationController = ClaimCreationController.of(context, listen: false);
        claimCreationController.canExpectManyClaims(canExpectManyClaims);
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'reportProviderError',
      callback: (args) async {
        final log = logger.child('reportProviderError');
        log.info('received provider error, args: $args');
        final errorMessage = json.decode(args[0]);
        if (errorMessage is! Map) {
          log.severe('Received error is not a map', errorMessage);
          return;
        }
        final claimCreationController = ClaimCreationController.of(context, listen: false);
        claimCreationController.setProviderError(errorMessage.cast<String, dynamic>());
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'requestLogs',
      callback: (args) async {
        final log = logger.child('request_logs');
        try {
          final requestData = json.decode(args[0]);
          final requestLog = RequestLog.fromJson(requestData);
          log.info('url : ${requestLog.url}, method : ${requestLog.method}');

          _manualReviewController.addRequest(requestLog);
        } catch (e, s) {
          logger.severe('Failed to add request log', e, s);
        }
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'customizeManualReviewMessage',
      callback: (args) async {
        final log = logger.child('manual_review_message');
        try {
          log.info({'data': args[0]});
          final data = ManualReviewActionData.fromString(args[0]);
          _manualReviewController.onCustomizationFromJSHandler(data);
        } catch (e, s) {
          log.severe('Failed to set manual review action data', e, s);
        }
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'debugLogs',
      callback: (args) {
        logger.child('debug_logs').info(args);
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'proofData',
      callback: (args) async {
        onProofDataReceived(args);
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'extractedData',
      callback: (args) async {
        _onExtractedDataReceived(args);
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'errorLogs',
      callback: (args) {
        logging.child('handleWebviewErrorLogs').severe({"errorLogs.args": args});
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'requiresUserInteraction',
      callback: (args) {
        final log = logging.child('requiresUserInteraction');
        log.info({"args": args});
        final data = json.decode(args[0]);
        if (data is! Map) {
          log.severe('Received requiresUserInteraction is not a map', data);
          return;
        }
        final isUserInteractionRequired = data['value'];
        if (isUserInteractionRequired is! bool) {
          log.severe('Received requiresUserInteraction.value is not a boolean', data);
          return;
        }
        requiresUserInteraction(isUserInteractionRequired);
      },
    );
  }

  void requiresUserInteraction(bool isUserInteractionRequired) {
    if (isUserInteractionRequired) {
      _claimCreationController.value.delegate?.hideReview();
    } else {
      _claimCreationController.value.delegate?.showReview();
    }
  }

  void onProofDataReceived(List<dynamic> args) async {
    final logger = logging.child('webview_screen.onProofDataReceived.${Object().hashCode}');
    logger.info('Completed request matching to start proof generation from webview');

    final vm = ClaimCreationWebClientViewModel.readOf(context);
    final messenger = ActionBarMessenger.of(context);
    final claimCreationController = ClaimCreationController.of(context, listen: false);
    final verification = VerificationController.readOf(context);

    final userAgent = await vm.getWebViewUserAgent();
    final actionControl = messenger.show(ActionBarMessage(type: ActionMessageType.claim));
    try {
      final proofData = json.decode(args[0]);

      final url = WebUri(proofData['url']);
      final String? requestHash = proofData['matchedRequest']['requestHash'];
      assert(requestHash != null, 'Request hash is null in proofData=${args[0]}');

      final requestData =
          claimCreationController.value.httpProvider?.requestData.where((it) {
            return it.requestHash == requestHash;
          }).firstOrNull;

      if (requestData == null) {
        logger.severe(
          'Request data not found for request hash: $requestHash. Available was ${verification.value.provider?.requestData.map((e) => e.requestHash)}',
        );
        return;
      }

      if (claimCreationController.value.isCompleted(requestData.requestIdentifier)) {
        logger.info('Request hash $requestHash is already completed. skipping.');
        return;
      }
      logger.info('Matched request with hash $requestHash, evaluating this with id ${requestData.requestIdentifier}');

      final cs = CookieService();
      final String cookieString = await cs.getCookieString(url);

      final Map<String, String> headers = Map<String, String>.from(proofData['headers']);

      final refererUrl = await vm.getCurrentRefererUrl(verification.value.provider?.loginUrl ?? '');

      headers['Referer'] = refererUrl;
      headers['User-Agent'] = userAgent;
      headers['Sec-Fetch-Mode'] = 'same-origin';
      headers['Sec-Fetch-Site'] = 'same-origin';
      final geoLocation = await getUserLocation(verification.value.provider?.geoLocation);

      if (!mounted) {
        logger.info('Claim creation cannot be started because the Webview has been disposed');
        return;
      }
      logger.info('Claim creation is starting.. opening claim creation bottom sheet on proof Data');

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
      );

      logger.info({'useSingleRequest': isSingleClaimRequest});

      if (!isSingleClaimRequest) {
        // update request with extracted data here with response redactions
        request = await claimCreationController.createRequestWithUpdatedProviderParams(proofData['response'], request);
      }

      logger.info('Starting claim creation');
      await claimCreationController.startClaimCreation(request);
      logger.info('Claim creation bottom sheet closed');
    } on ClaimCreationCancelledException {
      logger.info('claim creation was canceled');
    } on WorkCanceledException {
      logger.info('Claim creation stopped because the work was canceled');
    } on ReclaimException catch (e, s) {
      logger.severe('Claim creation stopped due to a reclaim exception', e, s);
      verification.updateException(e);
    } catch (e, s) {
      logger.severe('Claim creation stopped due to an error', e, s);
    } finally {
      actionControl.close();
    }
  }

  Future<void> _onExtractedDataReceived(List<dynamic> args) async {
    final logger = logging.child('webview_screen.extractedData.${Object().hashCode}');
    logger.info('Received claim request start proof generation from provider script running in webview');

    final vm = ClaimCreationWebClientViewModel.readOf(context);
    final messenger = ActionBarMessenger.of(context);
    final claimCreationController = ClaimCreationController.of(context, listen: false);

    // Discard any new claim creation if there is a provider script error
    if (claimCreationController.value.hasProviderScriptError) return;

    final verification = VerificationController.readOf(context);

    final userAgent = await vm.getWebViewUserAgent();
    final actionControl = messenger.show(ActionBarMessage(type: ActionMessageType.claim));
    try {
      if (args[0] == 'onboarding:exit_webview') {
        logger.info('Exiting webview because of exit webview');
        return;
      }

      final extractData = json.decode(args[0]);

      final requestData = DataProviderRequest.fromScriptInvocation(extractData);
      if (claimCreationController.value.isCompleted(requestData.requestIdentifier)) {
        logger.info('Request by id ${requestData.requestIdentifier} is already completed. skipping.');
        return;
      }

      logger.info('evaluating request by id ${requestData.requestIdentifier}');

      final url = WebUri(extractData['url']);
      final cs = CookieService();
      final String cookieString = await cs.getCookieString(url);

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
      );

      logger.info('Starting claim creation');
      await claimCreationController.startClaimCreation(request);
      logger.info('Claim creation bottom sheet closed');
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
