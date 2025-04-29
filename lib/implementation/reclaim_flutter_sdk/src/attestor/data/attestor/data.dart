import 'package:json_annotation/json_annotation.dart';

part 'data.g.dart';

/// Represents a typed data with a type and optional value.
///
/// This class is used for serializing and deserializing
/// typed data known to the attestor in RPC messages
/// between the client and attestor.

@JsonSerializable()
class AttestorData {
  /// The type of the data.
  final String
      type;

  /// The value of the data.
  final String?
      value;

  const AttestorData(
      {required this.type,
      required this.value});

  factory AttestorData.fromJson(Map<String, dynamic> json) =>
      _$AttestorDataFromJson(json);

  Map<String,
          dynamic>
      toJson() =>
          _$AttestorDataToJson(this);
}
