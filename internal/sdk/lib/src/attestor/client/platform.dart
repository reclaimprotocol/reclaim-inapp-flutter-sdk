import 'package:flutter/foundation.dart';

import '../../data/create_claim.dart';
import '../../logging/logging.dart';
import '../../utils/provider_performance_report.dart';
import '../claim/claim.dart';
import '../data/process.dart';
import '../data/request.dart';

typedef AttestorCreateClaimPerformanceReportCallback =
    void Function(Iterable<ZKComputePerformanceReport> performanceReports);

abstract class AttestorPlatform {
  AttestorPlatform({required this.debugLabel});

  Future<void> ensureReady();

  Future<bool> isPlatformSupported();

  final String debugLabel;

  bool get isFaulty;

  int _notRespondingCount = 0;

  int get notRespondingCount => _notRespondingCount;

  void markNotResponding() {
    _notRespondingCount++;
  }

  void markResponding() {
    _notRespondingCount = 0;
  }

  @protected
  // Using runtime type as name in debug mode to make it easier to identify the client in logs
  // In release mode, we use a string constant because real runtime type names may be obfuscated
  late final Logger logger = logging.child(
    '${kDebugMode ? runtimeType.toString() : 'AttestorPlatform'}#$hashCode.$debugLabel',
  );

  AttestorProcess<SetAttestorDebugLevelRequest, Object?> setAttestorDebugLevel(String level);

  AttestorProcess<AttestorClaimRequest, List<CreateClaimOutput>> createClaim({
    required Map<String, Object?> request,
    required AttestorClaimOptions options,
    AttestorCreateClaimPerformanceReportCallback? onPerformanceReports,
  });

  AttestorProcess<ExtractJsonValueIndexRequest, String> extractJSONValueIndex(
    String jsonString,
    String jsonPathExpression,
  );

  AttestorProcess<ExtractHtmlElementRequest, String> extractHtmlElement(String htmlString, String xPathExpression);

  @mustCallSuper
  Future<void> dispose();
}
