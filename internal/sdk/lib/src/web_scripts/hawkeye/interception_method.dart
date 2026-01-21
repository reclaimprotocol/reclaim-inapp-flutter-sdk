import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'interception_method.g.dart';

enum HawkeyeInterceptionMethod {
  PROXY,
  DIRECT_REPLACEMENT,
  GETTER_SETTER;

  static const defaultMethod = HawkeyeInterceptionMethod.PROXY;

  static HawkeyeInterceptionMethod fromString(String? value) {
    return switch (value?.toUpperCase()) {
      'PROXY' => HawkeyeInterceptionMethod.PROXY,
      'DIRECT_REPLACEMENT' => HawkeyeInterceptionMethod.DIRECT_REPLACEMENT,
      'GETTER_SETTER' => HawkeyeInterceptionMethod.GETTER_SETTER,
      _ => defaultMethod,
    };
  }

  bool get useProxyForFetch => this == HawkeyeInterceptionMethod.PROXY;
  bool get useGetterForFetch => this == HawkeyeInterceptionMethod.GETTER_SETTER;
}

@JsonSerializable()
class HawkeyeInterceptionOptions {
  @JsonKey(defaultValue: true)
  final bool disableFormIntercept;
  @JsonKey(defaultValue: false)
  final bool delayFormSubmitForFetch;
  @JsonKey(defaultValue: HawkeyeInterceptionMethod.PROXY)
  final HawkeyeInterceptionMethod interceptionMethod;

  const HawkeyeInterceptionOptions({
    this.disableFormIntercept = true,
    this.delayFormSubmitForFetch = false,
    this.interceptionMethod = HawkeyeInterceptionMethod.PROXY,
  });

  factory HawkeyeInterceptionOptions.fromJson(Map<String, dynamic> json) => _$HawkeyeInterceptionOptionsFromJson(json);
  factory HawkeyeInterceptionOptions.fromString(String? jsonString) {
    return HawkeyeInterceptionOptions.fromJson(json.decode(jsonString ?? '{}'));
  }

  Map<String, dynamic> toJson() => _$HawkeyeInterceptionOptionsToJson(this);

  HawkeyeInterceptionOptions copyWith({
    bool? disableFormIntercept,
    bool? delayFormSubmitForFetch,
    HawkeyeInterceptionMethod? interceptionMethod,
  }) {
    return HawkeyeInterceptionOptions(
      disableFormIntercept: disableFormIntercept ?? this.disableFormIntercept,
      delayFormSubmitForFetch: delayFormSubmitForFetch ?? this.delayFormSubmitForFetch,
      interceptionMethod: interceptionMethod ?? this.interceptionMethod,
    );
  }

  @override
  String toString() {
    return 'HawkeyeInterceptionOptions(disableFormIntercept: $disableFormIntercept, delayFormSubmitForFetch: $delayFormSubmitForFetch, interceptionMethod: $interceptionMethod)';
  }
}
