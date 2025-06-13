import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mesh/mesh.dart';

import '../../utils/observable_notifier.dart';
import '../claim_creation/claim_creation.dart';

/// A background that has an animating mesh gradient that changes based on the claim creation state.
class LiveBackground extends StatefulWidget {
  const LiveBackground({super.key, required this.child});
  final Widget child;

  @override
  State<LiveBackground> createState() => _LiveBackgroundState();
}

extension on OVertex {
  OVertex to(OVertex b, double t) => lerpTo(b, t);
}

extension on Color? {
  Color? to(Color? b, double t) => Color.lerp(this, b, t);
}

typedef C = Colors;

class _LiveBackgroundState extends State<LiveBackground> with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late ClaimCreationController claimCreationController;
  late final StreamSubscription claimCreationChangesSubscription;

  static const _progressingStartValue = 0.6;
  static const _notProgressingEndValue = 0.4;

  late final Stream<bool> claimCreationHasErrorStream;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: Duration(seconds: 5));
    controller.addListener(_onAnimationChanged);
    claimCreationController = ClaimCreationController.of(context, listen: false);
    // To prevent initial jank when verification view opens up
    Future.delayed(Durations.medium3, _afterInitDelay);
    claimCreationChangesSubscription = claimCreationController.changesStream.listen(_onClaimCreationChanges);
    claimCreationHasErrorStream = claimCreationController.changesStream.map((changes) {
      return changes.value.hasError;
    });
  }

  bool _canStartAnimating = false;

  void _afterInitDelay() {
    setState(() {
      _canStartAnimating = true;
    });
    _onAnimationChanged();
  }

  void _onAnimationChanged() {
    if (!mounted) return;
    final animationValue = controller.value;
    final claimCreationState = claimCreationController.value;
    final isProgressing = claimCreationState.inProgressOrCompleted && !claimCreationState.hasError;
    final startingValue = isProgressing ? _progressingStartValue : 0.0;
    final endingValue = isProgressing ? 1.0 : _notProgressingEndValue;

    if (animationValue == endingValue) {
      _animateTo(forward: false, start: startingValue);
    } else if (animationValue == startingValue) {
      _animateTo(forward: true, end: endingValue);
    }
  }

  void _onClaimCreationChanges(ChangedValues<ClaimCreationControllerState> changes) {
    if (!_canStartAnimating) return;

    final (oldValue, value) = changes.record;

    final wasProgressing = (oldValue != null && oldValue.inProgressOrCompleted && !oldValue.hasError);
    final isProgressing = (value.inProgressOrCompleted && !value.hasError);
    if (wasProgressing != isProgressing) {
      if (isProgressing) {
        _animateTo(forward: true);
      } else {
        _animateTo(forward: false);
      }
    }
  }

  void _animateTo({required bool forward, double start = 0.0, double end = 1.0}) {
    if (forward) {
      controller.animateTo(end, curve: Curves.easeInOutCubic);
    } else {
      controller.animateTo(start, curve: Curves.easeInOutQuint);
    }
  }

  @override
  dispose() {
    claimCreationChangesSubscription.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    late final meshAnimationBuilder = AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final dt = controller.value;
        return StreamBuilder(
          stream: claimCreationHasErrorStream,
          builder: (context, asyncSnapshot) {
            final hasError = asyncSnapshot.data ?? false;
            return OMeshGradient(
              tessellation: 6,
              size: Size.infinite,
              mesh: OMeshRect(
                width: 3,
                height: 4,
                // We have some different color spaces available
                colorSpace: OMeshColorSpace.lab,
                fallbackColor: C.transparent,
                vertices: [
                  (0.0, 0.3).v.to((0.0, 0.0).v, dt),
                  (0.5, 0.15).v.to((0.5, 0.1).v, dt * dt),
                  (1.0, -0.1).v.to((1.0, 0.3).v, dt * dt), //

                  (-0.05, 0.68).v.to((0.0, 0.45).v, dt),
                  (0.63, 0.3).v.to((0.48, 0.54).v, dt),
                  (1.0, 0.1).v.to((1.0, 0.6).v, dt), //

                  (-0.2, 0.92).v.to((0.0, 0.58).v, dt),
                  (0.32, 0.72).v.to((0.58, 0.69).v, dt * dt),
                  (1.0, 0.3).v.to((1.0, 0.8).v, dt), //

                  (0.0, 1.2).v.to((0.0, 0.86).v, dt),
                  (0.5, 0.88).v.to((0.5, 0.95).v, dt),
                  (1.0, 0.82).v.to((1.0, 1.0).v, dt), //
                ],
                colors:
                    [
                      null, null, null, //

                      if (hasError) ...[
                        C.red[500]
                            ?.withAlpha((255 * 0.8).floor())
                            .to(theme.colorScheme.primary.withValues(alpha: 0.5), dt),
                        C.red[200]
                            ?.withAlpha((255 * 0.8).floor())
                            .to(theme.colorScheme.primary.withValues(alpha: 0.2), dt),
                        C.red[400]
                            ?.withAlpha((255 * 0.9).floor())
                            .to(theme.colorScheme.primary.withValues(alpha: 0.4), dt),
                      ] else ...[
                        C.yellow[500]
                            ?.withAlpha((255 * 0.8).floor())
                            .to(theme.colorScheme.primary.withValues(alpha: 0.5), dt),
                        C.yellow[200]
                            ?.withAlpha((255 * 0.8).floor())
                            .to(theme.colorScheme.primary.withValues(alpha: 0.2), dt),
                        C.yellow[400]
                            ?.withAlpha((255 * 0.9).floor())
                            .to(theme.colorScheme.primary.withValues(alpha: 0.4), dt),
                      ], //

                      C.red[900].to(theme.colorScheme.primary.withValues(alpha: 0.9), dt),
                      C.red[800]
                          ?.withAlpha((255 * 0.4).floor())
                          .to(theme.colorScheme.primary.withValues(alpha: 0.8), dt),
                      C.red[900].to(theme.colorScheme.primary.withValues(alpha: 0.9), dt), //

                      null, null, null, //
                    ].map((e) => e?.withValues(alpha: e.a * 0.35)).toList(),
              ),
            );
          },
        );
      },
    );

    return Stack(
      children: [
        AnimatedSwitcher(
          duration: Durations.extralong3,
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          child: !_canStartAnimating ? const SizedBox.expand() : meshAnimationBuilder,
        ),
        widget.child,
      ],
    );
  }
}
