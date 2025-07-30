import 'package:flutter/material.dart';

import 'animated_progress.dart';

const _loadingIndicatorHeight = 3.0;

class ReclaimLinearProgress extends StatelessWidget {
  const ReclaimLinearProgress({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: switch (progress) {
        1.0 => const SizedBox(height: _loadingIndicatorHeight, width: double.infinity),
        _ => AnimatedLinearProgressIndicator(
          progress: progress,
          backgroundColor: Colors.transparent,
          minHeight: _loadingIndicatorHeight,
        ),
      },
    );
  }
}
