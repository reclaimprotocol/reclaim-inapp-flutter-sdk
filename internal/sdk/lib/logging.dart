import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import 'src/logging/logging.dart';

export 'src/logging/data/log.dart' show LogEntry;
export 'src/logging/event_type.dart' show LogEventType;
export 'src/logging/logging.dart' show LevelExtension, LevelWithEvent, LoggerExtension, metadataLoggingEnabled;
export 'src/services/source/source.dart' show ClientSource;

void startReclaimSdkLogging() {
  logging;
}

void setLoggingLevel(String level) {
  final requestedLevel = Level.LEVELS.firstWhereOrNull((it) => it.name.toLowerCase() == level.trim().toLowerCase());
  if (requestedLevel == null) {
    debugPrintThrottled(
      'setLoggingLevel was invoked with an unknown value: $level. Available levels: ${Level.LEVELS.map((e) => e.name).join(', ')}',
    );
    return;
  }
  logging.level = requestedLevel;
}
