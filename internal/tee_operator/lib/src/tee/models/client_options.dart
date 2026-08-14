/// Client configuration options for TEE protocol
/// Separating connection URLs and configuration from request data
class ClaimCreationClientOptions {
  /// URL of the TEE router service
  /// Default: https://tee.reclaimprotocol.org
  final String routerUrl;

  /// URL of the attestor service
  /// Default: wss://attestor.reclaimprotocol.org:444/ws
  final String attestorUrl;

  const ClaimCreationClientOptions({required this.routerUrl, required this.attestorUrl});

  Map<String, dynamic> toJson() {
    return {'routerUrl': routerUrl, 'attestorUrl': attestorUrl};
  }

  factory ClaimCreationClientOptions.fromJson(Map<String, dynamic> json) {
    return ClaimCreationClientOptions(
      routerUrl: json['routerUrl'] as String? ?? '',
      attestorUrl: json['attestorUrl'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'ClaimCreationClientOptions('
        'routerUrl: $routerUrl, '
        'attestorUrl: $attestorUrl'
        ')';
  }
}
