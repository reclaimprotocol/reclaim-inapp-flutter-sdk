import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;

import '../../build_env.dart';
import '../../constants.dart';
import '../../data/ai_response.dart';
import '../../data/app_events.dart';
import '../../data/screenshot_metadata.dart';
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

      final eventsTypes = events.map((e) => e.runtimeType).toList();

      logger.info('Sending Events to AI Service: length: ${eventDataList.length} types: $eventsTypes');
      logger.info('Events data: $data');

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
      final jsonData = json.decode(response.body);
      return AIResponse.fromJson(jsonData);
    } catch (e) {
      logger.severe('Error getting AI response: $e');
      return AIResponse(jobs: []);
    }
  }

  /// Upload screenshot to AI worker flow service
  Future<void> uploadScreenshot({required ScreenshotMetadata metadata, required Uint8List imageData}) async {
    final logger = logging.child('AiServiceClient.uploadScreenshot');
    try {
      logger.fine('Uploading screenshot to AI service');

      // Create multipart request for screenshot upload
      final request = http.MultipartRequest('POST', Uri.parse('${ReclaimUrls.AI_SERVICE_BASE_URL}/screenshot'));

      // Add metadata fields
      request.fields['sessionId'] = sessionId;
      request.fields['providerId'] = providerId;
      request.fields['screenshotId'] = metadata.id;
      // Convert to UTC before sending to ensure consistent timezone handling
      request.fields['timestamp'] = metadata.timestamp.toUtc().toIso8601String();
      request.fields['url'] = metadata.url;
      request.fields['pageTitle'] = metadata.pageTitle;

      if (metadata.screenshotNumber != null) {
        request.fields['screenshotNumber'] = metadata.screenshotNumber.toString();
      }

      if (metadata.eventType != null) {
        request.fields['eventType'] = metadata.eventType!;
      }

      if (metadata.additionalData != null) {
        request.fields['additionalData'] = json.encode(metadata.additionalData);
      }

      // Add image file with proper content type
      request.files.add(
        http.MultipartFile.fromBytes(
          'screenshot',
          imageData,
          filename: metadata.filename,
          contentType: http_parser.MediaType('image', 'png'),
        ),
      );

      // Send request
      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        logger.fine('Screenshot uploaded successfully: ${metadata.id}');
      } else {
        logger.warning('Failed to upload screenshot: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      logger.severe('Error uploading screenshot to AI service', e, stackTrace);
      rethrow;
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
        return const ShowInfoAction('This is a mock info text from the AI');
      case 2:
        return const RecommendationAction('This is a mock recommendation from the AI');
      case 3:
        return const NavigationAction('https://www.google.com');
      case 4:
        return const ProviderVersionUpdateAction('1.0.0-ai.1');
      case 5:
        return const ButtonClickAction(
          "#root > div.sc-dXvKWL.sc-kryrqB.eYNZQS.iSvphn > div > div.sc-cuTPZC.gSBegW > div.sc-fHNdyW.jrSmXv > div:nth-child(1) > a > button",
        );
      case 6:
        return const GoBackAction();
      default:
        return const NoAction();
    }
  }
}
