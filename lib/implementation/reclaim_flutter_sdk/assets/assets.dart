import 'dart:ui'
    as ui;
import 'package:flutter/material.dart'
    show
        TextTheme,
        ThemeData;
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'font/font.dart';

abstract class $ReclaimAssetImageProvider {
  static const _packageName =
      'reclaim_inapp_flutter_sdk';
  static const animatedLoading = AssetImage(
      'assets/animated_icons/animated_loading.gif',
      package:
          _packageName);
  static const checkCircle = AssetImage(
      'assets/animated_icons/check_circle.png',
      package:
          _packageName);
  static const lock = SvgAssetLoader(
      'assets/icons/lock.svg',
      packageName:
          _packageName);
  static const shieldTick = SvgAssetLoader(
      'assets/icons/shield_tick.svg',
      packageName:
          _packageName);
  static const steps =
      [
    SvgAssetLoader(
        'assets/icons/claim_creation/step1.svg',
        packageName: _packageName),
    SvgAssetLoader(
        'assets/icons/claim_creation/step2.svg',
        packageName: _packageName),
    SvgAssetLoader(
        'assets/icons/claim_creation/step3.svg',
        packageName: _packageName),
    SvgAssetLoader(
        'assets/icons/claim_creation/step4.svg',
        packageName: _packageName),
    SvgAssetLoader(
        'assets/icons/claim_creation/step5.svg',
        packageName: _packageName),
    SvgAssetLoader(
        'assets/icons/claim_creation/step6.svg',
        packageName: _packageName),
    SvgAssetLoader(
        'assets/icons/claim_creation/step7.svg',
        packageName: _packageName),
    SvgAssetLoader(
        'assets/icons/claim_creation/step8.svg',
        packageName: _packageName),
    SvgAssetLoader(
        'assets/icons/claim_creation/step9.svg',
        packageName: _packageName),
    SvgAssetLoader(
        'assets/icons/claim_creation/step10.svg',
        packageName: _packageName),
    SvgAssetLoader(
        'assets/icons/claim_creation/step11.svg',
        packageName: _packageName),
    SvgAssetLoader(
        'assets/icons/claim_creation/step12.svg',
        packageName: _packageName),
    SvgAssetLoader(
        'assets/icons/claim_creation/step13.svg',
        packageName: _packageName),
    SvgAssetLoader(
        'assets/icons/claim_creation/step14.svg',
        packageName: _packageName),
    SvgAssetLoader(
        'assets/icons/claim_creation/step15.svg',
        packageName: _packageName),
    SvgAssetLoader(
        'assets/icons/claim_creation/step16.svg',
        packageName: _packageName),
  ];
  static const navigateIcon = SvgAssetLoader(
      'assets/icons/navigate_icon.svg',
      packageName:
          _packageName);
  static const pointerIcon = SvgAssetLoader(
      'assets/icons/pointer_icon.svg',
      packageName:
          _packageName);
  static const rightArrow = SvgAssetLoader(
      'assets/icons/right_arrow_icon.svg',
      packageName:
          _packageName);
}

class $ReclaimFont {
  const $ReclaimFont._(
      this.description);

  final TargetFontDescription
      description;

  TextStyle
      _textStyle({
    TextStyle?
        textStyle,
    Color?
        color,
    Color?
        backgroundColor,
    double?
        fontSize,
    FontWeight?
        fontWeight,
    FontStyle?
        fontStyle,
    double?
        letterSpacing,
    double?
        wordSpacing,
    TextBaseline?
        textBaseline,
    double?
        height,
    Locale?
        locale,
    Paint?
        foreground,
    Paint?
        background,
    List<ui.Shadow>?
        shadows,
    List<ui.FontFeature>?
        fontFeatures,
    TextDecoration?
        decoration,
    Color?
        decorationColor,
    TextDecorationStyle?
        decorationStyle,
    double?
        decorationThickness,
  }) {
    // This will only load fonts once if they weren't
    // loaded before in flutter engine during the current
    // runtime
    description
        .installFontIfRequired();

    final fontTextStyle =
        TextStyle(
      fontFamily:
          description.name,
      color:
          color,
      backgroundColor:
          backgroundColor,
      fontSize:
          fontSize,
      fontWeight:
          fontWeight,
      fontStyle:
          fontStyle,
      letterSpacing:
          letterSpacing,
      wordSpacing:
          wordSpacing,
      textBaseline:
          textBaseline,
      height:
          height,
      locale:
          locale,
      foreground:
          foreground,
      background:
          background,
      shadows:
          shadows,
      fontFeatures:
          fontFeatures,
      decoration:
          decoration,
      decorationColor:
          decorationColor,
      decorationStyle:
          decorationStyle,
      decorationThickness:
          decorationThickness,
    );
    if (textStyle ==
        null) {
      return fontTextStyle;
    } else {
      return textStyle.merge(fontTextStyle);
    }
  }

  TextTheme
      textTheme([TextTheme? textTheme]) {
    textTheme ??=
        ThemeData.light().textTheme;
    return TextTheme(
      displayLarge:
          _textStyle(textStyle: textTheme.displayLarge),
      displayMedium:
          _textStyle(textStyle: textTheme.displayMedium),
      displaySmall:
          _textStyle(textStyle: textTheme.displaySmall),
      headlineLarge:
          _textStyle(textStyle: textTheme.headlineLarge),
      headlineMedium:
          _textStyle(textStyle: textTheme.headlineMedium),
      headlineSmall:
          _textStyle(textStyle: textTheme.headlineSmall),
      titleLarge:
          _textStyle(textStyle: textTheme.titleLarge),
      titleMedium:
          _textStyle(textStyle: textTheme.titleMedium),
      titleSmall:
          _textStyle(textStyle: textTheme.titleSmall),
      bodyLarge:
          _textStyle(textStyle: textTheme.bodyLarge),
      bodyMedium:
          _textStyle(textStyle: textTheme.bodyMedium),
      bodySmall:
          _textStyle(textStyle: textTheme.bodySmall),
      labelLarge:
          _textStyle(textStyle: textTheme.labelLarge),
      labelMedium:
          _textStyle(textStyle: textTheme.labelMedium),
      labelSmall:
          _textStyle(textStyle: textTheme.labelSmall),
    );
  }

  static const inter =
      $ReclaimFont._(TargetFontDescription(
    name:
        'Inter',
    url:
        'https://dev.reclaimprotocol.org/assets/fonts/inter-vf.ttf',
    expectedFileLength:
        804612,
    expectedFileHash:
        'cf3cb43b0366e2dc6df60e1132b1c9a4c15777f0cd8e5a53e0c15124003e9ed4',
  ));
}
