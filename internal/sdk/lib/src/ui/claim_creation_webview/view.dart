import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:retry/retry.dart';

import '../../../attestor.dart';
import '../../controller.dart';
import '../../data/http_request_log.dart';
import '../../data/manual_review.dart';
import '../../data/providers.dart';
import '../../exception/exception.dart';
import '../../logging/logging.dart';
import '../../repository/feature_flags.dart';
import '../../services/cookie_service.dart';
import '../../usecase/login_detection.dart';
import '../../utils/location.dart';
import '../../utils/observable_notifier.dart';
import '../../utils/sanitize.dart';
import '../../utils/single_work.dart';
import '../../utils/url.dart';
import '../../utils/webview_state_mixin.dart';
import '../../widgets/action_bar.dart';
import '../../widgets/claim_creation/claim_creation.dart';
import '../../widgets/feature_flags.dart';
import '../../widgets/verification_review/verification_review.dart';
import '../dev/dev.dart';
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
  late final ManualReviewController _manualReviewController = ManualReviewController();
  late ClaimCreationController _claimCreationController;

  @override
  void initState() {
    super.initState();
    _claimCreationController = ClaimCreationController.of(context, listen: false);
    // VerificationController.identity can throw StateError in the beginning, the future that completes with it is [startingSession].
    FeatureFlagsProvider.readAfterSessionStartedOf(context).then((featureFlagProvider) {
      _subscriptions.add(featureFlagProvider.stream(FeatureFlag.isWebInspectable).listen(_onWebViewInspectableChanged));
      featureFlagProvider.get(FeatureFlag.isWebInspectable).then(_onWebViewInspectableChanged);
      featureFlagProvider.get(FeatureFlag.sessionNoActivityTimeoutDurationInMins).then(_startNoActivityObserver);
    });
    _subscriptions.add(_claimCreationController.changesStream.listen(_onClaimCreationControllerChanges));
    final vm = ClaimCreationWebClientViewModel.readOf(context);
    vm.onUpdateWebView = _onUpdateWebView;
  }

  late GlobalKey _webviewKey = GlobalKey();

  Future<void> _onUpdateWebView() async {
    final log = logger.child('onUpdateWebView');
    log.info('updating webview key');
    setState(() {
      _webviewKey = GlobalKey();
    });
  }

  @override
  void dispose() {
    _sessionNoActivityObserverTimer?.cancel();
    _sessionNoActivityObserverTimer = null;
    for (final s in _subscriptions) {
      s.cancel();
    }
    _manualReviewController.dispose();
    super.dispose();
  }

  bool? isInspectablePreference;

  void _onWebViewInspectableChanged(bool isInspectable) async {
    if (mounted) {
      setState(() {
        isInspectablePreference = isInspectable;
      });
    }

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
    final log = logger.child('_hideReviewSheetIfRequired');
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
    await Future.delayed(Duration(milliseconds: 500));

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
        await Future.delayed(Duration(seconds: 4));
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

      log.fine('Closing review sheet because no proof generation started. can hide: ${_hideToken == token}');

      // Another _hideReviewSheetIfRequired call had been made
      if (_hideToken != token) return;

      log.finest('Closing review sheet because no proof generation started');
      requiresUserInteraction(true);
    }
  }

  void _onWebViewCreated(InAppWebViewController controller) {
    try {
      logger.info('onWebViewCreated');
      final vm = ClaimCreationWebClientViewModel.readOf(context);
      _setJSHandlers(controller);
      logger.info('added js handlers');
      vm.setController(controller);
      logger.info('set controller');
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

  bool? _wasInitializedWithIncognito;

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
              onLoadStart: _onLoad,
              initialSettings: settings,
              onProgressChanged: (controller, progress) {
                final vm = ClaimCreationWebClientViewModel.readOf(context);
                vm.setDisplayProgress(progress / 100);
              },
              onLoadStop: _onLoadStop,
              onCreateWindow: onCreateWindowAction,
              shouldOverrideUrlLoading: shouldOverrideUrlLoading,
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
        _onActivity();
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
        _onActivity();
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
          log.info({'customizeManualReviewMessage': args[0]});
          _onActivity();
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
        _onActivity();
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

  Timer? _sessionNoActivityObserverTimer;
  DateTime lastActivityDetectedAt = DateTime.now();

  void _startNoActivityObserver(int durationInMins) {
    final noActivityDuration = Duration(minutes: durationInMins);
    _sessionNoActivityObserverTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_claimCreationController.value.canExpectManyClaims) {
        logger.info('No activity detection skipped because canExpectManyClaims is enabled');
        _onActivity();
        return;
      }
      if (_claimCreationController.value.isFinished) {
        logger.info('No activity detection stopped because verification is finished');
        if (_claimCreationController.value.isFinished) {
          _sessionNoActivityObserverTimer?.cancel();
          _sessionNoActivityObserverTimer = null;
        }
        return;
      }
      if (_claimCreationController.value.hasError) {
        logger.info('No activity detection skipped because of error');
        logger.info('Error was: ${_claimCreationController.value.debugErrorDetails()}');
        return;
      }
      final durationSinceLastActivity = DateTime.now().difference(lastActivityDetectedAt).abs();
      if (durationSinceLastActivity >= noActivityDuration) {
        logger.info('No activity detected for $durationSinceLastActivity');
        if (kDebugMode) {
          // TODO: remove this when we not debug
          logger.info('Skipping error because of debug mode');
          return;
        }
        _claimCreationController.setClientError(
          ReclaimVerificationNoActivityDetectedException('Verification could not be completed in time'),
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

  Future<Duration> _getClaimCreationTimeoutDuration() async {
    final timeoutDuration = await () async {
      try {
        final timeoutDurationInMins = await FeatureFlagsProvider.readOf(
          context,
        ).get(FeatureFlag.claimCreationTimeoutDurationInMins).timeout(Duration(seconds: 5));
        return Duration(minutes: timeoutDurationInMins);
      } catch (e, s) {
        logger.severe('Failed to get claim creation timeout duration', e, s);
        return const Duration(minutes: 2);
      }
    }();
    logger.info('Using claim creation timeout duration: $timeoutDuration');
    return timeoutDuration;
  }

  void onProofDataReceived(List<dynamic> args) async {
    final logger = logging.child('webview_screen.onProofDataReceived.${Object().hashCode}');
    logger.info('Completed request matching to start proof generation from webview');

    _onActivity();

    final vm = ClaimCreationWebClientViewModel.readOf(context);
    final messenger = ActionBarMessenger.of(context);
    final claimCreationController = ClaimCreationController.of(context, listen: false);
    final verification = VerificationController.readOf(context);

    final claimCreationTimeoutDurationFuture = _getClaimCreationTimeoutDuration();

    final userAgent = await vm.getWebViewUserAgent();
    final actionControl = messenger.show(ActionBarMessage(type: ActionMessageType.claim));
    try {
      final proofData = json.decode(args[0]);

      DevController.shared.push('matchedRequest', proofData);

      final url = WebUri(proofData['url']);
      final String? requestHash = proofData['matchedRequest']['requestHash'];
      assert(requestHash != null, 'Request hash is null in proofData=${args[0]}');

      final requestData = claimCreationController.value.httpProvider?.requestData.where((it) {
        return it.requestHash == requestHash;
      }).firstOrNull;

      if (requestData == null) {
        logger.severe(
          'Request data not found for request hash: $requestHash. Available was ${verification.value.provider?.requestData.map((e) => e.requestHash)}',
        );
        return;
      }

      DevController.shared.push('DataProviderRequest', requestData);

      if (claimCreationController.value.isCompleted(requestData.requestIdentifier)) {
        logger.info('Request hash $requestHash is already completed. skipping.');
        return;
      }
      logger.info('Matched request with hash $requestHash, evaluating this with id ${requestData.requestIdentifier}');

      final cs = CookieService();
      final String cookieString = await cs.getCookieString(url, credentials: requestData.credentials);

      final headersFromProof = proofData['headers'] as Map;

      logger.debug({'headers': json.encode(headersFromProof)});

      final Map<String, String> headers = Map<String, String>.from({
        for (final entry in headersFromProof.entries) entry.key.toString(): entry.value.toString(),
      });

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
        claimCreationTimeoutDuration: await claimCreationTimeoutDurationFuture,
      );

      logger.info({'useSingleRequest': isSingleClaimRequest});

      if (!isSingleClaimRequest) {
        // update request with extracted data here with response redactions
        request = await retry(
          () async {
            return await claimCreationController.createRequestWithUpdatedProviderParams(proofData['response'], request);
          },
          retryIf: (e) {
            logger.warning('failed to create request with updated provider params, checking if we can retry', e);
            final canRetry = e is AttestorWebViewClientNotReadyException || e is TimeoutException;
            if (canRetry) {
              Attestor.instance
                  .executeJavascript('(() => { return 0 + 1; })()', timeout: Duration(seconds: 10))
                  .catchError((e, s) {
                    logger.severe('Error evaluating test javascript in attestor webview', e, s);
                    return null;
                  })
                  .then((it) {
                    logger.info('Successfully evaluated test javascript in attestor webview: $it');
                  })
                  .ignore();
            }
            return canRetry;
          },
        );
      }

      logger.info('Starting claim creation');
      await claimCreationController.startClaimCreation(request);
      logger.info('Claim creation bottom sheet closed');
      _onActivity();
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

    _onActivity();

    final vm = ClaimCreationWebClientViewModel.readOf(context);
    final messenger = ActionBarMessenger.of(context);
    final claimCreationController = ClaimCreationController.of(context, listen: false);

    // Discard any new claim creation if there is a provider script error
    if (claimCreationController.value.hasProviderScriptError) return;

    final verification = VerificationController.readOf(context);

    final claimCreationTimeoutDurationFuture = _getClaimCreationTimeoutDuration();

    final userAgent = await vm.getWebViewUserAgent();
    final actionControl = messenger.show(ActionBarMessage(type: ActionMessageType.claim));
    try {
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

      logger.info('evaluating request by id ${requestData.requestIdentifier}');

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
