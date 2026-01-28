import 'dart:async';
import 'dart:convert';

import 'package:reclaim_tee_operator_flutter/reclaim_tee_operator_flutter.dart';

import '../../../../attestor.dart';
import '../../../../logging.dart';
import '../../../data/create_claim.dart';
import '../../../usecase/zkoperator.dart';
import '../../../utils/provider_performance_report.dart';
import '../../data/request.dart';

class TeeUrls {
  final String attestorUrl;
  final String teekUrl;
  final String teetUrl;

  const TeeUrls({required this.attestorUrl, required this.teekUrl, required this.teetUrl});
}

class AttestorTeeClient extends AttestorPlatform {
  AttestorTeeClient() : super(debugLabel: 'AttestorTeeClient') {
    // Eagerly start operator initialization (which initializes FlutterZapLogger)
    _operatorFuture = _initializeTeeOperator();
    _setupProgressListener();
  }

  static final instance = AttestorTeeClient();

  late Future<ReclaimTEEOperator> _operatorFuture;
  StreamSubscription<ZapLogMessage>? _progressSubscription;

  @override
  Future<bool> isPlatformSupported() {
    return _operatorFuture.then((it) => it.isPlatformSupported());
  }

  /// Initialize the TEE operator for native execution
  /// This must be called before using TEE-based claim creation
  Future<ReclaimTEEOperator> _initializeTeeOperator() async {
    try {
      logger.info('Initializing TEE operator...');
      final operator = ReclaimTEEOperator.instance;
      final version = await operator.getVersion();
      logger.info('TEE operator initialized successfully. Version: $version');
      return operator;
    } catch (e, s) {
      logger.severe('Failed to initialize TEE operator', e, s);
      rethrow;
    }
  }

  /// Set up progress listener for UI updates
  /// Note: Go library logs are automatically bridged to Dart's Logger by the TEE operator
  void _setupProgressListener() {
    _progressSubscription = FlutterZapLogger.progressUpdates.listen((logMessage) {
      final percent = logMessage.progressPercentage;
      if (percent == null) {
        return;
      }
      final process = _processRequestById[logMessage.id];
      process?.updateSink?.add({
        'step': {
          "type": "update",
          "name": "attestor-progress",
          "step": {"name": "generating-zk-proofs", "proofsDone": percent, "proofsTotal": 100},
        },
      });
    });
  }

  @override
  Future<void> ensureReady() {
    return _operatorFuture;
  }

  Future<ReclaimTEEOperator> getOperator() async {
    try {
      final operator = await _operatorFuture;
      return operator;
    } catch (e, s) {
      logger.severe('Failed to initialize TEE operator', e, s);
      // TODO: FIX INTIALIZATION FOR MORE THAN 1 awaits
      _operatorFuture = _initializeTeeOperator();
      rethrow;
    }
  }

