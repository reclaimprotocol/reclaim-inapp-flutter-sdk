import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

// FFI callback signature matching Go: void (*LogCallback)(const char* level, const char* message, const char* fields, int progress_percentage, const char* progress_description)
typedef LogCallbackC =
    Void Function(
      Pointer<Utf8> level,
      Pointer<Utf8> message,
      Pointer<Utf8> fields,
      Int32 progressPercentage,
      Pointer<Utf8> progressDescription,
    );

// FFI function signatures
typedef SetLogCallbackC = Int32 Function(Pointer<NativeFunction<LogCallbackC>>);
typedef SetLogCallbackDart = int Function(Pointer<NativeFunction<LogCallbackC>>);

typedef ClearLogCallbackC = Void Function();
typedef ClearLogCallbackDart = void Function();

// Test function removed

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

  // FFI functions
  SetLogCallbackDart? _setLogCallback;
  ClearLogCallbackDart? _clearLogCallback;
  // Test function removed

  // Native callback
  NativeCallable<LogCallbackC>? _nativeCallback;

  // State
  bool _initialized = false;
  bool _available = false;

  bool get isInitialized => _initialized;
  bool get isAvailable => _available;

  // Log history
  final List<ZapLogMessage> _logHistory = [];
  List<ZapLogMessage> get logHistory => List.unmodifiable(_logHistory);
  final int maxHistorySize = 1000;

  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      // Timing removed
      // Load native library based on platform
      late final DynamicLibrary lib;

      if (Platform.isAndroid) {
        // Preload the library off the UI thread to avoid startup jank
        try {
          await Isolate.run(() {
            DynamicLibrary.open('libreclaim.so');
          });
        } catch (_) {}
        lib = DynamicLibrary.open('libreclaim.so');
      } else if (Platform.isIOS) {
        // Match the worker isolate: open the vendored framework directly
        const packageName = 'reclaim_tee_operator_flutter';
        lib = DynamicLibrary.open('$packageName.framework/$packageName');
      } else {
        _available = false;
        return false;
      }

      // Try to load logging functions
      try {
        _setLogCallback = lib.lookupFunction<SetLogCallbackC, SetLogCallbackDart>('set_log_callback');
        _clearLogCallback = lib.lookupFunction<ClearLogCallbackC, ClearLogCallbackDart>('clear_log_callback');

        // No test flutter logging lookup
      } catch (e) {
        // Logging not available in the library
        _available = false;
        return false;
      }

      // Create native callback
      _nativeCallback = NativeCallable<LogCallbackC>.listener(_handleLogCallback);

      // Register callback with Go
      // Timing removed
      final result = _setLogCallback!(_nativeCallback!.nativeFunction);
      if (result != 1) {
        throw Exception('Failed to set log callback, returned: $result');
      }

      _initialized = true;
      _available = true;
      // Initialized OK

      // No test logging

      return true;
    } catch (e) {
      _available = false;
      return false;
    }
  }

  // Callback handler - static so it can be called from native code
  static void _handleLogCallback(
    Pointer<Utf8> level,
    Pointer<Utf8> message,
    Pointer<Utf8> fields,
    int progressPercentage,
    Pointer<Utf8> progressDescription,
  ) {
    try {
      final levelStr = level.toDartString();
      final messageStr = message.toDartString();
      final fieldsStr = fields.toDartString();
      final progressDescStr = progressDescription.toDartString();

      final logMessage = ZapLogMessage.fromCallback(
        levelStr,
        messageStr,
        fieldsStr,
        progressPercentage,
        progressDescStr,
      );

      // Add to stream
      instance._logController.add(logMessage);

      // Add to history
      instance._logHistory.add(logMessage);
      if (instance._logHistory.length > instance.maxHistorySize) {
        instance._logHistory.removeAt(0);
      }

      // Emit to progress controller if it's a progress update
      if (logMessage.hasProgress) {
        instance._progressController.add(logMessage);
      }

      // Bridge Go logs to Dart's logging system
      _bridgeToDartLogger(logMessage);
    } catch (e) {
      // Ignore errors in release
    }
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

    _clearLogCallback?.call();
    _nativeCallback?.close();
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
