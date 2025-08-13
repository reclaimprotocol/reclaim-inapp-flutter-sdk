import '../../data/app_events.dart';
import '../../logging/logging.dart';
import '../../services/ai_services/ai_client_services.dart';
import 'ai_flow_handler.dart';
import 'handlers/handlers.dart';

/// Creates and configures the handler mapping for the AIFlowCoordinator.
Map<Type, List<AIFlowHandler>> configureHandlerMap() {
  final logger = logging.child('HandlerMapConfig');

  final networkRequestsHandler = BatchProcessingHandler(
    refreshInterval: const Duration(seconds: 5),
    jobType: AIJobType.network_request,
  );
  final userInteractionHandler = BatchProcessingHandler(
    refreshInterval: const Duration(seconds: 1),
    jobType: AIJobType.user_interaction,
  );

  final pageLoadedHandler = BasicAIEventHandler(
    jobType: AIJobType.page_loaded,
    sendPendingNetworkRequests: (aiClient) => networkRequestsHandler.processPendingEvents(aiClient),
  );

  final loginDetectionHandler = LoginDetectionHandler();
  final userInputDetectionHandler = UserInputDetectionHandler();

  // Define the mapping between event types and lists of handlers
  final Map<Type, List<AIFlowHandler>> handlerMap = {
    PageLoadedEvent: [loginDetectionHandler, pageLoadedHandler],
    // ClaimCreationFailedEvent: [basicHandler],
    NetworkRequestEvent: [networkRequestsHandler],
    UserInteractionEvent: [userInteractionHandler, userInputDetectionHandler],
  };

  // Log the configuration for verification
  logger.info('Handler map configured with mappings for: ${handlerMap.keys.join(', ')}');
  handlerMap.forEach((key, value) {
    logger.info(' - $key: ${value.map((h) => h.runtimeType).join(', ')}');
  });

  return handlerMap;
}
