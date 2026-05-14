import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple_shimmer/simple_shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../ui.dart';
import '../../constants.dart';
import '../../controller.dart';
import '../../data/data.dart';
import '../../data/web_context.dart';
import '../../exception/exception.dart';
import '../../l10n/provider.dart';
import '../../logging/logging.dart';
import '../../repository/feature_flags.dart';
import '../../theme/theme.dart';
import '../../ui/claim_creation_webview/view_model.dart';
import '../../ui/claim_creation_webview/window/controller.dart';
import '../../ui/claim_creation_webview/window/view.dart';
import '../../usecase/login_detection.dart';
import '../../utils/observable_notifier.dart';
import '../../utils/url.dart';
import '../ai_flow_coordinator_widget.dart';
import '../animated_icon/check.dart';
import '../claim_creation/claim_creation.dart';
import '../claim_creation/trigger_indicator.dart';
import '../color_or_image.dart';
import '../loading/shimmer_shader.dart';
import 'controller.dart';
import 'live_background.dart';

const _borderRadius = BorderRadius.all(Radius.circular(12));

class VerificationReview extends StatefulWidget {
  const VerificationReview({super.key, required this.onExtendNoActivity, required this.child});

  final VoidCallback onExtendNoActivity;
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

    final padding = MediaQuery.paddingOf(context);

    PopupWindowController? popupController;
    try {
      popupController = PopupWindowController.of(context);
    } catch (e) {
      // PopupWindowController not in tree, which is fine for some contexts
    }

    final isPopupVisible = popupController?.value.isVisible ?? false;

    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        // Render popup window if available and visible
        if (popupController != null)
          ValueListenableBuilder<PopupWindowState>(
            valueListenable: popupController,
            builder: (context, popupState, child) {
              if (!popupState.isVisible || popupState.parameters == null) {
                return const SizedBox.shrink();
              }
              return WebViewWindow(parameters: popupState.parameters!);
            },
          ),
        IgnorePointer(
          ignoring: !isEffectivelyVisible,
          child: AnimatedOpacity(
            duration: Durations.extralong4,
            opacity: isEffectivelyVisible ? 1 : 0,
            curve: Curves.fastEaseInToSlowEaseOut,
            child: VerificationReviewPage(
              key: verificationReviewPageKey,
              onExtendNoActivity: widget.onExtendNoActivity,
            ),
          ),
        ),
        // Show bottom bar when review is visible AND popup is visible
        // (main window already has its own bottom bar)
        if (isEffectivelyVisible && isPopupVisible)
          IgnorePointer(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: padding.bottom),
                child: const WebviewBottomBar(),
              ),
            ),
          ),
        IgnorePointer(
          child: Padding(
            // Add WebviewBottomBar height to padding only when popup is visible
            // (main window handles its own bottom bar padding)
            padding: EdgeInsets.only(bottom: padding.bottom + (isPopupVisible ? WebviewBottomBar.estimateHeight : 0)),
            child: const ClaimCreationIndicatorOverlay(),
          ),
        ),
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

    late final background = VerificationReviewBackground(
      child: Padding(
        padding: const EdgeInsets.only(top: 10.0, left: 20.0, right: 20.0, bottom: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: VerificationReviewPageSurface.smallScreenWidthExtent),
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
    );

    Color scaffoldBackgroundColor = theme.scaffoldBackgroundColor;

    final reclaimTheme = ReclaimTheme.of(context);

    switch (reclaimTheme.background) {
      case ColorDecorationProvider(color: final color):
        return Material(color: color, child: background);
      default:
        return Material(color: scaffoldBackgroundColor, child: background);
    }
  }
}

class VerificationReviewPage extends StatefulWidget {
  const VerificationReviewPage({super.key, required this.onExtendNoActivity});

