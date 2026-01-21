/// Claim model returned from the attestor
class ReclaimClaim {
  final String identifier;
  final String owner;
  final String provider;
  final String parameters;
  final String? context;
  final int timestampS;
  final int epoch;
  final bool success;
  final String? error;

  const ReclaimClaim({
    required this.identifier,
    required this.owner,
    required this.provider,
    required this.parameters,
    this.context,
    required this.timestampS,
    required this.epoch,
    required this.success,
    this.error,
  });

  factory ReclaimClaim.fromJson(Map<String, dynamic> json) {
    // The Go library returns: { claim: {...}, signatures: [...] }
    final claimData = json['claim'] as Map<String, dynamic>;

    return ReclaimClaim(
      identifier: claimData['identifier'] as String? ?? '',
      owner: claimData['owner'] as String? ?? '',
      provider: claimData['provider'] as String? ?? '',
      parameters: claimData['parameters'] as String? ?? '',
      context: claimData['context'] as String?,
      timestampS: (claimData['timestamp_s'] as num?)?.toInt() ?? 0,
      epoch: (claimData['epoch'] as num?)?.toInt() ?? 0,
      success: true,
      error: claimData['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'identifier': identifier,
    'owner': owner,
    'provider': provider,
    'parameters': parameters,
    if (context != null) 'context': context,
    'timestamp_s': timestampS,
    'epoch': epoch,
    'success': success,
    if (error != null) 'error': error,
  };

  @override
  String toString() {
    return 'ReclaimClaim('
        'identifier: $identifier, '
        'owner: $owner, '
        'provider: $provider, '
        'timestampS: $timestampS, '
        'epoch: $epoch, '
        'success: $success'
        ')';
  }
}
