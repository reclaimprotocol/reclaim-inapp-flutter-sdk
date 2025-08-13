import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:simple_shimmer/simple_shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants.dart';
import '../../controller.dart';
import '../../data/data.dart';
import '../../data/web_context.dart';
import '../../exception/exception.dart';
import '../../logging/logging.dart';
import '../../ui/claim_creation_webview/view_model.dart';
import '../../usecase/login_detection.dart';
import '../../utils/observable_notifier.dart';
import '../../utils/url.dart';
import '../action_button.dart';
import '../ai/recommendation_text.dart';
import '../ai_flow_coordinator_widget.dart';
import '../animated_icon/check.dart';
import '../app_provider_icon_bar.dart';
import '../claim_creation/claim_creation.dart';
import '../claim_creation/trigger_indicator.dart';
import '../fonts_loaded.dart';
import '../item_alignment.dart';
import '../loading/shimmer_shader.dart';
import '../params/params_text.dart';
import '../potential_failure_reasons.dart';
import 'controller.dart';
import 'live_background.dart';

const _borderRadius = BorderRadius.all(Radius.circular(12));

class VerificationReview extends StatefulWidget {
  const VerificationReview({super.key, required this.child});

  final Widget child;

  @override
  State<VerificationReview> createState() => _VerificationReviewState();
}

class _VerificationReviewState extends State<VerificationReview> {
  late VerificationReviewController controller;

  @override
  void initState() {
    super.initState();
    controller = VerificationReviewController.readOf(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller = VerificationReviewController.of(context);
  }

  @override
  void dispose() {
    super.dispose();
  }

  final verificationReviewPageKey = GlobalKey(debugLabel: 'verificationReviewPageKey');

  @override
  Widget build(BuildContext context) {
    final isEffectivelyVisible = controller.value.isVisible;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        IgnorePointer(
          ignoring: !isEffectivelyVisible,
          child: AnimatedOpacity(
            duration: Durations.extralong4,
            opacity: isEffectivelyVisible ? 1 : 0,
            curve: Curves.fastEaseInToSlowEaseOut,
            child: VerificationReviewPage(key: verificationReviewPageKey),
          ),
        ),
        IgnorePointer(child: ClaimCreationIndicatorOverlay()),
      ],
    );
  }
}

class VerificationReviewPageSurface extends StatelessWidget {
  const VerificationReviewPageSurface({super.key, required this.children, required this.alignment});

  final ItemAlignment alignment;
  final List<Widget> children;

