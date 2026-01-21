import 'package:logging/logging.dart';
export 'package:logging/logging.dart';

final sdkLogger = Logger('reclaim_inapp_sdk.reclaim_tee_operator');

extension SdkLoggerExtension on Logger {
  Logger child(String name) {
    return Logger('$fullName.$name');
  }
}
