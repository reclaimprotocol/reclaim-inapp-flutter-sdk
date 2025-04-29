part of '../../reclaim_gnark_zkoperator.dart';

class _LogRecordIsolateMessage {
  final String loggerName;
  final Level level;
  final String message;
  final String? error;
  final StackTrace? stackTrace;

  const _LogRecordIsolateMessage({
    required this.loggerName,
    required this.level,
    required this.message,
    required this.error,
    required this.stackTrace,
  });

  static void log(_LogRecordIsolateMessage data, [String? debugLabel = '']) {
    Logger(data.loggerName).log(data.level, '($debugLabel) ${data.message}', data.error, data.stackTrace);
  }

  static void setup(void Function(_LogRecordIsolateMessage) cb) {
    hierarchicalLoggingEnabled = true;
    Logger('')
      ..level = Level.ALL
      ..onRecord.listen((record) {
        cb(
          _LogRecordIsolateMessage(
            loggerName: record.loggerName,
            message: record.message,
            error: record.error?.toString(),
            stackTrace: record.stackTrace,
            level: record.level,
          ),
        );
      });
  }
}
