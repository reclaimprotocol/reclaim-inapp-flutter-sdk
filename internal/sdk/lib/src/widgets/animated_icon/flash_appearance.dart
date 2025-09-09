import 'package:flutter/material.dart';

class FlashAppearance extends StatefulWidget {
  const FlashAppearance({super.key, required this.child});
  final Widget child;

  @override
  State<FlashAppearance> createState() => FlashAppearanceState();
}

class FlashAppearanceState extends State<FlashAppearance> with TickerProviderStateMixin {
  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  late final Animation<double> _opacityAnimation = CurvedAnimation(
    parent: Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCirc)),
    curve: Curves.easeInOut,
  );
  late final Animation<double> _scaleAnimation = CurvedAnimation(
    parent: Tween<double>(
      begin: 0.8,
      end: 1,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCirc)),
    curve: Curves.easeInOut,
  );

  void startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      _animationController.forward();
    }
  }

  void reset() {
    _animationController.reset();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(startAnimation);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_opacityAnimation, _scaleAnimation]),
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(scale: _scaleAnimation.value, child: child),
        );
      },
      child: widget.child,
    );
  }
}
