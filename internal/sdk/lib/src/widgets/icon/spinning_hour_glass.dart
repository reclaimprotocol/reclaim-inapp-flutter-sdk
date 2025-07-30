import 'dart:async';

import 'package:flutter/material.dart';

// Custom Curve Implementation from above
class SplitCubicCurve extends Curve {
  const SplitCubicCurve();

  @override
  double transformInternal(double t) {
    if (t < 0.5) {
      return Curves.easeInOutCubic.transform(t * 2.0) * 0.5;
    } else {
      return 0.5 + Curves.easeInOutCubic.transform((t - 0.5) * 2.0) * 0.5;
    }
  }
}

class SpinningHourglass extends StatefulWidget {
  final double? size;
  final Color? color;

  const SpinningHourglass({
    super.key,
    this.size, // Default icon size
    this.color,
  });

  @override
  State<SpinningHourglass> createState() => _SpinningHourglassState();
}

class _SpinningHourglassState extends State<SpinningHourglass> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);

    // Apply a non-linear curve to the animation for a more dynamic feel.
    _animation = CurvedAnimation(parent: _controller, curve: const SplitCubicCurve());

    // Add a listener to control the animation sequence.
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // When the 180-degree flip is done, wait for a moment.
        Timer(const Duration(milliseconds: 800), () {
          if (mounted) {
            if (_controller.value == 1) {
              _controller.reset();
              _controller.animateTo(0.5);
            } else {
              _controller.animateTo(1);
            }
          }
        });
      }
    });

    // Start the first animation cycle.
    _controller.animateTo(0.5);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      // The animation controller with the specified curve now drives the rotation.
      turns: _animation,
      child: Icon(
        Icons.hourglass_empty_rounded,
        color: widget.color ?? Theme.of(context).colorScheme.secondary,
        size: widget.size,
      ),
    );
  }
}
