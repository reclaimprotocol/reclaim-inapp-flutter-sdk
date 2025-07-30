import 'package:flutter/widgets.dart';

import '../controller.dart';
import '../data/identity.dart';
import '../repository/feature_flags.dart';

class FeatureFlagsProvider {
  final SessionIdentity identity;
  final FeatureFlagRepository _repository;

  FeatureFlagsProvider(this.identity, {FeatureFlagRepository? repository})
    : _repository = repository ?? FeatureFlagRepository();

  static Future<FeatureFlagsProvider> readAfterSessionStartedOf(BuildContext context) async {
    final controller = VerificationController.readOf(context);
    final session = await controller.sessionStartFuture;
    return FeatureFlagsProvider(session.identity);
  }

  factory FeatureFlagsProvider.readOf(BuildContext context) {
    final controller = VerificationController.readOf(context);
    return FeatureFlagsProvider(controller.identity);
  }

  Stream<T> stream<T>(FeatureFlag<T> flag) {
    return _repository.watchFeatureFlag(identity, flag);
  }

  Future<T> get<T>(FeatureFlag<T> flag) {
    return _repository.getFeatureFlag(identity, flag);
  }

  Future<void> set<T>(FeatureFlag<T> flag, T value) {
    return _repository.setFeatureFlag(identity, flag, value);
  }
}
