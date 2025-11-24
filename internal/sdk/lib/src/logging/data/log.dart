import 'package:flutter/foundation.dart';
import '../../data/identity.dart';
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
    final logLineBuffer = StringBuffer(
      truncateLongerInformation ? shortenStringIfContainsLargeHtml(record.message) : record.message,
    );

    final error = record.error;

    if (error != null) {
      logLineBuffer.write('\n');
      logLineBuffer.writeln(truncateLongerInformation ? shortenStringIfContainsLargeHtml(error.toString()) : error);
      if (record.stackTrace != null) {
        logLineBuffer.write('\n');
        logLineBuffer.writeln(formatStackTrace(stackTrace: record.stackTrace));
      }
    }

    final level = record.level;

    return LogEntry(
      sessionIdentity: fallbackSessionIdentity.merge(identity),
      logLine: logLineBuffer.toString(),
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

  static String shortenStringIfContainsLargeHtml(String message) {
    if (message.length > 500 && message.contains('</div')) {
      // possibly html that's too large
      // TODO: Only truncate the html content within the string.
      return '${message.trim().substring(0, 500).trim()}...<other ${message.length - 500} characters>';
    }
    return message.trim();
  }
}
