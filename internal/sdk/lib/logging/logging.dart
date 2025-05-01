import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:reclaim_flutter_sdk/data/identity.dart';
import 'package:reclaim_flutter_sdk/logging/data/log.dart';
import 'package:reclaim_flutter_sdk/attestor.dart';
import 'package:reclaim_flutter_sdk/overrides/overrides.dart';
import 'package:reclaim_flutter_sdk/utils/dio.dart';
import 'package:reclaim_flutter_sdk/utils/source/source.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

export 'package:logging/logging.dart';

// Note: Do not use Logger inside this file. Prefer print or debugPrint

/// This is the logger we use in the sdk
final logging = Logger('reclaim_flutter_sdk');

extension LoggerExtension on Logger {
  /// Create a new child [Logging] instance with a [name].
  ///
  /// The full name of this new Logging will be this logging's full name + the [name].
  Logger child(String name) {
    return Logger('$fullName.$name');
  }

  bool get isDebugging => level < Level.INFO || kDebugMode;
}

final _dioClient = buildDio();

final _loggingApi = Uri.parse(
  'https://logs.reclaimprotocol.org/api/business-logs/logDump',
);

typedef _BufferLogEntry = ({LogRecord record, SessionIdentity? identity});

Future<String> _getDeviceLoggingId() async {
  final prefs = await SharedPreferences.getInstance();
  const key = '_DEVICE_LOGGING_ID';
  final value = prefs.getString(key);
  if (value != null) return value;
  final id = const Uuid().v4().toString();
  await prefs.setString(key, id);
  return id;
}

Future<void> _sendLogEntries(
  List<_BufferLogEntry> entries, {
  required SessionIdentity fallbackSessionIdentity,
  Uri? loggingUrl,
  bool truncateLongerInformation = false,
}) async {
  try {
    loggingUrl ??= _loggingApi;
    final logs = entries.map((e) {
      return LogEntry.fromRecord(
        e.record,
        e.identity,
        fallbackSessionIdentity: fallbackSessionIdentity,
        truncateLongerInformation: truncateLongerInformation,
      );
    }).toList();

    await _dioClient.postUri(
      loggingUrl,
      options: Options(
        headers: const {
          'content-type': 'application/json',
        },
      ),
      data: json.encode({
        'logs': logs,
        'source': await getClientSource(),
        'deviceId': await _getDeviceLoggingId(),
      }),
    );
  } catch (e) {
    debugPrintThrottled('Failed to send logs to url $loggingUrl: $e');
    rethrow;
  }
}

List<_BufferLogEntry> _buffer = [];

Completer<void>? _logsSendCompleter;

void _sendAndFlushLogs(_) async {
  if (_buffer.isEmpty) return;
  Completer<void>? completer = _logsSendCompleter;
  if (completer != null && !completer.isCompleted) {
    return;
  }

  final identity = SessionIdentity.latest;
  if (identity == null ||
      // wait for session id to get generated
      identity.sessionId.isEmpty) {
    return;
  }
  completer = Completer<void>();
  _logsSendCompleter = completer;

  final logs = _buffer;

  _buffer = [];

  try {
    await _sendLogEntries(
      logs,
      fallbackSessionIdentity: identity,
    );
    logs.clear();
  } catch (e, s) {
    if (kDebugMode) {
      debugPrintThrottled('Failed to send logs: $e');
      debugPrintThrottled(LogEntry.formatStackTrace(stackTrace: s));
    }
    debugPrintThrottled('Log error: ${e.runtimeType}');
    if (e is DioException && e.response?.statusCode == 413) {
      debugPrintThrottled('Error 413: payload too large');

      // 413 is the status code for payload too large
      // we should retry sending the logs in smaller length and size.
      // Split logs into 3 parts, and truncate longer information and try sending each part separately
      final partSize = (logs.length / 3).ceil();
      for (var i = 0; i < logs.length; i += partSize) {
        final end = (i + partSize < logs.length) ? i + partSize : logs.length;
        final part = logs.sublist(i, end);
        try {
          await _sendLogEntries(
            part,
            fallbackSessionIdentity: identity,
            truncateLongerInformation: true,
          );
          // Remove successfully sent logs from the original list
          logs.removeRange(i, end);
        } catch (retryError) {
          if (kDebugMode) {
            debugPrintThrottled('Failed to send partial logs: $retryError');
          }
          // Stop trying remaining parts if one fails
          break;
        }
        // Lets give up, we can't send the logs
        logs.clear();
      }
    }
    // re-insert logs that we weren't able to send
    _buffer.insertAll(0, logs);
  }
  completer.complete();
}

