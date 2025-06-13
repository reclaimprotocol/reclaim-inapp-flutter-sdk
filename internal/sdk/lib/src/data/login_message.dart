import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../logging/logging.dart';

part 'login_message.g.dart';

String? _nonBlankStringFromJson(Object? o) {
  if (o is! String) return null;
  final it = o.trim();
  if (it.isEmpty) return null;
  return it;
}

@JsonSerializable()
class LoginPromptActionData {
  @JsonKey(fromJson: _nonBlankStringFromJson)
  final String? message;
  @JsonKey(fromJson: _nonBlankStringFromJson)
  final String? ctaLabel;

  static final _logging = logging.child('LoginPromptActionData');

  const LoginPromptActionData({required this.message, required this.ctaLabel});

  factory LoginPromptActionData.fromJson(Map<String, dynamic> json) => _$LoginPromptActionDataFromJson(json);

  Map<String, dynamic> toJson() => _$LoginPromptActionDataToJson(this);

  static LoginPromptActionData? fromString(String? jsonString) {
    try {
      if (jsonString == null || jsonString.isEmpty) return null;
      final jsonMap = json.decode(jsonString);
      return LoginPromptActionData.fromJson(jsonMap);
    } catch (e, s) {
      _logging.warning('Failed to parse manual review action data', e, s);
    }
    return null;
  }

  @override
  String toString() {
    return 'LoginPromptActionData(message: $message, submitLabel: $ctaLabel)';
  }
}
