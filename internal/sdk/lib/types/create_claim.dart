import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:reclaim_flutter_sdk/data/providers.dart';
part 'create_claim.g.dart';

@JsonSerializable()
class ProviderClaimData {
  final String provider;
  final String parameters;
  final String owner;
  final int timestampS;
  final String context;
  final String identifier;
  final int epoch;

  ProviderClaimData({
    required this.provider,
    required this.parameters,
    required this.owner,
    required this.timestampS,
    required this.context,
    required this.identifier,
    required this.epoch,
  });

  factory ProviderClaimData.fromJson(Map<String, dynamic> json) =>
      _$ProviderClaimDataFromJson(json);

  Map<String, dynamic> toJson() => _$ProviderClaimDataToJson(this);
}

@JsonSerializable()
class WitnessData {
  final String id;
  final String url;

  WitnessData({required this.id, required this.url});

  factory WitnessData.fromJson(Map<String, dynamic> json) =>
      _$WitnessDataFromJson(json);

  Map<String, dynamic> toJson() => _$WitnessDataToJson(this);
}

@JsonSerializable()
class CreateClaimOutput {
  final String identifier;
  final ProviderClaimData claimData;
  final List<String> signatures;
  final List<WitnessData> witnesses;
  final int? taskId;
  Object? publicData;
  DataProviderRequest? providerRequest;

  CreateClaimOutput({
    required this.identifier,
    required this.claimData,
    required this.signatures,
    required this.witnesses,
    required this.publicData,
    required this.providerRequest,
    this.taskId,
  });

  CreateClaimOutput copyWithTaskId({int? taskId}) {
    return CreateClaimOutput(
      identifier: identifier,
      claimData: claimData,
      signatures: signatures,
      witnesses: witnesses,
      publicData: publicData,
      providerRequest: providerRequest,
      taskId: taskId,
    );
  }

  factory CreateClaimOutput.fromJson(Map<String, dynamic> json) =>
      _$CreateClaimOutputFromJson(json);

  Map<String, dynamic> toJson() => _$CreateClaimOutputToJson(this);

  static List<CreateClaimOutput> fromMeChainJson(Map<String, dynamic> json) {
    final taskId = json['taskId'] as int;
    final data = json['data'] as List<dynamic>;

    return data.map((item) {
      final createClaimOutput = CreateClaimOutput.fromJson(item);
      return createClaimOutput.copyWithTaskId(taskId: taskId);
    }).toList();
  }
}

@immutable
class ExtractedData {
  final String url;
  final Map<String, String> headers;
  final String cookies;
  final String requestBody;
  final String method;
  final List<ResponseRedaction> responseRedactions;
  final Map<String, String> witnessParams;
  final List<ResponseMatch> responseMatches;
  final String? geoLocation;

  const ExtractedData({
    required this.url,
    required this.headers,
    required this.cookies,
    required this.requestBody,
    required this.method,
    required this.responseRedactions,
    required this.witnessParams,
    required this.responseMatches,
    this.geoLocation,
  });

  ExtractedData copyWith({
    String? url,
    Map<String, String>? headers,
    String? cookies,
    String? requestBody,
    String? method,
    List<ResponseRedaction>? responseRedactions,
    Map<String, String>? witnessParams,
    List<ResponseMatch>? responseMatches,
    String? geoLocation,
  }) {
    return ExtractedData(
      url: url ?? this.url,
      headers: headers ?? this.headers,
      cookies: cookies ?? this.cookies,
      requestBody: requestBody ?? this.requestBody,
      method: method ?? this.method,
      responseRedactions: responseRedactions ?? this.responseRedactions,
      witnessParams: witnessParams ?? this.witnessParams,
      responseMatches: responseMatches ?? this.responseMatches,
      geoLocation: geoLocation ?? this.geoLocation,
    );
  }
}

class StepMeta {
  final String title;
  final int iconIndex;

  const StepMeta({required this.title, required this.iconIndex});
}
