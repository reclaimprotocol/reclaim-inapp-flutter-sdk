import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../attestor.dart';
import '../build_env.dart';
import '../data/identity.dart';
import '../overrides/overrides.dart';
import '../services/logging.dart';
import '../services/preferences/preference.dart';
import '../utils/sanitize.dart';
import 'data/log.dart';
import 'event_type.dart';

export 'package:logging/logging.dart';
export 'event_type.dart';

/// This is the logger we use in the sdk
final Logger logging = _createSdkLogger();

typedef ThrowErrorCallback = Exception Function();

class LevelWithEvent extends Level {
  final LogEventType eventType;
  final Level level;

  LevelWithEvent(this.level, this.eventType) : super(level.name, level.value);
}

extension LevelExtension on Level {
  LevelWithEvent withEvent(LogEventType eventType) {
    return LevelWithEvent(this, eventType);
  }
}

extension LoggerExtension on Logger {
  /// Create a new child [Logging] instance with a [name].
  ///
  /// The full name of this new Logging will be this logging's full name + the [name].
  Logger child(String name) {
    return Logger('$fullName.$name');
  }

  void debug(Object? message, [Level? level]) {
    final canUseInfo = kDebugMode || (!kIsWeb && BuildEnv.IS_FLUTTER_TEST);
    log(canUseInfo ? Level.INFO : (level ?? Level.FINEST), message);
  }

