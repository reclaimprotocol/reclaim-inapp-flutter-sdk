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
import 'timeline/timeline_event_creator.dart';

typedef AiServiceMetadata = Map<String, dynamic>;

enum AIJobType { network_request, page_loaded, user_interaction }

class AiServiceClient {
  final String sessionId;
  final String providerId;
  final String? _sessionToken;
  final http.Client client;

  AiServiceClient(this.sessionId, this.providerId, {String? sessionToken, http.Client? client})
    : _sessionToken = sessionToken,
      client = client ?? ReclaimHttpClient();

  late final Map<String, String> _authHeaders = {
    'Content-Type': 'application/json',
    if (_sessionToken != null) 'Authorization': 'Bearer $_sessionToken',
  };

  late final TimelineEventCreator createTimelineEvent = TimelineEventCreator(
    sessionId: sessionId,
    client: client,
    sessionToken: _sessionToken,
  );

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

      final msg = 'Sending Events to AI Service: length: ${eventDataList.length} types: $eventsTypes';

      logger.info(msg);
      logger.info(
        'Events payload: sessionId=$sessionId, providerId=$providerId, chunkId=$jobId, jobType=${jobType.name}, requestCount=${eventDataList.length}',
      );
      for (final event in eventDataList) {
        logger.info(
          'Event: url=${event['url']}, reqBodyLen=${event['requestBody']?.toString().length ?? 0}, resBodyLen=${event['responseBody']?.toString().length ?? 0}',
        );
      }

      final response = await client.post(
        Uri.parse(ReclaimUrls.AI_SERVICE_SEND_EVENTS),
        headers: _authHeaders,
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
        headers: _authHeaders,
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

      if (_sessionToken != null) {
        request.headers['Authorization'] = 'Bearer $_sessionToken';
      }

      // Send request
      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
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
    final responseType = (now ~/ 5000) % 8;

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
        return SetAIProofsAction.fromJson({
          "identifier": "0xfe2eb73e2047a21182736ec969b50d695f8f788afa5b5ce8451189b1615134e5",
          "claimData": {
            "provider": "http",
            "parameters":
                "{\"additionalClientOptions\":{},\"body\":\"{\\\"includeGroups\\\":false,\\\"includeLogins\\\":false,\\\"includeVerificationStatus\\\":true}\",\"geoLocation\":\"\",\"headers\":{\"Sec-Fetch-Mode\":\"same-origin\",\"Sec-Fetch-Site\":\"same-origin\",\"User-Agent\":\"AppleWebKit/602.1.50 (KHTML, like Gecko) CriOS/56.0.2924.75\",\"accept\":\"application/json\"},\"method\":\"POST\",\"paramValues\":{\"username\":\"karamshbeb\"},\"responseMatches\":[{\"invert\":false,\"type\":\"contains\",\"value\":\"\\\"userName\\\":\\\"{{username}}\\\"\"}],\"responseRedactions\":[{\"jsonPath\":\"\$.userName\",\"regex\":\"\\\"userName\\\":\\\"(.*)\\\"\",\"xPath\":\"\"}],\"url\":\"https://www.kaggle.com/api/i/users.UsersService/GetCurrentUser\"}",
            "owner": "0xf5393eb1b27bc0869d8402aac4336575d248d7dc",
            "timestampS": 1757077872,
            "context":
                "{\"extractedParameters\":{\"username\":\"karamshbeb\"},\"isAIProofs\":true,\"providerHash\":\"0xc9e2404b50af02ddd8797e218f19b0b2a896cdcd9dbf9ea525b89db2fa37de76\"}",
            "identifier": "0xfe2eb73e2047a21182736ec969b50d695f8f788afa5b5ce8451189b1615134e5",
            "epoch": 1,
          },
          "signatures": [
            "0x36391c8aba08878f85f1bda850aaab25749fba6e8b0f0117051585a3ca805a0a696ca0b1a6333cd44563a9a2ba9c3c4ae348e0bbc04a263bb498db83ba7855891c",
          ],
          "witnesses": [
            {"id": "0x244897572368eadf65bfbc5aec98d8e5443a9072", "url": "wss://attestor.reclaimprotocol.org/ws"},
          ],
          "publicData": null,
          "providerRequest": {
            "bodySniff": {
              "enabled": false,
              "template": "{\"includeGroups\":false,\"includeLogins\":false,\"includeVerificationStatus\":true}",
            },
            "credentials": "include",
            "expectedPageUrl": "",
            "method": "POST",
            "requestHash": "0x8f3ebf2865a1dce8f5c070ea087a3af86ee9127b82dc79cefff76c45d8968c42",
            "responseMatches": [
              {"invert": false, "type": "contains", "value": "\"userName\":\"{{username}}\""},
            ],
            "responseRedactions": [
              {"jsonPath": "\$.userName", "regex": "\"userName\":\"(.*)\"", "xPath": ""},
            ],
            "url": "https://www.kaggle.com/api/i/users.UsersService/GetCurrentUser",
            "urlType": "TEMPLATE",
          },
        });
      case 7:
        return const GoBackAction();
      default:
        return const NoAction();
    }
  }
}
