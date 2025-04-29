import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingParamValue
    extends StatelessWidget {
  const LoadingParamValue({
    super.key,
    this.height =
        14,
    this.width =
        100,
    this.borderRadius = const BorderRadius
        .all(
        Radius.circular(4)),
  });
  final double?
      height;
  final double?
      width;
  final BorderRadiusGeometry?
      borderRadius;

  @override
  Widget build(
      BuildContext
          context) {
    return Shimmer
        .fromColors(
      baseColor:
          Colors.grey[300]!,
      highlightColor:
          Colors.grey[100]!,
      child:
          Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
