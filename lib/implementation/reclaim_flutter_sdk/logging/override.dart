import 'dart:async';

import '../data/identity.dart';
import '../overrides/override.dart';

import 'logging.dart';

typedef LogRecordCallback
    = FutureOr<bool>
        Function(
  LogRecord
      record,
  SessionIdentity?
      identity,
);
typedef LogLevelChangedCallback
    = FutureOr<void>
        Function(Level? level);
typedef GetLevelCallback
    = FutureOr<Level>
        Function();

final class LogLevelChangeHandler {
  final LogLevelChangedCallback
      onLevelChanged;
  final GetLevelCallback
      getLevel;

  const LogLevelChangeHandler({
    required this.onLevelChanged,
    required this.getLevel,
  });
}

class LogConsumerOverride
    extends ReclaimOverride<
        LogConsumerOverride> {
  final bool
      canPrintLogs;
  // Return true if default behaviour in the sdk should also occur
  final LogRecordCallback?
      onRecord;
  // Return true if default behaviour in the sdk should also occur
  final LogLevelChangeHandler?
      levelChangeHandler;

  const LogConsumerOverride({
    this.canPrintLogs =
        reclaimCanPrintDebugLogs,
    this.onRecord,
    this.levelChangeHandler,
  });

  @override
  LogConsumerOverride
      copyWith({
    bool?
        canPrintLogs,
    LogRecordCallback?
        onRecord,
    LogLevelChangeHandler?
        levelChangeHandler,
  }) {
    return LogConsumerOverride(
      canPrintLogs:
          canPrintLogs ?? this.canPrintLogs,
      onRecord:
          onRecord ?? this.onRecord,
      levelChangeHandler:
          levelChangeHandler ?? this.levelChangeHandler,
    );
  }
}
