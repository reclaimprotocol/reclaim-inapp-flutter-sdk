import 'package:flutter/material.dart';

import '../data/reclaim_app_theme.dart';
import '../widgets/color_or_image.dart';
import '../widgets/reclaim_image_provider.dart';

export '../data/reclaim_app_theme.dart';

class BackgroundDecoration {
  final ColorOrImageDecorationProvider? background;
  final double blurStrength;
  final Color? blurColor;

  const BackgroundDecoration({required this.background, this.blurStrength = 0, this.blurColor});
}

class ParametersTheme {
  final ParametersDisplayStyle parameterListStyle;
  final Color? dividerColor;
  final bool isValueShown;

  const ParametersTheme({
    this.parameterListStyle = ParametersDisplayStyle.compact,
    this.dividerColor,
    this.isValueShown = true,
  });
}

class ReclaimTheme extends ThemeExtension<ReclaimTheme> {
  final Color primary;
  final Color secondaryColor;
  final Color surfaceColor;
  final Color green;
  final ColorOrImageDecorationProvider? providerToAppLoader;
  final ColorOrImageDecorationProvider? loading;
  final double? cardElevation;
  final Color? cardColor;
  final Color? onCardColor;
  final Color? termsNoticeColor;
  final Color? hyperlinkColor;
  final Color? sessionChipSurfaceColor;
  final Color? sessionChipOnSurfaceColor;
  final BackgroundDecoration? background;
  final ReclaimGraphicProvider? doneIconProvider;
  final ReclaimGraphicProvider? fieldVerifiedIconProvider;
  final ReclaimGraphicProvider? fieldVerifyingIconProvider;
  final ReclaimGraphicProvider? verificationCompleteIconProvider;
  final ReclaimGraphicProvider? verifyScreenAppIconProvider;
  final ReclaimGraphicOptions? appIconGraphicOptions;
  final ReturnToAppMessage? returnToAppMessage;
  final DataSharedMessage? dataSharedMessage;
  final Uri? termsAndConditionsUri;
  final Uri? privacyPolicyUri;
  final Uri? potentialFailureReasonsUri;
  final String? secureAndPrivateText;
  final ParametersTheme parametersTheme;

  const ReclaimTheme({
    this.primary = const Color(0xFF332FED),
    this.secondaryColor = const Color(0xFF2563EB),
    this.surfaceColor = const Color(0xFFF7F7F8),
    this.green = const Color(0xFF16A34A),
    this.background,
    this.providerToAppLoader,
    this.doneIconProvider,
    this.loading,
    this.cardColor = const Color(0xFFF2F2F7),
    this.onCardColor = const Color(0xFF23221f),
    this.sessionChipSurfaceColor,
    this.sessionChipOnSurfaceColor,
    this.fieldVerifiedIconProvider,
    this.fieldVerifyingIconProvider,
    this.verificationCompleteIconProvider,
    this.verifyScreenAppIconProvider,
    this.appIconGraphicOptions,
    this.cardElevation,
    this.termsNoticeColor,
    this.hyperlinkColor,
    this.returnToAppMessage,
    this.dataSharedMessage,
    this.termsAndConditionsUri,
    this.privacyPolicyUri,
    this.potentialFailureReasonsUri,
    this.secureAndPrivateText,
    this.parametersTheme = const ParametersTheme(),
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
