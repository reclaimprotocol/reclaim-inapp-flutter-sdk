import 'package:flutter/material.dart';

import '../assets/font/font.dart';

class FontsLoaded extends StatelessWidget {
  const FontsLoaded({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!TargetFontDescription.isLoadingFonts) {
      return child;
    }

    return FutureBuilder(
      future: TargetFontDescription.waitForPendingFonts().timeout(const Duration(seconds: 5)),
      builder: (context, snapshot) {
        return AnimatedOpacity(
          opacity: snapshot.connectionState == ConnectionState.done ? 1 : 0,
          duration: Durations.short4,
          curve: Curves.easeIn,
          child: child,
        );
      },
    );
  }
}
