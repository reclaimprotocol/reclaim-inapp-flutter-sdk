import 'dart:math'
    as math;
import 'package:flutter/widgets.dart';

class FractionallyPaddedSafeArea
    extends StatelessWidget {
  const FractionallyPaddedSafeArea({
    super.key,
    this.left =
        true,
    this.right =
        true,
    this.top =
        true,
    this.bottom =
        true,
    this.bottomFraction =
        1.0,
    this.maintainBottomViewPadding =
        false,
    this.minimum =
        EdgeInsets.zero,
    required this.child,
  });

  final bool
      maintainBottomViewPadding;
  final Widget
      child;
  final EdgeInsets
      minimum;
  final bool
      left;
  final bool
      right;
  final bool
      top;
  final bool
      bottom;
  final double
      bottomFraction;

  @override
  Widget build(
      BuildContext
          context) {
    assert(
        debugCheckHasMediaQuery(context));
    EdgeInsets
        padding =
        MediaQuery.paddingOf(context);
    // Bottom padding has been consumed - i.e. by the keyboard
    if (maintainBottomViewPadding) {
      padding =
          padding.copyWith(
        bottom: MediaQuery.viewPaddingOf(context).bottom,
      );
    }

    return Padding(
      padding:
          EdgeInsets.only(
        left: math.max(left ? padding.left : 0.0, minimum.left),
        top: math.max(top ? padding.top : 0.0, minimum.top),
        right: math.max(right ? padding.right : 0.0, minimum.right),
        bottom: math.max(bottom ? padding.bottom : 0.0, minimum.bottom) * bottomFraction,
      ),
      child:
          MediaQuery.removePadding(
        context: context,
        removeLeft: left,
        removeTop: top,
        removeRight: right,
        removeBottom: bottom,
        child: child,
      ),
    );
  }
}
