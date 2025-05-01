import 'override.dart';

import 'package:reclaim_flutter_sdk/data/providers_override.dart' show ReclaimProviderOverride;
import 'package:reclaim_flutter_sdk/types/app_info.dart' show AppInfo;
import 'package:reclaim_flutter_sdk/types/feature_flag_data.dart' show ReclaimFeatureFlagData;
import 'package:reclaim_flutter_sdk/logging/override.dart' show LogConsumerOverride;
import 'package:reclaim_flutter_sdk/services/capability/access_token.dart'
    show CapabilityAccessToken;
import 'package:reclaim_flutter_sdk/utils/session/session_override.dart'
    show ReclaimSessionOverride;
export 'package:reclaim_flutter_sdk/data/providers_override.dart' show ReclaimProviderOverride;
export 'package:reclaim_flutter_sdk/types/app_info.dart' show AppInfo;
export 'package:reclaim_flutter_sdk/types/feature_flag_data.dart' show ReclaimFeatureFlagData;
export 'package:reclaim_flutter_sdk/logging/override.dart' show LogConsumerOverride;
export 'package:reclaim_flutter_sdk/utils/session/session_override.dart'
    show ReclaimSessionOverride;

export 'override.dart';

interface class ReclaimOverrides {
  static ReclaimFeatureFlagData? get featureFlag {
    return ReclaimOverride.get<ReclaimFeatureFlagData>();
  }

  static ReclaimProviderOverride? get provider {
    return ReclaimOverride.get<ReclaimProviderOverride>();
  }

  static LogConsumerOverride? get logsConsumer {
    return ReclaimOverride.get<LogConsumerOverride>();
  }

  static ReclaimSessionOverride? get session {
    return ReclaimOverride.get<ReclaimSessionOverride>();
  }

  static AppInfo? get appInfo {
    return ReclaimOverride.get<AppInfo>();
  }

  static CapabilityAccessToken? get capabilityAccessToken {
    return ReclaimOverride.get<CapabilityAccessToken>();
  }
}
