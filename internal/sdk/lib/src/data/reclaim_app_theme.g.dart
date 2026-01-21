// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reclaim_app_theme.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImageAlignment _$ImageAlignmentFromJson(Map<String, dynamic> json) =>
    ImageAlignment(x: json['x'] as num? ?? 0, y: json['y'] as num? ?? 0);

Map<String, dynamic> _$ImageAlignmentToJson(ImageAlignment instance) => <String, dynamic>{
  'x': instance.x,
  'y': instance.y,
};

ReclaimImageInfoOptions _$ReclaimImageInfoOptionsFromJson(Map<String, dynamic> json) => ReclaimImageInfoOptions(
  alignment: json['alignment'] == null ? null : ImageAlignment.fromJson(json['alignment'] as Map<String, dynamic>),
  backgroundColor: (json['backgroundColor'] as num?)?.toInt(),
  opacity: json['opacity'] as num? ?? 1,
  fit: $enumDecodeNullable(_$ImageBoxFitEnumMap, json['fit']) ?? ImageBoxFit.cover,
  spin: json['spin'] as bool? ?? false,
);

Map<String, dynamic> _$ReclaimImageInfoOptionsToJson(ReclaimImageInfoOptions instance) => <String, dynamic>{
  'alignment': instance.alignment,
  'backgroundColor': instance.backgroundColor,
  'opacity': instance.opacity,
  'fit': _$ImageBoxFitEnumMap[instance.fit],
  'spin': instance.spin,
};

const _$ImageBoxFitEnumMap = {ImageBoxFit.cover: 'cover', ImageBoxFit.scaleDown: 'scale_down'};