  final VoidCallback onExtendNoActivity;

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
            hasProviderData: providerData != null,
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
                    key: const ValueKey('key-review-provider-data'),
                    duration: Durations.medium1,
                    switchInCurve: Curves.easeIn,
                    switchOutCurve: Curves.easeOut,
                    child: providerData == null || value.claims.every((e) => e.isIdle) || paramInfo.params.isEmpty
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!value.hasError)
                                const Padding(
                                  padding: EdgeInsets.only(top: 32.0),
                                  child: ReclaimCircularProgressIndicator(size: 14),
                                ),
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
                    padding: const EdgeInsets.only(top: 0.0, bottom: 0.0),
                    child: _ActionView(
                      isFinished: value.isFinished,
                      hasError: value.hasError,
                      onExtendNoActivity: widget.onExtendNoActivity,
                    ),
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
    () => context.l10n.lookingForInformationToVerify,
    () => context.l10n.youAreInCompleteControlOfYourData,
    () => context.l10n.youAlwaysControlWhoYouShareYourDataWith,
    () => context.l10n.waitingForVerification,
    () => context.l10n.thisMightTakeAFewSeconds,
    () {
      final webViewController = ClaimCreationWebClientViewModel.readOf(context);
      return context.l10n.verifyingDataFrom(domain: extractHost(webViewController.value.webAppBarValue.url));
    },
    () => context.l10n.thisShouldntTakeMuchLonger,
    () => context.l10n.pleaseHoldOnForJustALittleLonger,
    () => context.l10n.almostThereJustFinalizingTheDetails,
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
    webContext = AIFlowCoordinatorWidget.maybeReadWebContextOf(context) ?? WebContext();
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
    log.info('updating info text in review screen: $infoText');
    if (infoText.isNotEmpty && infoText != _aiInfoText) {
      setState(() {
        _aiInfoText = infoText;
      });
    }
  }

  void _startLoadingTextsTimer() {
    final t = _loadingTextsTimer;
    if (t != null && t.isActive) return;

    _loadingTextsTimer = Timer.periodic(const Duration(seconds: 5), _onTimerTick);
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
    webContext = AIFlowCoordinatorWidget.maybeWebContextOf(context) ?? webContext;
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
    Color textColor,
  ) {
    return theme.textTheme.titleMedium?.merge(
          TextStyle(
            fontWeight: value.hasError ? FontWeight.bold : fontWeight,
            color: textColor,
            fontSize: fontSize,
            height: lineHeight,
            fontVariations: value.hasError ? [const FontVariation.weight(700)] : [const FontVariation.weight(500)],
          ),
        ) ??
        TextStyle(fontWeight: fontWeight);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final value = controller.value;

    final primaryColor = const Color(0xFF0000EE); // theme.colorScheme.primary;
    final secondaryColor = const Color(0xFF0000EE).withValues(alpha: 0.4); // theme.colorScheme.secondary;

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
        subtitle = TextSpan(text: context.l10n.somethingWentWrong);
      }
    } else if (value.isFinished) {
      subtitle = TextSpan(
        children: buildTextSpanWithHighlights(
          context.l10n.sharingWith(appName: widget.appInfo?.appName ?? 'App'),
          highlightedStyle: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.w700,
            fontVariations: [const FontVariation.weight(700)],
          ),
        ),
      );
    } else if (_aiInfoText.isNotEmpty) {
      subtitle = TextSpan(text: _aiInfoText);
    } else if (!canStartWebClient) {
      subtitle = TextSpan(text: context.l10n.gettingReady);
    } else if (_maybeRequiresLogin && value.isIdle) {
      subtitle = TextSpan(text: context.l10n.gettingReadyToVerify);
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

    final brightness = Theme.brightnessOf(context);

    final textColor = switch (brightness) {
      Brightness.dark => Colors.white,
      Brightness.light => Colors.black,
    };

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
                            children: buildTextSpanWithHighlightsForAI(
                              subtitle.toPlainText(),
                              style: _buildTextStyle(theme, value, FontWeight.w400, fontSize, lineHeight, textColor),
                              highlightedStyle: _buildTextStyle(
                                theme,
                                value,
                                FontWeight.w900,
                                fontSize,
                                lineHeight,
                                textColor,
                              ),
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

class _TermsOfUseNotice extends StatefulWidget {
  const _TermsOfUseNotice({super.key, this.isVisible = true, this.isAutoSubmitEnabled = false});

  final bool isVisible;
  final bool isAutoSubmitEnabled;

  @override
  State<_TermsOfUseNotice> createState() => _TermsOfUseNoticeState();
}

class _TermsOfUseNoticeState extends State<_TermsOfUseNotice> {
  @override
  void initState() {
    super.initState();
    // pre-load terms
    getTermsFeatureFlags(TermsType.privacyPolicy);
    getTermsFeatureFlags(TermsType.termsOfService);
  }

  Future<Uri?> getTermsFeatureFlags(TermsType type) async {
    final identity = SessionIdentity.latest;

    if (identity == null) return null;

    final log = logging.child('getTermsFeatureFlags');
    try {
      final FeatureFlag<String> flag = switch (type) {
        TermsType.privacyPolicy => FeatureFlag.privacyPolicyUrl,
        TermsType.termsOfService => FeatureFlag.termsOfServiceUrl,
      };
      final repo = FeatureFlagRepository();
      final url = await repo.getFeatureFlag(identity, flag);
      if (url.trim().isEmpty) return null;
      return Uri.parse(url);
    } catch (e, s) {
      log.warning('Failed to get feature flag', e, s);
    }
    return null;
  }

  void _onTermsOfUsePressed(BuildContext context, TermsType type) async {
    final log = logging.child('TermsOfUseNotice');
    final messenger = ScaffoldMessenger.of(context);
    final reclaimTheme = ReclaimTheme.of(context);

    try {
      final Uri uri =
          switch (type) {
            TermsType.privacyPolicy => reclaimTheme.privacyPolicyUri,
            TermsType.termsOfService => reclaimTheme.termsAndConditionsUri,
          } ??
          (await getTermsFeatureFlags(type)) ??
          Uri.parse(type.url);
      log.info('Launching terms type url: $uri');

      final stopwatch = Stopwatch()..start();
      final didLaunch = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      stopwatch.stop();

      if (didLaunch || stopwatch.elapsed > const Duration(seconds: 2)) {
        return;
      }
    } catch (e, s) {
      log.severe('Failed to launch terms of use', e, s);
    }

    if (!context.mounted) return;

    messenger.showSnackBar(SnackBar(content: Text(context.l10n.findOurTermsOfServicePrivacyPolicyAt)));
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.sizeOf(context).width > VerificationReviewPageSurface.smallScreenWidthExtent;
    final reclaimTheme = ReclaimTheme.of(context);

    final highlightColor =
        reclaimTheme.hyperlinkColor ?? (Theme.brightnessOf(context) == Brightness.light ? Colors.indigo : Colors.amber);

    final textAlign = (isLargeScreen || widget.isAutoSubmitEnabled) ? TextAlign.center : TextAlign.start;

    return AnimatedOpacity(
      duration: Durations.short3,
      curve: Curves.easeIn,
      opacity: widget.isVisible ? 1 : 0,
      child: FontsLoaded(
        child: Padding(
          padding: textAlign == TextAlign.center ? const EdgeInsets.symmetric(horizontal: 25.0) : EdgeInsets.zero,
          child: Text.rich(
            TextSpan(
              children: buildTextSpanWithHighlights(
                context.l10n.byContinuingYouAgreeToThese,
                highlightedStyle: TextStyle(color: highlightColor, decoration: TextDecoration.underline),
                builder: ({text, style}) {
                  final termsType = text?.contains('@1') == true
                      ? TermsType.termsOfService
                      : (text?.contains('@2') == true ? TermsType.privacyPolicy : null);

                  return TextSpan(
                    text: text?.replaceFirst('@1', '').replaceFirst('@2', ''),
                    style: style,
                    recognizer: termsType == null
                        ? null
                        : (TapGestureRecognizer()..onTap = () => _onTermsOfUsePressed(context, termsType)),
                  );
                },
              ),
            ),
            style: TextStyle(color: reclaimTheme.termsNoticeColor),
            textAlign: textAlign,
          ),
        ),
      ),
    );
  }
}

class _ActionView extends StatefulWidget {
  const _ActionView({this.isFinished = false, this.hasError = false, required this.onExtendNoActivity});

  final bool isFinished;
  final bool hasError;
  final VoidCallback onExtendNoActivity;

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
    final log = logging.child('ClaimCreationBottomSheetState._onShared');
    log.finest('sharing proof');

    // show next page after sharing proof
    setState(() => _isSubmitted = true);

    // autohide bottom sheet after 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    // don't pop if widget already disposed (maybe user swiped down to close bottom sheet)
    if (!mounted) return;

    final maybeProofs = controller.value.claims.map((e) => e.proofs);
    final publicData = controller.value.publicData;
    // FINE is NOT sanitized by the upload pipeline; raw publicData would leak
    // end-user PII. INFO emits a redacted notification; FINER keeps the raw value.
    log.info('publicData ready (body redacted at INFO; raised to FINER for full payload)');
    log.finer('publicData: $publicData');
    final proofs =
        <CreateClaimOutput>[
          for (final proofs in maybeProofs)
            if (proofs != null) ...proofs,
        ]
        // attach public data to all proofs
        .map((e) => e.copyWith(publicData: publicData));

    assert(proofs.isNotEmpty);
    options?.onSubmitProofs(proofs);
  }

  bool _isSubmitted = false;

  final submitViewKey = GlobalKey(debugLabel: 'submitViewKey');

  @override
  Widget build(BuildContext context) {
    final isSubmitted = _isSubmitted || isAutoSubmitEnabled;
    final textScaler = MediaQuery.textScalerOf(context);

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
              return SizedBox(
                height: textScaler.scale(148),
                child: _ErrorWidget(onExtendNoActivity: widget.onExtendNoActivity),
              );
            }
            if (!widget.isFinished) {
              return const SizedBox(height: 100);
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
            key: const ValueKey('key-terms-of-use-notice'),
            isVisible: !_isSubmitted && !widget.hasError,
            isAutoSubmitEnabled: isAutoSubmitEnabled,
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
          Text(context.l10n.submit),
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
  const _ErrorWidget({required this.onExtendNoActivity});

  final VoidCallback onExtendNoActivity;

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
                    if (kDebugMode) {
                      Clipboard.setData(ClipboardData(text: clientError.toString()));
                      return;
                    }
                    // extend timer
                    onExtendNoActivity();
                    // clear the error and let the user continue
                    controller.setClientError(null);
                    // hide this review screen
                    controller.value.delegate?.hideReview();
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(context.l10n.tryAgain),
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
        const Padding(padding: EdgeInsets.only(top: 8.0), child: PotentialErrorReasonsLearnMoreWidget()),
      ],
    );
  }
}
