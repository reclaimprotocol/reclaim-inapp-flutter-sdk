import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import '../logging/logging.dart';
import '../utils/observable_notifier.dart';
import 'claim_creation/claim_creation.dart';
import 'claim_creation/trigger_indicator.dart';

part 'action_bar_host.dart';

typedef AsyncActionCallback = FutureOr<void> Function();

class ActionBarAction {
  final String label;
  final AsyncActionCallback onActionPressed;

  const ActionBarAction({required this.label, required this.onActionPressed});

  @override
  bool operator ==(Object other) {
    if (other is ActionBarAction) {
      return label == other.label && onActionPressed == other.onActionPressed;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(label.hashCode, onActionPressed.hashCode);

  @override
  String toString() {
    return 'ActionBarAction(label: $label, onActionPressed: $onActionPressed)';
  }
}

enum ActionMessageType {
  // primary colored indicator to indicate that the claim creation is triggered.
  claim,
  // yellow colored indicator to indicate that the processing (e.g ai) is triggered.
  processing,
  // error colored indicator to indicate that the claim creation failed.
  error,
  // no indicator should be visible.
  message,
}

enum ActionBarRule { clearAfterLogin }

class ActionBarMessage {
  /// The duration of the message. If null, the message will be persistent and not removed by a timer.
  final Duration? duration;

  /// The label that should be shown for this action. If null, only indicator is shown.
  final Widget? label;
  final ActionBarAction? action;
  final ActionMessageType type;
  final bool removeIndicatorOnClose;
  final Set<ActionBarRule> rules;

  const ActionBarMessage({
    this.duration,
    this.label,
    this.action,
    this.type = ActionMessageType.message,
    this.removeIndicatorOnClose = true,
    this.rules = const {},
  });

  ActionBarMessage copyWith({
    Duration? duration,
    Widget? label,
    ActionBarAction? action,
    ActionMessageType? type,
    bool? removeIndicatorOnClose,
    Set<ActionBarRule>? rules,
  }) {
    return ActionBarMessage(
      duration: duration ?? this.duration,
      label: label ?? this.label,
      action: action ?? this.action,
      type: type ?? this.type,
      removeIndicatorOnClose: removeIndicatorOnClose ?? this.removeIndicatorOnClose,
      rules: rules ?? this.rules,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is ActionBarMessage) {
      return duration == other.duration &&
          label == other.label &&
          action == other.action &&
          type == other.type &&
          removeIndicatorOnClose == other.removeIndicatorOnClose &&
          rules == other.rules;
    }
    return false;
  }

  @override
  int get hashCode {
    return Object.hash(duration, label, action, type, removeIndicatorOnClose, rules);
  }

  @override
  String toString() {
    return 'ActionBarMessage(duration: $duration, label: ${label != null ? "<widget>" : null}, action: $action, type: $type, removeIndicatorOnClose: $removeIndicatorOnClose, rules: $rules)';
  }
}

enum ActionBarClosedReason { timeout, swipe, action, removed, closed }

class ActionBarState {
  final ActionBarMessage message;
  final ActionBarClosedReason? reason;

  const ActionBarState({required this.message, required this.reason});

  ActionBarState copyWith({ActionBarMessage? message, ActionBarClosedReason? reason}) {
    return ActionBarState(message: message ?? this.message, reason: reason ?? this.reason);
  }

  @override
  bool operator ==(Object other) {
    if (other is ActionBarState) {
      return message == other.message && reason == other.reason;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(message.hashCode, reason.hashCode);

  @override
  String toString() {
    return 'ActionBarState(message: $message, reason: $reason)';
  }
}

class ActionBarController extends ObservableNotifier<ActionBarState> {
  ActionBarController(super.value);

  Future<ActionBarClosedReason> get closed {
    final reason = value.reason;
    if (reason != null) return Future.value(reason);
    return stream.firstWhere((it) => it.reason != null).then((it) {
      final reason = it.reason;
      if (reason == null) {
        // unknown reason.
        return ActionBarClosedReason.closed;
      }
      return reason;
    });
  }

  void _onClose(ActionBarClosedReason reason) {
    if (value.reason != null) return;
    value = value.copyWith(message: value.message, reason: reason);
  }

  void close() {
    _onClose(ActionBarClosedReason.closed);
  }
}

/// Manages the display of action bar lifecycle and UI.
/// Right now, internally uses a snackbar and claimTriggerIndicator for display, will be implemented internally soon.
///
/// Because of the use of snackbar, requires a Material App as an ancestor and Scaffold in its context
class ActionBarMessenger extends StatefulWidget {
  const ActionBarMessenger({super.key, required this.child});

  final Widget child;

  static ActionBarMessengerState of(BuildContext context) {
    final state = maybeOf(context);
    assert(state != null, 'ActionBarMessenger not found in context');
    return state!;
  }

  static ActionBarMessengerState readOf(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<_ActionBarMessengerScope>();
    final state = scope?.messengerState;
    assert(state != null, 'ActionBarMessenger not found in context');
    return state!;
  }

  static ActionBarMessengerState? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_ActionBarMessengerScope>();
    return scope?.messengerState;
  }

  @override
  State<ActionBarMessenger> createState() => _ActionBarMessengerState();
}

abstract interface class ActionBarMessengerState {
  void clear();

  ActionBarController show(ActionBarMessage message, {bool replace = true});

  void hideByRule(ActionBarRule rule);

  bool get hasMessages;
}

mixin ActionBarMessengerStateImpl implements ActionBarMessengerState, State<ActionBarMessenger> {
  static final Queue<ActionBarController> _queuedControllers = Queue();

  @override
  void clear() {
    final controllers = [..._queuedControllers];
    for (final controller in controllers) {
      controller._onClose(ActionBarClosedReason.removed);
    }
    _queuedControllers.clear();
    _updateMessaging();
  }

  void _registerController(ActionBarController controller) {
    _queuedControllers.add(controller);
    controller.closed.then((reason) {
      _queuedControllers.remove(controller);
      controller.dispose();
      _updateMessaging();
    });
    _updateMessaging();
  }

  @override
  bool get hasMessages {
    return _queuedControllers.isNotEmpty;
  }

  @override
  ActionBarController show(ActionBarMessage message, {bool replace = true}) {
    if (replace) {
      clear();
    }
    final controller = ActionBarController(ActionBarState(message: message, reason: null));
    _registerController(controller);
    return controller;
  }

  @override
  void hideByRule(ActionBarRule rule) {
    final controllers = [..._queuedControllers];
    for (final controller in controllers) {
      if (controller.value.message.rules.contains(rule)) {
        controller._onClose(ActionBarClosedReason.removed);
        _queuedControllers.remove(controller);
      }
    }
    _updateMessaging();
  }

  late ValueNotifier<ActionBarController?> _currentControllerNotifier;

  void _updateMessaging() {
    if (!mounted) return;
    final controller = _queuedControllers.firstOrNull;
    if (_currentControllerNotifier.value == controller) return;

    if (controller != null) {
      controller.closed.then((reason) {
        if (!mounted) return;
        if (_currentControllerNotifier.value == controller) {
          _currentControllerNotifier.value = null;
        }
      });
    }

    _currentControllerNotifier.value = controller;
  }
}

class _ActionBarMessengerState extends State<ActionBarMessenger> with ActionBarMessengerStateImpl {
  late final ClaimTriggerIndicatorController _claimTriggerIndicatorController;

  @override
  void initState() {
    super.initState();
    _claimTriggerIndicatorController = ClaimTriggerIndicatorController();
    _currentControllerNotifier = ValueNotifier(ActionBarMessengerStateImpl._queuedControllers.firstOrNull);
  }

  @override
  void dispose() {
    _currentControllerNotifier.dispose();
    _claimTriggerIndicatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _claimTriggerIndicatorController.wrap(
      child: _ActionBarMessengerScope(
        messengerState: this,
        child: _ActionBarHost(notifier: _currentControllerNotifier, child: widget.child),
      ),
    );
  }
}

class _ActionBarMessengerScope extends InheritedWidget {
  const _ActionBarMessengerScope({required super.child, required this.messengerState});

  final ActionBarMessengerState messengerState;

  @override
  bool updateShouldNotify(covariant _ActionBarMessengerScope oldWidget) {
    return oldWidget.messengerState != messengerState;
  }
}
