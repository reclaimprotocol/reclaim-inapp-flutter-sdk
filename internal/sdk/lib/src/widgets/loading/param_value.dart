import 'package:flutter/material.dart';

import 'shimmer_shader.dart';

class LoadingParamValue extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final primaryColor = color ?? Color(0xffD4D7DB);

    return ShimmerShader(
      animate: true,
      primaryColor: color,
      child: Container(
        decoration: BoxDecoration(color: primaryColor, borderRadius: borderRadius),
        width: width,
        height: height,
      ),
    );
  }
}
