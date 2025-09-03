import 'dart:async';

import '../../../data/app_events.dart';
import '../../../data/web_context.dart';
import '../../../logging/logging.dart';
import '../../../services/ai_services/ai_client_services.dart';
import '../ai_flow_handler.dart';

class LoginDetectionHandler implements AIFlowHandler {
  @override
  Future<void> handle(AppEvent event, AiServiceClient aiClient, WebContext webContext) async {
    final logger = logging.child('LoginDetectionHandler');
    logger.info('LoginDetectionHandler is called');
    if (event is PageLoadedEvent) {
      final currentUrl = event.url;
      final lastInputUrl = webContext.lastInputUrl;
      if (currentUrl != lastInputUrl && lastInputUrl.isNotEmpty) {
        logger.info('LoginDetectionHandler: the user is potentially logged in');
        webContext.handlePotentialLoginTimeout();
      }
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
  }
}
