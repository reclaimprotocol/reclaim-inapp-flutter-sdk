import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../build_env.dart';
import '../../constants.dart';
import '../../data/ai_response.dart';
import '../../data/app_events.dart';
import '../../logging/logging.dart';
import '../../utils/http/http.dart';

typedef AiServiceMetadata = Map<String, dynamic>;

enum AIJobType { network_request, page_loaded, user_interaction }

class AiServiceClient {
  final String sessionId;
  final String providerId;
  final http.Client client;

  AiServiceClient(this.sessionId, this.providerId, [http.Client? client]) : client = client ?? ReclaimHttpClient();

  Future<void> sendEvent<T extends AppEvent>(
    List<T> events,
    int jobId,
    AIJobType jobType,
    AiServiceMetadata? metadata,
  ) async {
    final logger = logging.child('AiServiceClient.sendEvent');
    try {
      logger.info('Sending events to AI service');

      // Convert list of events to list of maps
      final List<Map<String, dynamic>> eventDataList = events.map((event) {
        final Map<String, dynamic> eventData = event.toJson();
        if (metadata != null) {
          eventData['metadata'] = metadata;
        }
        return eventData;
      }).toList();

      final data = {
        'sessionId': sessionId,
        'providerId': providerId,
        'chunkId': jobId,
        'jobType': jobType.name,
        'requests': eventDataList,
      };
      final jsonData = json.encode(data);

      logger.info('Events list length: ${eventDataList.length}');
      logger.info('events types are: ${events.map((e) => e.runtimeType).toList()}');
      // logger.info('Events data: $data');

      final response = await client.post(
        Uri.parse(ReclaimUrls.AI_SERVICE_SEND_EVENTS),
        headers: {'Content-Type': 'application/json'},
        body: jsonData,
      );
      logger.info('Events sent successfully to AI service: $response');
    } catch (e) {
      logger.severe('Error sending events to AI service: $e');
    }
  }

  Future<AIResponse> getAIResponse() async {
    final logger = logging.child('AiServiceClient.getAIResponse');
    if (BuildEnv.MOCK_AI_SERVICE) {
      logger.info('Using mock AI response');
      return _getMockAIResponse();
    }
    try {
      final response = await client.get(
        Uri.parse('${ReclaimUrls.AI_SERVICE_GET_AI_RESPONSE}/$sessionId'),
        headers: {'Content-Type': 'application/json'},
      );
      logger.info('AI response received: ${response.body}');
      final jsonData = json.decode(response.body);
      return AIResponse.fromJson(jsonData);
    } catch (e) {
      logger.severe('Error getting AI response: $e');
      return AIResponse(jobs: []);
    }
  }

  // Mock response for testing purposes
  AIResponse _getMockAIResponse() {
    return AIResponse(
      jobs: [
        AIJob(jobId: 1, status: 'completed', actions: [_getMockAIAction()]),
      ],
    );
  }

  AIAction _getMockAIAction() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final responseType = (now ~/ 5000) % 7;

    switch (responseType) {
      case 0:
        return const NoAction();
      case 1:
        return ShowInfoAction('This is a mock info text from the AI');
      case 2:
        return RecommendationAction('This is a mock recommendation from the AI');
      case 3:
        return NavigationAction('https://www.google.com');
      case 4:
        return ProviderVersionUpdateAction('1.0.0-ai.1');
      case 5:
        return ButtonClickAction(
          "#root > div.sc-dXvKWL.sc-kryrqB.eYNZQS.iSvphn > div > div.sc-cuTPZC.gSBegW > div.sc-fHNdyW.jrSmXv > div:nth-child(1) > a > button",
        );
      case 6:
        return const GoBackAction();
      default:
        return const NoAction();
    }
  }
}
