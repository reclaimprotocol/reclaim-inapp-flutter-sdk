import 'src/logging/logging.dart';

export 'src/logging/data/log.dart' show LogEntry;
export 'src/logging/event_type.dart' show LogEventType;
export 'src/logging/logging.dart' show LevelExtension, LevelWithEvent, LoggerExtension;
export 'src/services/source/source.dart' show ClientSource;

void startReclaimSdkLogging() {
  logging;
}
