import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:reclaim_flutter_sdk/attestor.dart';
import 'package:reclaim_flutter_sdk/constants.dart';
import 'package:reclaim_flutter_sdk/data/providers.dart';
import 'package:reclaim_flutter_sdk/exception/exception.dart';
import 'package:reclaim_flutter_sdk/services/ai_flow_service.dart';
import 'package:reclaim_flutter_sdk/services/network_logs.dart';
import 'package:reclaim_flutter_sdk/src/utils/sanitize.dart';
import 'package:reclaim_flutter_sdk/types/app_info.dart';
import 'package:reclaim_flutter_sdk/utils/flags.dart';
import 'package:reclaim_flutter_sdk/utils/future.dart';
import 'package:reclaim_flutter_sdk/utils/permission.dart';
import 'package:reclaim_flutter_sdk/utils/session.dart';
import 'package:reclaim_flutter_sdk/utils/url.dart' as url_util;
import 'package:reclaim_flutter_sdk/utils/user_agent.dart';
import 'package:reclaim_flutter_sdk/widgets/action_bar.dart';
import 'package:reclaim_flutter_sdk/widgets/ai_flow/result_bottom_sheet.dart';
import 'package:reclaim_flutter_sdk/widgets/debug_bottom_sheet.dart';
import 'package:reclaim_flutter_sdk/widgets/claim_creation/trigger_indicator.dart';
import 'package:reclaim_flutter_sdk/widgets/recommendation_bar.dart';
import 'package:reclaim_flutter_sdk/widgets/webview_bottom.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:reclaim_flutter_sdk/logging/logging.dart';
import 'package:reclaim_flutter_sdk/utils/single_work.dart';
import 'package:reclaim_flutter_sdk/widgets/claim_creation/claim_creation.dart';
import 'package:reclaim_flutter_sdk/types/manual_verification.dart';
import 'package:reclaim_flutter_sdk/widgets/widgets.dart';
import 'package:reclaim_flutter_sdk/types/create_claim.dart';
import 'package:reclaim_flutter_sdk/utils/location.dart';
import 'package:reclaim_flutter_sdk/services/user_script_service.dart';

import '../inapp_sdk_route.dart';
import '../src/data/manual_review.dart';
import '../types/verification_options.dart';

class WebviewScreen extends StatefulWidget {
  final Map<String, String> parameters;
  final String sessionId;
  final String context;
  final String privateKey;
  final bool autoSubmit;
  final bool hideCloseButton;
  final String appId;
  final bool? debug;
  final bool acceptAiProviders;
  final String? webhookUrl;
  final HttpProvider? providerData;
  final ReclaimVerificationOptions? verificationOptions;
  final AttestorClaimOptions createClaimOptions;

  const WebviewScreen({
    super.key,
    required this.providerData,
    required this.sessionId,
    required this.context,
    required this.privateKey,
    required this.appId,
    required this.parameters,
    required this.acceptAiProviders,
    required this.hideCloseButton,
    required this.createClaimOptions,
    this.verificationOptions,
    this.debug = false,
    this.autoSubmit = false,
    this.webhookUrl,
  });

  @override
  WebviewScreenState createState() => WebviewScreenState();
}

