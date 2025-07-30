import 'package:flutter/material.dart';

class ReclaimTheme extends ThemeExtension<ReclaimTheme> {
  final Color primary;
  final Color grayBackground;
  final Color green;

  const ReclaimTheme({
    this.primary = const Color(0xFF332FED),
    this.grayBackground = const Color(0xFFF7F7F8),
    this.green = const Color(0xFF16A34A),
  });

  factory ReclaimTheme.of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<ReclaimTheme>() ?? const ReclaimTheme();
  }

  @override
  ReclaimTheme copyWith({Color? primary, Color? grayBackground, Color? green}) {
    return ReclaimTheme(
      primary: primary ?? this.primary,
      grayBackground: grayBackground ?? this.grayBackground,
      green: green ?? this.green,
    );
  }

  @override
  ReclaimTheme lerp(covariant ReclaimTheme? other, double t) {
    return ReclaimTheme(
      primary: Color.lerp(primary, other?.primary, t) ?? primary,
      grayBackground: Color.lerp(grayBackground, other?.grayBackground, t) ?? grayBackground,
      green: Color.lerp(green, other?.green, t) ?? green,
    );
  }
}
