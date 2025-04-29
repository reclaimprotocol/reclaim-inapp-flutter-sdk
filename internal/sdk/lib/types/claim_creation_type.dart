enum ClaimCreationType {
  standalone('createClaim'),
  onMeChain('createClaimOnMechain');

  const ClaimCreationType(this.type);

  final String type;

  static const ClaimCreationType defaultValue = ClaimCreationType.standalone;
}
