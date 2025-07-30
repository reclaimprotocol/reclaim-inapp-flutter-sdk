import 'package:json_annotation/json_annotation.dart';

import 'binary.dart';

part 'auth.g.dart';

/// {@template AttestorAuthenticationRequest}
/// An authentication request, if provided, will be used in the claim creation request.
/// This is used by attestor to authenticate the client.
/// {@endtemplate}
@JsonSerializable()
class AttestorAuthenticationRequest {
  final Map<String, Object?> data;
  final AttestorBinaryData? signature;

  const AttestorAuthenticationRequest({required this.data, required this.signature});

  factory AttestorAuthenticationRequest.fromJson(Map<String, dynamic> json) =>
      _$AttestorAuthenticationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AttestorAuthenticationRequestToJson(this);

  @override
  String toString() {
    return 'AttestorAuthenticationRequest(data: <redacted>, signature: $signature)';
  }
}
