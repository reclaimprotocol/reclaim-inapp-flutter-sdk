import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../assets/assets.dart';

class ReclaimThemeProvider
    extends StatelessWidget {
  const ReclaimThemeProvider(
      {super.key,
      required this.child});

  final Widget
      child;

  static const font =
      $ReclaimFont.inter;

  static ThemeData
      buildTheme() {
    ThemeData
        theme =
        ThemeData(
      colorScheme:
          ColorScheme.fromSeed(
        seedColor: Color(0xFF000099),
        primary: Color(0xFF4444EE),
        secondary: Color(0xFF2563EB),
        tertiary: Color(0xFF1375f6),
        brightness: Brightness.light,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      ),
      // SDK only has light theme
      brightness:
          Brightness.light,
      useMaterial3:
          true,
      fontFamily:
          font.description.name,
    );

    theme =
        theme.copyWith(
      splashFactory: (kIsWeb || kIsWasm)
          ? null
          : InkSparkle.splashFactory,
    );

    final textTheme =
        font.textTheme(theme.textTheme);

    theme =
        theme.copyWith(
      typography:
          Typography.material2021(
        platform: theme.platform,
        colorScheme: theme.colorScheme,
        black: textTheme,
        white: textTheme,
      ),
      primaryTextTheme:
          textTheme,
      textTheme:
          textTheme,
    );

    return theme;
  }

  @override
  Widget build(
      BuildContext
          context) {
    final theme =
        buildTheme();

    final TextStyle
        fallbackTextStyle =
        TextStyle(
      color:
          Colors.white,
      fontFamily:
          font.description.name,
      fontSize:
          16.0,
      fontWeight:
          FontWeight.normal,
      decoration:
          TextDecoration.none,
      debugLabel:
          'fallback style',
    );

    return Theme(
      data:
          theme,
      child:
          DefaultTextStyle(
        // used as fallback for providing font family wherever text theme isn't used
        style: fallbackTextStyle,
        child: child,
      ),
    );
  }
}
