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

  /// URL of the verification complete icon
  final ReclaimImageInfo? verificationCompleteIcon;

  final ReclaimImageInfo? verifyScreenAppIcon;

  const ReclaimVerificationReviewScreenTheme({
    required this.fieldVerifyingIcon,
    required this.fieldVerifiedIcon,
    required this.providerToAppLoaderColor,
    required this.verificationCompleteIcon,
    required this.verifyScreenAppIcon,
  });

  factory ReclaimVerificationReviewScreenTheme.fromJson(Map<String, dynamic> json) =>
      _$ReclaimVerificationReviewScreenThemeFromJson(json);

  Map<String, dynamic> toJson() => _$ReclaimVerificationReviewScreenThemeToJson(this);
}

@JsonSerializable()
class ReclaimAppTheme {
  /// Background configuration (can be a color or image)
  final ColorOrImage? background;

  final ReclaimAppColorScheme? colorScheme;

  /// Icon shown when verification is completed on success screen
  final ReclaimImageInfo? doneIcon;

  final ReclaimImageInfoOptions? appImageOptions;

  /// Icon shown wherever circular loading progress indicator is used.
  final int? loadingIconColor;

  final int? cardColor;

  final int? onCardColor;

  /// Theme information used on the verification review screen
  final ReclaimVerificationReviewScreenTheme? verificationReviewScreenTheme;

  const ReclaimAppTheme({
    this.background,
    this.colorScheme,
    this.loadingIconColor,
    this.doneIcon,
    this.cardColor,
    this.onCardColor,
    this.appImageOptions,
    this.verificationReviewScreenTheme,
  });

  factory ReclaimAppTheme.fromJson(Map<String, dynamic> json) => _$ReclaimAppThemeFromJson(json);

  Map<String, dynamic> toJson() => _$ReclaimAppThemeToJson(this);
}

@JsonSerializable()
class ReclaimAppThemeInfo {
  ///Supported application theme mode
  @JsonKey(defaultValue: ReclaimAppThemeMode.light)
  final ReclaimAppThemeMode themeMode;

  final ReclaimAppTheme? theme;
  final ReclaimAppTheme? darkTheme;
  final String? appName;

  const ReclaimAppThemeInfo({this.appName, this.themeMode = ReclaimAppThemeMode.light, this.theme, this.darkTheme});

  factory ReclaimAppThemeInfo.fromJson(Map<String, dynamic> json) => _$ReclaimAppThemeInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ReclaimAppThemeInfoToJson(this);

  ReclaimAppThemeInfo copyWith({String? appName}) {
    return ReclaimAppThemeInfo(
      appName: appName ?? this.appName,
      themeMode: themeMode,
      theme: theme,
      darkTheme: darkTheme,
    );
  }
}
