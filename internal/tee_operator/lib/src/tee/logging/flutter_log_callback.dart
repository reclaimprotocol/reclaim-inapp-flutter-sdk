import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../common/libreclaim/libreclaim.dart';
import '../../common/worker/isolate_worker/isolate_worker.dart';

// FFI callback signature matching Go: void (*LogCallback)(const char* level, const char* message, const char* fields, int progress_percentage, const char* progress_description)
typedef LogCallbackC = GoLogCallback;

// Log message model with optional progress tracking
class ZapLogMessage {
  final DateTime timestamp;
  final String level;
  final String message;
  final Map<String, dynamic> fields;
  final int? progressPercentage; // -1 means no progress, 0-100 for actual progress
  final String? progressDescription;
  final String? id; // Request ID to track which request this log belongs to

  ZapLogMessage({
    required this.timestamp,
    required this.level,
    required this.message,
    required this.fields,
    this.progressPercentage,
    this.progressDescription,
    this.id,
  });

  bool get hasProgress => progressPercentage != null && progressPercentage! >= 0 && progressPercentage! <= 100;

  factory ZapLogMessage.fromCallback(
    String level,
    String message,
    String fieldsJson,
    int progressPercentage,
    String progressDescription,
  ) {
    Map<String, dynamic> fields = {};
    DateTime timestamp = DateTime.now();
    String? requestId;

    try {
      fields = json.decode(fieldsJson) as Map<String, dynamic>;
      // Extract timestamp if present
      if (fields.containsKey('timestamp')) {
        final timestampStr = fields['timestamp'] as String;
        timestamp = DateTime.parse(timestampStr);
        fields.remove('timestamp');
      }
      // Extract request ID if present
      if (fields.containsKey('requestId')) {
        requestId = fields['requestId'] as String;
        fields.remove('requestId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to parse log fields: $e');
      }
    }

    return ZapLogMessage(
      timestamp: timestamp,
      level: level.toLowerCase(),
      message: message,
      fields: fields,
      progressPercentage: progressPercentage >= 0 ? progressPercentage : null,
      progressDescription: progressDescription.isNotEmpty ? progressDescription : null,
      id: requestId,
    );
  }

  Color get levelColor {
    switch (level.toLowerCase()) {
      case 'debug':
        return Colors.grey;
      case 'info':
        return Colors.blue;
      case 'warn':
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'fatal':
        return Colors.red.shade900;
      case 'panic':
        return Colors.purple;
      default:
        return Colors.white;
    }
  }

  String get levelEmoji {
    switch (level.toLowerCase()) {
      case 'debug':
        return '🔍';
      case 'info':
        return 'ℹ️';
      case 'warn':
      case 'warning':
        return '⚠️';
      case 'error':
        return '❌';
      case 'fatal':
        return '💀';
      case 'panic':
        return '🚨';
      default:
        return '📝';
    }
  }

  String toFormattedString() {
    final time = timestamp.toIso8601String().substring(11, 23);
    final fieldsStr = fields.isEmpty ? '' : ' | ${fields.entries.map((e) => '${e.key}: ${e.value}').join(', ')}';
    final progressStr = hasProgress ? ' [$progressPercentage% - $progressDescription]' : '';
    return '[$time] $levelEmoji [${level.toUpperCase()}] $message$progressStr$fieldsStr';
  }
}

// Main logging service
class FlutterZapLogger {
  static FlutterZapLogger? _instance;
  static FlutterZapLogger get instance => _instance ??= FlutterZapLogger._();

  FlutterZapLogger._();

  // Stream for log messages
  final _logController = StreamController<ZapLogMessage>.broadcast();
  Stream<ZapLogMessage> get logStream => _logController.stream;
  // Stream for progress updates only
  final _progressController = StreamController<ZapLogMessage>.broadcast();
  Stream<ZapLogMessage> get progressStream => _progressController.stream;

  /// Public static getter for accessing progress updates from Go library
  /// This allows external packages to listen for progress updates without exposing internal details
  static Stream<ZapLogMessage> get progressUpdates => instance.progressStream;

  // Filtered streams
  Stream<ZapLogMessage> get debugStream => logStream.where((log) => log.level == 'debug');
  Stream<ZapLogMessage> get infoStream => logStream.where((log) => log.level == 'info');
  Stream<ZapLogMessage> get warnStream => logStream.where((log) => log.level == 'warn' || log.level == 'warning');
  Stream<ZapLogMessage> get errorStream => logStream.where((log) => log.level == 'error');

  // Background worker that owns the native callback (see _GoLogListenerRunnable)
  BackgroundWorker<void, bool>? _worker;

  // State
  bool _initialized = false;
  bool _available = false;

  bool get isInitialized => _initialized;
  bool get isAvailable => _available;

  // Log history
  final Queue<ZapLogMessage> _logHistory = ListQueue<ZapLogMessage>();
  List<ZapLogMessage> get logHistory => _logHistory.toList(growable: false);
  final int maxHistorySize = 1000;

  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      if (!Platform.isAndroid && !Platform.isIOS) {
        _available = false;
        return false;
      }

      if (Platform.isAndroid) {
        // Preload the library off the UI thread to avoid startup jank
        try {
          await Isolate.run(() {
            DynamicLibrary.open('libreclaim.so');
          });
        } catch (_) {}
      }

