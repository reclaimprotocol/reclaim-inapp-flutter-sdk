import 'package:flutter/material.dart';

class ShimmerShader extends StatefulWidget {
  const ShimmerShader({super.key, this.primaryColor, this.secondaryColor, this.animate = true, required this.child});
  final Color? primaryColor;
  final Color? secondaryColor;
  final bool animate;
  final Widget child;

  @override
  State<ShimmerShader> createState() => _ShimmerShaderState();
}

class _ShimmerShaderState extends State<ShimmerShader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ShimmerShader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.reset();
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? Color(0xffD4D7DB); // theme.colorScheme.primary;
    final secondaryColor = widget.secondaryColor ?? primaryColor.withValues(alpha: 0.1); // theme.colorScheme.secondary;

    return AnimatedBuilder(
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
          blendMode: BlendMode.dstIn,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