  Future<List<CreateClaimOutput>> _createClaimWithTee(
    String id,
    AttestorClaimRequest request,
    StreamSink<Map<String, Object?>> updatesSink,
    AttestorCreateClaimPerformanceReportCallback? onPerformanceReports,
  ) async {
    final log = logger.child('_createClaimWithTee');
    final teeOperator = await getOperator();
    final claimRequest = request.message;

    try {
      final encoder = const JsonEncoder.withIndent('  ');
      final claimRequestJson = encoder.convert(claimRequest);
      log.info('🔐 TEE: Claim request data:\n$claimRequestJson');
    } catch (e) {
      log.warning('🔐 TEE: Failed to serialize claim request: $e');
      log.info('🔐 TEE: Claim request data: $claimRequest');
    }

    // Use the new clean constructor - eliminates all error-prone conversion!
    final requestData = ReclaimRequestData.fromClaimRequest(claimRequest);

    // Log request parameters in JSON format (like proxy mode does)
    try {
      final encoder = const JsonEncoder.withIndent('  ');
      final requestJson = requestData.toJson();
      log.info('🔐 TEE: Request parameters:\n${encoder.convert(requestJson)}');
    } catch (e) {
      log.warning('🔐 TEE: Failed to serialize request parameters: $e');
    }

    log.info('🔐 TEE: Executing request with native TEE protocol...');

    final teeUrls = await ZkOperatorManager().getTeeUrls();

    final String attestorUrl = teeUrls.attestorUrl;
    final String teekUrl = teeUrls.teekUrl;
    final String teetUrl = teeUrls.teetUrl;

    log.info(
      '🔐 TEE URLS: Using URLs from feature flags - attestorUrl: $attestorUrl, teekUrl: $teekUrl, teetUrl: $teetUrl',
    );

    final clientOptions = ClaimCreationClientOptions(attestorUrl: attestorUrl, teekUrl: teekUrl, teetUrl: teetUrl);
    // const clientOptions = ClaimCreationClientOptions(attestorUrl: 'wss://attestor-staging.reclaimprotocol.org/ws');
    //Debug part for delete after release
    // // Save request parameters to file before sending
    // await _saveRequestParamsToFile({
    //   'requestId': id,
    //   'timestamp': DateTime.now().toIso8601String(),
    //   'requestData': requestData.toJson(),
    //   'clientOptions': clientOptions.toJson(),
    //   'claimRequest': claimRequest,
    // });

    Future.microtask(() {
      updatesSink.add({
        'step': {
          "type": "update",
          "name": "attestor-progress",
          "step": {"name": "sending-request-data"},
        },
      });
    });

    final TEEExecutionResult result = await teeOperator.executeRequest(requestData, clientOptions, requestId: id);

    // Report performance if callback is provided and we have performance data
    if (onPerformanceReports != null && result.performanceReport != null) {
      final performanceReport = ZKComputePerformanceReport(
        algorithmName: 'tee_protocol',
        report: result.performanceReport!,
      );
      onPerformanceReports([performanceReport]);
    }

    // Store revealed bytes in pending metrics for the parent to use
    if (result.performanceReport != null) {
      final existingMetrics = _pendingMetrics[id] ?? {};
      // Always preserve existing metrics (like responseSize) and add new ones
      _pendingMetrics[id] = {
        ...existingMetrics,
        'teeTime': result.performanceReport!.elapsed.inMilliseconds,
        if (existingMetrics['revealedBytes'] == null) 'revealedBytes': 0,
      };
    }

    // Convert result to expected format
    final ReclaimClaim claim = result.claim;
    log.info('🔐 TEE: Request successful, claim created with ID: ${claim.identifier}');

    final claimOutput = CreateClaimOutput(
      identifier: claim.identifier,
      claimData: ProviderClaimData(
        provider: claim.provider,
        parameters: claim.parameters,
        owner: claim.owner,
        timestampS: claim.timestampS,
        context: claim.context ?? '',
        identifier: claim.identifier,
        epoch: claim.epoch,
      ),
      signatures: result.signatures.map((sig) => sig['claim_signature'] ?? '').toList(),
      witnesses: [],
      publicData: null, // TEE operator doesn't provide public data
    );

    return [claimOutput];
  }

  final _processRequestById = <String, AttestorProcess>{};
  //Analyziz part for delete after release
  final _pendingMetrics = <String, Map<String, dynamic>>{};
  // Accumulator for metrics across all provider calls
  final _cumulativeMetrics = <String, Map<String, dynamic>>{};

  // Get and remove metrics for a specific request ID
  Map<String, dynamic>? getAndRemoveMetrics(String id) {
    return _pendingMetrics.remove(id);
  }

  // Get all pending metrics without removing them
  Map<String, Map<String, dynamic>> getAllPendingMetrics() {
    return Map.from(_pendingMetrics);
  }

  // Clear all pending metrics
  void clearAllPendingMetrics() {
    _pendingMetrics.clear();
  }

  // Get and accumulate metrics for aggregated display
  Map<String, Map<String, dynamic>> getAndAccumulateMetrics(String currentId) {
    // Move current pending metrics to cumulative storage
    for (final entry in _pendingMetrics.entries) {
      _cumulativeMetrics[entry.key] = entry.value;
    }
    _pendingMetrics.clear();

    return Map.from(_cumulativeMetrics);
  }

  @override
  AttestorProcess<AttestorClaimRequest, List<CreateClaimOutput>> createClaim({
    required Map<String, Object?> request,
    required AttestorClaimOptions options,
    AttestorCreateClaimPerformanceReportCallback? onPerformanceReports,
  }) {
    final log = logger.child('createClaim');
    log.info('🔐 TEE: Starting native claim creation process');

    final id = Object().hashCode.toString();

    final responseCompleter = Completer<List<CreateClaimOutput>>();
    final updatesController = StreamController<Map<String, Object?>>.broadcast();

    final process = AttestorProcess(
      id: id,
      type: 'createClaim',
      request: AttestorClaimRequest.create(
        operationType: ZKOperationType.gnarkTEENative,
        options: options,
        request: request,
      ),
      response: responseCompleter.future,
      updateStream: updatesController.stream,
      updateSink: updatesController.sink,
    );

    () async {
      try {
        _processRequestById[id] = process;
        final result = await _createClaimWithTee(id, process.request, updatesController.sink, onPerformanceReports);
        responseCompleter.complete(result);
      } catch (e, s) {
        log.severe('🔐 TEE: Fatal error during claim creation', e, s);
        responseCompleter.completeError(e, s);
      } finally {
        updatesController.close();
        _processRequestById.remove(id);
      }
    }();

    return process;
  }

