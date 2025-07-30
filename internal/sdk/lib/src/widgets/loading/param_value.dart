import 'package:flutter/material.dart';

class LoadingParamValue extends StatefulWidget {
  const LoadingParamValue({
    super.key,
    this.height = 14,
    this.width = 150,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
    this.color,
  });
  final double? height;
  final double? width;
  final BorderRadiusGeometry? borderRadius;
  final Color? color;

  @override
  State<LoadingParamValue> createState() => _LoadingParamValueState();
}

class _LoadingParamValueState extends State<LoadingParamValue> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.color ?? Color(0xffD4D7DB); // theme.colorScheme.primary;
    final secondaryColor = primaryColor.withValues(alpha: 0.1); // theme.colorScheme.secondary;

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
      child: Container(
        decoration: BoxDecoration(color: primaryColor, borderRadius: widget.borderRadius),
        width: widget.width,
        height: widget.height,
      ),
    );
  }
}
