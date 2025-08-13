import 'dart:async';

import '../../../data/app_events.dart';
import '../../../data/web_context.dart';
import '../../../logging/logging.dart';
import '../../../services/ai_services/ai_client_services.dart';
import '../ai_flow_handler.dart';

class UserInputDetectionHandler implements AIFlowHandler {
  @override
  Future<void> handle(AppEvent event, AiServiceClient aiClient, WebContext webContext) async {
    final logger = logging.child('UserInputDetectionHandler');
    if (event is UserInteractionEvent && webContext.lastInputUrl.isEmpty) {
      if (event.interactionType == InteractionType.input) {
        logger.info('event.metadata: ${event.metadata}');
        webContext.setLastInputUrl(event.metadata?['url'] ?? '');
      }
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
  }
}