  @override
  AttestorProcess<ExtractHtmlElementRequest, String> extractHtmlElement(String htmlString, String xPathExpression) {
    final log = logger.child('extractHtmlElement');
    log.info('🔐 TEE: Extracting HTML element with XPath: $xPathExpression');

    final id = Object().hashCode.toString();
    final responseCompleter = Completer<String>();
    final updatesController = StreamController<Map<String, Object?>>.broadcast();

    final process = AttestorProcess(
      id: id,
      type: 'extractHtmlElement',
      request: ExtractHtmlElementRequest(html: htmlString, xpathExpression: xPathExpression, contentsOnly: false),
      response: responseCompleter.future,
      updateStream: updatesController.stream,
    );

    () async {
      try {
        final teeOperator = await getOperator();
        final ranges = await teeOperator.extractHTMLElementIndexes(htmlString, xPathExpression);
        if (ranges.isEmpty) {
          responseCompleter.complete('');
        } else {
          final range = ranges.first;
          final start = range['start']!;
          final end = range['end']!;
          final result = htmlString.substring(start, end);
          responseCompleter.complete(result);
        }
      } catch (e, s) {
        log.severe('🔐 TEE: HTML extraction failed', e, s);
        responseCompleter.completeError(e, s);
      } finally {
        updatesController.close();
      }
    }();

    return process;
  }

  @override
  AttestorProcess<ExtractJsonValueIndexRequest, String> extractJSONValueIndex(
    String jsonString,
    String jsonPathExpression,
  ) {
    final log = logger.child('extractJSONValueIndex');
    log.info('🔐 TEE: Extracting JSON value with path: $jsonPathExpression');

    final id = Object().hashCode.toString();
    final responseCompleter = Completer<String>();
    final updatesController = StreamController<Map<String, Object?>>.broadcast();

    final process = AttestorProcess(
      id: id,
      type: 'extractJSONValueIndex',
      request: ExtractJsonValueIndexRequest(jsonString: jsonString, jsonPath: jsonPathExpression),
      response: responseCompleter.future,
      updateStream: updatesController.stream,
    );

    () async {
      try {
        final teeOperator = await getOperator();
        final ranges = await teeOperator.extractJSONValueIndexes(jsonString, jsonPathExpression);
        if (ranges.isEmpty) {
          responseCompleter.complete('');
        } else {
          final range = ranges.first;
          final start = range['start']!;
          final end = range['end']!;
          final extractedValue = jsonString.substring(start, end);
          responseCompleter.complete(extractedValue);
        }
      } catch (e, s) {
        log.severe('🔐 TEE: JSON extraction failed', e, s);
        responseCompleter.completeError(e, s);
      } finally {
        updatesController.close();
      }
    }();

    return process;
  }

  @override
  AttestorProcess<SetAttestorDebugLevelRequest, Object?> setAttestorDebugLevel(String level) {
    // Logs handled from listener and sent to logging, no need of this for AttestorTeeClient
    return AttestorProcess(
      id: 'no-op',
      type: 'setAttestorDebugLevel',
      request: SetAttestorDebugLevelRequest(logLevel: level, sendLogsToApp: true),
      response: Future.value(null),
      updateStream: const Stream.empty(),
    );
  }
  //Debug part for delete after release
  //   Future<void> _saveRequestParamsToFile(Map<String, dynamic> params) async {
  //     try {
  //       // Hardcoded path for logs
  //       const logsPath = '/Users/laith/new-arch/reclaim-inapp-sdk/logs';
  //       final directory = Directory(logsPath);

  //       // Create directory if it doesn't exist
  //       if (!await directory.exists()) {
  //         await directory.create(recursive: true);
  //       }

  //       final file = File('$logsPath/tee_request_params.txt');

  //       // Pretty print JSON
  //       final encoder = const JsonEncoder.withIndent('  ');
  //       final prettyJson = encoder.convert(params);

  //       // Append to file with separator
  //       final content =
  //           '''
  // $prettyJson

  // ''';

  //       await file.writeAsString(content, mode: FileMode.append);
  //       logger.info('🔐 TEE: Request params saved to: ${file.path}');
  //     } catch (e) {
  //       logger.warning('🔐 TEE: Failed to save request params to file: $e');
  //     }
  //   }

  @override
  bool get isFaulty => false;

  @override
  Future<void> dispose() async {
    // Clean up TEE log subscriptions
    await _progressSubscription?.cancel();

    logger.info('🔐 TEE Client disposed and log subscriptions cancelled');
  }
}
