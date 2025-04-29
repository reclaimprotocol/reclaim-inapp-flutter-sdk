import 'package:flutter/material.dart';

class ActionButton
    extends StatelessWidget {
  final void
          Function()
      onPressed;
  final Widget
      child;

  const ActionButton(
      {super.key,
      required this.onPressed,
      required this.child});

  @override
  Widget build(
      BuildContext
          context) {
    final theme =
        Theme.of(context);
    final colorScheme =
        theme.colorScheme;
    final textTheme =
        theme.textTheme;

    return ElevatedButton(
      style:
          ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        textStyle: (textTheme.labelLarge ?? TextStyle()).merge(const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 17,
          height: 1.3,
        )),
        shape: const RoundedRectangleBorder(
          // Override rounded corners
          borderRadius: BorderRadius.zero,
        ),
        minimumSize: const Size(double.infinity, kMinInteractiveDimension),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      ),
      onPressed:
          onPressed,
      child:
          child,
    );
  }
}
