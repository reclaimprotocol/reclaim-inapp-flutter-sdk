import 'dart:async';

import '../../../data/app_events.dart';
import '../../../data/web_context.dart';
import '../../../services/ai_services/ai_client_services.dart';
import '../../../services/ai_services/job_status_manager.dart';
import '../ai_flow_handler.dart';

/// A handler that batches events and processes them periodically.
class BatchProcessingHandler extends AIFlowHandler {
  final List<AppEvent> _pendingEvents = [];
  Timer? _processTimer;
  bool _isProcessing = false;
  final _jobStatusManager = JobStatusManager();
  final Duration refreshInterval;
  final AIJobType jobType;

  BatchProcessingHandler({required this.refreshInterval, required this.jobType});

  @override
  Future<void> handle(AppEvent event, AiServiceClient aiClient, WebContext webContext) async {
    _pendingEvents.add(event);

    _processTimer ??= Timer.periodic(refreshInterval, (_) {
      if (webContext.aiFlowDone) {
        _processTimer?.cancel();
        _processTimer = null;
      } else {
        processPendingEvents(aiClient);
      }
    });
  }

  /// Processes all pending events immediately, regardless of the timer.
  Future<void> processPendingEvents(AiServiceClient aiClient) async {
    if (_isProcessing) return;
    if (_pendingEvents.isEmpty) return;

    _isProcessing = true;

    try {
      // Create a copy of pending events and clear the original list
      final eventsToProcess = List<AppEvent>.from(_pendingEvents);
      _pendingEvents.clear();

      final jobId = _jobStatusManager.generateJobId();
      await aiClient.sendEvent(eventsToProcess, jobId, jobType, null);
    } finally {
      _isProcessing = false;
    }
  }

  @override
  void dispose() {
    _processTimer?.cancel();
    _processTimer = null;
    _pendingEvents.clear();
  }
}
