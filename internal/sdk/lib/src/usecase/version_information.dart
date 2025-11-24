import 'package:flutter/foundation.dart';

import '../exception/exception.dart';
import '../logging/logging.dart';
import '../services/version.dart';

class SDKVersionInformation {
  static SDKUpdateRequirementType? cachedUpdateRequirement;

  Future<void> verifyUpdateRequirement() async {
    final logger = logging.child('SDKVersionInformation.verifyUpdateRequirement');
    if (cachedUpdateRequirement != null) {
      await Future.microtask(() => null);
    }
    cachedUpdateRequirement ??= await VersionInformationService().getUpdateRequirement();

    switch (cachedUpdateRequirement) {
      case SDKUpdateRequirementType.immediate:
        const message =
            '⚠️🚨 An update for inapp SDK is available. The current version cannot be used anymore, please update the inapp SDK version used by this app to ensure support.';
        logger.event(Level.SEVERE.withEvent(LogEventType.SDK_OUTDATED), message);
        debugPrint(message);
        throw const ReclaimVerificationOutdatedSDKException();
      case SDKUpdateRequirementType.flexible:
        const message =
            '⚠️ An update for inapp SDK is available. Please update the inapp SDK version used by this app to ensure support.';
        logger.event(Level.WARNING.withEvent(LogEventType.UPDATE_AVAILABLE), message);
        debugPrint(message);
        return;
      case SDKUpdateRequirementType.none:
      case null:
        return;
    }
  }
}
