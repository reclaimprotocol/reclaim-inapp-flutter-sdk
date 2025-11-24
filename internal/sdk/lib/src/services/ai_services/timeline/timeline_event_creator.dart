import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../constants.dart';
import '../../../logging/logging.dart';
import 'timeline_event_types.dart';

/// Helper class for creating timeline events with predefined configurations
/// Usage: aiClient.createTimelineEvent.sendEvents(message)
class TimelineEventCreator {
  final String sessionId;
  final http.Client client;

  TimelineEventCreator({required this.sessionId, required this.client});

  Future<TimelineEventResponse> sendEvents(String message, {Map<String, dynamic>? details}) {
    return _sendTimelineEvent(
      eventType: 'send_events',
      message: message,
      severity: TimelineEventSeverity.info,
      details: details,
    );
  }

  Future<TimelineEventResponse> executeAction(String message, {Map<String, dynamic>? details}) {
    return _sendTimelineEvent(
      eventType: 'execute_action',
      message: message,
      severity: TimelineEventSeverity.info,
      details: details,
    );
  }

  Future<TimelineEventResponse> error(String message, {Map<String, dynamic>? details}) {
    return _sendTimelineEvent(
      eventType: 'error',
      message: message,
      severity: TimelineEventSeverity.error,
      details: details,
    );
  }

  Future<TimelineEventResponse> warning(String message, {Map<String, dynamic>? details}) {
    return _sendTimelineEvent(
      eventType: 'warning',
      message: message,
      severity: TimelineEventSeverity.warning,
      details: details,
    );
  }

  Future<TimelineEventResponse> proofGeneratedSuccess(String message, {Map<String, dynamic>? details}) {
    return _sendTimelineEvent(
      eventType: 'proof_generated_success',
      message: message,
      severity: TimelineEventSeverity.success,
      details: details,
    );
  }

  Future<TimelineEventResponse> proofGenerationFailed(String message, {Map<String, dynamic>? details}) {
    return _sendTimelineEvent(
      eventType: 'proof_generation_failed',
      message: message,
      severity: TimelineEventSeverity.error,
      details: details,
    );
  }

  /// Generic custom event (use predefined methods when possible)
  Future<TimelineEventResponse> custom({
    required String eventType,
    required String message,
    TimelineEventSeverity severity = TimelineEventSeverity.info,
    Map<String, dynamic>? details,
  }) {
    return _sendTimelineEvent(eventType: eventType, message: message, severity: severity, details: details);
  }

  /// Internal method to send a timeline event to the AI service
  Future<TimelineEventResponse> _sendTimelineEvent({
    required String eventType,
    required String message,
    required TimelineEventSeverity severity,
    Map<String, dynamic>? details,
  }) async {
    final logger = logging.child('TimelineEventCreator._sendTimelineEvent');

    try {
      // Prepare request body
      final body = {
        'sessionId': sessionId,
        'eventType': eventType,
        'source': 'app', // Always 'app' since this is app-side
        'message': message,
        'severity': severity.toJson(),
        if (details != null) 'details': details,
      };

      logger.info('Creating timeline event: $body');

      final response = await client.post(
        Uri.parse('${ReclaimUrls.AI_SERVICE_BASE_URL}/timeline/event'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      final responseData = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        logger.info('Timeline event created successfully');
        return TimelineEventResponse.fromJson(responseData);
      } else {
        logger.warning('Failed to create timeline event: ${response.statusCode} - ${response.body}');
        return TimelineEventResponse(
          success: false,
          message: responseData['message'] as String? ?? 'Failed to create timeline event',
          error: responseData['error'] as String?,
        );
      }
    } catch (e, stackTrace) {
      logger.severe('Error creating timeline event', e, stackTrace);
      return TimelineEventResponse(
        success: false,
        message: 'Exception occurred while creating timeline event',
        error: e.toString(),
      );
    }
  }
}
