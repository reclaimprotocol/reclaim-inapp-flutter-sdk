import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:uuid/uuid.dart';

import '../constants.dart';
import '../logging/data/log.dart';
import '../logging/logging.dart';
import '../utils/http/http.dart';
import 'preferences/preference.dart';
import 'source/source.dart';

class DiagnosticLogging {
  final http.Client client;

  DiagnosticLogging([http.Client? client]) : client = client ?? ReclaimHttpClient();

  final Preference<String?, String> _deviceLoggingIdPreference = Preference(key: '_DEVICE_LOGGING_ID');

  Future<String> getDeviceLoggingId() async {
    final id = await _deviceLoggingIdPreference.value;
    if (id != null) {
      return id;
    }
    final newId = Uuid().v4();
    await _deviceLoggingIdPreference.setValue(newId);
    return newId;
  }

  Future<void> sendLogs(List<LogEntry> entries) async {
    try {
      final body = json.encode({
        'logs': entries,
        'source': await getClientSource(),
        'deviceId': await getDeviceLoggingId(),
      });
      final response = await client.post(
        Uri.parse(ReclaimUrls.DIAGNOSTIC_LOGGING),
        headers: {'content-type': 'application/json'},
        body: body,
      );
      if (!response.isSuccess) {
        logging.severe(
          'Failed to send ${entries.length} logs [${utf8.encode(body).lengthInBytes} B] (batch ${entries.hashCode})',
          response.body,
        );
      }
    } catch (e, s) {
      logging.severe('Failed to send logs (batch ${entries.hashCode})', e, s);
    }
  }

  void dispose() {
    client.close();
  }
}
