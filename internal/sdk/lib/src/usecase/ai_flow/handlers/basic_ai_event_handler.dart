import '../../../data/app_events.dart';
import '../../../data/web_context.dart';
import '../../../logging/logging.dart';
import '../../../services/ai_services/ai_client_services.dart';
import '../../../services/ai_services/job_status_manager.dart';
import '../ai_flow_handler.dart';

/// A basic handler that sends a single event to the AI service.
/// This handler is used for simple events that don't require complex processing.
class BasicAIEventHandler implements AIFlowHandler {
  final AIJobType jobType;
  final Future<void> Function(AiServiceClient)? sendPendingNetworkRequests;

  BasicAIEventHandler({required this.jobType, this.sendPendingNetworkRequests});

  @override
  Future<void> handle(AppEvent event, AiServiceClient aiClient, WebContext webContext) async {
    final logger = logging.child('BasicAIEventHandler');

    if (webContext.aiFlowDone) {
      logger.info('AI flow already done, skipping event ${event.runtimeType}');
      return;
    }

    logger.info('Handling event ${event.runtimeType}');

    final jobId = JobStatusManager().generateJobId();
    try {
      if (sendPendingNetworkRequests != null) {
        await sendPendingNetworkRequests!(aiClient);
      }

      await aiClient.sendEvent([event], jobId, jobType, null);
      logger.info('Successfully sent event ${event.runtimeType} to AI service');
    } catch (e, stackTrace) {
      logger.severe('Failed to send event ${event.runtimeType} to AI service', e, stackTrace);
      rethrow;
    }
  }

  @override
  void dispose() {
    // No resources to dispose of
  }
}
