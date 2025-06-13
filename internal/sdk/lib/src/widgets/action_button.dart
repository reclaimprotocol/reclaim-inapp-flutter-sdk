import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final void Function() onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? colorScheme.primary,
        foregroundColor: foregroundColor ?? colorScheme.onPrimary,
        textStyle: (textTheme.labelLarge ?? TextStyle()).merge(
          TextStyle(fontWeight: FontWeight.w600, fontSize: 17, height: 1.3, color: foregroundColor),
        ),
        shape: const RoundedRectangleBorder(
          // Override rounded corners
          borderRadius: BorderRadius.zero,
        ),
        minimumSize: const Size(double.infinity, kMinInteractiveDimension),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      ),
      onPressed: onPressed,
      child: child,
    );
  }
}
