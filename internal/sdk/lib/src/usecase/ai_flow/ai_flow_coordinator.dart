import 'dart:async';

import 'package:synchronized/synchronized.dart';

import '../../data/app_events.dart';
import '../../data/web_context.dart';
import '../../logging/logging.dart';
import '../../services/ai_services/ai_client_services.dart';
import 'ai_flow_handler.dart';

/// Configuration for the AIFlowCoordinator
class AIFlowCoordinatorConfig {
  final Duration handlerTimeout;
  final int maxRetries;
  final Duration retryDelay;

  const AIFlowCoordinatorConfig({
    this.handlerTimeout = const Duration(seconds: 10),
    this.maxRetries = 2,
    this.retryDelay = const Duration(seconds: 1),
  });
}

class AIFlowCoordinator {
  final Map<Type, List<AIFlowHandler>> _handlerMap;
  final AiServiceClient _aiClient;
  final AIFlowCoordinatorConfig _config;
  final _lock = Lock();
  final _queue = <Future<void> Function()>[];
  bool _isProcessing = false;
  final _logger = logging.child('AIFlowCoordinator');
  final WebContext _webContext = WebContext();

  AIFlowCoordinator({
    required Map<Type, List<AIFlowHandler>> handlerMap,
    required AiServiceClient aiClient,
    AIFlowCoordinatorConfig? config,
  }) : _handlerMap = handlerMap,
       _aiClient = aiClient,
       _config = config ?? const AIFlowCoordinatorConfig();

  AiServiceClient get aiClient => _aiClient;

  WebContext get webContext => _webContext;

  Future<void> _processQueue() async {
    if (_isProcessing) return;

    await _lock.synchronized(() async {
      if (_isProcessing) return;
      _isProcessing = true;
    });

    try {
      while (true) {
        Future<void> Function()? nextTask;

        await _lock.synchronized(() {
          if (_queue.isEmpty) {
            _isProcessing = false;
            return;
          }
          nextTask = _queue.removeAt(0);
        });

        if (nextTask == null) break;

        try {
          await nextTask!();
        } catch (e, stackTrace) {
          _logger.severe('Error processing queue task', e, stackTrace);
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _executeHandlerWithRetry(AIFlowHandler handler, AppEvent event) async {
    var retries = 0;
    while (retries <= _config.maxRetries) {
      try {
        await handler.handle(event, _aiClient, _webContext).timeout(_config.handlerTimeout);
        return;
      } catch (e) {
        if (retries == _config.maxRetries) {
          rethrow;
        }
        retries++;
        await Future.delayed(_config.retryDelay * retries);
      }
    }
  }

  void pushEvent(AppEvent event) {
    final logger = logging.child('AIFlowCoordinator.pushEvent');
    final eventType = event.runtimeType;

    // Handler lookup
    final handlers = _handlerMap;

    if (handlers.isEmpty) {
      logger.warning('No handlers registered for event type $eventType');
      return;
    }

    // Get handlers for this event type
    final List<AIFlowHandler> eventHandlers = handlers[eventType] ?? [];
    if (eventHandlers.isEmpty) {
      logger.warning('No handlers registered for event type $eventType');
      return;
    }

    // Add handlers to queue
    for (final handler in eventHandlers) {
      final handlerName = handler.runtimeType.toString();

      _lock.synchronized(() {
        _queue.add(() async {
          try {
            await _executeHandlerWithRetry(handler, event);
          } catch (e, stackTrace) {
            logger.severe('Error in handler $handlerName for $eventType', e, stackTrace);
          }
        });
      });
    }

    // Start processing the queue if not already processing
    _processQueue();
  }

  void dispose() {
    // Dispose any handlers that need cleanup
    for (final handlers in _handlerMap.values) {
      for (final handler in handlers) {
        handler.dispose();
      }
    }
  }
}
