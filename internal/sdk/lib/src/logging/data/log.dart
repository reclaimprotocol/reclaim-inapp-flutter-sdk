import 'package:flutter/foundation.dart';
import '../../data/identity.dart';
import '../../utils/sanitize.dart';
import '../logging.dart';

enum LogEntryLogLevel {
  // Failures & Errors
  SEVERE,
  WARNING,
  INFO,
  // Configurations
  CONFIG,
  // Verbose debugging logs
  FINE,
  // PII Logging
  FINER,
  // PII & Extremely Verbose debugging logs
  FINEST;

  factory LogEntryLogLevel.fromLoggingLevel(Level level) {
    if (level.value >= Level.SEVERE.value) {
      return LogEntryLogLevel.SEVERE;
    } else if (level.value >= Level.WARNING.value) {
      return LogEntryLogLevel.WARNING;
    } else if (level.value >= Level.INFO.value) {
      return LogEntryLogLevel.INFO;
    } else if (level.value >= Level.CONFIG.value) {
      return LogEntryLogLevel.CONFIG;
    } else if (level.value >= Level.FINE.value) {
      return LogEntryLogLevel.FINE;
    } else if (level.value >= Level.FINER.value) {
      return LogEntryLogLevel.FINER;
    } else {
      return LogEntryLogLevel.FINEST;
    }
  }

  Level toLevel() {
    switch (this) {
      case LogEntryLogLevel.SEVERE:
        return Level.SEVERE;
      case LogEntryLogLevel.WARNING:
        return Level.WARNING;
      case LogEntryLogLevel.INFO:
        return Level.INFO;
      case LogEntryLogLevel.CONFIG:
        return Level.CONFIG;
      case LogEntryLogLevel.FINE:
        return Level.FINE;
      case LogEntryLogLevel.FINER:
        return Level.FINER;
      case LogEntryLogLevel.FINEST:
        return Level.FINEST;
    }
  }
}

class LogEntry {
  final SessionIdentity sessionIdentity;
  final String logLine;
  final int sequence;
  final DateTime time;
  final String type;
  final LogEntryLogLevel logLevel;
  final LogEventType? eventType;

  LogEntry({
    required this.sessionIdentity,
    required this.logLine,
    required this.sequence,
    required this.type,
    required this.eventType,
    required DateTime? time,
    required this.logLevel,
  }) : time = time ?? DateTime.now();

  factory LogEntry.fromRecord(
    LogRecord record,
    SessionIdentity? identity, {
    bool truncateLongerInformation = false,
    required SessionIdentity fallbackSessionIdentity,
  }) {
    final int safeLength = truncateLongerInformation ? 500 : 2000;

    final message = truncateLogString(record.message, maxLength: safeLength);
    final logLineBuffer = StringBuffer(message);

    final error = record.error;

    if (error != null) {
      logLineBuffer.write('\n');
      final errorStr = error.toString();
      logLineBuffer.writeln(truncateLogString(errorStr, maxLength: safeLength));
      if (record.stackTrace != null) {
        logLineBuffer.write('\n');
        // Cap stack traces dynamically to prevent unbounded logs
        logLineBuffer.writeln(formatStackTrace(stackTrace: record.stackTrace, maxFrames: 20));
      }
    }

    final level = record.level;

    final messageToSanitize = logLineBuffer.toString();

    return LogEntry(
      sessionIdentity: fallbackSessionIdentity.merge(identity),
      logLine: record.level > Level.FINE ? sanitizeLogMessage(messageToSanitize) : messageToSanitize,
      sequence: record.sequenceNumber,
      type: record.loggerName,
      time: record.time,
      eventType: level is LevelWithEvent ? level.eventType : null,
      logLevel: LogEntryLogLevel.fromLoggingLevel(record.level),
    );
  }

  Map<String, Object?> toJson() {
    return {
      "logLine": logLine,
      "ts": fromDateTimeToTimeStamp(time),
      "type": type,
      "sessionId": sessionIdentity.sessionId,
      "providerId": sessionIdentity.providerId,
      "appId": sessionIdentity.appId,
      "logLevel": logLevel.name,
      "eventType": eventType?.name ?? '',
    };
  }

  @visibleForTesting
  static String fromDateTimeToTimeStamp(DateTime dateTime) {
    final ms = dateTime.toUtc().millisecondsSinceEpoch;
    final ts = (ms * 1000000).toString();
    return ts;
  }

  static String formatStackTrace({StackTrace? stackTrace, int? maxFrames}) {
    if (stackTrace == null) {
      stackTrace = StackTrace.current;
    } else {
      stackTrace = FlutterError.demangleStackTrace(stackTrace);
    }
    Iterable<String> lines = stackTrace.toString().trimRight().split('\n');
    if (kIsWeb && lines.isNotEmpty) {
      // Remove extra call to StackTrace.current for web platform.
      // TODO(mushaheed): remove when https://github.com/flutter/flutter/issues/37635 is addressed.
      lines = lines.skipWhile((String line) {
        return line.contains('StackTrace.current') ||
            line.contains('dart-sdk/lib/_internal') ||
            line.contains('logging/logging') ||
            line.contains('package:logging') ||
            line.contains('dart:sdk_internal');
      });
    }
    if (maxFrames != null) {
      lines = lines.take(maxFrames);
    }
    return lines.join('\n');
  }

  static String truncateLogString(String message, {int maxLength = 2000}) {
    message = message.trim();
    if (message.length > maxLength) {
      return '${message.substring(0, maxLength)}...<truncated ${message.length - maxLength} chars>';
    }
    return message;
  }
}
