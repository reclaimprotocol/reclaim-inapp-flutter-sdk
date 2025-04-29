// dart format width=250

import 'dart:math' as math;

import 'package:measure_performance/measure_performance.dart';
import 'package:meta/meta.dart';
import 'package:reclaim_flutter_sdk/logging/logging.dart';
export 'package:measure_performance/measure_performance.dart';

Map<String, Object?> _reportToJsonMapConverter(PerformanceReport report) {
  return {
    'started_at': report.startedAt.toIso8601String(),
    'stopped_at': report.stoppedAt.toIso8601String(),
    'elapsed': report.elapsed.inMicroseconds,
    'memory_usage_before_start_bytes': report.memoryUsageBeforeStartBytes,
    'memory_usage_after_stop_bytes': report.memoryUsageAfterStoppedBytes,
    // don't need this for now
    // 'memory_usage_bytes': report.memoryUsageBytes,
  };
}

class ProviderRequestPerformanceReport {
  final PerformanceReport requestReport;
  final Iterable<ZKComputePerformanceReport> proofs;

  const ProviderRequestPerformanceReport({required this.requestReport, required this.proofs});

  Map<String, Object?> toJson() {
    return {'request': requestReport.copyWith(toJsonMapConverter: _reportToJsonMapConverter), 'number_of_proofs': proofs.length, 'proofs': proofs.toList()};
  }
}

class ZKComputePerformanceReport {
  final String algorithmName;
  final PerformanceReport report;

  ZKComputePerformanceReport({required this.algorithmName, required this.report});

  Map<String, Object?> toJson() {
    return {'algorithmName': algorithmName, 'report': report.copyWith(toJsonMapConverter: _reportToJsonMapConverter)};
  }
}

extension ZKComputePerformanceReportNullableIterable on Iterable<ZKComputePerformanceReport?> {
  ZKComputePerformanceReport? get firstRecord {
    if (isEmpty) return null;
    return whereType<ZKComputePerformanceReport>().reduce((a, b) => a.report.startedAt.isBefore(b.report.startedAt) ? a : b);
  }

  ZKComputePerformanceReport? get lastRecord {
    if (isEmpty) return null;
    return whereType<ZKComputePerformanceReport>().reduce((a, b) => a.report.stoppedAt.isAfter(b.report.stoppedAt) ? a : b);
  }
}

extension PerformanceReportNullableIterable on Iterable<PerformanceReport?> {
  PerformanceReport? get firstRecord {
    if (isEmpty) return null;
    return whereType<PerformanceReport>().reduce((a, b) => a.startedAt.isBefore(b.startedAt) ? a : b);
  }

  PerformanceReport? get lastRecord {
    if (isEmpty) return null;
    return whereType<PerformanceReport>().reduce((a, b) => a.stoppedAt.isAfter(b.stoppedAt) ? a : b);
  }
}

extension MathIterable on Iterable<int> {
  int get sum {
    if (isEmpty) return 0;
    return fold(0, (a, b) => a + b);
  }

  int get average {
    if (isEmpty) return 0;
    return (fold(0, (a, b) => a + b) / length).round();
  }

  int get max {
    if (isEmpty) return 0;
    return fold(0, math.max);
  }

  int? get min {
    if (isEmpty) return null;
    return fold(null, (a, b) {
      if (a == null) return b;
      return math.min(a, b);
    });
  }
}

extension MathIterableNested on Iterable<Iterable<int>> {
  int get averageNested {
    if (isEmpty) return 0;
    final nestedSum = map((e) => e.sum).sum;
    final nestedLength = map((e) => e.length).sum;

    return (nestedSum / nestedLength).round();
  }
}

class ProviderRequestPerformanceMeasurements {
  final Iterable<ProviderRequestPerformanceReport> reports;

  const ProviderRequestPerformanceMeasurements({required this.reports});

  Map<String, Object?> toJson() {
    final statistics = () {
      try {
        return getStatistics();
      } catch (e, s) {
        logging.warning('Error getting statistics', e, s);
      }
    }();
    return {'reports': reports.toList(), 'statistics': statistics};
  }

  @visibleForTesting
  Map<String, dynamic> getStatistics() {
    final numberOfProofs = reports.map((e) => e.proofs.length);
    final requestReports = reports.map((e) => e.requestReport);
    final algorithmNames = reports.map((e) => e.proofs.map((e) => e.algorithmName)).fold(<String>{}, (a, b) {
      return {...a, ...b};
    });

    return {
      'number_of_proof_compute_per_request_max': numberOfProofs.max,
      'number_of_proof_compute_per_request_min': numberOfProofs.min ?? 0,
      'number_of_proof_compute_per_request_avg': numberOfProofs.average,
      'request_compute_time_elapsed_first': requestReports.firstRecord?.elapsed.inMicroseconds,
      'request_compute_time_elapsed_last': requestReports.lastRecord?.elapsed.inMicroseconds,
      'request_compute_time_elapsed_max': requestReports.map((e) => e.elapsed.inMicroseconds).max,
      'request_compute_time_elapsed_min': requestReports.map((e) => e.elapsed.inMicroseconds).min ?? 0,
      'request_compute_time_elapsed_avg': requestReports.map((e) => e.elapsed.inMicroseconds).average,
      'request_compute_memory_usage_first': requestReports.firstRecord?.memoryUsageBytes.firstOrNull,
      'request_compute_memory_usage_last': requestReports.lastRecord?.memoryUsageBytes.lastOrNull,
      'request_compute_memory_usage_max': requestReports.map((e) => e.maxMemoryUsageBytes).max,
      'request_compute_memory_usage_min': requestReports.map((e) => e.minMemoryUsageBytes).min ?? 0,
      'request_compute_memory_usage_avg': requestReports.map((e) => e.averageMemoryUsageBytes).average,
      'by_algorithm':
          algorithmNames.map((algorithmName) {
            final proofByAlgorithm = reports.map((e) => e.proofs.where((proof) => proof.algorithmName == algorithmName));

            return {
              'algorithm_name': algorithmName,
              'proof_compute_time_elapsed_first': proofByAlgorithm.map((e) => e.firstRecord).firstRecord?.report.elapsed.inMicroseconds,
              'proof_compute_time_elapsed_last': proofByAlgorithm.map((e) => e.lastRecord).lastRecord?.report.elapsed.inMicroseconds,
              'proof_compute_time_elapsed_max': proofByAlgorithm.map((e) => e.map((e) => e.report.elapsed.inMicroseconds).max).max,
              'proof_compute_time_elapsed_min': proofByAlgorithm.map((e) => e.map((e) => e.report.elapsed.inMicroseconds).min).whereType<int>().min,
              'proof_compute_time_elapsed_avg': proofByAlgorithm.map((e) => e.map((e) => e.report.elapsed.inMicroseconds)).averageNested,
              'proof_compute_memory_usage_first': proofByAlgorithm.map((e) => e.firstRecord).firstRecord?.report.memoryUsageBytes.firstOrNull,
              'proof_compute_memory_usage_last': proofByAlgorithm.map((e) => e.firstRecord).lastRecord?.report.memoryUsageBytes.lastOrNull,
              'proof_compute_memory_usage_max': proofByAlgorithm.map((e) => e.map((e) => e.report.maxMemoryUsageBytes).max).max,
              'proof_compute_memory_usage_min': proofByAlgorithm.map((e) => e.map((e) => e.report.minMemoryUsageBytes).min).whereType<int>().min,
              'proof_compute_memory_usage_avg': proofByAlgorithm.map((e) => e.map((e) => e.report.averageMemoryUsageBytes)).averageNested,
            };
          }).toList(),
    };
  }
}
