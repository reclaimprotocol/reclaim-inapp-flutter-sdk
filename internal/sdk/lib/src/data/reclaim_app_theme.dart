import 'package:json_annotation/json_annotation.dart';

part 'reclaim_app_theme.g.dart';

enum ReclaimAppThemeMode {
  @JsonValue('dark')
  dark,
  @JsonValue('light')
  light,
  @JsonValue('system')
  system,
}

enum ImageBoxFit {
  @JsonValue('cover')
  cover,
  @JsonValue('scale_down')
  scaleDown,
}

@JsonSerializable()
class ImageAlignment {
  @JsonKey(defaultValue: 0)
  /// Range between 0 and 1
  final num x;
  @JsonKey(defaultValue: 0)
  /// Range between 0 and 1
  final num y;

  const ImageAlignment({this.x = 0, this.y = 0});

  static const center = ImageAlignment(x: 0, y: 0);

  factory ImageAlignment.fromJson(Map<String, dynamic> json) => _$ImageAlignmentFromJson(json);

  Map<String, dynamic> toJson() => _$ImageAlignmentToJson(this);
}

@JsonSerializable()
class ReclaimImageInfoOptions {
  @JsonKey()
  final ImageAlignment? alignment;
  final int? backgroundColor;
  @JsonKey(defaultValue: 1)
  final num opacity;
  @JsonKey()
  final ImageBoxFit? fit;
  @JsonKey(defaultValue: false)
  final bool spin;

  const ReclaimImageInfoOptions({
    this.alignment,
    this.backgroundColor,
    this.opacity = 1,
    this.fit = ImageBoxFit.cover,
    this.spin = false,
  });

  factory ReclaimImageInfoOptions.fromJson(Map<String, dynamic> json) => _$ReclaimImageInfoOptionsFromJson(json);

  Map<String, dynamic> toJson() => _$ReclaimImageInfoOptionsToJson(this);
}

@JsonSerializable()
class ReclaimImageInfo {
  final String? url;
  final ReclaimImageInfoOptions? options;

  const ReclaimImageInfo({required this.url, this.options = const ReclaimImageInfoOptions()});

  factory ReclaimImageInfo.fromJson(Map<String, dynamic> json) => _$ReclaimImageInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ReclaimImageInfoToJson(this);
}

@JsonSerializable()
class ColorOrImage {
  /// Color value as integer (e.g., 0xFF000000)
  final int? color;

  /// URL of the image
  final ReclaimImageInfo? image;

  const ColorOrImage({this.color, this.image});

  factory ColorOrImage.fromJson(Map<String, dynamic> json) => _$ColorOrImageFromJson(json);

  Map<String, dynamic> toJson() => _$ColorOrImageToJson(this);

  ColorOrImage copyWith({int? color, ReclaimImageInfo? image}) {
    return ColorOrImage(color: color ?? this.color, image: image ?? this.image);
  }
}

@JsonSerializable()
class ReclaimAppColorScheme {
  /// Theme color value as integer
  final int? themeColor;

  /// Surface color value as integer (optional)
  final int? surfaceColor;

  /// On Surface color value as integer (optional)
  final int? onSurfaceColor;

  const ReclaimAppColorScheme({required this.themeColor, required this.surfaceColor, required this.onSurfaceColor});

  factory ReclaimAppColorScheme.fromJson(Map<String, dynamic> json) => _$ReclaimAppColorSchemeFromJson(json);

  Map<String, dynamic> toJson() => _$ReclaimAppColorSchemeToJson(this);
}

@JsonSerializable()
class ReclaimVerificationReviewScreenTheme {
  /// URL of the field verifying icon
  final ReclaimImageInfo? fieldVerifyingIcon;

  /// URL of the field verified icon
  final ReclaimImageInfo? fieldVerifiedIcon;

  /// Color for provider to app loader as integer
  final int? providerToAppLoaderColor;
  final ColorOrImage? providerToAppLoader;

  /// URL of the verification complete icon
  final ReclaimImageInfo? verificationCompleteIcon;

  final ReclaimImageInfo? verifyScreenAppIcon;

  const ReclaimVerificationReviewScreenTheme({
    required this.fieldVerifyingIcon,
    required this.fieldVerifiedIcon,
    required this.providerToAppLoaderColor,
    required this.providerToAppLoader,
    required this.verificationCompleteIcon,
    required this.verifyScreenAppIcon,
  });

  factory ReclaimVerificationReviewScreenTheme.fromJson(Map<String, dynamic> json) =>
      _$ReclaimVerificationReviewScreenThemeFromJson(json);

  Map<String, dynamic> toJson() => _$ReclaimVerificationReviewScreenThemeToJson(this);
}

