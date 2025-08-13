import 'dart:async';
import '../data/ai_response.dart';
import '../logging/logging.dart';
import '../services/ai_services/ai_client_services.dart';

class AiResponsePuller {
  final AiServiceClient _client;
  Timer? _timer;
  final _logger = logging.child('AiResponsePuller');
  final _responseController = StreamController<AIResponse>.broadcast();

  Stream<AIResponse> get responseStream => _responseController.stream;

  AiResponsePuller(this._client);

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final response = await _client.getAIResponse();
        _responseController.add(response);
      } catch (e) {
        _logger.severe('Error in AI response puller: $e');
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _responseController.close();
  }
}
