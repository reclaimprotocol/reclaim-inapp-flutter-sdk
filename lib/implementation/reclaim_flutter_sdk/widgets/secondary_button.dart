import 'package:flutter/material.dart';

final _secondaryButtonStyle =
    OutlinedButton
        .styleFrom(
  elevation:
      0,
  textStyle:
      const TextStyle(
    fontWeight:
        FontWeight.w400,
    fontSize:
        17,
    height:
        1.3,
  ),
  shape:
      const RoundedRectangleBorder(
    // Override rounded corners
    borderRadius:
        BorderRadius.all(Radius.circular(12)),
  ),
  minimumSize: const Size(
      double.infinity,
      50),
  padding: const EdgeInsets
      .symmetric(
      horizontal:
          20,
      vertical:
          15),
);

class SecondaryButton
    extends StatelessWidget {
  final void
          Function()
      onPressed;
  final Widget
      child;

  const SecondaryButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(
      BuildContext
          context) {
    return OutlinedButton(
      style:
          _secondaryButtonStyle,
      onPressed:
          onPressed,
      child:
          child,
    );
  }
}
