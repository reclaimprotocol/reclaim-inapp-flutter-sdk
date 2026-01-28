import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:logging/logging.dart';
import 'package:measure_performance/measure_performance.dart';
import 'package:reclaim_tee_operator_flutter/src/common/libreclaim/libreclaim.dart';

import '../common/algorithm_initializer.dart';
import '../common/exceptions.dart';
import '../common/operator_interface.dart';
import '../common/reusable_resource_pool.dart';
import '../common/worker/isolate_worker/isolate_worker.dart';
import 'logging/flutter_log_callback.dart';
import 'models/client_options.dart';
import 'models/request_data.dart';
import 'worker/tee_operations.dart';

final _logger = Logger('reclaim_flutter_sdk.reclaim_tee_operator.tee');

typedef OnProofPerformanceReportCallback = void Function(PerformanceReport);

/// Main class for interacting with Reclaim TEE operations
/// Instance-based design for better testability and lifecycle management
///
/// Unlike the GNARK operator, the TEE operator doesn't require explicit OPRF methods
/// (groth16Prove, finaliseOPRF, generateOPRFRequestData) as the native Go library
/// handles all proof generation internally.
class ReclaimTEEOperator extends ReclaimTEEOperatorBase {
  /// Private constructor
  ReclaimTEEOperator._() {
    // Ensure prover algorithms is used atleast once to setup lazy initialization.
    ProverAlgorithmInitializer.instance;
  }

  static ReclaimTEEOperator? _cachedInstances;

  /// Factory constructor that creates operator instance
  /// Library loading and initialization happens in background workers
  static ReclaimTEEOperator get instance {
    if (_cachedInstances == null) {
      _logger.info('Starting TEE Operator creation...');

      final opr = ReclaimTEEOperator._();

      unawaited(opr._initializeGoLibraryLogging());

      _logger.info('Reclaim TEE Operator initialized successfully');
      _cachedInstances = opr;
      return opr;
    }
    return _cachedInstances!;
  }