@JsonSerializable()
class ParameterStyle {
  final ParametersDisplayStyle? displayStyle;
  final int? dividerColor;
  @JsonKey(defaultValue: true)
  final bool? isValueShown;

  const ParameterStyle({this.displayStyle, this.dividerColor, this.isValueShown});

  factory ParameterStyle.fromJson(Map<String, dynamic> json) => _$ParameterStyleFromJson(json);

  Map<String, dynamic> toJson() => _$ParameterStyleToJson(this);
}

@JsonSerializable()
class ReclaimAppTheme {
  /// Background configuration (can be a color or image)
  final ColorOrImage? background;

  final double? backgroundBlurStrength;
  final int? backgroundBlurColor;
  final ParameterStyle? parameterStyle;

  final ReclaimAppColorScheme? colorScheme;

  /// Icon shown when verification is completed on success screen
  final ReclaimImageInfo? doneIcon;

  final ReclaimImageInfoOptions? appImageOptions;

  /// Icon shown wherever circular loading progress indicator is used.
  final ColorOrImage? loading;

  final double? cardElevation;

  final int? cardColor;
  final int? onCardColor;

  final int? sessionChipSurfaceColor;
  final int? sessionChipOnSurfaceColor;

  final int? termsNoticeColor;
  final int? hyperlinkColor;
  @Deprecated('Replaced by hyperlinkColor')
  final int? hyperlinkColorInt;

  /// Theme information used on the verification review screen
  final ReclaimVerificationReviewScreenTheme? verificationReviewScreenTheme;

  const ReclaimAppTheme({
    this.background,
    this.backgroundBlurStrength,
    this.backgroundBlurColor,
    this.colorScheme,
    this.loading,
    this.doneIcon,
    this.cardColor,
    this.onCardColor,
    this.sessionChipSurfaceColor,
    this.sessionChipOnSurfaceColor,
    this.appImageOptions,
    this.verificationReviewScreenTheme,
    this.cardElevation,
    this.termsNoticeColor,
    this.hyperlinkColor,
    // ignore: deprecated_consistency
    this.hyperlinkColorInt,
    this.parameterStyle,
  });

  factory ReclaimAppTheme.fromJson(Map<String, dynamic> json) => _$ReclaimAppThemeFromJson(json);

  Map<String, dynamic> toJson() => _$ReclaimAppThemeToJson(this);
}

@JsonSerializable()
class ReturnToAppMessage {
  final String? success;
  final String? failure;

  const ReturnToAppMessage({required this.success, required this.failure});

  factory ReturnToAppMessage.fromJson(Map<String, dynamic> json) => _$ReturnToAppMessageFromJson(json);

  Map<String, dynamic> toJson() => _$ReturnToAppMessageToJson(this);
}

@JsonSerializable()
class DataSharedMessage {
  final String? savedAndShared;
  final String? shared;
  final String? whatWasShared;

  const DataSharedMessage({required this.savedAndShared, required this.shared, required this.whatWasShared});

  factory DataSharedMessage.fromJson(Map<String, dynamic> json) => _$DataSharedMessageFromJson(json);

  Map<String, dynamic> toJson() => _$DataSharedMessageToJson(this);
}

enum ParametersDisplayStyle { compact, dividerSeparated }

@JsonSerializable()
class ReclaimAppThemeInfo {
  ///Supported application theme mode
  @JsonKey(defaultValue: ReclaimAppThemeMode.light)
  final ReclaimAppThemeMode themeMode;

  final ReclaimAppTheme? theme;
  final ReclaimAppTheme? darkTheme;
  final String? appName;
  final ReturnToAppMessage? returnToAppMessage;
  final DataSharedMessage? dataSharedMessage;
  final String? termsAndConditionLink;
  final String? privacyPolicyLink;
  final String? preferredLocale;

  const ReclaimAppThemeInfo({
    this.appName,
    this.themeMode = ReclaimAppThemeMode.light,
    this.theme,
    this.darkTheme,
    this.returnToAppMessage,
    this.dataSharedMessage,
    this.termsAndConditionLink,
    this.privacyPolicyLink,
    this.preferredLocale,
  });

  factory ReclaimAppThemeInfo.fromJson(Map<String, dynamic> json) => _$ReclaimAppThemeInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ReclaimAppThemeInfoToJson(this);

  ReclaimAppThemeInfo copyWith({String? appName}) {
    return ReclaimAppThemeInfo(
      appName: appName ?? this.appName,
      themeMode: themeMode,
      theme: theme,
      darkTheme: darkTheme,
      returnToAppMessage: returnToAppMessage,
      dataSharedMessage: dataSharedMessage,
      termsAndConditionLink: termsAndConditionLink,
      privacyPolicyLink: privacyPolicyLink,
    );
  }
}
