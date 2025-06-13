import 'package:json_annotation/json_annotation.dart';

part 'session_init.g.dart';

@JsonSerializable()
class SessionInitResponse {
  @JsonKey(defaultValue: '')
  final String sessionId;
  final String? resolvedProviderVersion;

  const SessionInitResponse({required this.sessionId, required this.resolvedProviderVersion});

  factory SessionInitResponse.fromJson(Map<String, dynamic> json) => _$SessionInitResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SessionInitResponseToJson(this);
}
