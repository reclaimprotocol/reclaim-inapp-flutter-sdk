import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'widgets.dart';

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

class ReclaimCircularProgressIndicator extends StatelessWidget {
  const ReclaimCircularProgressIndicator({
    super.key,
    this.padding = const EdgeInsets.all(3.0),
    this.size,
    this.defaultIndicatorStrokeWidth = 4.0,
  });

  final EdgeInsetsGeometry? padding;
  final double? size;
  final double? defaultIndicatorStrokeWidth;

  @override
  Widget build(BuildContext context) {
    final reclaimTheme = ReclaimTheme.of(context);
    final accentColor = reclaimTheme.secondaryColor;
    final loadingTheme = reclaimTheme.loading;
    final loadingAssetProvider = reclaimTheme.loading?.map(
      onColor: (color) => null,
      onAssetProvider: (provider) => provider,
    );

    final loadingIconColor =
        loadingTheme?.map(onColor: (color) => color, onAssetProvider: (_) => null) ??
        reclaimTheme.providerToAppLoader?.map(onColor: (color) => color, onAssetProvider: (_) => null) ??
        accentColor;

    late final circularProgressIndicator = CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(loadingIconColor),
      strokeCap: StrokeCap.round,
      strokeWidth: defaultIndicatorStrokeWidth,
      value: null,
    );

    final loadingWidget = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: SizedBox.square(
        dimension: size,
        child: loadingAssetProvider != null
            ? ReclaimGraphicIcon(
                placeholder: circularProgressIndicator,
                provider: loadingAssetProvider,
                fit: BoxFit.scaleDown,
                size: size,
              )
            : circularProgressIndicator,
      ),
    );

    return loadingWidget;
  }
}
