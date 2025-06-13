import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../attestor.dart';
import '../data/identity.dart';
import '../overrides/overrides.dart';
import '../services/logging.dart';
import '../services/preferences/preference.dart';

import 'data/log.dart';

export 'package:logging/logging.dart';

/// This is the logger we use in the sdk
final Logger logging = _createSdkLogger();

typedef ThrowErrorCallback = Exception Function();

extension LoggerExtension on Logger {
  /// Create a new child [Logging] instance with a [name].
  ///
  /// The full name of this new Logging will be this logging's full name + the [name].
  Logger child(String name) {
    return Logger('$fullName.$name');
  }

  void debug(Object? message, [Level? level]) {
    final canUseInfo = kDebugMode || (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'));
    log(canUseInfo ? Level.INFO : (level ?? Level.FINE), message);
  }

  bool get isDebugging => level < Level.INFO || kDebugMode;
}

Logger _createSdkLogger() {
  WidgetsFlutterBinding.ensureInitialized();

  hierarchicalLoggingEnabled = true;

  // don't use logging inside this function, use l instead
  final l = Logger('reclaim_inapp_sdk');

  l.onRecord.listen(_onLoggingLogRecord);

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
  _uploadDiagnisticLogs();

  return l;
}

Future<bool> _canAppSeeConsoleLogs() async {
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
        ReclaimOverrides.logsConsumer?.canPrintLogs ?? (!kReleaseMode && await _canAppSeeConsoleLogs());
    if (canPrintLogs) {
      _onLogsToConsole(record);
    }

    final onRecord = ReclaimOverrides.logsConsumer?.onRecord;
    if (onRecord != null) {
      final canHandleLogs = await onRecord(record, SessionIdentity.latest);
      if (!canHandleLogs) {
        // the sdk will not use this log record
        return;
      }
    }
    _buffer.add((record: record, identity: SessionIdentity.latest));
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

List<LogEntry> _getLogEntryFromBuffer(List<_BufferLogEntry> logs, SessionIdentity identity) {
  final entries =
      logs.map((e) {
        return LogEntry.fromRecord(e.record, e.identity, fallbackSessionIdentity: identity);
      }).toList();
  return entries;
}

const _mb4 = 40000000;
int _getSizeInBytes(List<_BufferLogEntry> logs, SessionIdentity identity) {
  final entries = _getLogEntryFromBuffer(logs, identity);
  return utf8.encode(json.encode(entries)).lengthInBytes;
}

void _uploadDiagnisticLogs() {
  try {
    final identity = SessionIdentity.latest;
    if (identity == null ||
        // wait for session id to get generated
        identity.sessionId.isEmpty) {
      return;
    }

    if (_buffer.isEmpty) {
      // no logs to upload
      return;
    }

    final logs = _buffer;
    _buffer = [];

    final entries =
        logs.map((e) {
          return LogEntry.fromRecord(e.record, e.identity, fallbackSessionIdentity: identity);
        }).toList();

    try {
      while (_getSizeInBytes(logs, identity) >= _mb4) {
        if (logs.length == 1 || logs.isEmpty) return;
        final e = logs.removeLast();
        // adding will eventually move the biggest log at the end
        _buffer.add(e);
      }
    } catch (e, s) {
      logging.severe('Failed to get size of logs', e, s);
    }

    _loggingService.sendLogs(entries);
  } catch (e, s) {
    logging.severe('Failed to upload diagnostic logs', e, s);
    // don't reinsert failed logs in the buffer again. ReclaimHttpClients will have retried on errors.
    // this is why we aren't awaiting to avoid blocking other logs from being uploaded.
  } finally {
    // schedule the next upload
    diagnosticLogUploadTimer = Timer(_diagnosticLogUploadInterval, _uploadDiagnisticLogs);
  }
}

final _logDateFormat = DateFormat('hh:mm:ss aa');

void _onLogsToConsole(LogRecord record) {
  final formattedTime = _logDateFormat.format(record.time);

  final label = '$formattedTime ${record.level.name} ${record.loggerName} (${record.sequenceNumber})';

  final message = record.message;
  debugPrintThrottled('$label ${LogEntry.shortenStringIfContainsLargeHtml(message)}'.trim());
  final error = record.error;
  if (error != null) {
    debugPrintThrottled('$label [Error] ${LogEntry.shortenStringIfContainsLargeHtml(error.toString())}');
  }
  if (record.level >= Level.WARNING) {
    debugPrintThrottled(label);
    debugPrintThrottled(LogEntry.formatStackTrace(stackTrace: record.stackTrace, maxFrames: 50));
  }
}