  /// Log with an event type
  ///
  /// ```dart
  /// log.event(Level.INFO.withEvent(LogEventType.pass), 'message');
  /// ```
  void event(LevelWithEvent levelEvent, Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(levelEvent, message, error, stackTrace);

  bool get isDebugging => level < Level.INFO || kDebugMode;
}

Logger _createSdkLogger() {
  WidgetsFlutterBinding.ensureInitialized();

  hierarchicalLoggingEnabled = true;

  // don't use logging inside this function, use l instead
  final l = Logger('reclaim_inapp_sdk');

  l.onRecord.listen(_onLoggingLogRecord);

  if (BuildEnv.IS_FLUTTER_TEST) {
    l.level = Level.ALL;
  } else {
    unawaited(
      _logLevelPreference.value.then((value) async {
        final effectiveLevel = await () async {
          try {
            final getLevel = ReclaimOverrides.logsConsumer?.levelChangeHandler?.getLevel;
            if (getLevel != null) {
              return await getLevel();
            }
          } catch (e, s) {
            logging.severe('Failed to get effective log level', e, s);
          }
          return value ?? Level.INFO;
        }();
        l.level = effectiveLevel;
        _onLoggingLogLevelChanged(effectiveLevel);
        l.onLevelChanged.listen(_onLoggingLogLevelChanged);
      }),
    );
  }

  final platformDispatcherLogger = l.child('PlatformDispatcher');
  final previousPlatformDispatcherErrorHandler = PlatformDispatcher.instance.onError;
  // log unhandled errors
  PlatformDispatcher.instance.onError = (e, s) {
    platformDispatcherLogger.severe('Failed', e, s);
    final previousHandler = previousPlatformDispatcherErrorHandler;
    if (previousHandler != null) {
      return previousHandler(e, s);
    }
    return true;
  };

  final flutterErrorLogger = l.child('FlutterError');
  final previousFlutterErrorHandler = FlutterError.onError;
  FlutterError.onError = (error) {
    flutterErrorLogger.warning(error.toString(), error.exception, error.stack);
    previousFlutterErrorHandler?.call(error);
  };

  // an always alive periodic timer
  _uploadDiagnosticLogsPeriodic();

  return l;
}

Future<bool> _canAppSeeConsoleLogs() async {
  if (BuildEnv.IS_FLUTTER_TEST) {
    return true;
  }

  final packageInfo = await PackageInfo.fromPlatform();
  return switch (packageInfo.packageName) {
    'org.reclaimprotocol.app' => true,
    'org.reclaimprotocol.app.clip' => true,
    'com.reclaim.example' => true,
    _ => false,
  };
}

typedef _BufferLogEntry = ({LogRecord record, SessionIdentity? identity});

List<_BufferLogEntry> _buffer = [];

void _onLoggingLogRecord(LogRecord record) async {
  try {
    // Only print logs if not release mode and app is allowed (when not overriden)
    final canPrintLogs =
        (ReclaimOverrides.logsConsumer?.canPrintLogs ?? (!kReleaseMode && await _canAppSeeConsoleLogs()));
    if (canPrintLogs) {
      _onLogsToConsole(record);
    }

    final onRecord = ReclaimOverrides.logsConsumer?.onRecord;
    if (onRecord != null) {
      final entry = LogEntry.fromRecord(
        record,
        SessionIdentity.latest,
        fallbackSessionIdentity: const SessionIdentity(appId: '', providerId: '', sessionId: ''),
      );
      final canHandleLogs = await onRecord(entry);
      if (!canHandleLogs) {
        // the sdk will not use this log record
        return;
      }
    }
    _buffer.add((record: record, identity: SessionIdentity.latest));

    // Trim buffer to prevent unbounded memory growth if uploads fail or back up
    if (_buffer.length > 2000) {
      _buffer.removeRange(0, _buffer.length - 2000);
    }
  } catch (e, s) {
    debugPrint(e.toString());
    debugPrintStack(stackTrace: s);
  }
}

final Preference<Level?, int> _logLevelPreference = Preference(
  key: 'reclaim_flutter_sdk#log_level',
  transformer: ValueTransformer(
    fromEncodable: (value) {
      if (value is! int) return null;

      for (var level in Level.LEVELS) {
        if (level.value == value) {
          return level;
        }
      }
      return Level(value.toString(), value);
    },
    toEncodable: (value) {
      return value?.value;
    },
  ),
);

bool? _oldIsDebug;
void _onLoggingLogLevelChanged(Level? level) async {
  final setLevel = ReclaimOverrides.logsConsumer?.levelChangeHandler?.onLevelChanged;
  if (setLevel != null) {
    setLevel(level);
  } else {
    _logLevelPreference.setValue(level);
  }

  final isDebug = level != null && level < Level.INFO;
  if (isDebug != _oldIsDebug) {
    _oldIsDebug = isDebug;
    final attestorCoreLogLevel = isDebug ? 'debug' : 'info';
    Attestor.instance.setAttestorDebugLevel(attestorCoreLogLevel);
  }
}

const Duration _diagnosticLogUploadInterval = Duration(seconds: 5);
Timer? diagnosticLogUploadTimer;

// global private variable to keep the http connection alive
final _loggingService = DiagnosticLogging();

List<LogEntry> _processLogsInBackground(Map<String, dynamic> params) {
  final List<dynamic> rawLogs = params['logs'];
  final Map<String, dynamic> fallbackJson = params['fallbackIdentity'];
  final fallbackIdentity = SessionIdentity(
    appId: fallbackJson['appId'] as String? ?? '',
    providerId: fallbackJson['providerId'] as String? ?? '',
    sessionId: fallbackJson['sessionId'] as String? ?? '',
  );

  final List<LogEntry> entries = [];
  for (final raw in rawLogs) {
    try {
      final rawIdentity = raw['identity'] as Map<String, dynamic>?;
      SessionIdentity? identity;
      if (rawIdentity != null) {
        identity = SessionIdentity(
          appId: rawIdentity['appId'] as String? ?? '',
          providerId: rawIdentity['providerId'] as String? ?? '',
          sessionId: rawIdentity['sessionId'] as String? ?? '',
        );
      }

      final int safeLength = 2000;
      final message = LogEntry.truncateLogString(raw['message'] as String, maxLength: safeLength);
      final logLineBuffer = StringBuffer(message);

      final errorStr = raw['errorStr'] as String?;
      if (errorStr != null) {
        logLineBuffer.write('\n');
        logLineBuffer.writeln(LogEntry.truncateLogString(errorStr, maxLength: safeLength));
        final stackTraceStr = raw['stackTraceStr'] as String?;
        if (stackTraceStr != null) {
          logLineBuffer.write('\n');
          logLineBuffer.writeln(LogEntry.truncateLogString(stackTraceStr, maxLength: safeLength));
        }
      }

      final int levelValue = raw['levelValue'] as int;
      final messageToSanitize = logLineBuffer.toString();
      final logLine = levelValue > Level.FINE.value ? sanitizeLogMessage(messageToSanitize) : messageToSanitize;

      LogEventType? eventType;
      final eventTypeStr = raw['eventType'] as String?;
      if (eventTypeStr != null) {
        eventType = LogEventType.values.firstWhere((e) => e.name == eventTypeStr, orElse: () => LogEventType.PASS);
      }

      entries.add(
        LogEntry(
          sessionIdentity: fallbackIdentity.merge(identity),
          logLine: logLine,
          sequence: raw['sequenceNumber'] as int,
          type: raw['loggerName'] as String,
          eventType: eventType,
          time: DateTime.fromMillisecondsSinceEpoch(raw['timeMs'] as int),
          logLevel: LogEntryLogLevel.fromLoggingLevel(Level('temp', levelValue)),
        ),
      );
    } catch (e) {
      // Ignore corrupted map structs natively skipping
    }
  }
  return entries;
}

Future<void> uploadDiagnosticLogs({SessionIdentity? sessionIdentityFallack}) async {
  final SessionIdentity identity;
  SessionIdentity? latest = SessionIdentity.latest;
  if (latest == null || latest.sessionId.isEmpty) {
    final fallback = sessionIdentityFallack;
    if (fallback == null) {
      // wait for session id to get generated
      return;
    }
    // use the fallback session identity if available
    identity = fallback;
  } else {
    identity = latest;
  }

  if (_buffer.isEmpty) {
    // no logs to upload
    return;
  }

  final logs = _buffer;
  _buffer = [];

  // Limit oversized payloads — defer excess entries to next upload cycle
  // Uses a safe chunk limit to avoid exponential UTF-8 JSON encoding overhead
  try {
    while (logs.length > 500) {
      final e = logs.removeLast();
      _buffer.add(e);
    }
  } catch (e, s) {
    logging.severe('Failed to constrain payload bounds', e, s);
  }

  // Dump unstructured dictionaries for Thread passage isolating the Memory Heap
  final rawLogs = logs.map((e) {
    return {
      'levelValue': e.record.level.value,
      'message': e.record.message,
      'loggerName': e.record.loggerName,
      'timeMs': e.record.time.millisecondsSinceEpoch,
      'sequenceNumber': e.record.sequenceNumber,
      'errorStr': e.record.error?.toString(),
      'stackTraceStr': e.record.stackTrace != null
          ? LogEntry.formatStackTrace(stackTrace: e.record.stackTrace, maxFrames: 20)
          : null,
      'eventType': e.record.level is LevelWithEvent ? (e.record.level as LevelWithEvent).eventType.name : null,
      'identity': e.identity?.toJson(),
    };
  }).toList();

  final payload = {'logs': rawLogs, 'fallbackIdentity': identity.toJson()};

  try {
    // Process heavy strings and array mappings on background Isolate! CPU stays idle here.
    final entries = await compute(_processLogsInBackground, payload);
    _loggingService.sendLogs(entries);
  } catch (e, s) {
    logging.severe('Failed to compute background logs', e, s);
  }

  // F-054: Zero buffer contents after upload
  logs.clear();
}

void _uploadDiagnosticLogsPeriodic() async {
  try {
    await uploadDiagnosticLogs();
  } catch (e, s) {
    logging.severe('Failed to upload diagnostic logs', e, s);
    // don't reinsert failed logs in the buffer again. ReclaimHttpClients will have retried on errors.
    // this is why we aren't awaiting to avoid blocking other logs from being uploaded.
  } finally {
    // schedule the next upload
    diagnosticLogUploadTimer = Timer(_diagnosticLogUploadInterval, _uploadDiagnosticLogsPeriodic);
  }
}

final _logDateFormat = DateFormat('hh:mm:ss aa');

void _onLogsToConsole(LogRecord record) {
  final formattedTime = _logDateFormat.format(record.time);

  final label = '$formattedTime ${record.level.name} ${record.loggerName} (${record.sequenceNumber})';

  final message = record.message;
  debugPrintThrottled('$label ${LogEntry.truncateLogString(message)}'.trim());
  final error = record.error;
  if (error != null) {
    debugPrintThrottled('$label [Error] ${LogEntry.truncateLogString(error.toString())}');
  }
  if (record.level >= Level.WARNING) {
    debugPrintThrottled(label);
    debugPrintThrottled(LogEntry.formatStackTrace(stackTrace: record.stackTrace, maxFrames: 50));
  }
}
