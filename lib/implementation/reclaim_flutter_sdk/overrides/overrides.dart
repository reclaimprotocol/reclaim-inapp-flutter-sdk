import '../data/providers_override.dart'
    show
        ReclaimProviderOverride;
import '../logging/override.dart'
    show
        LogConsumerOverride;
import '../services/capability/access_token.dart'
    show
        CapabilityAccessToken;
import '../types/app_info.dart'
    show
        AppInfo;
import '../types/feature_flag_data.dart'
    show
        ReclaimFeatureFlagData;
import '../utils/session/session_override.dart'
    show
        ReclaimSessionOverride;
import 'override.dart';

export '../data/providers_override.dart'
    show
        ReclaimProviderOverride;
export '../logging/override.dart'
    show
        LogConsumerOverride;
export '../types/app_info.dart'
    show
        AppInfo;
export '../types/feature_flag_data.dart'
    show
        ReclaimFeatureFlagData;
export '../utils/session/session_override.dart'
    show
        ReclaimSessionOverride;

export 'override.dart';

interface class ReclaimOverrides {
  static ReclaimFeatureFlagData?
      get featureFlag {
    return ReclaimOverride.get<
        ReclaimFeatureFlagData>();
  }

  static ReclaimProviderOverride?
      get provider {
    return ReclaimOverride.get<
        ReclaimProviderOverride>();
  }

  static LogConsumerOverride?
      get logsConsumer {
    return ReclaimOverride.get<
        LogConsumerOverride>();
  }

  static ReclaimSessionOverride?
      get session {
    return ReclaimOverride.get<
        ReclaimSessionOverride>();
  }

  static AppInfo?
      get appInfo {
    return ReclaimOverride.get<
        AppInfo>();
  }

  static CapabilityAccessToken?
      get capabilityAccessToken {
    return ReclaimOverride.get<
        CapabilityAccessToken>();
  }
}