  static const smallScreenWidthExtent = 600.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: LiveBackground(
        child: Padding(
          padding: const EdgeInsets.only(top: 10.0, left: 20.0, right: 20.0, bottom: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: VerificationReviewPageSurface.smallScreenWidthExtent),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: alignment.isStarting ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VerificationReviewPage extends StatefulWidget {
  const VerificationReviewPage({super.key});

  @override
  State<VerificationReviewPage> createState() => _VerificationReviewPageState();
}

class _VerificationReviewPageState extends State<VerificationReviewPage> {
  AppInfo? appInfo;

  @override
  void initState() {
    super.initState();
    verificationController = VerificationController.readOf(context);
    final appId = verificationController.request.applicationId;
    AppInfo.fromAppId(appId).then((appInfo) {
      if (mounted) {
        setState(() {
          this.appInfo = appInfo;
        });
      }
    }).ignore();
  }

  late ThemeData theme;
  late ClaimCreationController controller;
  late VerificationController verificationController;
  late ClaimCreationWebClientViewModel webClientViewModel;
  late ParamInfo paramInfo;

  final paramsTextKey = GlobalKey(debugLabel: 'paramsTextKey');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    controller = ClaimCreationController.of(context);
    verificationController = VerificationController.of(context);
    webClientViewModel = ClaimCreationWebClientViewModel.of(context);
    paramInfo = ParamInfo.fromBuildContext(context);
  }

  final _animatedAppProviderIconsBarKey = GlobalKey(debugLabel: 'animatedAppProviderIconsBarKey');

  @override
  Widget build(BuildContext context) {
    final value = controller.value;

    final providerData = value.httpProvider;

    final itemAlignment = ItemAlignment.center;

    final shimmerTheme = SimpleShimmerTheme.of(context);

    return SimpleShimmerTheme(
      data: shimmerTheme.copyWith(decoration: shimmerTheme.decoration.copyWith(borderRadius: _borderRadius)),
      child: VerificationReviewPageSurface(
        alignment: itemAlignment,
        children: [
          const SizedBox(height: 16.0),
          AppProviderIconsBar(
            key: _animatedAppProviderIconsBarKey,
            itemAlignment: itemAlignment,
            appImageUrl: appInfo?.appImage,
            appName: appInfo?.appName,
            providerImageUrl: providerData?.logoUrl,
            providerName: providerData?.name,
            borderRadius: _borderRadius,
            useInheritedVerificationInformation: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: _VerificationStatusMessage(itemAlignment: itemAlignment, appInfo: appInfo),
          ),
          const SizedBox(height: 16.0),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.max,
              children: [
                Flexible(
                  child: AnimatedSwitcher(
                    key: ValueKey('key-review-provider-data'),
                    duration: Durations.medium1,
                    switchInCurve: Curves.easeIn,
                    switchOutCurve: Curves.easeOut,
                    child: providerData == null || value.claims.every((e) => e.isIdle) || paramInfo.params.isEmpty
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!value.hasError)
                                Padding(padding: const EdgeInsets.only(top: 32.0), child: CupertinoActivityIndicator()),
                            ],
                          )
                        : FontsLoaded(
                            child: AnimatedOpacity(
                              duration: Durations.medium1,
                              curve: Curves.easeIn,
                              opacity: value.hasError ? 0.6 : 1,
                              child: ParamsText.fromParamInfo(
                                key: paramsTextKey,
                                info: paramInfo,
                                padding: EdgeInsets.zero,
                                shrinkWrap: false,
                              ),
                            ),
                          ),
                  ),
                ),
                Flexible(
                  flex: 0,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 0.0, bottom: 20.0),
                    child: _ActionView(isFinished: value.isFinished, hasError: value.hasError),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationStatusMessage extends StatefulWidget {
  const _VerificationStatusMessage({required this.itemAlignment, required this.appInfo});

  final ItemAlignment itemAlignment;
  final AppInfo? appInfo;

  @override
  State<_VerificationStatusMessage> createState() => _VerificationStatusMessageState();
}

class _VerificationStatusMessageState extends State<_VerificationStatusMessage> with SingleTickerProviderStateMixin {
  final log = logging.child('VerificationStatusMessage');

  late ClaimCreationController controller;
  late VerificationController verificationController;
  late WebContext webContext;
  Timer? _loadingTextsTimer;

  late final List<String Function()> _loadingTextsQueue = [
    () => 'Looking for information to verify',
    () => 'Your data resides exclusively on your phone',
    () => 'Waiting for verification',
    () => 'This might take a few seconds',
    () {
      final webViewController = ClaimCreationWebClientViewModel.readOf(context);
      return 'Verifying data from ${extractHost(webViewController.value.webAppBarValue.url)}';
    },
    () => 'Please hold on for just a little longer',
  ];

  String get currentLoadingText => _loadingTextsQueue.first();

  final List<StreamSubscription> _subscriptions = [];

  late final ClaimCreationWebClientViewModel webViewModel;
  bool isAiProvider = false;
  bool _maybeRequiresLogin = false;
  String _aiInfoText = '';

  @override
  void initState() {
    super.initState();
    controller = ClaimCreationController.readOf(context);
    verificationController = VerificationController.readOf(context);
    isAiProvider = verificationController.value.provider?.isAIProvider == true;
    _maybeRequiresLogin = isAiProvider;
    webViewModel = ClaimCreationWebClientViewModel.readOf(context);
    _subscriptions.add(webViewModel.subscribe(_claimCreationChange));
    _onWebPageUpdate();
  }

  Timer? _isLoginEvaluationTimer;

  void _claimCreationChange(ChangedValues<ClaimCreationWebState> changes) {
    final (oldValue, value) = changes.record;
    if (oldValue == value) return;
    if (oldValue?.webAppBarValue == value.webAppBarValue) return;
    final url = value.webAppBarValue.url;
    if (value.isLoading) return;
    if (url.isEmpty) return;
    _onWebPageUpdate();
  }

  void _onWebPageUpdate() async {
    final log = logging.child('onWebPageUpdate');
    log.info('onWebPageUpdate');
    if (isAiProvider) {
      _onWebPageUpdateRemoteDetection();
    } else {
      _onWebPageUpdateLocalDetection();
    }
  }

  void _onWebPageUpdateLocalDetection() async {
    final log = logging.child('onWebPageUpdate');

    _isLoginEvaluationTimer?.cancel();
    _isLoginEvaluationTimer = Timer(Durations.extralong4, () async {
      if (!mounted) return;
      if (!canStartWebClient) {
        // provider is not set yet, so we can't evaluate if current page is login
        setState(() {
          _maybeRequiresLogin = true;
        });
        return;
      }

      bool maybeRequiresLogin = false;
      final loginDetection = LoginDetection.readOf(context);
      try {
        if (await webViewModel.maybeCurrentPageRequiresLogin(loginDetection)) {
          maybeRequiresLogin = true;
        }
      } catch (e, s) {
        log.severe('Failed to evaluate if current page is login', e, s);
      }

      if (mounted) {
        setState(() {
          _maybeRequiresLogin = maybeRequiresLogin;
        });
      }
    });
  }

  void _onWebPageUpdateRemoteDetection() async {
    final log = logging.child('onWebPageUpdateRemoteDetection');

    if (!mounted) return;

    _onInfoTextUpdate(webContext.infoText);

    if (!_maybeRequiresLogin) return;

    try {
      log.info('webContext.isLoggedIn: ${webContext.isLoggedIn}');
      if (webContext.isLoggedIn) {
        setState(() {
          _maybeRequiresLogin = false;
        });
      }
    } catch (e, s) {
      log.severe('Failed to evaluate if current page is login', e, s);
    }
  }

  void _onInfoTextUpdate(String infoText) {
    final isAiFlowDone = webContext.aiFlowDone;
    log.info('updating info text in review screen: $infoText');
    if (isAiFlowDone) {
      setState(() {
        _aiInfoText = '';
      });
    } else if (infoText.isNotEmpty && infoText != _aiInfoText) {
      setState(() {
        _aiInfoText = infoText;
      });
    }
  }

  void _startLoadingTextsTimer() {
    final t = _loadingTextsTimer;
    if (t != null && t.isActive) return;

    _loadingTextsTimer = Timer.periodic(Duration(seconds: 3), _onTimerTick);
  }

  void _stopLoadingTextsTimer() {
    _loadingTextsTimer?.cancel();
    _loadingTextsTimer = null;
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _loadingTextsTimer?.cancel();
    super.dispose();
  }

  void _onTimerTick(_) {
    setState(() {
      final first = _loadingTextsQueue.removeAt(0);
      _loadingTextsQueue.add(first);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller = ClaimCreationController.of(context);
    verificationController = VerificationController.of(context);
    webContext = AIFlowCoordinatorWidget.maybeWebContext(context) ?? WebContext();
    webContext.onInfoTextChanged(_onInfoTextUpdate);
  }

  final reviewSubtitleKey = GlobalKey(debugLabel: 'reviewSubtitleKey');

  bool get canStartWebClient =>
      verificationController.value.userScripts != null && verificationController.value.provider != null;

  TextStyle _buildTextStyle(
    ThemeData theme,
    ClaimCreationControllerState value,
    FontWeight fontWeight,
    double fontSize,
    double lineHeight,
  ) {
    return theme.textTheme.titleMedium?.merge(
          TextStyle(
            fontWeight: value.hasError ? FontWeight.bold : fontWeight,
            color: value.hasError ? theme.colorScheme.error : Colors.black,
            fontSize: fontSize,
            height: lineHeight,
            fontVariations: value.hasError ? [FontVariation.weight(700)] : [FontVariation.weight(500)],
          ),
        ) ??
        TextStyle(fontWeight: fontWeight);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final value = controller.value;

    final primaryColor = Color(0xFF0000EE); // theme.colorScheme.primary;
    final secondaryColor = Color(0xFF0000EE).withValues(alpha: 0.4); // theme.colorScheme.secondary;

    final TextSpan subtitle;

    bool isShowingLoadingText = false;

    if (value.hasError) {
      final providerErrorMessage = value.providerError?.message?.trim();
      final clientErrorMessage = value.clientError?.message?.toString().trim();
      if (providerErrorMessage != null && providerErrorMessage.isNotEmpty) {
        subtitle = TextSpan(text: providerErrorMessage);
      } else if (clientErrorMessage != null && clientErrorMessage.isNotEmpty) {
        subtitle = TextSpan(text: clientErrorMessage);
      } else {
        subtitle = TextSpan(text: 'Something went wrong');
      }
    } else if (value.isFinished) {
      subtitle = TextSpan(
        text: 'Sharing with ',
        children: [
          TextSpan(
            text: widget.appInfo?.appName ?? 'App',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w700,
              fontVariations: [FontVariation.weight(700)],
            ),
          ),
        ],
      );
    } else if (_aiInfoText.isNotEmpty) {
      subtitle = TextSpan(text: _aiInfoText);
    } else if (!canStartWebClient) {
      subtitle = const TextSpan(text: 'Getting ready..');
    } else if (_maybeRequiresLogin && value.isIdle) {
      subtitle = TextSpan(text: 'Getting ready to verify');
    } else {
      isShowingLoadingText = true;

      _startLoadingTextsTimer();

      // page loading or proving or waiting for continuation
      subtitle = TextSpan(text: currentLoadingText);
    }

    if (!isShowingLoadingText) {
      _stopLoadingTextsTimer();
    }

    final isShimmerAnimationEnabled = !value.hasError && !value.isFinished;

    const int lines = 2;

    const fontSize = 20.0;
    const lineHeight = 1.2;

    return SizedBox(
      height: fontSize * lineHeight * lines,
      child: FontsLoaded(
        child: AnimatedSwitcher(
          key: reviewSubtitleKey,
          duration: Durations.long2,
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          child: Column(
            key: ValueKey('key-review-subtitle-$subtitle'),
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: widget.itemAlignment.isStarting ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: Row(
                  mainAxisAlignment: widget.itemAlignment.isStarting
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: ShimmerShader(
                        animate: isShimmerAnimationEnabled,
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor,
                        child: Text.rich(
                          TextSpan(
                            children: parseHighlightedText(
                              subtitle.toPlainText(),
                              _buildTextStyle(theme, value, FontWeight.w400, fontSize, lineHeight),
                              _buildTextStyle(theme, value, FontWeight.w900, fontSize, lineHeight),
                            ),
                          ),
                          textAlign: widget.itemAlignment.isStarting ? TextAlign.start : TextAlign.center,
                          maxLines: lines,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum TermsType {
  privacyPolicy(url: ReclaimUrls.PRIVACY_POLICY_URL),
  termsOfService(url: ReclaimUrls.TERMS_OF_SERVICE_URL);

  final String url;

  const TermsType({required this.url});
}

class _TermsOfUseNotice extends StatelessWidget {
  const _TermsOfUseNotice({super.key, this.isVisible = true});

  final bool isVisible;

  void _onTermsOfUsePressed(BuildContext context, TermsType type) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final stopwatch = Stopwatch()..start();
      final didLaunch = await launchUrl(Uri.parse(type.url), mode: LaunchMode.inAppBrowserView);
      stopwatch.stop();

      if (didLaunch || stopwatch.elapsed > const Duration(seconds: 2)) {
        return;
      }
    } catch (e, s) {
      logging.child('TermsOfUseNotice').severe('Failed to launch terms of use', e, s);
    }
    messenger.showSnackBar(
      SnackBar(content: Text('Find our terms of service & privacy policy at reclaimprotocol.org')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.sizeOf(context).width > VerificationReviewPageSurface.smallScreenWidthExtent;
    return AnimatedOpacity(
      duration: Durations.short3,
      curve: Curves.easeIn,
      opacity: isVisible ? 1 : 0,
      child: FontsLoaded(
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'By continuing, you agree to these '),
              TextSpan(
                text: 'Terms of Service',
                recognizer: TapGestureRecognizer()
                  ..onTap = () => _onTermsOfUsePressed(context, TermsType.termsOfService),
                style: TextStyle(color: Colors.indigo, decoration: TextDecoration.underline),
              ),
              TextSpan(text: ' and '),
              TextSpan(
                text: 'Privacy Policy',
                recognizer: TapGestureRecognizer()
                  ..onTap = () => _onTermsOfUsePressed(context, TermsType.privacyPolicy),
                style: TextStyle(color: Colors.indigo, decoration: TextDecoration.underline),
              ),
            ],
          ),
          textAlign: isLargeScreen ? TextAlign.center : TextAlign.start,
        ),
      ),
    );
  }
}

class _ActionView extends StatefulWidget {
  const _ActionView({this.isFinished = false, this.hasError = false});

  final bool isFinished;
  final bool hasError;

  @override
  State<_ActionView> createState() => _ActionViewState();
}

class _ActionViewState extends State<_ActionView> {
  late ClaimCreationController controller;
  late ClaimCreationUIDelegateOptions? options;

  bool get isAutoSubmitEnabled => options?.autoSubmit == true;

  @override
  void initState() {
    super.initState();
    controller = ClaimCreationController.of(context, listen: false);
    options = ClaimCreationUIDelegateOptions.of(context, listen: false);
  }

  @override
  void didUpdateWidget(covariant _ActionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFinished != oldWidget.isFinished && widget.isFinished) {
      if (isAutoSubmitEnabled) {
        Future.microtask(_onShared);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller = ClaimCreationController.of(context);
    options = ClaimCreationUIDelegateOptions.of(context);
  }

  /// This only animates the widget to [_DataSharedView] and pops this bottom sheet. Proof is actually
  /// returned from [ClaimCreationController.startClaimCreation] after [ClaimCreationBottomSheet] bottom sheet is closed.
  void _onShared() async {
    if (!mounted) return;

    logging.child('ClaimCreationBottomSheetState._onShared').finest('sharing proof');

    // show next page after sharing proof
    setState(() => _isSubmitted = true);

    // autohide bottom sheet after 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    // don't pop if widget already disposed (maybe user swiped down to close bottom sheet)
    if (!mounted) return;

    final maybeProofs = controller.value.claims.map((e) => e.proofs);
    final proofs = maybeProofs.whereType<List<CreateClaimOutput>>();

    assert(proofs.isNotEmpty && proofs.length == maybeProofs.length);
    options?.onSubmitProofs(proofs.expand((e) => e).toList());
  }

  bool _isSubmitted = false;

  final submitViewKey = GlobalKey(debugLabel: 'submitViewKey');

  @override
  Widget build(BuildContext context) {
    final isSubmitted = _isSubmitted || isAutoSubmitEnabled;
    final textScaleFactor = MediaQuery.textScalerOf(context).textScaleFactor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(
          key: const ValueKey('ClaimSuccessView'),
          duration: Durations.medium4,
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          child: () {
            if (widget.hasError) {
              return SizedBox(height: 148 * textScaleFactor, child: _ErrorWidget());
            }
            if (!widget.isFinished) {
              return SizedBox(height: 100);
            }
            if (!isSubmitted) {
              return SizedBox(
                height: 100,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [_SubmitWidget(key: submitViewKey, onShareButtonPress: _onShared)],
                ),
              );
            }
            return _DataSharedView(height: 100, play: isSubmitted);
          }(),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: _TermsOfUseNotice(
            key: ValueKey('key-terms-of-use-notice'),
            isVisible: !_isSubmitted && !widget.hasError,
          ),
        ),
      ],
    );
  }
}

class _DataSharedView extends StatefulWidget {
  const _DataSharedView({this.play = false, this.height});

  final bool play;
  final double? height;

  @override
  State<_DataSharedView> createState() => _DataSharedViewState();
}

class _DataSharedViewState extends State<_DataSharedView> {
  final tickKey = GlobalKey<DataSharedCheckAnimatedIconState>(debugLabel: 'tickKey');

  void play() {
    tickKey.currentState?.startAnimation();
  }

  void reset() {
    tickKey.currentState?.reset();
  }

  @override
  void didUpdateWidget(covariant _DataSharedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play != oldWidget.play) {
      if (widget.play) {
        play();
      } else {
        reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: DataSharedCheckAnimatedIcon(key: tickKey, height: widget.height),
          ),
        ],
      ),
    );
  }
}

class _SubmitWidget extends StatelessWidget {
  final VoidCallback onShareButtonPress;

  const _SubmitWidget({super.key, required this.onShareButtonPress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ActionButton(
      key: const ValueKey('ReclaimSubmitButton'),
      onPressed: onShareButtonPress,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text('Submit'),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [Icon(Icons.arrow_forward_ios_sharp, size: 16.0, color: colorScheme.onPrimary)],
          ),
        ],
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget();

  @override
  Widget build(BuildContext context) {
    final controller = ClaimCreationController.of(context);
    final clientError = controller.value.providerError ?? controller.value.clientError;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Icon(Icons.error_rounded, color: colorScheme.error, size: 40),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (clientError == null || clientError is ReclaimVerificationNoActivityDetectedException)
              Expanded(
                child: ActionButton(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                  onPressed: () {
                    controller.requestRetry();
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Text('Try again'),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [Icon(Icons.replay_rounded, size: 16.0, color: colorScheme.onPrimary)],
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ActionButton(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                  onPressed: () {
                    Navigator.of(context).pop();
                    final options = ClaimCreationUIDelegateOptions.of(context, listen: false);
                    options?.onException(clientError);
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(MaterialLocalizations.of(context).okButtonLabel),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [Icon(Icons.keyboard_return_rounded, size: 16.0, color: colorScheme.onPrimary)],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        Padding(padding: const EdgeInsets.only(top: 8.0), child: PotentialErrorReasonsLearnMoreWidget()),
      ],
    );
  }
}