final _logDateFormat = DateFormat('hh:mm:ss aa');

void _onLogsToConsole(LogRecord record) {
  final formattedTime = _logDateFormat.format(record.time);

  final label =
      '$formattedTime ${record.level.name} ${record.loggerName} (${record.sequenceNumber})';

  final message = record.message;
  debugPrintThrottled(
      '$label ${LogEntry.shortenStringIfContainsLargeHtml(message)}'.trim());
  final error = record.error;
  if (error != null) {
    debugPrintThrottled(
        '$label [Error] ${LogEntry.shortenStringIfContainsLargeHtml(error.toString())}');
  }
  if (record.level >= Level.WARNING) {
    debugPrintThrottled(label);
    debugPrintThrottled(
      LogEntry.formatStackTrace(
        stackTrace: record.stackTrace,
        maxFrames: 30,
      ),
    );
  }
}

const bool reclaimCanPrintDebugLogs = !kReleaseMode;

void _onLogRecord(LogRecord record) async {
  final canPrintLogs =
      ReclaimOverrides.logsConsumer?.canPrintLogs ?? reclaimCanPrintDebugLogs;
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

  _buffer.add((
    record: record,
    identity: SessionIdentity.latest,
  ));
}

bool _isInitialized = false;

bool? _oldIsDebug;
void _updateAttestorLogLevel(Level? level) {
  if (level == null) return;
  final isDebug = level < Level.INFO;
  if (isDebug != _oldIsDebug) {
    _oldIsDebug = isDebug;
    final attestorCoreLogLevel = isDebug ? 'debug' : 'info';
    Attestor.instance.setAttestorDebugLevel(attestorCoreLogLevel);
  }
}

void _onLogLevelChange(Level? level) {
  _saveLogLevel(level);
  _updateAttestorLogLevel(level);
}

const _logLevelPrefKey = 'reclaim_flutter_sdk#log_level';

Future<Level> _loadSavedLevel() async {
  final getLevel = ReclaimOverrides.logsConsumer?.levelChangeHandler?.getLevel;
  if (getLevel != null) {
    return getLevel();
  }
  final prefs = await SharedPreferences.getInstance();
  final value = prefs.getInt(_logLevelPrefKey);
  if (value == null) return Level.INFO;
  for (var level in Level.LEVELS) {
    if (level.value == value) {
      return level;
    }
  }
  return Level(value.toString(), value);
}

Future<void> _saveLogLevel(Level? level) async {
  final setLevel =
      ReclaimOverrides.logsConsumer?.levelChangeHandler?.onLevelChanged;
  if (setLevel != null) {
    await setLevel(level);
    return;
  }
  final prefs = await SharedPreferences.getInstance();
  if (level == null) {
    await prefs.remove(_logLevelPrefKey);
    return;
  }
  await prefs.setInt(_logLevelPrefKey, level.value);
}

void initializeReclaimLogging() async {
  if (_isInitialized) return;
  _isInitialized = true;

  hierarchicalLoggingEnabled = true;

  WidgetsFlutterBinding.ensureInitialized();

  // TODO(mushaheed): Should we record all logs from the app or just logs under 'reclaim_flutter_sdk'?
  Logger.root.onRecord.listen(_onLogRecord);
  logging.onLevelChanged.listen(_onLogLevelChange);
  logging.level = await _loadSavedLevel();
  _updateAttestorLogLevel(logging.level);

  final platformDispatcherLogger = logging.child('PlatformDispatcher');
  PlatformDispatcher.instance.onError = (e, s) {
    platformDispatcherLogger.severe('Failed', e, s);
    return true;
  };
  final flutterErrorLogger = logging.child('FlutterError');
  final previousFlutterErrorHandler = FlutterError.onError;

  FlutterError.onError = (error) {
    flutterErrorLogger.warning(error.toString(), error.exception, error.stack);
    previousFlutterErrorHandler?.call(error);
  };

  // an always alive periodic timer
  Timer.periodic(
    const Duration(seconds: 5),
    _sendAndFlushLogs,
  );
}
