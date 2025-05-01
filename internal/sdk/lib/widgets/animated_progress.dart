import 'package:flutter/material.dart';
import 'package:reclaim_flutter_sdk/constants.dart';

class AnimatedLinearProgressIndicator extends StatefulWidget {
  const AnimatedLinearProgressIndicator({
    super.key,
    this.backgroundColor,
    this.progress,
    this.minHeight,
    this.valueColor = ReclaimTheme.primary,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });

  final Color? backgroundColor;
  final double? progress;
  final Color valueColor;
  final double? minHeight;
  final BorderRadius borderRadius;

  @override
  State<AnimatedLinearProgressIndicator> createState() =>
      _AnimatedLinearProgressIndicatorState();
}

class _AnimatedLinearProgressIndicatorState
    extends State<AnimatedLinearProgressIndicator> {
  late double? lastProgress = widget.progress;
  Tween<double> progressIndicatorTween = Tween(begin: 0, end: 0);

  void _updateProgressAnimation(double? newProgress) {
    if (newProgress == null) {
      setState(() {
        lastProgress = null;
      });
      return;
    }
    setState(() {
      progressIndicatorTween = Tween<double>(
        begin: lastProgress ?? 0,
        end: newProgress,
      );
    });
    lastProgress = newProgress;
  }

  void _onStepProgress() {
    _updateProgressAnimation(widget.progress);
  }

  @override
  void didUpdateWidget(covariant AnimatedLinearProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      _onStepProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? const Color(0xFFF2F2F7);
    final valueColor = AlwaysStoppedAnimation<Color>(widget.valueColor);
    final minHeight = widget.minHeight ?? 6.0;
    final borderRadius = widget.borderRadius;

    if (lastProgress == null) {
      return LinearProgressIndicator(
        backgroundColor: backgroundColor,
        valueColor: valueColor,
        minHeight: minHeight,
        borderRadius: borderRadius,
      );
    }
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      tween: progressIndicatorTween,
      builder: (context, value, _) {
        return LinearProgressIndicator(
          value: value,
          backgroundColor: backgroundColor,
          valueColor: valueColor,
          minHeight: minHeight,
          borderRadius: borderRadius,
        );
      },
    );
  }
}

class AnimatedCardProgressIndicator extends StatefulWidget {
  const AnimatedCardProgressIndicator({
    super.key,
    this.backgroundColor,
    this.progress,
    this.valueColor = ReclaimTheme.primary,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    required this.child,
  });

  final Color? backgroundColor;
  final double? progress;
  final Color valueColor;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  State<AnimatedCardProgressIndicator> createState() =>
      _AnimatedCardProgressIndicatorState();
}

class _AnimatedCardProgressIndicatorState
    extends State<AnimatedCardProgressIndicator> {
  late double? lastProgress = widget.progress;
  Tween<double> progressIndicatorTween = Tween(begin: 0, end: 0);

  void _updateProgressAnimation(double? newProgress) {
    if (newProgress == null) {
      setState(() {
        lastProgress = null;
      });
      return;
    }
    setState(() {
      progressIndicatorTween = Tween<double>(
        begin: lastProgress ?? 0,
        end: newProgress,
      );
    });
    lastProgress = newProgress;
  }

  void _onStepProgress() {
    _updateProgressAnimation(widget.progress);
  }

  @override
  void didUpdateWidget(covariant AnimatedCardProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      _onStepProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? const Color(0xFFF2F2F7);
    final borderRadius = widget.borderRadius;

    if (lastProgress == null) {
      return widget.child;
    }
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      tween: progressIndicatorTween,
      builder: (context, value, _) {
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              colors: [widget.valueColor, backgroundColor, backgroundColor],
              stops: [value, value + 0.05, 1],
            ),
            boxShadow: kElevationToShadow[12]?.map((e) {
              return e.copyWith(
                color: widget.valueColor.withValues(alpha: 0.1),
              );
            }).toList(),
          ),
          child: widget.child,
        );
      },
    );
  }
}
