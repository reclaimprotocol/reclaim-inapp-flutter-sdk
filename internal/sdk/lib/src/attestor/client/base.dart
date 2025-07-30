import 'dart:async';

import 'package:meta/meta.dart';

import '../../data/claim_creation_type.dart';
import '../../data/create_claim.dart';
import '../../utils/provider_performance_report.dart';
import '../claim/options.dart';
import '../claim/request.dart';
import '../data/data.dart';
import '../data/request.dart';
import '../operator/operator.dart';

typedef AttestorResponseTransformer<RESPONSE> = FutureOr<RESPONSE> Function(dynamic value);
typedef AttestorCreateClaimPerformanceReportCallback =
    void Function(Iterable<ZKComputePerformanceReport> performanceReports);

abstract class AttestorClient {
  final String debugLabel;
  final DateTime createdAt;

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

  Future<Object?> executeJavascript(String js);

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

  AttestorProcess<REQUEST, RESPONSE> sendRequest<REQUEST, RESPONSE>({
    required String type,
    // request should be json serializable
    required REQUEST request,
    required AttestorResponseTransformer<RESPONSE> transformResponse,
  });

  Future<void> dispose();

  @override
  String toString() {
    return 'AttestorClient(debugLabel: $debugLabel, createdAt: $createdAt, age: ${AttestorClient.getClientAge(this)})';
  }
}
