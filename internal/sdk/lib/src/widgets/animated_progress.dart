import 'package:flutter/material.dart';
import '../theme/theme.dart';

class AnimatedLinearProgressIndicator extends StatefulWidget {
  const AnimatedLinearProgressIndicator({
    super.key,
    this.backgroundColor,
    this.progress,
    this.minHeight,
    this.valueColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.indeterminateProgress = false,
  });

  final Color? backgroundColor;
  final double? progress;
  final Color? valueColor;
  final double? minHeight;
  final BorderRadiusGeometry borderRadius;
  final bool indeterminateProgress;

  @override
  State<AnimatedLinearProgressIndicator> createState() => _AnimatedLinearProgressIndicatorState();
}

class _AnimatedLinearProgressIndicatorState extends State<AnimatedLinearProgressIndicator> {
  late double? lastProgress = widget.progress;
  late Tween<double> progressIndicatorTween = Tween(begin: 0, end: widget.progress ?? 0);

  void _updateProgressAnimation(double? newProgress) {
    if (newProgress == null) {
      setState(() {
        lastProgress = null;
      });
      return;
    }
    setState(() {
      progressIndicatorTween = Tween<double>(begin: lastProgress ?? 0, end: newProgress);
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
    final effectiveValueColor = widget.valueColor ?? ReclaimTheme.of(context).primary;
    final valueColor = AlwaysStoppedAnimation<Color>(effectiveValueColor);
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
          value: widget.indeterminateProgress ? null : value,
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
    this.valueColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.showProgress = true,
    required this.child,
  });

  final Color? backgroundColor;
  final double? progress;
  final Color? valueColor;
  final BorderRadius borderRadius;
  final bool showProgress;
  final Widget child;

  @override
  State<AnimatedCardProgressIndicator> createState() => _AnimatedCardProgressIndicatorState();
}

class _AnimatedCardProgressIndicatorState extends State<AnimatedCardProgressIndicator> {
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
      progressIndicatorTween = Tween<double>(begin: lastProgress ?? 0, end: newProgress);
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

    final effectiveValueColor = widget.valueColor ?? ReclaimTheme.of(context).primary;
    final shadowColor = effectiveValueColor.withValues(alpha: 0.1);

    return TweenAnimationBuilder<double>(
      duration: Durations.short4,
      curve: Curves.easeInOut,
      tween: progressIndicatorTween,
      builder: (context, value, _) {
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: widget.showProgress ? null : backgroundColor,
            gradient:
                widget.showProgress
                    ? LinearGradient(
                      colors: [effectiveValueColor, backgroundColor, backgroundColor],
                      stops: [value, value + 0.05, 1],
                    )
                    : null,
            boxShadow:
                kElevationToShadow[9]?.map((e) {
                  return e.copyWith(color: shadowColor);
                }).toList(),
          ),
          child: widget.child,
        );
      },
    );
  }
}
