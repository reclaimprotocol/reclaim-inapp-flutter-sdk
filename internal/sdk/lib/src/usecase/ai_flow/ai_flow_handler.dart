import '../../data/app_events.dart';
import '../../data/web_context.dart';
import '../../services/ai_services/ai_client_services.dart';
import '../../utils/disposable.dart';

/// Abstract interface for handlers that trigger AI flows based on AppEvents.
///
/// Implementations should initiate AI tasks via the [aiClient] but
/// MUST NOT await or return the AI processing result directly.
abstract class AIFlowHandler implements Disposable {
  /// Handles the incoming [event] by initiating appropriate AI tasks
  /// using the provided [aiClient].
  ///
  /// This method should perform necessary type checks or pattern matching
  /// on the [event] to extract relevant data required for the AI task.
  ///
  /// Returns a [Future<void>] that completes when the AI task initiation
  /// is successfully requested or started via the [aiClient]. It does *not*
  /// wait for the AI task to complete its processing. The primary goal is
  /// rapid initiation and decoupling from the AI result lifecycle.
  Future<void> handle(AppEvent event, AiServiceClient aiClient, WebContext webContext);

  /// Default implementation of dispose that does nothing.
  /// Override this method if the handler needs to clean up resources.
  @override
  void dispose() {
    // Default implementation does nothing
  }
}
