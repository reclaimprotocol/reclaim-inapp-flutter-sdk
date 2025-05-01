import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_flutter_sdk/src/utils/provider_performance_report.dart';

void main() {
  group('ProviderRequestPerformanceMeasurements', () {
    final now = DateTime.parse('2025-04-06T12:40:00');
    test('should return the correct statistics for uniform measurements', () {
      final measurements = ProviderRequestPerformanceMeasurements(
        reports: [
          ProviderRequestPerformanceReport(
            requestReport: PerformanceReport(
              startedAt: now,
              stoppedAt: now.add(Duration(milliseconds: 100)),
              elapsed: Duration(milliseconds: 100),
              memoryUsageBeforeStartBytes: 100,
              memoryUsageAfterStoppedBytes: 120,
              memoryUsageBytes: [100, 120],
            ),
            proofs: [
              ZKComputePerformanceReport(
                algorithmName: 'algorithm-a',

                report: PerformanceReport(
                  startedAt: now,
                  stoppedAt: now.add(Duration(milliseconds: 100)),
                  elapsed: Duration(milliseconds: 100),
                  memoryUsageBeforeStartBytes: 100,
                  memoryUsageAfterStoppedBytes: 120,
                  memoryUsageBytes: [100, 120],
                ),
              ),
              ZKComputePerformanceReport(
                algorithmName: 'algorithm-b',

                report: PerformanceReport(
                  startedAt: now,
                  stoppedAt: now.add(Duration(milliseconds: 100)),
                  elapsed: Duration(milliseconds: 100),
                  memoryUsageBeforeStartBytes: 100,
                  memoryUsageAfterStoppedBytes: 120,
                  memoryUsageBytes: [100, 120],
                ),
              ),
            ],
          ),
          ProviderRequestPerformanceReport(
            requestReport: PerformanceReport(
              startedAt: now,
              stoppedAt: now.add(Duration(milliseconds: 100)),
              elapsed: Duration(milliseconds: 150),
              memoryUsageBeforeStartBytes: 80,
              memoryUsageAfterStoppedBytes: 200,
              memoryUsageBytes: [80, 200],
            ),
            proofs: [
              ZKComputePerformanceReport(
                algorithmName: 'algorithm-b',

                report: PerformanceReport(
                  startedAt: now,
                  stoppedAt: now.add(Duration(milliseconds: 100)),
                  elapsed: Duration(milliseconds: 50),
                  memoryUsageBeforeStartBytes: 100,
                  memoryUsageAfterStoppedBytes: 120,
                  memoryUsageBytes: [100, 120],
                ),
              ),
              ZKComputePerformanceReport(
                algorithmName: 'algorithm-b',

                report: PerformanceReport(
                  startedAt: now,
                  stoppedAt: now.add(Duration(milliseconds: 100)),
                  elapsed: Duration(milliseconds: 100),
                  memoryUsageBeforeStartBytes: 100,
                  memoryUsageAfterStoppedBytes: 120,
                  memoryUsageBytes: [100, 120],
                ),
              ),
            ],
          ),
          ProviderRequestPerformanceReport(
            requestReport: PerformanceReport(
              startedAt: now,
              stoppedAt: now.add(Duration(milliseconds: 100)),
              elapsed: Duration(milliseconds: 100),
              memoryUsageBeforeStartBytes: 100,
              memoryUsageAfterStoppedBytes: 120,
              memoryUsageBytes: [100, 120],
            ),
            proofs: [
              ZKComputePerformanceReport(
                algorithmName: 'algorithm-a',

                report: PerformanceReport(
                  startedAt: now,
                  stoppedAt: now.add(Duration(milliseconds: 100)),
                  elapsed: Duration(milliseconds: 100),
                  memoryUsageBeforeStartBytes: 100,
                  memoryUsageAfterStoppedBytes: 120,
                  memoryUsageBytes: [100, 120],
                ),
              ),
              ZKComputePerformanceReport(
                algorithmName: 'algorithm-b',

                report: PerformanceReport(
                  startedAt: now,
                  stoppedAt: now.add(Duration(milliseconds: 100)),
                  elapsed: Duration(milliseconds: 100),
                  memoryUsageBeforeStartBytes: 100,
                  memoryUsageAfterStoppedBytes: 120,
                  memoryUsageBytes: [100, 120],
                ),
              ),
            ],
          ),
        ],
      );

      final stats = measurements.getStatistics();

      expect(stats['number_of_proof_compute_per_request_max'], 2);
      expect(stats['number_of_proof_compute_per_request_min'], 2);
      expect(stats['number_of_proof_compute_per_request_avg'], 2);
      expect(stats['request_compute_time_elapsed_first'], 100 * 1000);
      expect(stats['request_compute_time_elapsed_last'], 100 * 1000);
      expect(stats['request_compute_time_elapsed_max'], 150 * 1000);
      expect(stats['request_compute_time_elapsed_min'], 100 * 1000);
      expect(stats['request_compute_time_elapsed_avg'], 116.667 * 1000);
      expect(stats['request_compute_memory_usage_first'], 100);
      expect(stats['request_compute_memory_usage_last'], 120);
      expect(stats['request_compute_memory_usage_max'], 200);
      expect(stats['request_compute_memory_usage_min'], 80);
      expect(stats['request_compute_memory_usage_avg'], 120);
    });

    test('should handle empty reports', () {
      final measurements = ProviderRequestPerformanceMeasurements(reports: []);

      final stats = measurements.getStatistics();

      expect(stats['number_of_proof_compute_per_request_max'], 0);
      expect(stats['number_of_proof_compute_per_request_min'], 0);
      expect(stats['number_of_proof_compute_per_request_avg'], 0);
      expect(stats['request_compute_time_elapsed_first'], null);
      expect(stats['request_compute_time_elapsed_last'], null);
      expect(stats['request_compute_time_elapsed_max'], 0);
      expect(stats['request_compute_time_elapsed_min'], 0);
      expect(stats['request_compute_time_elapsed_avg'], 0);
      expect(stats['request_compute_memory_usage_first'], null);
      expect(stats['request_compute_memory_usage_last'], null);
      expect(stats['request_compute_memory_usage_max'], 0);
      expect(stats['request_compute_memory_usage_min'], 0);
      expect(stats['request_compute_memory_usage_avg'], 0);
    });

    test('should handle reports with varying number of proofs', () {
      final measurements = ProviderRequestPerformanceMeasurements(
        reports: [
          ProviderRequestPerformanceReport(
            requestReport: PerformanceReport(
              startedAt: now.subtract(Duration(milliseconds: 100)),
              stoppedAt: now.add(Duration(milliseconds: 100)),
              elapsed: Duration(milliseconds: 100),
              memoryUsageBeforeStartBytes: 100,
              memoryUsageAfterStoppedBytes: 120,
              memoryUsageBytes: [100, 120],
            ),
            proofs: [
              ZKComputePerformanceReport(
                algorithmName: 'algorithm-a',

                report: PerformanceReport(
                  startedAt: now.subtract(Duration(milliseconds: 100)),
                  stoppedAt: now.add(Duration(milliseconds: 100)),
                  elapsed: Duration(milliseconds: 100),
                  memoryUsageBeforeStartBytes: 100,
                  memoryUsageAfterStoppedBytes: 120,
                  memoryUsageBytes: [100, 120],
                ),
              ),
            ],
          ),
          ProviderRequestPerformanceReport(
            requestReport: PerformanceReport(
              startedAt: now,
              stoppedAt: now.add(Duration(milliseconds: 150)),
              elapsed: Duration(milliseconds: 150),
              memoryUsageBeforeStartBytes: 80,
              memoryUsageAfterStoppedBytes: 200,
              memoryUsageBytes: [80, 200],
            ),
            proofs: [
              ZKComputePerformanceReport(
                algorithmName: 'algorithm-b',

                report: PerformanceReport(
                  startedAt: now,
                  stoppedAt: now.add(Duration(milliseconds: 50)),
                  elapsed: Duration(milliseconds: 50),
                  memoryUsageBeforeStartBytes: 100,
                  memoryUsageAfterStoppedBytes: 120,
                  memoryUsageBytes: [100, 120],
                ),
              ),
              ZKComputePerformanceReport(
                algorithmName: 'algorithm-b',

                report: PerformanceReport(
                  startedAt: now,
                  stoppedAt: now.add(Duration(milliseconds: 100)),
                  elapsed: Duration(milliseconds: 100),
                  memoryUsageBeforeStartBytes: 100,
                  memoryUsageAfterStoppedBytes: 120,
                  memoryUsageBytes: [100, 120],
                ),
              ),
              ZKComputePerformanceReport(
                algorithmName: 'algorithm-c',

                report: PerformanceReport(
                  startedAt: now,
                  stoppedAt: now.add(Duration(milliseconds: 150)),
                  elapsed: Duration(milliseconds: 150),
                  memoryUsageBeforeStartBytes: 100,
                  memoryUsageAfterStoppedBytes: 120,
                  memoryUsageBytes: [100, 120],
                ),
              ),
            ],
          ),
        ],
      );

      final stats = measurements.getStatistics();

      expect(stats['number_of_proof_compute_per_request_max'], 3);
      expect(stats['number_of_proof_compute_per_request_min'], 1);
      expect(stats['number_of_proof_compute_per_request_avg'], 2);

      expect(stats['request_compute_time_elapsed_first'], 100 * 1000);
      expect(stats['request_compute_time_elapsed_last'], 150 * 1000);
      expect(stats['request_compute_time_elapsed_max'], 150 * 1000);
      expect(stats['request_compute_time_elapsed_min'], 100 * 1000);
      expect(stats['request_compute_time_elapsed_avg'], 125 * 1000);
      expect(stats['request_compute_memory_usage_first'], 100);
      expect(stats['request_compute_memory_usage_last'], 200);
      expect(stats['request_compute_memory_usage_max'], 200);
      expect(stats['request_compute_memory_usage_min'], 80);
      expect(stats['request_compute_memory_usage_avg'], 125);
    });

    test('should handle reports with zero memory usage', () {
      final measurements = ProviderRequestPerformanceMeasurements(
        reports: [
          ProviderRequestPerformanceReport(
            requestReport: PerformanceReport(
              startedAt: now,
              stoppedAt: now.add(Duration(milliseconds: 100)),
              elapsed: Duration(milliseconds: 100),
              memoryUsageBeforeStartBytes: 0,
              memoryUsageAfterStoppedBytes: 0,
              memoryUsageBytes: [0, 0],
            ),
            proofs: [
              ZKComputePerformanceReport(
                algorithmName: 'algorithm-a',

                report: PerformanceReport(
                  startedAt: now,
                  stoppedAt: now.add(Duration(milliseconds: 100)),
                  elapsed: Duration(milliseconds: 100),
                  memoryUsageBeforeStartBytes: 0,
                  memoryUsageAfterStoppedBytes: 0,
                  memoryUsageBytes: [0, 0],
                ),
              ),
            ],
          ),
        ],
      );

      final stats = measurements.getStatistics();

      expect(stats['by_algorithm'][0]['proof_compute_memory_usage_first'], 0);
      expect(stats['by_algorithm'][0]['proof_compute_memory_usage_last'], 0);
      expect(stats['by_algorithm'][0]['proof_compute_memory_usage_max'], 0);
      expect(stats['by_algorithm'][0]['proof_compute_memory_usage_min'], 0);
      expect(stats['by_algorithm'][0]['proof_compute_memory_usage_avg'], 0);
      expect(stats['request_compute_memory_usage_first'], 0);
      expect(stats['request_compute_memory_usage_last'], 0);
      expect(stats['request_compute_memory_usage_max'], 0);
      expect(stats['request_compute_memory_usage_min'], 0);
      expect(stats['request_compute_memory_usage_avg'], 0);
    });

    test('should correctly encode statistics to json string', () {
      final measurements = ProviderRequestPerformanceMeasurements(
        reports: [
          ProviderRequestPerformanceReport(
            requestReport: PerformanceReport(
              startedAt: now,
              stoppedAt: now.add(Duration(milliseconds: 100)),
              elapsed: Duration(milliseconds: 100),
              memoryUsageBeforeStartBytes: 100,
              memoryUsageAfterStoppedBytes: 120,
              memoryUsageBytes: [100, 120],
            ),
            proofs: [
              ZKComputePerformanceReport(
                algorithmName: 'algorithm-a',

                report: PerformanceReport(
                  startedAt: now,
                  stoppedAt: now.add(Duration(milliseconds: 100)),
                  elapsed: Duration(milliseconds: 100),
                  memoryUsageBeforeStartBytes: 100,
                  memoryUsageAfterStoppedBytes: 120,
                  memoryUsageBytes: [100, 120],
                ),
              ),
              ZKComputePerformanceReport(
                algorithmName: 'algorithm-b',

                report: PerformanceReport(
                  startedAt: now,
                  stoppedAt: now.add(Duration(milliseconds: 100)),
                  elapsed: Duration(milliseconds: 100),
                  memoryUsageBeforeStartBytes: 100,
                  memoryUsageAfterStoppedBytes: 120,
                  memoryUsageBytes: [100, 120],
                ),
              ),
            ],
          ),
          ProviderRequestPerformanceReport(
            requestReport: PerformanceReport(
              startedAt: now,
              stoppedAt: now.add(Duration(milliseconds: 100)),
              elapsed: Duration(milliseconds: 150),
              memoryUsageBeforeStartBytes: 80,
              memoryUsageAfterStoppedBytes: 200,
              memoryUsageBytes: [80, 200],
            ),
            proofs: [
              ZKComputePerformanceReport(
                algorithmName: 'algorithm-b',

                report: PerformanceReport(
                  startedAt: now,
                  stoppedAt: now.add(Duration(milliseconds: 100)),
                  elapsed: Duration(milliseconds: 50),
                  memoryUsageBeforeStartBytes: 100,
                  memoryUsageAfterStoppedBytes: 120,
                  memoryUsageBytes: [100, 120],
                ),
              ),
              ZKComputePerformanceReport(
                algorithmName: 'algorithm-b',

                report: PerformanceReport(
                  startedAt: now,
                  stoppedAt: now.add(Duration(milliseconds: 100)),
                  elapsed: Duration(milliseconds: 100),
                  memoryUsageBeforeStartBytes: 100,
                  memoryUsageAfterStoppedBytes: 120,
                  memoryUsageBytes: [100, 120],
                ),
              ),
              ZKComputePerformanceReport(
                algorithmName: 'algorithm-a',

                report: PerformanceReport(
                  startedAt: now,
                  stoppedAt: now.add(Duration(milliseconds: 100)),
                  elapsed: Duration(milliseconds: 100),
                  memoryUsageBeforeStartBytes: 100,
                  memoryUsageAfterStoppedBytes: 120,
                  memoryUsageBytes: [100, 120],
                ),
              ),
            ],
          ),
        ],
      );

      expect(
        json.encode(measurements.getStatistics()),
        r'{"number_of_proof_compute_per_request_max":3,"number_of_proof_compute_per_request_min":2,"number_of_proof_compute_per_request_avg":3,"request_compute_time_elapsed_first":150000,"request_compute_time_elapsed_last":150000,"request_compute_time_elapsed_max":150000,"request_compute_time_elapsed_min":100000,"request_compute_time_elapsed_avg":125000,"request_compute_memory_usage_first":80,"request_compute_memory_usage_last":200,"request_compute_memory_usage_max":200,"request_compute_memory_usage_min":80,"request_compute_memory_usage_avg":125,"by_algorithm":[{"algorithm_name":"algorithm-a","proof_compute_time_elapsed_first":100000,"proof_compute_time_elapsed_last":100000,"proof_compute_time_elapsed_max":100000,"proof_compute_time_elapsed_min":100000,"proof_compute_time_elapsed_avg":100000,"proof_compute_memory_usage_first":100,"proof_compute_memory_usage_last":120,"proof_compute_memory_usage_max":120,"proof_compute_memory_usage_min":100,"proof_compute_memory_usage_avg":110},{"algorithm_name":"algorithm-b","proof_compute_time_elapsed_first":100000,"proof_compute_time_elapsed_last":100000,"proof_compute_time_elapsed_max":100000,"proof_compute_time_elapsed_min":50000,"proof_compute_time_elapsed_avg":83333,"proof_compute_memory_usage_first":100,"proof_compute_memory_usage_last":120,"proof_compute_memory_usage_max":120,"proof_compute_memory_usage_min":100,"proof_compute_memory_usage_avg":110}]}',
      );
      expect(
        json.encode(measurements),
        r'{"reports":[{"request":{"started_at":"2025-04-06T12:40:00.000","stopped_at":"2025-04-06T12:40:00.100","elapsed":100000,"memory_usage_before_start_bytes":100,"memory_usage_after_stop_bytes":120},"number_of_proofs":2,"proofs":[{"algorithmName":"algorithm-a","report":{"started_at":"2025-04-06T12:40:00.000","stopped_at":"2025-04-06T12:40:00.100","elapsed":100000,"memory_usage_before_start_bytes":100,"memory_usage_after_stop_bytes":120}},{"algorithmName":"algorithm-b","report":{"started_at":"2025-04-06T12:40:00.000","stopped_at":"2025-04-06T12:40:00.100","elapsed":100000,"memory_usage_before_start_bytes":100,"memory_usage_after_stop_bytes":120}}]},{"request":{"started_at":"2025-04-06T12:40:00.000","stopped_at":"2025-04-06T12:40:00.100","elapsed":150000,"memory_usage_before_start_bytes":80,"memory_usage_after_stop_bytes":200},"number_of_proofs":3,"proofs":[{"algorithmName":"algorithm-b","report":{"started_at":"2025-04-06T12:40:00.000","stopped_at":"2025-04-06T12:40:00.100","elapsed":50000,"memory_usage_before_start_bytes":100,"memory_usage_after_stop_bytes":120}},{"algorithmName":"algorithm-b","report":{"started_at":"2025-04-06T12:40:00.000","stopped_at":"2025-04-06T12:40:00.100","elapsed":100000,"memory_usage_before_start_bytes":100,"memory_usage_after_stop_bytes":120}},{"algorithmName":"algorithm-a","report":{"started_at":"2025-04-06T12:40:00.000","stopped_at":"2025-04-06T12:40:00.100","elapsed":100000,"memory_usage_before_start_bytes":100,"memory_usage_after_stop_bytes":120}}]}],"statistics":{"number_of_proof_compute_per_request_max":3,"number_of_proof_compute_per_request_min":2,"number_of_proof_compute_per_request_avg":3,"request_compute_time_elapsed_first":150000,"request_compute_time_elapsed_last":150000,"request_compute_time_elapsed_max":150000,"request_compute_time_elapsed_min":100000,"request_compute_time_elapsed_avg":125000,"request_compute_memory_usage_first":80,"request_compute_memory_usage_last":200,"request_compute_memory_usage_max":200,"request_compute_memory_usage_min":80,"request_compute_memory_usage_avg":125,"by_algorithm":[{"algorithm_name":"algorithm-a","proof_compute_time_elapsed_first":100000,"proof_compute_time_elapsed_last":100000,"proof_compute_time_elapsed_max":100000,"proof_compute_time_elapsed_min":100000,"proof_compute_time_elapsed_avg":100000,"proof_compute_memory_usage_first":100,"proof_compute_memory_usage_last":120,"proof_compute_memory_usage_max":120,"proof_compute_memory_usage_min":100,"proof_compute_memory_usage_avg":110},{"algorithm_name":"algorithm-b","proof_compute_time_elapsed_first":100000,"proof_compute_time_elapsed_last":100000,"proof_compute_time_elapsed_max":100000,"proof_compute_time_elapsed_min":50000,"proof_compute_time_elapsed_avg":83333,"proof_compute_memory_usage_first":100,"proof_compute_memory_usage_last":120,"proof_compute_memory_usage_max":120,"proof_compute_memory_usage_min":100,"proof_compute_memory_usage_avg":110}]}}',
      );
    });
  });
}
