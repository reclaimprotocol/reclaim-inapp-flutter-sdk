import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reclaim_flutter_sdk/logging/logging.dart';
import 'package:reclaim_flutter_sdk/types/create_claim.dart';
import 'package:reclaim_flutter_sdk/widgets/action_button.dart';
import 'package:reclaim_flutter_sdk/widgets/changing_tile.dart';
import 'package:reclaim_flutter_sdk/widgets/claim_creation/claim_creation.dart';
import 'package:reclaim_flutter_sdk/widgets/animated_icon/check.dart';
import 'package:reclaim_flutter_sdk/widgets/params/params_text.dart';
import 'package:reclaim_flutter_sdk/widgets/reclaim_theme_provider.dart';
import 'package:reclaim_flutter_sdk/widgets/resize_observer.dart';
import 'package:reclaim_flutter_sdk/widgets/webview_bottom.dart';
import 'package:reclaim_flutter_sdk/types/app_info.dart';

import '../animated_progress.dart';
import '../icon.dart';

// Same as [ExpansionTile]'s default duration
const _animationDuration = Durations.short3;
const _animationInCurve = Curves.easeIn;
const _animationOutCurve = Curves.easeOut;

class ClaimCreationBottomSheet extends StatelessWidget {
  const ClaimCreationBottomSheet({super.key});

