// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_review.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ManualReviewActionData _$ManualReviewActionDataFromJson(Map<String, dynamic> json) => ManualReviewActionData(
  message: _nonBlankStringFromJson(json['message']),
  submitLabel: _nonBlankStringFromJson(json['submitLabel']),
  canSubmit: json['canSubmit'] as bool? ?? true,
  rule:
      $enumDecodeNullable(_$ManualReviewPromptDisplayRuleEnumMap, json['rule']) ??
      ManualReviewPromptDisplayRule.TIMEOUT,
  confirmationDialogTitle: _nonBlankStringFromJson(json['confirmationDialogTitle']),
  confirmationDialogMessage: _nonBlankStringFromJson(json['confirmationDialogMessage']),
);

Map<String, dynamic> _$ManualReviewActionDataToJson(ManualReviewActionData instance) => <String, dynamic>{
  'message': instance.message,
  'submitLabel': instance.submitLabel,
  'canSubmit': instance.canSubmit,
  'rule': _$ManualReviewPromptDisplayRuleEnumMap[instance.rule]!,
  'confirmationDialogTitle': instance.confirmationDialogTitle,
  'confirmationDialogMessage': instance.confirmationDialogMessage,
};

const _$ManualReviewPromptDisplayRuleEnumMap = {
  ManualReviewPromptDisplayRule.IMMEDIATELY: 'IMMEDIATELY',
  ManualReviewPromptDisplayRule.NOT_LOGIN: 'NOT_LOGIN',
  ManualReviewPromptDisplayRule.TIMEOUT: 'TIMEOUT',
};
