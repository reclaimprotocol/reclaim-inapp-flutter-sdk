class ReclaimVerificationRequest {
  final String appId;
  final String secret;
  final String providerId;

  const ReclaimVerificationRequest({required this.appId, required this.secret, required this.providerId});

  factory ReclaimVerificationRequest.fromJson(Map<String, dynamic> json) {
    return ReclaimVerificationRequest(appId: json['appId'], secret: json['secret'], providerId: json['providerId']);
  }

  Map<String, dynamic> toJson() {
    return {'appId': appId, 'secret': secret, 'providerId': providerId};
  }
}