  Future<void> _initializeGoLibraryLogging() async {
    // Initialize Go library logging in main isolate so SDK can access log streams
    try {
      final success = await FlutterZapLogger.instance.initialize().timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      );
      if (success) {
        _logger.info('Go library logging initialized in main isolate');
      } else {
        _logger.warning('Go library logging not available on this platform');
      }
    } catch (e, s) {
      _logger.warning('Failed to initialize Go library logging', e, s);
    }
  }

  /// Get the library version
  /// Uses background worker to avoid blocking main thread
  @override
  Future<String> getVersion() async {
    Future<BackgroundWorker<void, String>>? versionWorkerFuture;
    try {
      versionWorkerFuture = const WorkerManager(TEEVersionRunnable()).createWorker();
      final worker = await versionWorkerFuture;
      final versionStr = await worker.executeInBackground(null, timeout: const Duration(seconds: 10));

      _logger.fine('Library version: $versionStr');
      return versionStr;
    } catch (e) {
      _logger.warning('Version worker failed, recreating: $e');
      // Force recreate worker on failure/timeout
      versionWorkerFuture?.then((w) => w.close()).ignore();
      versionWorkerFuture = null;

      if (e.toString().contains('not supported')) {
        throw UnsupportedError(e.toString());
      }
      rethrow;
    }
  }

  final _executeRequestWorkerManager = WorkerManager(TEEExecuteRunnable());

  late final _executeRequestPool = ReusableResourcePool<BackgroundWorker<TEEOperationInput, TEEOperationResult>>(
    initialPoolSize: 3,
    createResource: () {
      return _executeRequestWorkerManager.createWorker();
    },
    disposeResource: (resource) => resource.close(),
    ageLimit: const Duration(minutes: 5),
    getResourceAge: (resource) => Duration(minutes: 0), // Placeholder, implement actual age tracking if needed,
    isResourceFaulty: (resource) => false, // Placeholder, implement actual health check if needed,
  );

  /// Execute a complete HTTP request using the TEE protocol and get a claim
  /// Uses background worker to avoid blocking main thread
  ///
  /// Throws [ReclaimProofGenerationException] if proof generation fails
  /// Throws [ReclaimNetworkException] if network communication fails
  /// Throws [ReclaimOperatorException] for other TEE operation errors
  @override
  Future<TEEExecutionResult> executeRequest(
    ReclaimRequestData requestData,
    ClaimCreationClientOptions? clientOptions, {
    String? requestId,
  }) async {
    _logger.info('Starting TEE request execution in background worker');

    try {
      final input = TEEOperationInput(requestData: requestData, clientOptions: clientOptions, requestId: requestId);

      return await _executeRequestPool.compute((worker) async {
        final result = await worker.executeInBackground(input, timeout: const Duration(minutes: 10));

        _logger.info(
          'TEE request execution completed: success=${result.success}, signatures=${result.signatures?.length ?? 0}',
        );

        // If the result indicates failure, throw an exception
        if (!result.success || result.claim == null) {
          throw ReclaimProofGenerationException(result.error ?? 'TEE operation failed without error message');
        }

        return TEEExecutionResult(
          claim: result.claim!,
          signatures: result.signatures ?? [],
          performanceReport: result.performanceReport,
        );
      });
    } catch (e, s) {
      _logger.severe('Execute request failed in background worker', e, s);
      rethrow;
    }
  }

  /// Extract JSON value indexes using TEE operator
  @override
  Future<List<Map<String, int>>> extractJSONValueIndexes(String jsonString, String jsonPath) async {
    try {
      final bindings = ReclaimBindings.instance;

      // Encode document as base64 to preserve exact bytes through JSON round-trip
      final originalJsonBytes = utf8.encode(jsonString);
      final base64Document = base64.encode(originalJsonBytes);
      final input = {'document_base64': base64Document, 'jsonPath': jsonPath};
      final inputJson = json.encode(input);
      final inputBytes = utf8.encode(inputJson);

      utf8.decode(inputBytes);
      final inputSlice = _convertToGoSlice(inputBytes);

      try {
        final result = bindings.extractJSONValueIndexes(inputSlice);
        // Use the length returned by Go to properly read the string
        final resultStr = result.r0.cast<Utf8>().toDartString(length: result.r1);
        bindings.freeString(result.r0.cast());

        final response = json.decode(resultStr) as Map<String, dynamic>;

        // Handle successful response with ranges
        if (response.containsKey('ranges')) {
          final ranges = response['ranges'] as List<dynamic>;

          _logger.info('🔍 JSON Extraction - Raw response from Go:');
          _logger.info('  JSONPath: $jsonPath');
          _logger.info(
            '  Ranges from Go (BYTE positions): ${ranges.map((r) => {'start': r['start'], 'end': r['end']}).toList()}',
          );

          // Convert byte positions to character positions for use with String.substring()
          final result = ranges.map((item) {
            final range = item as Map<String, dynamic>;
            final byteStart = range['start'] as int;
            final byteEnd = range['end'] as int;

            _logger.info('🔍 Converting byte range: byteStart=$byteStart, byteEnd=$byteEnd');

            // Verify what we're extracting at byte level
            if (byteStart < originalJsonBytes.length && byteEnd <= originalJsonBytes.length) {
              final byteSlice = originalJsonBytes.sublist(byteStart, byteEnd);
              final extractedAtBytes = utf8.decode(byteSlice, allowMalformed: true);
              _logger.info('🔍 Value at byte positions [$byteStart:$byteEnd]: "$extractedAtBytes"');
            }

            // Convert byte positions to character positions
            final charStart = _bytePositionToCharPosition(originalJsonBytes, byteStart);
            final charEnd = _bytePositionToCharPosition(originalJsonBytes, byteEnd);

            _logger.info('🔍 Converted to char positions: charStart=$charStart, charEnd=$charEnd');

            return {'start': charStart, 'end': charEnd};
          }).toList();
          return result;
        }

        // Unexpected response format
        throw Exception('Unexpected response format from ExtractJSONValueIndexes - missing ranges field');
      } finally {
        calloc.free(inputSlice.data);
      }
    } catch (e) {
      _logger.severe('Failed to extract JSON value indexes: $e');
      rethrow;
    }
  }

  /// Extract HTML element indexes using TEE operator
  @override
  Future<List<Map<String, int>>> extractHTMLElementIndexes(
    String html,
    String xpath, {
    bool contentsOnly = false,
  }) async {
    try {
      final bindings = ReclaimBindings.instance;

      // Encode HTML as base64 to preserve exact bytes through JSON round-trip (same as JSON extraction)
      final originalHtmlBytes = utf8.encode(html);
      final base64Html = base64.encode(originalHtmlBytes);
      final input = {'html_base64': base64Html, 'xpath': xpath, 'contentsOnly': contentsOnly};

      final inputJson = json.encode(input);
      final inputBytes = utf8.encode(inputJson);
      final inputSlice = _convertToGoSlice(inputBytes);

      try {
        final result = bindings.extractHTMLElementsIndexes(inputSlice);
        // Use the length returned by Go to properly read the string
        final resultStr = result.r0.cast<Utf8>().toDartString(length: result.r1);
        bindings.freeString(result.r0.cast());

        final response = json.decode(resultStr) as Map<String, dynamic>;

        // Check if response is an error object
        if (response.containsKey('error')) {
          final errorMessage = response['error'] as String;
          throw Exception('HTML extraction failed: $errorMessage');
        }

        // Handle successful response with ranges
        if (response.containsKey('ranges')) {
          final ranges = response['ranges'] as List<dynamic>;
          // Use the same byte array we sent to Go (via base64)
          return ranges.map((item) {
            final range = item as Map<String, dynamic>;
            final byteStart = range['start'] as int;
            final byteEnd = range['end'] as int;
            return {
              'start': _bytePositionToCharPosition(originalHtmlBytes, byteStart),
              'end': _bytePositionToCharPosition(originalHtmlBytes, byteEnd),
            };
          }).toList();
        }

        // Unexpected response format
        throw Exception('Unexpected response format from ExtractHTMLElementsIndexes - missing ranges field');
      } finally {
        calloc.free(inputSlice.data);
      }
    } catch (e) {
      _logger.severe('Failed to extract HTML element indexes: $e');
      rethrow;
    }
  }

  GoSlice _convertToGoSlice(List<int> data) {
    final ptr = calloc<Uint8>(data.length);
    final nativeBytes = ptr.asTypedList(data.length);
    nativeBytes.setAll(0, data);

    final slice = calloc<GoSlice>();
    slice.ref.data = ptr.cast();
    slice.ref.len = data.length;
    slice.ref.cap = data.length;

    return slice.ref;
  }

  /// Convert UTF-8 byte position to string character position
  /// Since Go works with the exact UTF-8 bytes we sent (via base64), we can directly
  /// map byte positions to character positions by decoding up to that byte position
  int _bytePositionToCharPosition(List<int> utf8Bytes, int bytePosition) {
    if (bytePosition == 0) {
      return 0;
    }

    if (bytePosition >= utf8Bytes.length) {
      // Decode entire string to get total character count
      return utf8.decode(utf8Bytes).length;
    }

    // Decode from start up to the byte position to get character count
    // This correctly handles multi-byte UTF-8 characters
    final substring = utf8.decode(utf8Bytes.sublist(0, bytePosition), allowMalformed: true);
    return substring.length;
  }
}
