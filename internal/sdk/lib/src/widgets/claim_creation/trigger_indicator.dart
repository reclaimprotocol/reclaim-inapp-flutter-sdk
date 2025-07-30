import 'dart:async';

import 'package:flutter/material.dart';

import '../animated_progress.dart';
import '../verification_review/controller.dart';
import 'claim_creation.dart';

enum ClaimTriggerType {
  // primary colored indicator to indicate that the claim creation is triggered.
  claim,
  // yellow colored indicator to indicate that something (for ex. AI) is in proces.
  processing,
  // error colored indicator to indicate that the claim creation failed.
  error,
  // none to indicate that the indicator is not visible.
  none,
}

// Note: Use [ActionBarMessenger] instead of this class for showing indicator in the UI.
class ClaimTriggerIndicatorController extends ValueNotifier<ClaimTriggerType> {
  ClaimTriggerIndicatorController() : super(ClaimTriggerType.none);

  @protected
  @override
  set value(ClaimTriggerType value) {
    if (_isDisposed) {
      return;
    }
    super.value = value;
  }

  void notifyClaim() {
    value = ClaimTriggerType.claim;
  }

  void notifyProcessing() {
    value = ClaimTriggerType.processing;
  }

  Timer? _removeIndicatorTimer;

  void _scheduleRemoveIndicator(Duration removeAfter) {
    _removeIndicatorTimer?.cancel();
    _removeIndicatorTimer = Timer(removeAfter, () {
      // don't use remove because it will do nothing when current value is `error`.
      if (value == ClaimTriggerType.error) {
        value = ClaimTriggerType.none;
      }
    });
  }

  void notifyError([Duration removeAfter = const Duration(seconds: 5)]) {
    value = ClaimTriggerType.error;
    _scheduleRemoveIndicator(removeAfter);
  }

  void remove([bool keepError = true]) {
    if (keepError) {
      // ignore errors, they will be discarded by the timer.
      if (value == ClaimTriggerType.error) return;
    } else {
      _removeIndicatorTimer?.cancel();
    }
    value = ClaimTriggerType.none;
  }

  Widget wrap({required Widget child}) {
    return _Provider(notifier: this, child: child);
  }

  static ClaimTriggerIndicatorController readOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_Provider>()!.notifier!;
  }

  static ClaimTriggerIndicatorController of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_Provider>()!.notifier!;
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

class _Provider extends InheritedNotifier<ClaimTriggerIndicatorController> {
  const _Provider({required super.child, required ClaimTriggerIndicatorController super.notifier});

  @override
  bool updateShouldNotify(covariant _Provider oldWidget) {
    return oldWidget.notifier?.value != notifier?.value;
  }
}

class ClaimTriggerIndicator extends StatelessWidget {
  const ClaimTriggerIndicator({
    super.key,
    required this.color,
    this.emphasise = false,
    this.progress,
    this.padding,
    this.thickness = 6,
  });

  final Color color;
  // When true, progress starts from middle and then completes with an animation in 250 milliseconds.
  // Shows indeterminate progress when false.
  final bool emphasise;
  final double? progress;
  final EdgeInsetsGeometry? padding;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    final mediaQuerySize = MediaQuery.sizeOf(context).width;
    final horizontalPadding = mediaQuerySize * 0.2;

    Widget child;
    if (progress != null) {
      child = Stack(
        fit: StackFit.passthrough,
        children: [
          AnimatedLinearProgressIndicator(
            progress: progress,
            backgroundColor: Colors.transparent,
            minHeight: thickness,
            valueColor: color,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          AnimatedLinearProgressIndicator(
            indeterminateProgress: true,
            backgroundColor: Colors.transparent,
            minHeight: thickness,
            valueColor: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ],
      );
    } else {
      final double? effectiveProgress = emphasise ? 1.0 : null;
      final indicator = AnimatedLinearProgressIndicator(
        indeterminateProgress: !emphasise,
        progress: effectiveProgress,
        backgroundColor: Colors.transparent,
        minHeight: (thickness - 2).clamp(1, 10),
        valueColor: color,
        borderRadius: BorderRadiusDirectional.only(topStart: Radius.circular(16), bottomStart: Radius.circular(16)),
      );
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: indicator),
          Expanded(child: Transform.flip(flipX: true, child: indicator)),
        ],
      );
    }

    return Padding(
      padding: padding ?? EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: child,
    );
  }
}

class ClaimCreationIndicatorOverlay extends StatelessWidget {
  const ClaimCreationIndicatorOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [AnimatedSwitcher(duration: Durations.medium1, child: const ClaimCreationIndicator())],
    );
  }
}

class ClaimCreationIndicator extends StatelessWidget {
  const ClaimCreationIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final controller = ClaimTriggerIndicatorController.of(context);
    final indicationType = controller.value;

    Widget indicator;
    final isVisible = VerificationReviewController.of(context).value.isVisible;
    if (isVisible && indicationType != ClaimTriggerType.error) {
      final value = ClaimCreationController.of(context).value;
      if (value.isFinished || value.httpProvider == null) {
        indicator = SizedBox();
      } else {
        indicator = ClaimTriggerIndicator(
          key: ValueKey('iw-progress-indicator'),
          color: colorScheme.primary,
          progress: value.progress,
        );
      }
      // show progress
    } else {
      switch (indicationType) {
        case ClaimTriggerType.claim:
          indicator = ClaimTriggerIndicator(key: ValueKey('iw-claim-indicator'), color: colorScheme.primary);
        case ClaimTriggerType.processing:
          indicator = ClaimTriggerIndicator(key: ValueKey('iw-processing-indicator'), color: Color(0xffffc636));
        case ClaimTriggerType.error:
          indicator = ClaimTriggerIndicator(
            key: ValueKey('iw-error-indicator'),
            color: colorScheme.error,
            emphasise: true,
          );
        case ClaimTriggerType.none:
          indicator = SizedBox();
      }
    }
    return indicator;
  }
}
