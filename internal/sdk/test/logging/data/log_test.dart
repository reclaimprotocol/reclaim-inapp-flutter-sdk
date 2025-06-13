import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_inapp_sdk/src/logging/data/log.dart';

DateTime _fromTimeStampToDateTime(String ts) {
  final ms = (num.parse(ts) / 1000000).round();
  final date = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  return date;
}

void main() {
  group('LogEntry', () {
    test('fromDateTimeToTimeStamp', () {
      DateTime now = DateTime.parse('2024-09-27 14:44:00+05:30');
      final result = _fromTimeStampToDateTime(LogEntry.fromDateTimeToTimeStamp(now));
      expect(result.toLocal(), now.toLocal());
      expect(result.toUtc(), now.toUtc());
      expect(result.toUtc().toString(), '2024-09-27 09:14:00.000Z');
    });
  });
}
