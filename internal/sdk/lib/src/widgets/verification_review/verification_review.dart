import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:simple_shimmer/simple_shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../assets/assets.dart';
import '../../constants.dart';
import '../../controller.dart';
import '../../data/data.dart';
import '../../logging/logging.dart';
import '../../ui/claim_creation_webview/view_model.dart';
import '../../utils/url.dart';
import '../animated_icon/check.dart';
import '../claim_creation/claim_creation.dart';
import '../claim_creation/trigger_indicator.dart';
import '../widgets.dart';
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
            duration: Durations.medium1,
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

enum ItemAlignment {
  center,
  start;

  bool get isStarting => this == ItemAlignment.start;
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

    final isPageLoading = webClientViewModel.value.isLoading;

    final providerData = value.httpProvider;
    final hasVerifiedAtleastOneClaim = value.hasVerifiedAtleastOneClaim;

    final itemAlignment = ItemAlignment.start;

    final shimmerTheme = SimpleShimmerTheme.of(context);

    final appInfoTitleTextStyle = TextStyle(
      fontWeight: FontWeight.w900,
      height: 1.2,
      fontSize: 22,
      color: Colors.black,
      fontFamily: $ReclaimFont.inter.description.name,
    );

    return SimpleShimmerTheme(
      data: shimmerTheme.copyWith(decoration: shimmerTheme.decoration.copyWith(borderRadius: _borderRadius)),
      child: VerificationReviewPageSurface(
        alignment: itemAlignment,
        children: [
          _AppProviderIconsBar(
            key: _animatedAppProviderIconsBarKey,
            itemAlignment: itemAlignment,
            appInfo: appInfo,
            providerData: providerData,
            hasVerifiedAtleastOneClaim: hasVerifiedAtleastOneClaim,
          ),
          const SizedBox(height: 8.0),
          AnimatedSwitcher(
            key: ValueKey('key-review-title'),
            duration: Durations.short3,
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            child: Row(
              mainAxisAlignment: itemAlignment.isStarting ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Text(
                  key: ValueKey('key-has-app-info-${appInfo != null}'),
                  appInfo == null ? 'Starting verification' : 'Sharing with ${appInfo?.appName ?? 'App'}',
                  textAlign: itemAlignment.isStarting ? TextAlign.start : TextAlign.center,
                  style: appInfoTitleTextStyle,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),
          _VerificationStatusMessage(itemAlignment: itemAlignment),
          Divider(),
          SizedBox(height: 10),
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
                    child:
                        providerData == null ||
                                (isPageLoading && value.claims.every((e) => e.isIdle)) ||
                                paramInfo.params.isEmpty
                            ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [CupertinoActivityIndicator()])
                            : AnimatedOpacity(
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
                Flexible(
                  flex: 0,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
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
  const _VerificationStatusMessage({required this.itemAlignment});

  final ItemAlignment itemAlignment;

  @override
  State<_VerificationStatusMessage> createState() => _VerificationStatusMessageState();
}

class _VerificationStatusMessageState extends State<_VerificationStatusMessage> with SingleTickerProviderStateMixin {
  final log = logging.child('VerificationStatusMessage');

  late ClaimCreationController controller;
  late VerificationController verificationController;
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

  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    controller = ClaimCreationController.readOf(context);
    verificationController = VerificationController.readOf(context);
    _controller = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  void _startLoadingTextsTimer() {
    final t = _loadingTextsTimer;
    if (t != null && t.isActive) return;

    _loadingTextsTimer = Timer.periodic(Duration(seconds: 3), _onTimerTick);
    Future.microtask(() {
      if (!mounted) return;

      _controller.reset();
      _controller.repeat();
    });
  }

  void _stopLoadingTextsTimer() {
    _controller.stop();
    _controller.reset();
    _loadingTextsTimer?.cancel();
    _loadingTextsTimer = null;
  }

  @override
  void dispose() {
    _controller.dispose();
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
  }

  final reviewSubtitleKey = GlobalKey(debugLabel: 'reviewSubtitleKey');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final value = controller.value;

    String subtitle;

    final canStartWebClient = verificationController.value.userScripts != null;

    bool isShowingLoadingText = false;

    if (value.hasError) {
      final providerErrorMessage = value.providerError?.message?.trim();
      subtitle =
          providerErrorMessage != null && providerErrorMessage.isNotEmpty
              ? providerErrorMessage
              : 'Something went wrong';
    } else if (value.isFinished) {
      subtitle = 'You are sharing';
    } else if (!canStartWebClient) {
      subtitle = 'Getting ready..';
    } else {
      isShowingLoadingText = true;

      _startLoadingTextsTimer();

      // page loading or proving or waiting for continuation
      subtitle = currentLoadingText;
    }

    if (!isShowingLoadingText) {
      _stopLoadingTextsTimer();
    }

    const int lines = 2;

    final primaryColor = Color(0xFF0000EE); // theme.colorScheme.primary;
    final secondaryColor = Color(0xFF0000EE).withValues(alpha: 0.4); // theme.colorScheme.secondary;

    return SizedBox(
      height: 18 * 1.3 * lines,
      child: AnimatedSwitcher(
        key: reviewSubtitleKey,
        duration: Durations.long2,
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: Column(
          key: ValueKey('key-review-subtitle-$subtitle'),
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: widget.itemAlignment.isStarting ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: Row(
                mainAxisAlignment: widget.itemAlignment.isStarting ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return ShaderMask(
                          shaderCallback: (bounds) {
                            final offset = _animation.value * 2;
                            return LinearGradient(
                              colors: [primaryColor, secondaryColor, primaryColor, primaryColor],
                              stops: [-1, -0.5, 0, 1].map((e) => e + offset).toList(),
                            ).createShader(bounds);
                          },
                          child: child,
                        );
                      },
                      child: Text(
                        subtitle,
                        textAlign: widget.itemAlignment.isStarting ? TextAlign.start : TextAlign.center,
                        style: theme.textTheme.titleMedium?.merge(
                          TextStyle(
                            fontWeight: FontWeight.w900,
                            color: value.hasError ? theme.colorScheme.error : const Color.fromARGB(221, 0, 10, 100),
                            fontSize: 18,
                            height: 1.2,
                            fontVariations: value.hasError ? [FontVariation.weight(600)] : null,
                          ),
                        ),
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
    );
  }
}

class _AppProviderIconsBar extends StatelessWidget {
  const _AppProviderIconsBar({
    super.key,
    required this.itemAlignment,
    required this.appInfo,
    required this.providerData,
    required this.hasVerifiedAtleastOneClaim,
  });

  final ItemAlignment itemAlignment;
  final AppInfo? appInfo;
  final HttpProvider? providerData;
  final bool hasVerifiedAtleastOneClaim;

  @override
  Widget build(BuildContext context) {
    final defaultIconSize = 30.0;

    final double logoSize = 60.0;
    final verifiedTickAdjustment = 6.0;

    final appImage = appInfo?.appImage;
    final providerData = this.providerData;

    final applicationIcon = InkWell(
      onDoubleTap: () {
        VerificationReviewController.readOf(context).setIsVisible(false);
      },
      borderRadius: _borderRadius,
      child: AnimatedSwitcher(
        duration: Durations.medium1,
        child:
            appImage != null && appImage.isNotEmpty
                ? LogoIcon(logoUrl: appImage, size: logoSize, borderRadius: _borderRadius)
                : SimpleShimmer(height: logoSize, width: logoSize),
      ),
    );

    final isStartAligned = itemAlignment.isStarting;

    final movementTransitionDuration = Durations.medium1;
    final maxWidth = (logoSize * 2) + defaultIconSize + (verifiedTickAdjustment * (isStartAligned ? 1 : 2));

    return Row(
      mainAxisAlignment: isStartAligned ? MainAxisAlignment.start : MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: logoSize + verifiedTickAdjustment, maxWidth: maxWidth),
          child: Stack(
            alignment: AlignmentDirectional.center,
            fit: StackFit.expand,
            children: [
              AnimatedPositioned(
                top: verifiedTickAdjustment,
                right:
                    providerData == null
                        ? (isStartAligned ? maxWidth - logoSize : ((maxWidth / 2) - (logoSize / 2)))
                        : verifiedTickAdjustment,
                height: logoSize,
                width: logoSize,
                curve: Curves.fastEaseInToSlowEaseOut,
                duration: movementTransitionDuration,
                child: applicationIcon,
              ),
              AnimatedPositioned(
                top: 6,
                left: isStartAligned ? 0 : verifiedTickAdjustment,
                height: logoSize,
                width: logoSize + defaultIconSize,
                curve: Curves.easeIn,
                duration: movementTransitionDuration,
                child: AnimatedSwitcher(
                  duration: movementTransitionDuration,
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  child:
                      providerData == null
                          ? SizedBox(height: logoSize)
                          : Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Tooltip(
                                message: providerData.name ?? 'Provider',
                                child: LogoIcon(
                                  logoUrl: providerData.logoUrl,
                                  size: logoSize,
                                  borderRadius: _borderRadius,
                                ),
                              ),
                              Icon(Icons.arrow_forward_rounded, color: Colors.black, size: defaultIconSize),
                            ],
                          ),
                ),
              ),
              AnimatedAlign(
                alignment: AlignmentDirectional.topEnd,
                curve: Curves.easeIn,
                duration: movementTransitionDuration,
                child: AnimatedOpacity(
                  opacity: hasVerifiedAtleastOneClaim ? 1 : 0,
                  duration: Durations.medium1,
                  child: VerifiedIcon(),
                ),
              ),
            ],
          ),
        ),
      ],
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
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: 'By continuing, you agree to these '),
            TextSpan(
              text: 'Terms of Service',
              recognizer: TapGestureRecognizer()..onTap = () => _onTermsOfUsePressed(context, TermsType.termsOfService),
              style: TextStyle(color: Colors.indigo, decoration: TextDecoration.underline),
            ),
            TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              recognizer: TapGestureRecognizer()..onTap = () => _onTermsOfUsePressed(context, TermsType.privacyPolicy),
              style: TextStyle(color: Colors.indigo, decoration: TextDecoration.underline),
            ),
          ],
        ),
        textAlign: isLargeScreen ? TextAlign.center : TextAlign.start,
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
              return SizedBox(height: 100, child: _ErrorWidget());
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
            isVisible: !isSubmitted && !widget.hasError,
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
        children: [Flexible(child: DataSharedCheckAnimatedIcon(key: tickKey, height: widget.height))],
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
    final providerError = controller.value.providerError;

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
            if (providerError == null)
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
                    options?.onException(providerError);
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
      ],
    );
  }
}