class WebviewScreenState extends State<WebviewScreen>
    with WidgetsBindingObserver {
  late final logger = logging.child('WebviewScreenState');

  final GlobalKey webViewKey = GlobalKey();
  final UniqueKey _key = UniqueKey();
  List<RequestLog>? requestLogs = [];

  late ClaimCreationController claimCreationController;
  late AIFlowService aiFlowService;
  InAppWebViewController? webViewController;
  CreateWindowAction? _createWindowAction;
  ClaimCreationStatus? oldClaimCreationState;

  Timer? _manualVerificationPromptTimer;
  Timer? _requestShareConsentPromptTimer;
  Timer? _aiCheckingTimer;

  final ValueNotifier<double> _webviewProgressNotifier = ValueNotifier(0.0);
  String _webviewUrl = "";
  Completer<void>? _websiteLoadingCompleter;

  bool _hasShownLoginToast = false;

  void markWebsiteLoading() {
    final completer = _websiteLoadingCompleter;
    _websiteLoadingCompleter = Completer<void>();
    if (completer != null && !completer.isCompleted) {
      completer.completeError(Exception('Website re-loaded'));
    }
  }

  void markWebsiteLoaded() {
    final completer = _websiteLoadingCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  // Used to wait until the website is loaded on proof data and extract data callback
  // handler because the controller may have outdated data i.e url. (could be a bug in plugin)
  Future<void> waitUntilWebsiteLoaded() async {
    final completer = _websiteLoadingCompleter;
    if (completer == null) {
      return;
    }
    try {
      await completer.future;
    } catch (_) {
      // website relaoded
      return waitUntilWebsiteLoaded();
    }
  }

  Future<String> getCurrentRefererUrl() async {
    String currentUrl = _webviewUrl;
    try {
      final webUri = await webViewController?.getUrl().then(
        (e) => e?.toString(),
      );
      if (webUri != null && webUri.isNotEmpty) {
        currentUrl = webUri;
      }
    } catch (e, s) {
      logger.severe('Failed to get current referer url', e, s);
    }
    return url_util.createRefererUrl(currentUrl) ?? _webviewUrl;
  }

  String? _aiRecommendation;

  int idleTimeThreshold = 2;
  int consecutiveNonLoginUrls = 0;
  int _activeIndex = 0;

  bool _isLoggedIn = false;
  bool _isAiRecommendationDismissed = false;
  bool _isWebInspectable = false;
  bool _isAIVerificationStarted = false;
  bool _isKeyboardVisible = false;
  bool _useSingleRequest = false;
  bool cookiePersist = false;
  bool aiCheckingLoading = false;

  bool _isAiFlowEnabled = false;
  ManualReviewActionData? _manualReviewMessage;

  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers = {
    Factory(() => EagerGestureRecognizer()),
  };

  final Completer<UnmodifiableListView<UserScript>> _userScriptsCompleter =
      Completer<UnmodifiableListView<UserScript>>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SharedPreferences.getInstance().then((prefs) {
      CookieManager cookieManager = CookieManager.instance();
      // PlatformInAppWebViewController.debugLoggingSettings.enabled = false;

      final cookiePersistPref = Flags.isCookiePersist(prefs);
      final isSingleReclaimRequestPref = Flags.isSingleReclaimRequest(prefs);
      idleTimeThreshold = Flags.getIdleTimeThreshold(prefs);
      _isWebInspectable = Flags.isWebInspectable(prefs);
      _isAiFlowEnabled = Flags.isAIFlowEnabled(prefs);
      _manualReviewMessage = ManualReviewActionData.fromString(
        Flags.getManualReviewMessage(prefs),
      );
      setState(() {
        cookiePersist = cookiePersistPref;
        _useSingleRequest = isSingleReclaimRequestPref;
      });

      final preventCookieDeletion =
          widget.verificationOptions?.preventCookieDeletion ?? false;

      if (!preventCookieDeletion) {
        if (!cookiePersist) {
          cookieManager.deleteAllCookies();
        }
      }
      AppInfo.fromAppId(widget.appId);
      if (mounted) {
        _loadUserScripts();
      }
      _scheduleToShowRequestShareConsentPromptIfRequired();
    });

    claimCreationController = ClaimCreationController(
      httpProvider: widget.providerData!,
    );
    claimCreationController.addListener(_onClaimCreationUpdate);
    aiFlowService = AIFlowService(
      getWebViewController,
      (recommendation) {
        _aiRecommendation = recommendation;
        if (mounted) {
          setState(() {});
        }
      },
      (isLoggedIn) {
        _isLoggedIn = isLoggedIn;
        if (mounted) {
          setState(() {});
        }
      },
      _handleLoginAiToast,
    );
  }

  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  void _loadUserScripts() async {
    try {
      final userScripts = await UserScriptService.createUserScripts(
        providerData: widget.providerData!,
        parameters: widget.parameters,
        idleTimeThreshold: idleTimeThreshold,
      );
      _userScriptsCompleter.complete(userScripts);
    } catch (e, s) {
      _userScriptsCompleter.completeError(e, s);
      _onReclaimException(ReclaimException.onError(e));
    }
  }

  @override
  void didChangeMetrics() {
    final bottomInset = View.of(context).viewInsets.bottom;
    bool isKeyboardVisible = bottomInset > 0;
    if (isKeyboardVisible != _isKeyboardVisible) {
      setState(() {
        _isKeyboardVisible = isKeyboardVisible;
      });
      if (_isKeyboardVisible) {
        aiFlowService.reset();
      }
    }
    super.didChangeMetrics();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _manualVerificationPromptTimer?.cancel();
    _requestShareConsentPromptTimer?.cancel();
    _aiCheckingTimer?.cancel();
    aiFlowService.reset(onDispose: true);
    claimCreationController.dispose();
    try {
      webViewController?.dispose();
      webViewController = null;
    } catch (e, s) {
      logger.severe('Failed to dispose webview', e, s);
    }
    _webviewProgressNotifier.dispose();
    super.dispose();
  }

  bool isAIProvider() {
    return widget.providerData?.isAIProvider() ?? false;
  }

  InAppWebViewController getWebViewController() {
    if (webViewController == null) {
      throw Exception('WebViewController is not initialized');
    }
    return webViewController!;
  }

  void markAILoadingState(bool isLoading) {
    if (isLoading != aiCheckingLoading) {
      setState(() {
        aiCheckingLoading = isLoading;
      });
    }
  }

  bool isAiForrbiddenToTrigger() {
    if (!_isAiFlowEnabled) {
      return true;
    }
    return claimCreationController.value.inProgressOrCompleted &&
        !isAIProvider();
  }

  List<AIFlowDataReceipt> _aiFlowDataReceipts = [
    AIFlowDataReceipt(
      name: 'full_name',
      extractedValue: null,
      recommendation: null,
      actionUrl: null,
    ),
    AIFlowDataReceipt(
      name: 'field_of_study',
      extractedValue: null,
      recommendation: null,
      actionUrl: null,
    ),
  ];

  void _updateAiFlowDataReceipts(List<AIFlowDataReceipt> receipts) {
    setState(() {
      _aiFlowDataReceipts =
          _aiFlowDataReceipts.map((param) {
            final matchingResult = receipts.firstWhere(
              (r) => r.name == param.name,
              orElse: () => param,
            );

            if (param.extractedValue == null &&
                (matchingResult.extractedValue != null)) {
              return matchingResult;
            }
            return param;
          }).toList();
    });
  }

  Future<void> submitManualVerification() async {
    final log = logger.child('submitManualVerification');
    log.info('Submitting manual verification');

    final payload = CreateManualVerificationSessionPayload(
      sessionId: widget.sessionId,
      appId: widget.appId,
      httpProviderId: widget.providerData!.httpProviderId!,
      parameters:
          _aiFlowDataReceipts
              .where((r) => r.extractedValue != null)
              .map(
                (r) => ManualVerificationParameter(
                  key: r.name,
                  value: r.extractedValue!,
                ),
              )
              .toList(),
    );

    await aiFlowService.fallbackToManualVerification(
      payload,
      widget.sessionId,
      requestLogs ?? [],
      widget.providerData!.name!,
      widget.providerData!.httpProviderId!,
      Map.fromEntries(
        _aiFlowDataReceipts
            .where((r) => r.extractedValue != null)
            .map((r) => MapEntry(r.name, r.extractedValue!)),
      ),
    );
  }

  Future<void> onAiDismiss() async {
    if (!mounted) return;
    aiFlowService.reset();
    setState(() {
      _isAiRecommendationDismissed = true;
    });
    Timer(const Duration(seconds: 4), () async {
      setState(() {
        _isAiRecommendationDismissed = false;
      });
      _isAIVerificationStarted = false;
    });
  }

  Future<bool> onAiContinue(String expectedPageUrl) async {
    _isAIVerificationStarted = false;
    return _onContinue(expectedPageUrl);
  }

  void _handleLoginAiToast() {
    if (!_hasShownLoginToast) {
      _hasShownLoginToast = true;

      final fieldNames = _aiFlowDataReceipts
          .map(
            (r) => r.name
                .split("_")
                .map((word) => word[0].toUpperCase() + word.substring(1))
                .join(" "),
          )
          .join(", ");

      Fluttertoast.showToast(
        msg: "Login to verify your $fieldNames",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 4,
        backgroundColor: Colors.blue.shade800,
        textColor: Colors.white,
        fontSize: 14.0,
        webPosition: "center",
        webBgColor: "#2563EB",
        webShowClose: true,
      );
    }
  }

  Future<void> _triggerAIChecking() async {
    final log = logger.child('_triggerAIChecking');
    if (!mounted ||
        aiCheckingLoading ||
        _isAIVerificationStarted ||
        _isKeyboardVisible ||
        _isAiRecommendationDismissed ||
        isAiForrbiddenToTrigger()) {
      return;
    }
    if (_aiCheckingTimer != null && _aiCheckingTimer!.isActive) {
      _aiCheckingTimer!.cancel();
    }
    try {
      if (_isLoggedIn) {
        _isAIVerificationStarted = true;
        markAILoadingState(true);
        aiFlowService.reset();
        await ResultBottomSheet.show(
          context,
          providerData: widget.providerData!,
          params: _aiFlowDataReceipts,
          aiFlowService: aiFlowService,
          sessionId: widget.sessionId,
          webviewUrl: _webviewUrl,
          onSubmit: () {
            aiFlowService.reset();
            Navigator.of(context).pop();
            _onSubmitProofs([
              aiFlowService.createClaimOutputFromAIFlowDataReceipts(
                _aiFlowDataReceipts,
              ),
            ]);
          },
          onUpdate: _updateAiFlowDataReceipts,
          onContinue: onAiContinue,
          onSubmitManualVerification: submitManualVerification,
          onAiDismiss: onAiDismiss,
        );
      } else {
        markAILoadingState(true);
        await aiFlowService.checkLoggedInState(
          _webviewUrl,
          _isLoggedIn,
          _aiRecommendation,
          CookieManager.instance(),
        );
        markAILoadingState(false);
      }
    } catch (e) {
      log.info('Error during AI checking: $e');
    } finally {
      // Schedule the next trigger
      if (!_isLoggedIn) {
        _aiCheckingTimer = Timer(Duration(seconds: 6), () {
          if (!mounted) {
            return;
          }
          if (!isAiForrbiddenToTrigger()) {
            _triggerAIChecking();
          }
        });
      }
      markAILoadingState(false);
    }
  }

  _onClaimCreationUpdate() async {
    final status = claimCreationController.value.status;
    if (oldClaimCreationState != status) {
      switch (status) {
        case ClaimCreationStatus.retryRequested:
          _resetWebview();
          break;
        default:
          break;
      }
    }
    oldClaimCreationState = status;
  }

  bool _isClosedWithException = false;

  void _onReclaimException(ReclaimException e) {
    if (e is ReclaimVerificationRequirementException) {
      // Requirement for verification could not be met. We can ignore this error.
      return;
    }
    if (_isClosedWithException) return;
    _isClosedWithException = true;
    if (mounted) {
      Navigator.of(context).pop(e);
    }
  }

  void _onSubmitProofs(Iterable<CreateClaimOutput> proofs) {
    final log = logger.child('_onCreateClaimOutput');
    log.finest('Closing screen with claim output');
    // Pop every route from navigation stack repeatedly until we reach the Reclaim Webview Screen
    Navigator.of(context).popUntil((route) {
      return route.settings.name == reclaimInAppSDKRouteSettings.name;
    });
    // Pop Reclaim Webview Screen with Result
    Navigator.of(context).pop(UnmodifiableListView(proofs));
  }

  _showDebugBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (buildContext) {
        return StatefulBuilder(
          builder:
              (context, setState) => DebugBottomSheet(
                refreshPage: () {
                  CookieManager cookieManager = CookieManager.instance();
                  if (!cookiePersist) cookieManager.deleteAllCookies();
                  if (webViewController != null) {
                    webViewController!.reload();
                  }
                  Navigator.of(context).pop();
                },
                copySessionId: () {
                  Clipboard.setData(ClipboardData(text: widget.sessionId)).then(
                    (_) {
                      Fluttertoast.showToast(msg: 'Copied to your clipboard!');
                    },
                  );
                },
                toggleCookiePersist: () async {
                  await Flags.setCookiePersist(!cookiePersist);

                  setState(() {
                    cookiePersist = !cookiePersist;
                  });
                },
                cookiePersist: cookiePersist,
                useSingleRequest: _useSingleRequest,
                toggleUseSingleRequest: () async {
                  final value = !_useSingleRequest;
                  await Flags.setSingleReclaimRequest(value);

                  setState(() {
                    _useSingleRequest = value;
                  });
                },
                setIsWebInspectable: (isInspectable) async {
                  final prefs = await SharedPreferences.getInstance();
                  await Flags.setIsWebInspectable(isInspectable, prefs);
                  setState(() {
                    _isWebInspectable = isInspectable;
                  });
                  _updateWebInspectable();
                },
              ),
        );
      },
    );
  }

  Future<void> _updateWebInspectable() async {
    final isInspectable = Flags.isWebInspectable(
      await SharedPreferences.getInstance(),
    );
    final ctrl = webViewController;
    if (ctrl == null) return;
    final settings = await ctrl.getSettings() ?? InAppWebViewSettings();
    settings.isInspectable = isInspectable;
    await ctrl.setSettings(settings: settings);
  }

  _resetWebview() {
    CookieManager cookieManager = CookieManager.instance();
    if (!cookiePersist) cookieManager.deleteAllCookies();
    if (webViewController != null) {
      webViewController!.reloadFromOrigin();
    }
    if (!mounted) {
      return;
    }
    aiFlowService.reset();
    setState(() {
      consecutiveNonLoginUrls = 0;
      _manualVerificationPromptTimer?.cancel();
      _aiRecommendation = null;
    });
  }

  void onProofDataReceived(List<dynamic> args, String userAgent) async {
    final logger = logging.child(
      'webview_screen.onProofDataReceived.${Object().hashCode}',
    );

    try {
      logger.info(
        'Completed request matching to start proof generation from webview',
      );

      claimCreationController.claimTriggerIndicatorController.notifyClaim();

      logger.finest('Waiting for website to load');
      await waitUntilWebsiteLoaded();
      logger.finest('Website load finished');

      final proofData = json.decode(args[0]);

      final url = WebUri(proofData['url']);
      final String? requestHash = proofData['matchedRequest']['requestHash'];
      assert(
        requestHash != null,
        'Request hash is null in proofData=${args[0]}',
      );
      final requestData =
          widget.providerData?.requestData.where((it) {
            return it.requestHash == requestHash;
          }).firstOrNull;

      if (requestData == null) {
        logger.severe(
          'Request data not found for request hash: $requestHash. Available was ${widget.providerData?.requestData.map((e) => e.requestHash)}',
        );
        return;
      }

      if (claimCreationController.value.isCompleted(
        requestData.requestIdentifier,
      )) {
        logger.info(
          'Request hash $requestHash is already completed. skipping.',
        );
        return;
      }
      logger.info(
        'Matched request with hash $requestHash, evaluating this with id ${requestData.requestIdentifier}',
      );

      final String cookieString = await url_util.getCookieString(url);

      final Map<String, String> headers = Map<String, String>.from(
        proofData['headers'],
      );

      final refererUrl = await getCurrentRefererUrl();
      headers['Referer'] = refererUrl;
      headers['User-Agent'] = userAgent;
      headers['Sec-Fetch-Mode'] = 'same-origin';
      headers['Sec-Fetch-Site'] = 'same-origin';
      if (!mounted) {
        logger.info(
          'Claim creation cannot be started because the Webview has been disposed',
        );
        return;
      }
      logger.info(
        'Claim creation is starting.. opening claim creation bottom sheet on proof Data',
      );

      final geoLocation = await getUserLocation(
        widget.providerData?.geoLocation,
      );

      var request = ClaimCreationRequest(
        appId: widget.appId,
        claimContext: widget.context,
        sessionId: widget.sessionId,
        privateKey: widget.privateKey,
        proofData: proofData,
        providerData: widget.providerData!,
        headers: headers,
        initialWitnessParams: widget.parameters,
        cookieString: cookieString,
        useSingleRequest: _useSingleRequest,
        requestData: requestData,
        geoLocation: geoLocation,
        createClaimOptions: widget.createClaimOptions,
      );

      logger.info({'useSingleRequest': _useSingleRequest});

      if (!_useSingleRequest) {
        // update request with extracted data here with response redactions
        request = await claimCreationController
            .createRequestWithUpdatedProviderParams(
              proofData['response'],
              request,
            );
      }
      logger.info('Starting claim creation');
      await claimCreationController.startClaimCreation(request);
      logger.info('Claim creation bottom sheet closed');
    } on WorkCanceledException {
      logger.info('Claim creation stopped because the work was canceled');
    } on ReclaimException catch (e, s) {
      logger.severe('Claim creation stopped due to a reclaim exception', e, s);
      _onReclaimException(e);
    } catch (e, s) {
      logger.severe('Claim creation stopped due to an error', e, s);
    } finally {
      claimCreationController.claimTriggerIndicatorController.remove();
    }
  }

  Future<void> _onExtractedDataReceived(
    List<dynamic> args,
    String userAgent,
  ) async {
    final logger = logging.child(
      'webview_screen.extractedData.${Object().hashCode}',
    );
    try {
      logger.info(
        'Received claim request start proof generation from provider script running in webview',
      );

      claimCreationController.claimTriggerIndicatorController.notifyClaim();

      if (args[0] == 'onboarding:exit_webview') {
        logger.info('Exiting webview because of exit webview');
        return;
      }

      logger.finest('Waiting for website to load');
      await waitUntilWebsiteLoaded();
      logger.finest('Website load finished');

      final extractData = json.decode(args[0]);

      final requestData = DataProviderRequest.fromScriptInvocation(extractData);
      if (claimCreationController.value.isCompleted(
        requestData.requestIdentifier,
      )) {
        logger.info(
          'Request by id ${requestData.requestIdentifier} is already completed. skipping.',
        );
        return;
      }

      logger.info('evaluating request by id ${requestData.requestIdentifier}');

      final url = WebUri(extractData['url']);
      final String cookieString = await url_util.getCookieString(url);

      final Map<String, String> headers =
          (extractData['headers'] is Map
              ? ensureMap<String, String>(extractData['headers'])
              : null) ??
          <String, String>{};
      final refererUrl = await getCurrentRefererUrl();
      headers['Referer'] = refererUrl;
      headers['User-Agent'] = userAgent;
      headers['Sec-Fetch-Mode'] = 'same-origin';
      extractData['witnessParameters'] = Map<String, String>.from({
        ...?ensureMap<String, String>(extractData['witnessParameters']),
        ...?ensureMap<String, String>(extractData['extractedParams']),
      });
      if (!mounted) {
        logger.info(
          'Claim creation cannot be started because the Webview has been disposed',
        );
        return;
      }
      logger.info(
        'Claim creation is starting.. opening claim creation bottom sheet on extractedData',
      );

      final Map<String, String>? extractedDataWitnessParameters =
          extractData['witnessParameters'];

      final Map<String, String> initialWitnessParams = {
        ...widget.parameters,
        ...?extractedDataWitnessParameters,
      };

      final geoLocation = await getUserLocation(extractData['geoLocation']);

      var request = ClaimCreationRequest(
        appId: widget.appId,
        claimContext: widget.context,
        sessionId: widget.sessionId,
        privateKey: widget.privateKey,
        proofData: extractData,
        providerData: widget.providerData!,
        headers: headers,
        initialWitnessParams: initialWitnessParams,
        cookieString: cookieString,
        useSingleRequest: false,
        requestData: requestData,
        createClaimOptions: widget.createClaimOptions,
        geoLocation: geoLocation,
        isRequestFromProviderScript: true,
      );

      logger.info('Starting claim creation');
      await claimCreationController.startClaimCreation(request);
      logger.info('Claim creation bottom sheet closed');
    } on ReclaimException catch (e, s) {
      logger.severe('Claim creation stopped due to a reclaim exception', e, s);
      _onReclaimException(e);
    } on WorkCanceledException {
      logger.info('Claim creation stopped because the work was canceled');
    } catch (e, s) {
      logger.severe('Claim creation stopped due to an error', e, s);
    } finally {
      claimCreationController.claimTriggerIndicatorController.remove();
    }
  }

  Future<GeolocationPermissionShowPromptResponse>
  _onGeolocationPermissionsShowPrompt(controller, origin) async {
    final log = logger.child('_onGeolocationPermissionsShowPrompt');
    try {
      final messenger = ScaffoldMessenger.of(context);
      await requestPermission(Permission.location);
      await requestPermission(Permission.locationWhenInUse);
      await requestPermission(Permission.locationAlways);
      final status = await Permission.location.status;
      if (status.isDenied || status.isPermanentlyDenied) {
        openAppSettings();
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Website requires location permissions. Please grant location permission in settings',
            ),
          ),
        );
      }
    } catch (e, s) {
      log.severe('Failed to request location permissions', e, s);
    }
    return GeolocationPermissionShowPromptResponse(
      allow: true,
      origin: origin,
      retain: true,
    );
  }

  void _onWebViewCreated(InAppWebViewController controller) async {
    webViewController = controller;

    final String userAgentString =
        await WebViewUserAgentUtil.setEffectiveUserAgent(
          controller,
          widget.providerData?.userAgent,
        );
    controller.addJavaScriptHandler(
      handlerName: 'publicData',
      callback: (args) async {
        final publicData = json.decode(args[0]);
        logger.child('proof_generation_events').info('Received public data ');
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
          log.severe(
            'Received canExpectManyClaims.value is not a boolean',
            data,
          );
          return;
        }
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
        claimCreationController.setProviderError(
          errorMessage.cast<String, dynamic>(),
        );
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'requestLogs',
      callback: (args) async {
        final log = logger.child('request_logs');
        try {
          log.info('got requests');
          final requestData = json.decode(args[0]);
          final requestLog = RequestLog.fromJson(requestData);
          log.info('url : ${requestLog.url}, method : ${requestLog.method}');

          // don't store logs if the `requestLogs` buffer is null.
          // this can happen when canUseAiFlow is false
          requestLogs?.add(requestLog);
        } catch (e, s) {
          log.severe('Failed to add request log', e, s);
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
          _manualReviewMessage = data;
          if (data != null && data.rule != ManualReviewPromptDisplayRule.TIMEOUT) {
            _showRequestShareConsentPrompt();
          }
        } catch (e, s) {
          log.severe('Failed to set manual review action data', e, s);
        }
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'debugLogs',
      callback: (args) {
        logger.child('debug_logs').info(args.toString());
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'proofData',
      callback: (args) async {
        onProofDataReceived(args, userAgentString);
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'extractedData',
      callback: (args) async {
        _onExtractedDataReceived(args, userAgentString);
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'errorLogs',
      callback: (args) {
        logging.child('handleWebviewErrorLogs').severe({
          "errorLogs.args": args,
        });
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'triggerAIFlow',
      callback: (args) async {
        if (_isAiRecommendationDismissed) return;
        await _triggerAIChecking();
      },
    );
    _updateWebInspectable();
  }

  String? _nextExpectedPageUrl;

  void evaluateExpectedPageUrlOnLoadStop(String? url) async {
    final log = logger.child('evaluateUrlOnLoadStop');

    final expectedUrl = claimCreationController.getNextLocation();
    if (expectedUrl == null) {
      // Do nothing, wait for user to press the continue button
      return;
    }

    if (!await _canContinueWithExpectedUrl(expectedUrl)) return;

    if (mounted) {
      log.info('canGuideToExpected: $expectedUrl');
      setState(() {
        _nextExpectedPageUrl = expectedUrl;
      });
    }
  }

  void _navigateToExpectedPage() async {
    final expectedPage = _nextExpectedPageUrl;

    if (expectedPage == null) {
      return;
    }
    _nextExpectedPageUrl = null;
    final didContinue = await _onContinue(expectedPage);
    // if the expected page is not navigated to, then we need to show the [_ContinueExpectedPageActionBar] again
    if (!didContinue && _nextExpectedPageUrl == null && mounted) {
      setState(() {
        _nextExpectedPageUrl = expectedPage;
      });
    }
  }

  Future<bool> _canContinueWithExpectedUrl(String expectedPageUrl) async {
    final log = logger.child('WebviewScreenState._canContinueWithExpectedUrl');
    final controller = webViewController;
    if (controller == null) return false;
    final currentUrl = await controller.getUrl().then((value) {
      return value?.toString();
    });
    if (currentUrl == null) return true;
    if (url_util.isLoginUrl(currentUrl)) {
      log.finer(
        'Cannot continue to expected page "$expectedPageUrl" because current url is a login url: "$currentUrl"',
      );
      return false;
    }
    if (url_util.isUrlsEqual(currentUrl, expectedPageUrl)) {
      log.finer(
        'Cannot continue to expected page "$expectedPageUrl" because current url is "$currentUrl"',
      );
      return false;
    }
    return true;
  }

  void _sendRequestsForDiagnosisPeriodic() {
    logger.info('Sending requests for diagnosis');
    try {
      final logs = requestLogs;
      if (logs == null || logs.isEmpty) {
        logger.finest('No logs to send for diagnosis');
        return;
      }
      requestLogs = [];
      // not awaiting result
      NetworkLogsService().addToQueue(
        widget.sessionId,
        widget.providerData?.httpProviderId ?? '',
        logs,
      );
    } catch (e, s) {
      logger.severe('Failed to send requests for diagnosis', e, s);
    } finally {
      if (mounted) {
        Timer(Duration(seconds: 5), _sendRequestsForDiagnosisPeriodic);
      }
    }
  }

  void _showRequestShareConsentPromptIfError() {
    if (!mounted) return;
    final msg = _scaffoldMessenger!;
    // show prompt immediately if there is an error
    final claimState = claimCreationController.value;
    if (claimState.hasError) {
      _requestShareConsentPromptTimer?.cancel();
      _requestShareConsentPromptTimer = null;
      claimCreationController.removeListener(
        _showRequestShareConsentPromptIfError,
      );
      _showRequestShareConsentPrompt();
    } else if (claimState.delegate?.isBottomSheetOpen == true) {
      msg.clearSnackBars();
      msg.removeCurrentSnackBar();
    }
  }

  bool didConsentToShareRequests = false;

  Future<bool> _isCurrentPageLogin() async {
    final url = (await webViewController?.getUrl())?.toString();
    final loginUrl = widget.providerData?.loginUrl;
    if (url != null) {
      if (loginUrl == null && url_util.isLoginUrl(url)) {
        return true;
      } else if (url_util.isUrlsEqual(url, loginUrl)) {
        return true;
      }
    }
    return false;
  }

  void _showRequestShareConsentPrompt() async {
    if (!mounted) return;
    final msg = _scaffoldMessenger!;
    final log = logger.child('_showRequestShareConsentPrompt');
    log.finer('Asking for permission to dump requests now');
    if (didConsentToShareRequests) {
      // we already have the consent, so we don't need to show the request share consent prompt
      return;
    }
    if (claimCreationController.value.isFinished) {
      // if the claim is finished, then we don't need to show the request share consent prompt
      return;
    }

    final manualReviewMessage = _manualReviewMessage?.message;
    final canSubmit = _manualReviewMessage?.canSubmit ?? true;
    final displayRule = _manualReviewMessage?.rule;

    if (displayRule != null && displayRule == ManualReviewPromptDisplayRule.NOT_LOGIN) {
      if (await _isCurrentPageLogin()) {
        log.info(
          'Current page is login page, skipping request share consent prompt',
        );
        return;
      }
    }

    late ScaffoldFeatureController<SnackBar, SnackBarClosedReason> ctrl;

    void onSharePressed() {
      if (!canSubmit) return;

      didConsentToShareRequests = true;
      _sendRequestsForDiagnosisPeriodic();
      ctrl.close();
      if (claimCreationController.value.delegate?.isBottomSheetOpen == true) {
        Navigator.of(context).pop();
      }
      unawaitedSequence([
        ReclaimSession.sendLogs(
          appId: widget.appId,
          sessionId: widget.sessionId,
          providerId: widget.providerData?.httpProviderId ?? '',
          logType: 'PROOF_MANUAL_VERIFICATION_SUBMITTED',
        ),
        ReclaimSession.updateSession(
          widget.sessionId,
          SessionStatus.PROOF_MANUAL_VERIFICATION_SUBMITED,
        ),
      ]);
      _onReclaimException(const ReclaimVerificationManualReviewException());
    }

    msg.clearSnackBars();
    msg.removeCurrentSnackBar();
    ctrl = msg.showSnackBar(
      SnackBar(
        backgroundColor: Color(0xFFF7F7F8),
        content: InkWell(
          onTap: onSharePressed,
          child: Text.rich(
            manualReviewMessage != null
                ? TextSpan(text: manualReviewMessage)
                : TextSpan(
                  children: [
                    TextSpan(text: 'Tap '),
                    TextSpan(
                      text: 'Share',
                      style: TextStyle(
                        color: ReclaimTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(text: ' to send data for manual review'),
                  ],
                ),
            style: TextStyle(color: Colors.black),
          ),
        ),
        // show this for a very long time
        duration: const Duration(seconds: 120),
        action:
            !canSubmit
                ? null
                : SnackBarAction(
                  label: _manualReviewMessage?.submitLabel ?? 'Share',
                  backgroundColor: ReclaimTheme.primary.withValues(alpha: 0.08),
                  textColor: ReclaimTheme.primary,
                  onPressed: onSharePressed,
                ),
      ),
    );
    ctrl.closed.then((value) {
      if (value == SnackBarClosedReason.remove) {
        return;
      }
      _rescheduleRequestShareConsentPromptWithIdleTimeThreshold();
    });
  }

  void _rescheduleRequestShareConsentPromptWithIdleTimeThreshold() {
    // user dismissed for some reason, so we need to show the prompt again if required after idle time threshold
    if (!didConsentToShareRequests) {
      _requestShareConsentPromptTimer?.cancel();
      _requestShareConsentPromptTimer = Timer(
        Duration(seconds: idleTimeThreshold),
        _showRequestShareConsentPrompt,
      );
    }
  }

  Future<void> _scheduleToShowRequestShareConsentPromptIfRequired() async {
    final log = logger.child('_showRequestShareConsentPromptIfRequired');
    final prefs = await SharedPreferences.getInstance();
    final canUseAiFlow = Flags.getCanUseAiFlow(prefs);
    log.info({
      'canUseAiFlow': canUseAiFlow,
      'manualReviewMessage': _manualReviewMessage,
    });
    if (!canUseAiFlow) {
      requestLogs = null;
      log.finest(
        'Cannot use AI flow, skipping request share consent prompt scheduling',
      );
      return;
    }
    claimCreationController.addListener(_showRequestShareConsentPromptIfError);
    if (!mounted) return;
    log.finer('scheduling prompting request share consent prompt');
    _requestShareConsentPromptTimer?.cancel();
    if (_manualReviewMessage?.rule == ManualReviewPromptDisplayRule.IMMEDIATELY) {
      Future.microtask(_showRequestShareConsentPrompt);
    }
    final requestShareConsentPromptThreshold =
        Flags.getSessionTimeoutForManualVerificationTrigger(prefs);
    log.finer(
      'Asking for permission to dump requests in $requestShareConsentPromptThreshold seconds',
    );
    _requestShareConsentPromptTimer = Timer(
      Duration(seconds: requestShareConsentPromptThreshold),
      _showRequestShareConsentPrompt,
    );
  }

  Future<bool> _onContinue(String expectedPageUrl) async {
    final log = logger.child('WebviewScreenState._onContinue');
    final controller = webViewController;
    if (controller == null) return false;
    final currentUrl = await controller.getUrl().then(
      (value) => value?.toString(),
    );

    // Get the host from current URL and use it for relative URLs
    final currentHost = currentUrl != null ? Uri.parse(currentUrl).host : '';
    final fullExpectedUrl =
        expectedPageUrl.startsWith('http')
            ? expectedPageUrl
            : 'https://${expectedPageUrl.startsWith('/') ? currentHost + expectedPageUrl : expectedPageUrl}';

    if (!await _canContinueWithExpectedUrl(fullExpectedUrl)) {
      return false;
    }
    if (!mounted) {
      log.finer(
        'Cannot continue to expected page "$fullExpectedUrl" because the Webview has been disposed',
      );
      return false;
    }
    log.info(
      'Navigating to expected page "$fullExpectedUrl" from "$currentUrl"',
    );
    await controller.loadUrl(
      urlRequest: URLRequest(url: WebUri(fullExpectedUrl)),
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ClaimCreationScope(
      uiDelegateOptions: ClaimCreationUIDelegateOptions(
        autoSubmit: widget.autoSubmit,
        appId: widget.appId,
        onSubmitProofs: _onSubmitProofs,
        onContinue: _onContinue,
        onException: _onReclaimException,
      ),
      controller: claimCreationController,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _activeIndex,
          children: [
            Column(
              children: [
                AnimatedBuilder(
                  animation: _webviewProgressNotifier,
                  builder: (context, snapshot) {
                    return WebviewBar(
                      webviewUrl:
                          (() {
                            final url = _webviewUrl.trim();
                            if (url.isNotEmpty) return url;

                            return widget.providerData?.loginUrl ??
                                'loading...';
                          })(),
                      webviewProgress: _webviewProgressNotifier.value,
                      openDebugMenu: () => _showDebugBottomSheet(),
                      close:
                          !widget.hideCloseButton
                              ? () => Navigator.of(context).pop()
                              : null,
                    );
                  },
                ),
                Expanded(
                  child: Stack(
                    children: [
                      FutureBuilder(
                        future: _userScriptsCompleter.future,
                        builder: (context, snapshot) {
                          final data = snapshot.data;
                          if (data == null) {
                            return const SizedBox.shrink();
                          }
                          return InAppWebView(
                            key: _key,
                            gestureRecognizers: gestureRecognizers,
                            onGeolocationPermissionsShowPrompt:
                                _onGeolocationPermissionsShowPrompt,
                            onPermissionRequest: _onPermissionRequestedFromWeb,
                            initialUserScripts: data,
                            onLoadStart: (controller, url) {
                              markWebsiteLoading();
                              if (url.toString() != _webviewUrl) {
                                if (_aiCheckingTimer != null &&
                                    _aiCheckingTimer!.isActive) {
                                  _aiCheckingTimer?.cancel();
                                  setState(() {
                                    _aiRecommendation = null;
                                  });
                                }
                              }
                              _webviewUrl = url.toString();
                              _webviewProgressNotifier.value = 0.1;
                              logger
                                  .child('webview_load_event')
                                  .info('Webview load start $url');
                              setState(() {
                                //
                              });
                            },
                            onProgressChanged: (controller, progress) {
                              setState(() {
                                _webviewProgressNotifier.value =
                                    progress / 100.0;
                              });
                            },
                            onLoadStop: (controller, url) async {
                              logger
                                  .child('webview_load_event')
                                  .info('Webview load stop $url');
                              markWebsiteLoaded();
                              _webviewUrl = url?.toString() ?? '';
                              evaluateExpectedPageUrlOnLoadStop(
                                url?.toString(),
                              );
                              if (mounted) {
                                if (_manualReviewMessage?.rule == ManualReviewPromptDisplayRule.NOT_LOGIN) {
                                  _showRequestShareConsentPrompt();
                                }
                                if (isAIProvider() && !aiCheckingLoading) {
                                  await waitUntilWebsiteLoaded();
                                  _isAIVerificationStarted = false;
                                  _isAiRecommendationDismissed = false;
                                  await _triggerAIChecking();
                                } else if (aiCheckingLoading) {
                                  aiFlowService.reset();
                                  await waitUntilWebsiteLoaded();
                                  _isAIVerificationStarted = false;
                                  _isAiRecommendationDismissed = false;
                                  await _triggerAIChecking();
                                }
                              }
                            },
                            initialUrlRequest: URLRequest(
                              url: WebUri(widget.providerData?.loginUrl ?? ''),
                            ),
                            initialSettings: InAppWebViewSettings(
                              javaScriptCanOpenWindowsAutomatically: true,
                              supportMultipleWindows: true,
                              isInspectable: _isWebInspectable,
                              incognito:
                                  widget.providerData?.useIncognitoWebview,
                            ),
                            onWebViewCreated: _onWebViewCreated,
                            onCreateWindow: (
                              controller,
                              createWindowAction,
                            ) async {
                              setState(() {
                                _createWindowAction = createWindowAction;
                                _activeIndex = 1;
                              });
                              return true;
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                if (_nextExpectedPageUrl != null)
                  _ContinueExpectedPageActionBar(
                    onPressed: _navigateToExpectedPage,
                  )
                else if (_aiRecommendation != null && !_isKeyboardVisible)
                  RecommendationBar(
                    label: _aiRecommendation!,
                    backgroundColor: Colors.grey[300]!,
                    foregroundColor: Colors.black,
                    isLoading: true,
                    onDismiss: onAiDismiss,
                  ),
              ],
            ),
            if (_createWindowAction != null)
              WindowPopup(
                createWindowAction: _createWindowAction!,
                closePopup:
                    () => {
                      setState(() {
                        _activeIndex = 0;
                      }),
                    },
              ),
          ],
        ),
        bottomNavigationBar: ClaimCreationIndicatorWrapper(
          child: WebviewBottomBar(
            sessionId: widget.sessionId,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          ),
        ),
      ),
    );
  }

  Future<PermissionResponse?> _onPermissionRequestedFromWeb(
    controller,
    request,
  ) async {
    for (final resource in request.resources) {
      if (resource == PermissionResourceType.CAMERA) {
        await requestPermission(Permission.camera);
      } else if (resource == PermissionResourceType.CAMERA_AND_MICROPHONE) {
        await requestPermission(Permission.camera);
        await requestPermission(Permission.microphone);
      } else if (resource == PermissionResourceType.MICROPHONE) {
        await requestPermission(Permission.microphone);
      } else if (resource == PermissionResourceType.GEOLOCATION) {
        await requestPermission(Permission.location);
        await requestPermission(Permission.locationAlways);
        await requestPermission(Permission.locationWhenInUse);
      } else {
        // do nothing
      }
    }
    return PermissionResponse(
      action: PermissionResponseAction.PROMPT,
      resources: request.resources,
    );
  }

  void extractUrlTemplateParams(proofData, Map<String, String> params) {
    UserScriptService.extractUrlTemplateParams(
      proofData,
      params,
      widget.parameters,
    );
  }
}

class _ContinueExpectedPageActionBar extends StatelessWidget {
  final VoidCallback onPressed;
  const _ContinueExpectedPageActionBar({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ActionBar(
      onPressed: onPressed,
      label: 'Tap to continue verification',
      backgroundColor: const Color(0xffffc636),
      foregroundColor: Colors.black,
    );
  }
}
