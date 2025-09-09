import 'package:flutter/material.dart';

import '../widgets/color_or_image.dart';
import '../widgets/reclaim_image_provider.dart';

class ReclaimTheme extends ThemeExtension<ReclaimTheme> {
  final Color primary;
  final Color secondaryColor;
  final Color surfaceColor;
  final Color green;
  final Color? providerToAppLoaderColor;
  final Color? loadingIconColor;
  final Color? cardColor;
  final Color? onCardColor;
  final ColorOrImageDecorationProvider? background;
  final ReclaimGraphicProvider? doneIconProvider;
  final ReclaimGraphicProvider? fieldVerifiedIconProvider;
  final ReclaimGraphicProvider? fieldVerifyingIconProvider;
  final ReclaimGraphicProvider? verificationCompleteIconProvider;
  final ReclaimGraphicProvider? verifyScreenAppIconProvider;
  final ReclaimGraphicOptions? appIconGraphicOptions;

  const ReclaimTheme({
    this.primary = const Color(0xFF332FED),
    this.secondaryColor = const Color(0xFF2563EB),
    this.surfaceColor = const Color(0xFFF7F7F8),
    this.green = const Color(0xFF16A34A),
    this.background,
    this.providerToAppLoaderColor,
    this.doneIconProvider,
    this.loadingIconColor,
    this.cardColor = const Color(0xFFF2F2F7),
    this.onCardColor = const Color(0xFF23221f),
    this.fieldVerifiedIconProvider,
    this.fieldVerifyingIconProvider,
    this.verificationCompleteIconProvider,
    this.verifyScreenAppIconProvider,
    this.appIconGraphicOptions,
  });

  factory ReclaimTheme.of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<ReclaimTheme>() ?? const ReclaimTheme();
  }

  @override
  ReclaimTheme copyWith({Color? primary, Color? surfaceColor, Color? green}) {
    return ReclaimTheme(
      primary: primary ?? this.primary,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      green: green ?? this.green,
    );
  }

  @override
  ReclaimTheme lerp(covariant ReclaimTheme? other, double t) {
    return ReclaimTheme(
      primary: Color.lerp(primary, other?.primary, t) ?? primary,
      surfaceColor: Color.lerp(surfaceColor, other?.surfaceColor, t) ?? surfaceColor,
      green: Color.lerp(green, other?.green, t) ?? green,
    );
  }
}
