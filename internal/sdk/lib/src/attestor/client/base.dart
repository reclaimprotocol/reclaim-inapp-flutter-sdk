import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:web_socket/web_socket.dart';

import '../../data/claim_creation_type.dart';
import '../../data/create_claim.dart';
import '../../logging/logging.dart';
import '../../utils/provider_performance_report.dart';
import '../claim/options.dart';
import '../claim/request.dart';
import '../data/data.dart';
import '../data/message.dart';
import '../data/request.dart';
import '../exception/exception.dart';
import '../operator/operator.dart';
import 'manager.dart';

export '../data/message.dart';
export '../exception/exception.dart';

typedef AttestorResponseTransformer<RESPONSE> = FutureOr<RESPONSE> Function(dynamic value);
typedef AttestorCreateClaimPerformanceReportCallback =
    void Function(Iterable<ZKComputePerformanceReport> performanceReports);

abstract class AttestorClient {
  final String debugLabel;
  final DateTime createdAt;

  @protected
  // Using runtime type as name in debug mode to make it easier to identify the client in logs
  // In release mode, we use a string constant because real runtime type names may be obfuscated
  late final Logger logger = logging.child(
    '${kDebugMode ? runtimeType.toString() : 'AttestorClient'}#$hashCode.$debugLabel',
  );

  AttestorClient({required this.debugLabel}) : createdAt = DateTime.now();

  static Duration getClientAge(AttestorClient client) {
    return client.createdAt.difference(DateTime.now()).abs();
  }

  int _notRespondingCount = 0;

  int get notRespondingCount => _notRespondingCount;

  void markNotResponding() {
    _notRespondingCount++;
  }

  void markResponding() {
    _notRespondingCount = 0;
  }

  bool get isFaulty => _notRespondingCount > 6;

  Future<void> ensureReady();

  AttestorZkOperator? zkOperator;

  final List<ZKComputePerformanceReport> _performanceReports = [];

  @protected
  void addPerformanceReport(ZKComputePerformanceReport report) {
    _performanceReports.add(report);
  }

  void _clearPerformanceReports() {
    _performanceReports.clear();
  }

  AttestorProcess<AttestorClaimRequest, List<CreateClaimOutput>> createClaim({
    required Map<String, Object?> request,
    required AttestorClaimOptions options,
    AttestorCreateClaimPerformanceReportCallback? onPerformanceReports,
  }) {
    final result = sendRequest(
      type: options.claimCreationType.type,
      request: AttestorClaimRequest.create(
        request: request,
        options: options,
        operationType: zkOperator != null ? ZKOperationType.gnarkRpc : ZKOperationType.snarkJs,
      ),
      transformResponse: (value) {
        if (onPerformanceReports != null) {
          onPerformanceReports(List.unmodifiable([..._performanceReports]));
        }
        _clearPerformanceReports();
        if (options.claimCreationType == ClaimCreationType.meChain) {
          return CreateClaimOutput.fromMeChainJson(value);
        }
        return [CreateClaimOutput.fromJson(value)];
      },
    );

    return result;
  }

  AttestorProcess<ExtractHtmlElementRequest, String> extractHtmlElement(String htmlString, String xPathExpression) {
    return sendRequest(
      type: 'extractHtmlElement',
      request: ExtractHtmlElementRequest(html: htmlString, xpathExpression: xPathExpression, contentsOnly: false),
      transformResponse: (value) => value?.toString() ?? '',
    );
  }

  AttestorProcess<ExtractJsonValueIndexRequest, String> extractJSONValueIndex(
    String jsonString,
    String jsonPathExpression,
  ) {
    return sendRequest(
      type: 'extractJSONValueIndex',
      request: ExtractJsonValueIndexRequest(jsonString: jsonString, jsonPath: jsonPathExpression),
      transformResponse: (value) {
        final start = (value['start'] as num).toInt();
        final end = (value['end'] as num).toInt();
        assert(end >= start, 'start of this range should precede end');
        return jsonString.substring(start, end);
      },
    );
  }

  AttestorProcess<SetAttestorDebugLevelRequest, Object?> setAttestorDebugLevel(String level) {
    return sendRequest(
      type: 'setLogLevel',
      request: SetAttestorDebugLevelRequest(logLevel: level, sendLogsToApp: false),
      transformResponse: (value) => value,
    );
  }

  AttestorProcess<Object?, Object?> ping() {
    return sendRequest(type: 'ping', request: null, transformResponse: (value) => value);
  }

  final Map<String, AttestorRpcProcessManager> _processManagers = {};

  @protected
  AttestorRpcProcessManager? getProcessManagerById(String id) {
    return _processManagers[id];
  }

  @protected
  List<AttestorRpcProcessManager> getProcessManagers() {
    return _processManagers.values.toList();
  }

  /// Post a message to the attestor client's browser rpc handler
  Future<void> postMessage(RpcMessage rpcMessage);

  static const String hostMessengerChannelName = 'HostMessenger';

  AttestorProcess<REQUEST, RESPONSE> sendRequest<REQUEST, RESPONSE>({
    required String type,
    // request should be json serializable
    required REQUEST request,
    required FutureOr<RESPONSE> Function(dynamic value) transformResponse,
  }) {
    final log = logger.child('sendRequest');
    log.info({'tag': 'sendRequest', 'type': type, 'request': request});

    final manager = AttestorRpcProcessManager<REQUEST, RESPONSE>.create(
      requestType: type,
      request: request,
      transformer: transformResponse,
    );

    log.info({'tag': 'manager', 'manager': manager});

    final process = manager.process;

    log.info({'tag': 'process', 'process': process, 'process.id': process.id});

    _processManagers[process.id] = manager;

    log.info({
      'tag': 'process.id',
      'process.id': process.id,
      'event': 'sending message',
      'currentManagers': getProcessManagers().map((e) => e.process.id).toList(),
    });

    () async {
      try {
        await postMessage(process.createRequest(channel: hostMessengerChannelName));
        log.info({'tag': 'response'});
      } catch (e, s) {
        log.severe('Error sending request', e, s);
        final completer = manager.completer;
        if (completer.isCompleted) return;
        completer.completeError(AttestorRequestMessagingException(e), s);
      }
    }();

    log.info({'tag': 'process.id', 'process.id': process.id, 'event': 'message sent'});

    return process;
  }

  final Map<String, WebSocket> _sockets = {};

  @protected
  void addSocket(String id, WebSocket ws) {
    _sockets[id] = ws;
  }

  @protected
  WebSocket? getSocketById(String id) {
    return _sockets[id];
  }

  @protected
  Future<void> removeSocket(String id) async {
    final ws = _sockets.remove(id);
    try {
      await ws?.close();
    } catch (e, s) {
      if (e is WebSocketConnectionClosed) {
        return;
      }
      logger.severe('Error closing socket $ws for id $id', e, s);
    }
  }

  @mustCallSuper
  Future<void> dispose() async {
    logger.info('disposing with following managers: ${_processManagers.values.map((e) => e.process.id).toList()}');
    for (final controller in _processManagers.values) {
      controller.onCancel();
    }

    _processManagers.clear();

    for (final s in _sockets.entries) {
      s.value.close().catchError((e, s) {
        logger.severe('Error closing socket $s for id ${s.key}', e, s);
      });
    }
    _sockets.clear();
  }

  @override
  String toString() {
    return 'AttestorClient(debugLabel: $debugLabel, createdAt: $createdAt, age: ${AttestorClient.getClientAge(this)})';
  }
}
