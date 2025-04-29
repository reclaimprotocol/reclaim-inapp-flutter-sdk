class ReclaimVerificationResponse {
  final String sessionId;
  final List<Map<String, Object?>> proofs;

  const ReclaimVerificationResponse({required this.sessionId, required this.proofs});

  factory ReclaimVerificationResponse.fromJson(Map json) {
    return ReclaimVerificationResponse(sessionId: json['sessionId'], proofs: json['proofs']);
  }

  Map<String, dynamic> toJson() {
    return {'sessionId': sessionId, 'proofs': proofs};
  }
}
