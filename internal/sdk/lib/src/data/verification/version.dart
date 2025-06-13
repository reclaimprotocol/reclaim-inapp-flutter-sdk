sealed class ProviderVersion {
  String get versionExpression;

  const ProviderVersion();

  static const any = ProviderVersion.constraint('');

  const factory ProviderVersion.constraint(String versionExpression) = ProviderVersionConstraint;

  const factory ProviderVersion.exact(String resolvedVersion, {String? versionExpression}) = ProviderVersionExact;
}

final class ProviderVersionConstraint implements ProviderVersion {
  @override
  final String versionExpression;

  const ProviderVersionConstraint(this.versionExpression);

  ProviderVersionExact asExact() {
    return ProviderVersionExact('', versionExpression: versionExpression);
  }
}

final class ProviderVersionExact implements ProviderVersion {
  @override
  final String versionExpression;

  final String resolvedVersion;

  const ProviderVersionExact(this.resolvedVersion, {String? versionExpression})
    : versionExpression = versionExpression ?? resolvedVersion;
}
