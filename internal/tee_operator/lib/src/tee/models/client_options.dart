/// Client configuration options for TEE protocol
/// Separating connection URLs and configuration from request data
class ClaimCreationClientOptions {
  /// URL of the attestor service
  /// Default: ws://localhost:8001/ws
  final String? attestorUrl;

  /// URL of the TEE_K service
  /// Default: wss://tee-k.reclaimprotocol.org/ws
  final String? teekUrl;

  /// URL of the TEE_T service
  /// Default: wss://tee-t.reclaimprotocol.org/ws
  final String? teetUrl;

  const ClaimCreationClientOptions({this.attestorUrl, this.teekUrl, this.teetUrl});

  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{};
    if (attestorUrl != null) result['attestorUrl'] = attestorUrl;
    if (teekUrl != null) result['teekUrl'] = teekUrl;
    if (teetUrl != null) result['teetUrl'] = teetUrl;
    return result;
  }

  factory ClaimCreationClientOptions.fromJson(Map<String, dynamic> json) {
    return ClaimCreationClientOptions(
      attestorUrl: json['attestorUrl'] as String?,
      teekUrl: json['teekUrl'] as String?,
      teetUrl: json['teetUrl'] as String?,
    );
  }

  @override
  String toString() {
    return 'ClaimCreationClientOptions('
        'attestorUrl: $attestorUrl, '
        'teekUrl: $teekUrl, '
        'teetUrl: $teetUrl'
        ')';
  }
}