      // Register the native callback from a background worker isolate (same
      // pattern as the native networking and ZK-init callbacks) so FFI string
      // decoding and JSON parsing never run on the main isolate.
      final worker = await const WorkerManager(_GoLogListenerRunnable())
          .createWorker(debugLabel: 'GoLogListener', onMessageFromBackground: _onLogMessageFromWorker);
      final registered = await worker.executeInBackground(null, timeout: const Duration(seconds: 10));
      if (!registered) {
        worker.close();
        throw Exception('Failed to set log callback');
      }
      _worker = worker;

      _initialized = true;
      _available = true;

      return true;
    } catch (e) {
      _available = false;
      return false;
    }
  }

  // Receives parsed log messages from the worker isolate
  void _onLogMessageFromWorker(dynamic message) {
    if (message is! ZapLogMessage) return;

    // Add to stream
    _logController.add(message);

    // Add to history
    _logHistory.add(message);
    if (_logHistory.length > maxHistorySize) {
      _logHistory.removeFirst();
    }

    // Emit to progress controller if it's a progress update
    if (message.hasProgress) {
      _progressController.add(message);
    }

    // Bridge Go logs to Dart's logging system
    _bridgeToDartLogger(message);
  }

  // Bridge Go library logs to Dart's Logger hierarchy
  static void _bridgeToDartLogger(ZapLogMessage logMessage) {
    try {
      final logLevel = _mapZapLevelToDartLevel(logMessage.level);
      // Use reclaim_inapp_sdk hierarchy so SDK's logger can capture Go logs
      final loggerName = logMessage.fields['logger'] as String? ?? 'reclaim_inapp_sdk.reclaim_tee_shared_library';
      final logger = Logger(loggerName);

      // Format message with fields if present
      final message = logMessage.fields.isEmpty
          ? logMessage.message
          : '${logMessage.message} | ${logMessage.fields.entries.map((e) => '${e.key}=${e.value}').join(', ')}';

      logger.log(logLevel, message);
    } catch (e) {
      // Ignore bridging errors
    }
  }

  // Map Zap log levels to Dart Logger levels
  static Level _mapZapLevelToDartLevel(String zapLevel) {
    switch (zapLevel.toLowerCase()) {
      case 'debug':
        return Level.FINE;
      case 'info':
        return Level.INFO;
      case 'warn':
      case 'warning':
        return Level.WARNING;
      case 'error':
        return Level.SEVERE;
      case 'fatal':
      case 'panic':
        return Level.SHOUT;
      default:
        return Level.INFO;
    }
  }

  // testLogging removed

  void clearHistory() {
    _logHistory.clear();
  }

  void dispose() {
    if (!_initialized) return;

    // Shutting down the worker runs _GoLogListenerRunnable.close() in the
    // worker isolate, which clears the Go callback and closes the callable.
    _worker?.close();
    _worker = null;
    _logController.close();
    _progressController.close();
    _initialized = false;
    // Disposed
  }

  // Helper to filter logs by component/service
  List<ZapLogMessage> getLogsByService(String service) {
    return _logHistory.where((log) {
      return log.fields['service'] == service || log.fields['logger'] == service;
    }).toList();
  }

  // Helper to get recent errors
  List<ZapLogMessage> getRecentErrors({int limit = 10}) {
    return _logHistory
        .where((log) => log.level == 'error' || log.level == 'fatal')
        .toList()
        .reversed
        .take(limit)
        .toList();
  }
}

/// Runs in a background worker isolate: registers the Go log callback via
/// [ReclaimBindings] and forwards parsed [ZapLogMessage]s to the owner
/// isolate. Registering through the shared bindings guarantees the callback
/// lands in the same copy of the native library that executes the protocol
/// (opening the library by path here can resolve to a different image — e.g.
/// the embedded framework instead of the statically linked copy on iOS —
/// leaving the executing copy without a registered callback, which silently
/// drops all log/progress updates).
class _GoLogListenerRunnable extends Runnable<void, bool> {
  const _GoLogListenerRunnable();

  // Per-isolate state: these statics live in the worker isolate only.
  static SendPort? _sendPort;
  static NativeCallable<LogCallbackC>? _callback;

  @override
  Future<bool> call(
    void input, {
    required String debugLabel,
    required ReceivePort receivePort,
    required SendPort sendPort,
  }) async {
    if (_callback != null) return true;

    _sendPort = sendPort;
    final callback = NativeCallable<LogCallbackC>.listener(_onGoLog);
    final result = ReclaimBindings.instance.setLogCallback(callback.nativeFunction);
    if (result != 1) {
      callback.close();
      _sendPort = null;
      return false;
    }
    _callback = callback;
    return true;
  }

  static void _onGoLog(
    Pointer<Utf8> level,
    Pointer<Utf8> message,
    Pointer<Utf8> fields,
    int progressPercentage,
    Pointer<Utf8> progressDescription,
  ) {
    try {
      final levelStr = level.toDartString();

      // Skip debug logs entirely in release mode to prevent excessive string
      // allocations and cross-isolate traffic.
      // progressPercentage >= 0 indicates a progress update, which we shouldn't skip.
      if (levelStr == 'debug' && !kDebugMode && progressPercentage < 0) {
        return;
      }

      final logMessage = ZapLogMessage.fromCallback(
        levelStr,
        message.toDartString(),
        fields.toDartString(),
        progressPercentage,
        progressDescription.toDartString(),
      );

      _sendPort?.send(MessageForOwner(logMessage));
    } catch (e) {
      // Ignore errors in release
    }
  }

  @override
  void close() {
    try {
      ReclaimBindings.instance.clearLogCallback();
    } catch (_) {}
    _callback?.close();
    _callback = null;
    _sendPort = null;
  }
}
