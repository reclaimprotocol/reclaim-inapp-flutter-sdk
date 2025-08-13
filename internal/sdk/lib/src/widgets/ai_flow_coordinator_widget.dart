import 'dart:async';
import 'package:flutter/widgets.dart';

import '../controller.dart';
import '../data/app_events.dart';
import '../data/web_context.dart';
import '../services/ai_services/ai_client_services.dart';
import '../usecase/ai_flow/ai_flow_coordinator.dart';
import '../usecase/ai_flow/handler_map_config.dart';

/// A widget that manages the AIFlowCoordinator instance and provides it to its descendants.
/// This widget must be used within a context that has both [ActionBarMessenger] and [ClaimCreationWebClientViewModel] available.
class AIFlowCoordinatorWidget extends StatefulWidget {
  final Widget child;
  final bool? isAiProvider; // Made optional to support dynamic detection
  static AIFlowCoordinator? _coordinator;
  static bool _isAiProvider = false;

  const AIFlowCoordinatorWidget({super.key, required this.child, this.isAiProvider});

  /// Returns the [AIFlowCoordinator] instance from the nearest [AIFlowCoordinatorWidget].
  static AIFlowCoordinator of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<_AIFlowCoordinatorProvider>();
    assert(provider != null, 'No AIFlowCoordinatorWidget found in context');
    return provider!.coordinator;
  }

  static AIFlowCoordinator? maybeOf(BuildContext context) {
    try {
      final provider = context.dependOnInheritedWidgetOfExactType<_AIFlowCoordinatorProvider>();
      return provider?.coordinator;
    } catch (e) {
      return null;
    }
  }

  /// Pushes an event to the AI flow coordinator without requiring context.
  static void pushEvent(AppEvent event) {
    if (_isAiProvider) {
      _coordinator?.pushEvent(event);
    }
  }

  /// Returns the WebContext from the nearest AIFlowCoordinatorWidget, or null if not found.
  /// This is a safe alternative to directly accessing the webContext when the widget might not be available.
  static WebContext? maybeWebContext(BuildContext context) {
    final coordinator = maybeOf(context);
    return coordinator?.webContext;
  }

  @override
  State<AIFlowCoordinatorWidget> createState() => _AIFlowCoordinatorWidgetState();
}

class _AIFlowCoordinatorWidgetState extends State<AIFlowCoordinatorWidget> {
  AIFlowCoordinator? _coordinator;
  bool? _isAiProvider;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _setupAIProviderDetection();
    _initializeCoordinator();
  }

  void _setupAIProviderDetection() {
    // If isAiProvider is explicitly provided, use it
    if (widget.isAiProvider != null) {
      _isAiProvider = widget.isAiProvider;
      AIFlowCoordinatorWidget._isAiProvider = widget.isAiProvider!;
      return;
    }

    // Otherwise, detect dynamically from verification controller
    final verificationController = VerificationController.readOf(context);
    _checkIfAiProvider(verificationController);

    _subscription = verificationController.subscribe((change) {
      final (oldValue, value) = change.record;
      if (oldValue?.provider != value.provider) {
        _checkIfAiProvider(verificationController);
      }
    });
  }

  void _checkIfAiProvider(VerificationController verificationController) {
    final isAiProvider = verificationController.value.provider?.isAIProvider == true;
    if (_isAiProvider != isAiProvider) {
      setState(() {
        _isAiProvider = isAiProvider;
      });
      AIFlowCoordinatorWidget._isAiProvider = isAiProvider;
    }
  }

  Future<void> _initializeCoordinator() async {
    final controller = VerificationController.readOf(context);
    final session = await controller.sessionStartFuture;

    final handlerMap = configureHandlerMap();
    final aiClient = AiServiceClient(session.sessionInformation.sessionId, session.identity.providerId);
    final config = AIFlowCoordinatorConfig();

    if (!mounted) return;
    setState(() {
      _coordinator = AIFlowCoordinator(handlerMap: handlerMap, aiClient: aiClient, config: config);
      AIFlowCoordinatorWidget._coordinator = _coordinator;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _coordinator?.dispose();
    AIFlowCoordinatorWidget._coordinator = null;
    AIFlowCoordinatorWidget._isAiProvider = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Changing positions of widget in tree can cause recreation of descendant widgets and listeners to miss events.
    if (_coordinator == null) {
      return SizedBox(child: widget.child);
    }
    return _AIFlowCoordinatorProvider(coordinator: _coordinator!, child: widget.child);
  }
}

class _AIFlowCoordinatorProvider extends InheritedWidget {
  final AIFlowCoordinator coordinator;

  const _AIFlowCoordinatorProvider({required this.coordinator, required super.child});

  @override
  bool updateShouldNotify(_AIFlowCoordinatorProvider oldWidget) {
    return coordinator != oldWidget.coordinator;
  }
}
