enum ClaimCreationType {
  standalone('createClaim'),
  meChain('createClaimOnMechain');

  const ClaimCreationType(this.type);

  final String type;

  static const ClaimCreationType defaultValue = ClaimCreationType.standalone;
}