ReclaimImageInfo _$ReclaimImageInfoFromJson(Map<String, dynamic> json) => ReclaimImageInfo(
  url: json['url'] as String?,
  options: json['options'] == null
      ? const ReclaimImageInfoOptions()
      : ReclaimImageInfoOptions.fromJson(json['options'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ReclaimImageInfoToJson(ReclaimImageInfo instance) => <String, dynamic>{
  'url': instance.url,
  'options': instance.options,
};

ColorOrImage _$ColorOrImageFromJson(Map<String, dynamic> json) => ColorOrImage(
  color: (json['color'] as num?)?.toInt(),
  image: json['image'] == null ? null : ReclaimImageInfo.fromJson(json['image'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ColorOrImageToJson(ColorOrImage instance) => <String, dynamic>{
  'color': instance.color,
  'image': instance.image,
};

ReclaimAppColorScheme _$ReclaimAppColorSchemeFromJson(Map<String, dynamic> json) => ReclaimAppColorScheme(
  themeColor: (json['themeColor'] as num?)?.toInt(),
  surfaceColor: (json['surfaceColor'] as num?)?.toInt(),
  onSurfaceColor: (json['onSurfaceColor'] as num?)?.toInt(),
);

Map<String, dynamic> _$ReclaimAppColorSchemeToJson(ReclaimAppColorScheme instance) => <String, dynamic>{
  'themeColor': instance.themeColor,
  'surfaceColor': instance.surfaceColor,
  'onSurfaceColor': instance.onSurfaceColor,
};

ReclaimVerificationReviewScreenTheme _$ReclaimVerificationReviewScreenThemeFromJson(Map<String, dynamic> json) =>
    ReclaimVerificationReviewScreenTheme(
      fieldVerifyingIcon: json['fieldVerifyingIcon'] == null
          ? null
          : ReclaimImageInfo.fromJson(json['fieldVerifyingIcon'] as Map<String, dynamic>),
      fieldVerifiedIcon: json['fieldVerifiedIcon'] == null
          ? null
          : ReclaimImageInfo.fromJson(json['fieldVerifiedIcon'] as Map<String, dynamic>),
      providerToAppLoaderColor: (json['providerToAppLoaderColor'] as num?)?.toInt(),
      providerToAppLoader: json['providerToAppLoader'] == null
          ? null
          : ColorOrImage.fromJson(json['providerToAppLoader'] as Map<String, dynamic>),
      verificationCompleteIcon: json['verificationCompleteIcon'] == null
          ? null
          : ReclaimImageInfo.fromJson(json['verificationCompleteIcon'] as Map<String, dynamic>),
      verifyScreenAppIcon: json['verifyScreenAppIcon'] == null
          ? null
          : ReclaimImageInfo.fromJson(json['verifyScreenAppIcon'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ReclaimVerificationReviewScreenThemeToJson(ReclaimVerificationReviewScreenTheme instance) =>
    <String, dynamic>{
      'fieldVerifyingIcon': instance.fieldVerifyingIcon,
      'fieldVerifiedIcon': instance.fieldVerifiedIcon,
      'providerToAppLoaderColor': instance.providerToAppLoaderColor,
      'providerToAppLoader': instance.providerToAppLoader,
      'verificationCompleteIcon': instance.verificationCompleteIcon,
      'verifyScreenAppIcon': instance.verifyScreenAppIcon,
    };

ParameterStyle _$ParameterStyleFromJson(Map<String, dynamic> json) => ParameterStyle(
  displayStyle: $enumDecodeNullable(_$ParametersDisplayStyleEnumMap, json['displayStyle']),
  dividerColor: (json['dividerColor'] as num?)?.toInt(),
  isValueShown: json['isValueShown'] as bool? ?? true,
);

Map<String, dynamic> _$ParameterStyleToJson(ParameterStyle instance) => <String, dynamic>{
  'displayStyle': _$ParametersDisplayStyleEnumMap[instance.displayStyle],
  'dividerColor': instance.dividerColor,
  'isValueShown': instance.isValueShown,
};

const _$ParametersDisplayStyleEnumMap = {
  ParametersDisplayStyle.compact: 'compact',
  ParametersDisplayStyle.dividerSeparated: 'dividerSeparated',
};

ReclaimAppTheme _$ReclaimAppThemeFromJson(Map<String, dynamic> json) => ReclaimAppTheme(
  background: json['background'] == null ? null : ColorOrImage.fromJson(json['background'] as Map<String, dynamic>),
  backgroundBlurStrength: (json['backgroundBlurStrength'] as num?)?.toDouble(),
  backgroundBlurColor: (json['backgroundBlurColor'] as num?)?.toInt(),
  colorScheme: json['colorScheme'] == null
      ? null
      : ReclaimAppColorScheme.fromJson(json['colorScheme'] as Map<String, dynamic>),
  loading: json['loading'] == null ? null : ColorOrImage.fromJson(json['loading'] as Map<String, dynamic>),
  doneIcon: json['doneIcon'] == null ? null : ReclaimImageInfo.fromJson(json['doneIcon'] as Map<String, dynamic>),
  cardColor: (json['cardColor'] as num?)?.toInt(),
  onCardColor: (json['onCardColor'] as num?)?.toInt(),
  sessionChipSurfaceColor: (json['sessionChipSurfaceColor'] as num?)?.toInt(),
  sessionChipOnSurfaceColor: (json['sessionChipOnSurfaceColor'] as num?)?.toInt(),
  appImageOptions: json['appImageOptions'] == null
      ? null
      : ReclaimImageInfoOptions.fromJson(json['appImageOptions'] as Map<String, dynamic>),
  verificationReviewScreenTheme: json['verificationReviewScreenTheme'] == null
      ? null
      : ReclaimVerificationReviewScreenTheme.fromJson(json['verificationReviewScreenTheme'] as Map<String, dynamic>),
  cardElevation: (json['cardElevation'] as num?)?.toDouble(),
  termsNoticeColor: (json['termsNoticeColor'] as num?)?.toInt(),
  hyperlinkColor: (json['hyperlinkColor'] as num?)?.toInt(),
  hyperlinkColorInt: (json['hyperlinkColorInt'] as num?)?.toInt(),
  parameterStyle: json['parameterStyle'] == null
      ? null
      : ParameterStyle.fromJson(json['parameterStyle'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ReclaimAppThemeToJson(ReclaimAppTheme instance) => <String, dynamic>{
  'background': instance.background,
  'backgroundBlurStrength': instance.backgroundBlurStrength,
  'backgroundBlurColor': instance.backgroundBlurColor,
  'parameterStyle': instance.parameterStyle,
  'colorScheme': instance.colorScheme,
  'doneIcon': instance.doneIcon,
  'appImageOptions': instance.appImageOptions,
  'loading': instance.loading,
  'cardElevation': instance.cardElevation,
  'cardColor': instance.cardColor,
  'onCardColor': instance.onCardColor,
  'sessionChipSurfaceColor': instance.sessionChipSurfaceColor,
  'sessionChipOnSurfaceColor': instance.sessionChipOnSurfaceColor,
  'termsNoticeColor': instance.termsNoticeColor,
  'hyperlinkColor': instance.hyperlinkColor,
  'hyperlinkColorInt': instance.hyperlinkColorInt,
  'verificationReviewScreenTheme': instance.verificationReviewScreenTheme,
};

ReturnToAppMessage _$ReturnToAppMessageFromJson(Map<String, dynamic> json) =>
    ReturnToAppMessage(success: json['success'] as String?, failure: json['failure'] as String?);

Map<String, dynamic> _$ReturnToAppMessageToJson(ReturnToAppMessage instance) => <String, dynamic>{
  'success': instance.success,
  'failure': instance.failure,
};

DataSharedMessage _$DataSharedMessageFromJson(Map<String, dynamic> json) => DataSharedMessage(
  savedAndShared: json['savedAndShared'] as String?,
  shared: json['shared'] as String?,
  whatWasShared: json['whatWasShared'] as String?,
);

Map<String, dynamic> _$DataSharedMessageToJson(DataSharedMessage instance) => <String, dynamic>{
  'savedAndShared': instance.savedAndShared,
  'shared': instance.shared,
  'whatWasShared': instance.whatWasShared,
};

ReclaimAppThemeInfo _$ReclaimAppThemeInfoFromJson(Map<String, dynamic> json) => ReclaimAppThemeInfo(
  appName: json['appName'] as String?,
  themeMode: $enumDecodeNullable(_$ReclaimAppThemeModeEnumMap, json['themeMode']) ?? ReclaimAppThemeMode.light,
  theme: json['theme'] == null ? null : ReclaimAppTheme.fromJson(json['theme'] as Map<String, dynamic>),
  darkTheme: json['darkTheme'] == null ? null : ReclaimAppTheme.fromJson(json['darkTheme'] as Map<String, dynamic>),
  returnToAppMessage: json['returnToAppMessage'] == null
      ? null
      : ReturnToAppMessage.fromJson(json['returnToAppMessage'] as Map<String, dynamic>),
  dataSharedMessage: json['dataSharedMessage'] == null
      ? null
      : DataSharedMessage.fromJson(json['dataSharedMessage'] as Map<String, dynamic>),
  termsAndConditionLink: json['termsAndConditionLink'] as String?,
  privacyPolicyLink: json['privacyPolicyLink'] as String?,
  potentialFailureReasonsLink: json['potentialFailureReasonsLink'] as String?,
  preferredLocale: json['preferredLocale'] as String?,
);

Map<String, dynamic> _$ReclaimAppThemeInfoToJson(ReclaimAppThemeInfo instance) => <String, dynamic>{
  'themeMode': _$ReclaimAppThemeModeEnumMap[instance.themeMode]!,
  'theme': instance.theme,
  'darkTheme': instance.darkTheme,
  'appName': instance.appName,
  'returnToAppMessage': instance.returnToAppMessage,
  'dataSharedMessage': instance.dataSharedMessage,
  'termsAndConditionLink': instance.termsAndConditionLink,
  'privacyPolicyLink': instance.privacyPolicyLink,
  'potentialFailureReasonsLink': instance.potentialFailureReasonsLink,
  'preferredLocale': instance.preferredLocale,
};

const _$ReclaimAppThemeModeEnumMap = {
  ReclaimAppThemeMode.dark: 'dark',
  ReclaimAppThemeMode.light: 'light',
  ReclaimAppThemeMode.system: 'system',
};
