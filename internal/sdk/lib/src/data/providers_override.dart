import 'dart:async';

import '../overrides/override.dart';

import 'providers.dart';

typedef ProviderInformationCallback =
    FutureOr<HttpProvider> Function({
      required String appId,
      required String providerId,
      required String sessionId,
      required String signature,
      required String timestamp,
    });

class ReclaimProviderOverride extends ReclaimOverride<ReclaimProviderOverride> {
  /// Override the reclaim http provider to use for verification.
  /// When null, default provider from reclaim is fetched using session information like appId, providerId.
  final ProviderInformationCallback? fetchProviderInformation;

  const ReclaimProviderOverride({required this.fetchProviderInformation});

  @override
  ReclaimProviderOverride copyWith({ProviderInformationCallback? fetchProviderInformation}) {
    return ReclaimProviderOverride(fetchProviderInformation: fetchProviderInformation ?? this.fetchProviderInformation);
  }
}
