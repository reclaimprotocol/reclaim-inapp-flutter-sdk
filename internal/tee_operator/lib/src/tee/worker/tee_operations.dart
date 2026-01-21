import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:logging/logging.dart';
import 'package:measure_performance/measure_performance.dart';
import 'package:reclaim_tee_operator_flutter/src/common/libreclaim/libreclaim.dart';

import '../../common/worker/isolate_worker/isolate_worker.dart';
import '../models/claim.dart';
import '../models/client_options.dart';
import '../models/request_data.dart';

final _logger = Logger('reclaim_flutter_sdk.reclaim_tee_operator.tee.worker.tee_operations');

/// Input data for TEE operations
class TEEOperationInput {
  final ReclaimRequestData requestData;
  final ClaimCreationClientOptions? clientOptions;
  final String? requestId; // Unique ID to track this request through the system

  const TEEOperationInput({required this.requestData, required this.clientOptions, this.requestId});

  Map<String, dynamic> toJson() => {
    'requestData': requestData.toJson(),
    'clientOptions': clientOptions?.toJson(),
    'requestId': requestId,
  };

  factory TEEOperationInput.fromJson(Map<String, dynamic> json) {
    return TEEOperationInput(
      requestData: ReclaimRequestData.fromJson(json['requestData'] as Map<String, dynamic>),
      clientOptions: json['clientOptions'] != null
          ? ClaimCreationClientOptions.fromJson(json['clientOptions'] as Map<String, dynamic>)
          : null,
      requestId: json['requestId'] as String?,
    );
  }
}

/// Wrapper for provider JSON format that can be automatically encoded
class _ProviderRequestWrapper {
  final ReclaimRequestData requestData;

  const _ProviderRequestWrapper(this.requestData);

  // toJson() returns the provider format expected by native library
  Map<String, dynamic> toJson() => requestData.toProviderJson();
}

/// Result of TEE operations
class TEEOperationResult {
  final bool success;
  final ReclaimClaim? claim;
  final List<Map<String, String>>? signatures;
  final String? error;
  final PerformanceReport? performanceReport;

  const TEEOperationResult({required this.success, this.claim, this.signatures, this.error, this.performanceReport});

  Map<String, dynamic> toJson() => {
    'success': success,
    'claim': claim?.toJson(),
    'signatures': signatures,
    'error': error,
  };

  factory TEEOperationResult.fromJson(Map<String, dynamic> json) {
    return TEEOperationResult(
      success: json['success'] as bool,
      claim: json['claim'] != null ? ReclaimClaim.fromJson(json['claim'] as Map<String, dynamic>) : null,
      signatures: json['signatures'] != null
          ? (json['signatures'] as List<dynamic>).map((s) => Map<String, String>.from(s as Map)).toList()
          : null,
      error: json['error'] as String?,
      performanceReport: null, // Performance reports are not serialized across isolates
    );
  }
}

/// Runnable for executing TEE protocol operations in background isolate
class TEEExecuteRunnable extends Runnable<TEEOperationInput, TEEOperationResult> {
  const TEEExecuteRunnable();

  @override
  Future<TEEOperationResult> call(
    TEEOperationInput input, {
    required String debugLabel,
    required ReceivePort receivePort,
    required SendPort sendPort,
  }) async {
    _logger.info('[$debugLabel] Starting TEE protocol execution in background isolate');

    final measure = MeasurePerformance();

    try {
      // Initialize the native library in the isolate
      final bindings = ReclaimBindings.instance;

      // Convert input to the format expected by native library
      // json.encode automatically calls toJson() on objects
      measure.start();
      final providerData = _ProviderRequestWrapper(input.requestData).toJson();

      final requestJson = json.encode(providerData);

      // Include requestId in the config if provided
      final configMap = <String, dynamic>{
        ...(input.clientOptions?.toJson() ?? {}),
        if (input.requestId != null) 'requestId': input.requestId,
      };
      final configJson = json.encode(configMap);

      final cRequestJson = requestJson.toNativeUtf8();
      final cConfigJson = configJson.toNativeUtf8();
      final claimJson = calloc<Pointer<Char>>();
      final claimLength = calloc<Int>();

      try {
        _logger.info('[$debugLabel] Executing protocol with native library');

        final result = bindings.executeProtocol(cRequestJson.cast(), cConfigJson.cast(), claimJson, claimLength);

        if (result != reclaim_error_t.RECLAIM_SUCCESS) {
          final errorMsg = bindings.getErrorMessage(result);
          final errorStr = errorMsg.toDartString();
          bindings.freeString(errorMsg);

          _logger.severe('[$debugLabel] Execute request failed: $errorStr');

          measure.stop();
          return TEEOperationResult(
            success: false,
            error: 'Protocol failed: $errorStr',
            performanceReport: measure.getReport(),
          );
        }

        final claimStr = claimJson.value.toDartString(claimLength.value);
        bindings.freeString(claimJson.value);

        final completeResponse = json.decode(claimStr) as Map<String, dynamic>;
        final claim = ReclaimClaim.fromJson(completeResponse);

        // Extract signatures from the Go response
        final signatures = (completeResponse['signatures'] as List<dynamic>?)
            ?.map((s) => Map<String, String>.from(s as Map))
            .toList();

        _logger.info(
          '[$debugLabel] TEE protocol execution completed successfully with ${signatures?.length ?? 0} signatures',
        );
        measure.stop();
        return TEEOperationResult(
          success: claim.success,
          claim: claim,
          signatures: signatures,
          error: claim.error,
          performanceReport: measure.getReport(),
        );
      } finally {
        calloc.free(cRequestJson);
        calloc.free(cConfigJson);
        calloc.free(claimJson);
        calloc.free(claimLength);
      }
    } catch (e, s) {
      _logger.severe('[$debugLabel] TEE protocol execution failed: $e\\nStack: $s');
      measure.stop();
      return TEEOperationResult(success: false, error: e.toString(), performanceReport: measure.getReport());
    }
  }
}

/// Runnable for getting library version in background isolate
class TEEVersionRunnable extends Runnable<void, String> {
  const TEEVersionRunnable();

  @override
  Future<String> call(
    void input, {
    required String debugLabel,
    required ReceivePort receivePort,
    required SendPort sendPort,
  }) async {
    _logger.info('[$debugLabel] Getting library version in background isolate');

    try {
      final bindings = ReclaimBindings.instance;
      final version = bindings.version;
      final versionStr = version.toDartString();
      bindings.freeString(version);

      _logger.fine('[$debugLabel] Library version: $versionStr');
      return versionStr;
    } catch (e, s) {
      _logger.severe('[$debugLabel] Failed to get library version: $e\\nStack: $s');
      rethrow;
    }
  }
}
