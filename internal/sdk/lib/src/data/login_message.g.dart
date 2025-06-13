// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginPromptActionData _$LoginPromptActionDataFromJson(Map<String, dynamic> json) => LoginPromptActionData(
  message: _nonBlankStringFromJson(json['message']),
  ctaLabel: _nonBlankStringFromJson(json['ctaLabel']),
);

Map<String, dynamic> _$LoginPromptActionDataToJson(LoginPromptActionData instance) => <String, dynamic>{
  'message': instance.message,
  'ctaLabel': instance.ctaLabel,
};