  static Future<void> open(
    BuildContext context, {
    required ClaimCreationController claimCreationController,
    required ClaimCreationUIDelegateOptions options,
  }) async {
    if (!context.mounted) return;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      constraints: BoxConstraints(),
      builder: (buildContext) {
        return ReclaimThemeProvider(
          child: ClaimCreationUIDelegateInheritedWidget(
            options: options,
            child: ClaimCreationControllerProvider(
              controller: claimCreationController,
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ClaimCreationBottomSheet(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ClaimCreationController.of(context);

    final value = controller.value;

    Widget child;
    if (value.hasError) {
      child = const _ErrorWidget();
    } else if (value.isFinished) {
      child = const _SuccessView();
    } else if (value.isWaitingForContinuation) {
      child = const _WaitingForContinuationWidget();
    } else {
      return const _LoadingView();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInCubic,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey,
                    boxShadow:
                        kElevationToShadow[12]?.map((e) {
                          return e.copyWith(color: Colors.grey.withValues(alpha: 0.1));
                        }).toList(),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.98),
                      borderRadius: BorderRadius.circular(13),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingView extends StatefulWidget {
  const _LoadingView();

  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView> {
  static Size? _cachedSize;

  static double getEstimateHeight() {
    return _cachedSize?.height ?? 78.0;
  }

  bool _isExpanded = false;

  void toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ClaimCreationController.of(context);
    final progress = controller.value.progress;

    final params = ParamInfo.fromBuildContext(context);
    final uniqueParamsCount = params.uniqueParamsCount;

    final bool isExpandable = uniqueParamsCount > 1;
    final bool isExpanded = _isExpanded && isExpandable;

    final Iterable<Widget> paramTiles = ParamsText.buildTiles(
      context,
      params,
      onlyShowPublicAndInProgressParams: !isExpanded,
    );

    late final changingParamTileBuilder = ChangingTileBuilder(
      length: paramTiles.length,
      builder: (context, index) {
        return paramTiles.elementAt(index);
      },
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: AnimatedCardProgressIndicator(
                  progress: progress,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.98),
                      borderRadius: BorderRadius.circular(13),
                      child: InkWell(
                        onTap: isExpandable ? toggleExpanded : null,
                        borderRadius: BorderRadius.circular(13),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: AnimatedSize(
                            duration: _animationDuration,
                            alignment: Alignment.center,
                            curve: _animationInCurve,
                            child: ResizeObserver(
                              onResized: (oldSize, newSize) {
                                _cachedSize = newSize;
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      top: 10.0,
                                      start: 14.0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'VERIFYING',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.1,
                                          ),
                                          textAlign: TextAlign.start,
                                        ),
                                        Flexible(
                                          child: WebviewBottomBar(
                                            // TODO: Include sessionId in controller value
                                            sessionId:
                                                controller
                                                    .value
                                                    .claims
                                                    .firstOrNull
                                                    ?.request
                                                    .sessionId ??
                                                '',
                                            padding: EdgeInsetsDirectional.only(
                                              end: 12,
                                            ),
                                            mainAxisSize: MainAxisSize.min,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 12.0,
                                    ),
                                    child: () {
                                      if (!isExpandable || paramTiles.isEmpty) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            // match the height & position with the widgets that are shown when isExpanded is true
                                            top: 4.0,
                                          ),
                                          child: ParamsText.fromTiles(
                                            padding: EdgeInsets.zero,
                                            tiles: paramTiles,
                                          ),
                                        );
                                      }

                                      return Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: AnimatedCrossFade(
                                              crossFadeState:
                                                  isExpanded
                                                      ? CrossFadeState.showSecond
                                                      : CrossFadeState.showFirst,
                                              duration: _animationDuration,
                                              firstCurve: _animationInCurve,
                                              secondCurve: _animationOutCurve,
                                              firstChild: changingParamTileBuilder,
                                              secondChild: ParamsText.fromTiles(
                                                padding: EdgeInsets.zero,
                                                tiles: paramTiles,
                                              ),
                                            ),
                                          ),
                                          AnimatedCrossFade(
                                            crossFadeState:
                                                isExpanded
                                                    ? CrossFadeState.showSecond
                                                    : CrossFadeState.showFirst,
                                            duration: _animationDuration,
                                            firstCurve: _animationInCurve,
                                            secondCurve: _animationOutCurve,
                                            firstChild: Icon(
                                              Icons.arrow_drop_down_rounded,
                                            ),
                                            secondChild: Icon(
                                              Icons.arrow_drop_up_rounded,
                                            ),
                                          ),
                                        ],
                                      );
                                    }(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WaitingForContinuationWidget extends StatefulWidget {
  const _WaitingForContinuationWidget();

  @override
  State<_WaitingForContinuationWidget> createState() =>
      _WaitingForContinuationWidgetState();
}

class _WaitingForContinuationWidgetState
    extends State<_WaitingForContinuationWidget> {
  late ClaimCreationController controller;

  @override
  void initState() {
    super.initState();
    controller = ClaimCreationController.of(context, listen: false);
    Future.delayed(
      // wait for a few moments before automatically continuing to capture any claim triggers on this same page
      const Duration(milliseconds: 1400),
      _onContinueAutomatically,
    );
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      if (!_hasClaimWaitDurationElapsed && !_hasContinued) {
        // let the user see the continue button when no claim was triggered in the last few moments
        // and when the user has not pressed continue button
        setState(() {
          _hasClaimWaitDurationElapsed = true;
        });
      }
    });
  }

  // We wait for a few moments for a claim to get triggered on the same page before showing the continue button
  bool _hasClaimWaitDurationElapsed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller = ClaimCreationController.of(context);
  }

  bool _hasContinued = false;

  void _onContinueAutomatically() {
    if (!mounted) return;

    final options = ClaimCreationUIDelegateOptions.of(context, listen: false);

    final nextLocation = controller.getNextLocation();
    if (nextLocation == null) {
      // do nothing
      return;
    }

    _hasContinued = true;

    options?.onContinue(nextLocation);

    Navigator.of(context).pop();
  }

  void _onContinue() {
    _hasContinued = true;

    if (!mounted) return;

    // Hides the bottom sheet to let the user navigate to a different screen manually when
    // no claim were triggered within the waiting duration
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final nextLocation = controller.getNextLocation();

    if (nextLocation == null && _hasClaimWaitDurationElapsed) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;

      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _VerificationCardContent(title: 'Continue Verification'),
          const SizedBox(height: 16.0),
          ActionButton(
            onPressed: _onContinue,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text('Continue'),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.redo_rounded,
                      size: 16.0,
                      color: colorScheme.onPrimary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          WebviewBottomBar(
            sessionId:
                controller.value.claims.firstOrNull?.request.sessionId ?? '',
          ),
        ],
      );
    }

    final double height = _LoadingViewState.getEstimateHeight();

    return ConstrainedBox(
      constraints: BoxConstraints.tightFor(height: height),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              'Continuing verification..',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                height: 1.2,
                color: Color(0xFF1D2126),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            // dimension / 1.6
            padding: EdgeInsetsDirectional.only(start: 9.4),
            child: SizedBox.square(
              // fontSize / text span height
              dimension: 15,
              child: CircularProgressIndicator(
                color: Color(0xFF1D2126),
                strokeCap: StrokeCap.round,
                strokeWidth: 2.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatefulWidget {
  const _SuccessView();

  @override
  State<_SuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends State<_SuccessView> {
  late ClaimCreationController controller;
  late ClaimCreationUIDelegateOptions? options;

  bool get isAutoSubmitEnabled => options?.autoSubmit == true;

  @override
  void initState() {
    super.initState();
    controller = ClaimCreationController.of(context, listen: false);
    options = ClaimCreationUIDelegateOptions.of(context, listen: false);
    if (isAutoSubmitEnabled) {
      _onShared();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller = ClaimCreationController.of(context);
    options = ClaimCreationUIDelegateOptions.of(context);
  }

  CrossFadeState _pageState = CrossFadeState.showFirst;

  /// This only animates the widget to [_DataSharedView] and pops this bottom sheet. Proof is actually
  /// returned from [ClaimCreationController.startClaimCreation] after [ClaimCreationBottomSheet] bottom sheet is closed.
  void _onShared() async {
    logging
        .child('ClaimCreationBottomSheetState._onShared')
        .finest('sharing proof');

    // show next page after sharing proof
    setState(() {
      _pageState = CrossFadeState.showSecond;
    });
    // autohide bottom sheet after 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    // don't pop if widget already disposed (maybe user swiped down to close bottom sheet)
    if (!mounted) return;
    Navigator.of(context).pop();
    final maybeProofs = controller.value.claims.map((e) => e.proofs);
    final proofs = maybeProofs.whereType<List<CreateClaimOutput>>();

    assert(proofs.isNotEmpty && proofs.length == maybeProofs.length);
    options?.onSubmitProofs(proofs.expand((e) => e).toList());
  }

  final submitViewKey = GlobalKey();

  double get submitViewHeight {
    if (isAutoSubmitEnabled) {
      return _LoadingViewState.getEstimateHeight();
    }
    final submitView = submitViewKey.currentContext?.findRenderObject();
    if (submitView is RenderBox) {
      final height = submitView.size.height;
      return height;
    }
    return 187.0;
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitted = _pageState == CrossFadeState.showSecond;
    return AnimatedCrossFade(
      key: const ValueKey('ClaimSuccessView'),
      duration: const Duration(milliseconds: 300),
      crossFadeState: _pageState,
      firstCurve: Curves.easeIn,
      sizeCurve: Curves.easeIn,
      firstChild: _SubmitWidget(
        key: submitViewKey,
        onShareButtonPress: _onShared,
        sessionId: controller.value.claims.firstOrNull?.request.sessionId ?? '',
      ),
      secondChild: _DataSharedView(height: submitViewHeight, play: isSubmitted),
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
  final tickKey = GlobalKey<DataSharedCheckAnimatedIconState>();

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
            child: DataSharedCheckAnimatedIcon(
              key: tickKey,
              height: widget.height,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitWidget extends StatelessWidget {
  final VoidCallback onShareButtonPress;
  final String sessionId;

  const _SubmitWidget({
    super.key,
    required this.onShareButtonPress,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _VerificationCardContent(title: 'You are sharing'),
        const SizedBox(height: 16.0),
        ActionButton(
          onPressed: onShareButtonPress,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Text('Submit'),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.arrow_forward_ios_sharp,
                    size: 16.0,
                    color: colorScheme.onPrimary,
                  ),
                ],
              ),
            ],
          ),
        ),
        WebviewBottomBar(sessionId: sessionId),
      ],
    );
  }
}

class _VerificationCardContent extends StatelessWidget {
  const _VerificationCardContent({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final controller = ClaimCreationController.of(context);
    final providerData = controller.value.httpProvider;
    final hasVerifiedAtleastOneClaim =
        controller.value.hasVerifiedAtleastOneClaim;

    const double logoSize = 40.0;
    const borderRadius = BorderRadius.all(Radius.circular(12));

    final appProviderIcons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: AlignmentDirectional.topEnd,
          fit: StackFit.passthrough,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 6.0,
                vertical: 6.0,
              ),
              child: Row(
                children: [
                  Builder(
                    builder: (context) {
                      final options = ClaimCreationUIDelegateOptions.of(
                        context,
                      );
                      if (options == null) return const SizedBox();
                      return FutureBuilder(
                        future: AppInfo.fromAppId(options.appId),
                        builder: (context, snapshot) {
                          final appImage = snapshot.data?.appImage;
                          if (appImage == null || appImage.isEmpty) {
                            return SizedBox();
                          }
                          return Padding(
                            padding: const EdgeInsetsDirectional.only(end: 1.0),
                            child: LogoIcon(
                              logoUrl: appImage,
                              size: logoSize,
                              borderRadius: borderRadius,
                            ),
                          );
                        },
                      );
                    },
                  ),
                  Tooltip(
                    message: providerData.name ?? 'Provider',
                    child: LogoIcon(
                      logoUrl: providerData.logoUrl,
                      size: logoSize,
                      borderRadius: borderRadius,
                    ),
                  ),
                ],
              ),
            ),
            if (hasVerifiedAtleastOneClaim) VerifiedIcon(),
          ],
        ),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.merge(
                TextStyle(
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                  color: Color(0xFF0000EE),
                ),
              ),
            ),
            appProviderIcons,
          ],
        ),
        _ParamsView(),
      ],
    );
  }
}

