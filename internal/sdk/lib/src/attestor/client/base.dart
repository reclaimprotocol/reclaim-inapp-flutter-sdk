import 'dart:async';

import 'package:meta/meta.dart';
import 'package:reclaim_flutter_sdk/src/utils/provider_performance_report.dart';

import '../claim/options.dart';
import '../claim/request.dart';
import '../data/data.dart';
import '../data/request.dart';
import '../operator/operator.dart';
import 'package:reclaim_flutter_sdk/types/claim_creation_type.dart';

typedef AttestorResponseTransformer<RESPONSE> =
    FutureOr<RESPONSE> Function(dynamic value);
typedef AttestorCreateClaimPerformanceReportCallback =
    void Function(Iterable<ZKComputePerformanceReport> performanceReports);

abstract class AttestorClient {
  AttestorClient();

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

  AttestorProcess<AttestorClaimRequest, List<AttestorClaimResponse>> createClaim({
    required Map<String, Object?> request,
    required AttestorClaimOptions options,
    AttestorCreateClaimPerformanceReportCallback? onPerformanceReports,
  }) {
    final result = sendRequest(
      type: options.claimCreationType.type,
      request: AttestorClaimRequest.create(
        request: request,
        options: options,
        operationType:
            zkOperator != null
                ? ZKOperationType.gnarkRpc
                : ZKOperationType.snarkJs,
      ),
      transformResponse: (value) {
        if (onPerformanceReports != null) {
          onPerformanceReports(List.unmodifiable([..._performanceReports]));
        }
        _clearPerformanceReports();
        if (options.claimCreationType == ClaimCreationType.onMeChain) {
          return AttestorClaimResponse.fromMeChainJson(value);
        }
        return [AttestorClaimResponse.fromJson(value)];
      },
    );

    return result;
  }

  AttestorProcess<ExtractHtmlElementRequest, String> extractHtmlElement(
    String htmlString,
    String xPathExpression,
  ) {
    return sendRequest(
      type: 'extractHtmlElement',
      request: ExtractHtmlElementRequest(
        html: htmlString,
        xpathExpression: xPathExpression,
        contentsOnly: false,
      ),
      transformResponse: (value) => value?.toString() ?? '',
    );
  }

  AttestorProcess<ExtractJsonValueIndexRequest, String> extractJSONValueIndex(
    String jsonString,
    String jsonPathExpression,
  ) {
    return sendRequest(
      type: 'extractJSONValueIndex',
      request: ExtractJsonValueIndexRequest(
        jsonString: jsonString,
        jsonPath: jsonPathExpression,
      ),
      transformResponse: (value) {
        final start = (value['start'] as num).toInt();
        final end = (value['end'] as num).toInt();
        assert(end >= start, 'start of this range should precede end');
        return jsonString.substring(start, end);
      },
    );
  }

  AttestorProcess<SetAttestorDebugLevelRequest, Object?> setAttestorDebugLevel(
    String level,
  ) {
    return sendRequest(
      type: 'setLogLevel',
      request: SetAttestorDebugLevelRequest(
        logLevel: level,
        sendLogsToApp: false,
      ),
      transformResponse: (value) => value,
    );
  }

  AttestorProcess<REQUEST, RESPONSE> sendRequest<REQUEST, RESPONSE>({
    required String type,
    // request should be json serializable
    required REQUEST request,
    required AttestorResponseTransformer<RESPONSE> transformResponse,
  });

  Future<void> dispose();
}