class _ParamsView extends StatelessWidget {
  const _ParamsView();

  @override
  Widget build(BuildContext context) {
    return ParamsText.fromParamInfo(
      info: ParamInfo.fromBuildContext(context),
      padding: EdgeInsets.zero,
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget();

  @override
  Widget build(BuildContext context) {
    final controller = ClaimCreationController.of(context);
    final sessionId =
        controller.value.claims.firstOrNull?.request.sessionId ?? '';
    final providerError = controller.value.providerError;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 5.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              Icons.error_rounded,
              color: colorScheme.error,
              size: 70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            providerError?.message ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 1.2,
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (providerError == null)
                Expanded(
                  child: ActionButton(
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
                          children: [
                            Icon(
                              Icons.replay_rounded,
                              size: 16.0,
                              color: colorScheme.onPrimary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ActionButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      final options = ClaimCreationUIDelegateOptions.of(
                        context,
                        listen: false,
                      );
                      options?.onException(providerError);
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(MaterialLocalizations.of(context).okButtonLabel),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.keyboard_return_rounded,
                              size: 16.0,
                              color: colorScheme.onPrimary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          WebviewBottomBar(sessionId: sessionId),
        ],
      ),
    );
  }
}

typedef StepProgress = ({int completed, int total, num approxTimeLeftSeconds});
