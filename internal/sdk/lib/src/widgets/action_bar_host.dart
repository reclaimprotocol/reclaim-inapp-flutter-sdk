part of 'action_bar.dart';

class _ActionBarHost extends StatefulWidget {
  const _ActionBarHost({required this.notifier, required this.child});

  final ValueNotifier<ActionBarController?> notifier;
  final Widget child;

  @override
  State<_ActionBarHost> createState() => _ActionBarHostState();
}

class _ActionBarHostState extends State<_ActionBarHost> {
  @override
  void initState() {
    super.initState();
    final notifier = widget.notifier;
    notifier.addListener(_onNotifierUpdate);
    _controller = widget.notifier.value;
    _controller?.addListener(_onActionControllerUpdate);
  }

  @override
  void didUpdateWidget(covariant _ActionBarHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.notifier != oldWidget.notifier) {
      oldWidget.notifier.removeListener(_onNotifierUpdate);
      widget.notifier.addListener(_onNotifierUpdate);
      _onNotifierUpdate();
    }
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onNotifierUpdate);
    super.dispose();
  }

  ActionBarController? _controller;

  void _onNotifierUpdate() {
    final nextController = widget.notifier.value;
    if (nextController == _controller) return;
    final previousController = _controller;
    _controller = nextController;

    previousController?.removeListener(_onActionControllerUpdate);
    nextController?.addListener(_onActionControllerUpdate);
    _onActionControllerUpdate();
  }

  ActionBarState? actionState;

  void _onActionControllerUpdate() {
    final ctrl = _controller;
    final newActionState = ctrl?.value;
    if (ctrl == null || newActionState == null) return;
    actionState = newActionState;
    try {
      _onActionStateUpdate(ctrl);
      // TODO: update entry or exit animation.
      // TODO: setup timer to close the action bar.
    } catch (e, s) {
      _logger.severe('Error in onControllerChanged', e, s);
    }
  }

  Color _getSurfaceColor(ActionMessageType type) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    switch (type) {
      case ActionMessageType.claim:
        return colorScheme.primary;
      case ActionMessageType.processing:
        return Color(0xffffc636);
      case ActionMessageType.error:
        return colorScheme.error;
      case ActionMessageType.message:
        return const Color(0xFFF7F7F8);
    }
  }

  Color _getActionColor(ActionMessageType type) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    switch (type) {
      case ActionMessageType.claim:
      case ActionMessageType.message:
        return colorScheme.primary;
      case ActionMessageType.processing:
        return Colors.black;
      case ActionMessageType.error:
        return Colors.black;
    }
  }

  final _logger = logging.child('ActionBarHost');

  Timer? _indicatorRemovalTimer;

  late ScaffoldMessengerState _scaffoldMessenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  void _onActionStateUpdate(ActionBarController actionBarCtrl) {
    final log = _logger.child('onControllerChanged');
    log.finest('onControllerChanged with message: ${actionBarCtrl.value}');

    late ScaffoldFeatureController<SnackBar, SnackBarClosedReason> snackbarCtrl;
    if (!mounted) return;
    final claimCreationController = ClaimCreationController.of(context, listen: false);
    if (claimCreationController.value.hasProviderScriptError &&
        actionBarCtrl.value.message.type != ActionMessageType.error) {
      // No need for any more updates when provider error
      return;
    }
    final msg = _scaffoldMessenger;
    msg.clearSnackBars();
    msg.removeCurrentSnackBar();

    final indicatorNotifier = ClaimTriggerIndicatorController.readOf(context);

    final message = actionBarCtrl.value.message;
    final duration = message.duration ?? const Duration(seconds: 60 * 10);

    switch (message.type) {
      case ActionMessageType.claim:
        indicatorNotifier.notifyClaim();
        break;
      case ActionMessageType.processing:
        indicatorNotifier.notifyProcessing();
        break;
      case ActionMessageType.error:
        indicatorNotifier.notifyError(duration);
        break;
      case ActionMessageType.message:
        indicatorNotifier.remove(false);
        break;
    }

    final action = message.action;

    bool isClosed = false;

    void onContentClosed() {
      isClosed = true;
    }

    actionBarCtrl.closed.then((reason) {
      switch (reason) {
        case ActionBarClosedReason.closed:
        case ActionBarClosedReason.timeout:
        case ActionBarClosedReason.swipe:
        case ActionBarClosedReason.action:
          if (message.removeIndicatorOnClose) {
            indicatorNotifier.remove();
          }
        default:
      }
    });

    final label = message.label;
    if (action == null && label == null) {
      _indicatorRemovalTimer?.cancel();
      _indicatorRemovalTimer = Timer(duration, () {
        onContentClosed();
        indicatorNotifier.remove();
      });
      return;
    }

    late final ThemeData theme = Theme.of(context);
    late final ColorScheme colors = theme.colorScheme;
    final contentTextStyle = (Theme.of(context).textTheme.bodyMedium ?? TextStyle()).copyWith(
      color: colors.onSurface,
      fontWeight: FontWeight.bold,
    );

    final surfaceColor = _getSurfaceColor(message.type);
    final backgroundColor = Color.lerp(surfaceColor, const Color(0xFFF7F7F8), 0.96);
    final handler = _SnackBarActionHandler();
    final actionColor = _getActionColor(message.type);

    final canDismiss = duration > Duration(seconds: 5);

    snackbarCtrl = msg.showSnackBar(
      SnackBar(
        hitTestBehavior: HitTestBehavior.translucent,
        backgroundColor: backgroundColor,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: action != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            if (label != null)
              Padding(
                padding: EdgeInsets.only(top: (action != null || canDismiss) ? 8.0 : 0.0),
                child: DefaultTextStyle(
                  style: contentTextStyle,
                  textAlign: action != null ? TextAlign.start : TextAlign.center,
                  child: label,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (action != null)
                    _SnackBarAction(
                      handler: handler,
                      label: action.label.toUpperCase(),
                      backgroundColor: Colors.transparent, // actionColor.withValues(alpha: 0.08),
                      textColor: actionColor,
                      onPressed: action.onActionPressed,
                    ),
                  if (canDismiss)
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: colors.onSurface),
                      onPressed: () {
                        msg.hideCurrentSnackBar(reason: SnackBarClosedReason.dismiss);
                      },
                      child: Text(
                        MaterialLocalizations.of(context).modalBarrierDismissLabel.toUpperCase(),
                        style: TextStyle(color: colors.onSurface),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        // show this for a very long time
        duration: duration,
      ),
    );

    snackbarCtrl.closed.then((value) async {
      if (isClosed) return;
      onContentClosed();
      actionBarCtrl._onClose(switch (value) {
        SnackBarClosedReason.action => ActionBarClosedReason.action,
        SnackBarClosedReason.dismiss => ActionBarClosedReason.swipe,
        SnackBarClosedReason.swipe => ActionBarClosedReason.swipe,
        SnackBarClosedReason.hide => ActionBarClosedReason.removed,
        SnackBarClosedReason.remove => ActionBarClosedReason.removed,
        SnackBarClosedReason.timeout => ActionBarClosedReason.timeout,
      });
    });

    actionBarCtrl.closed.then((reason) {
      if (isClosed) return;
      onContentClosed();
      switch (reason) {
        case ActionBarClosedReason.closed:
          snackbarCtrl.close();
          break;
        default:
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _SnackBarAction extends StatefulWidget implements SnackBarAction {
  /// Creates an action for a [SnackBar].
  const _SnackBarAction({
    this.textColor,
    // ignore: unused_element_parameter
    this.disabledTextColor,
    this.backgroundColor,
    // ignore: unused_element_parameter
    this.disabledBackgroundColor,
    required this.label,
    required this.onPressed,
    required this.handler,
  });

  /// The button label color. If not provided, defaults to
  /// [SnackBarThemeData.actionTextColor].
  ///
  /// If [textColor] is a [WidgetStateColor], then the text color will be
  /// resolved against the set of [WidgetState]s that the action text
  /// is in, thus allowing for different colors for states such as pressed,
  /// hovered and others.
  @override
  final Color? textColor;

  /// The button background fill color. If not provided, defaults to
  /// [SnackBarThemeData.actionBackgroundColor].
  ///
  /// If [backgroundColor] is a [WidgetStateColor], then the text color will
  /// be resolved against the set of [WidgetState]s that the action text is
  /// in, thus allowing for different colors for the states.
  @override
  final Color? backgroundColor;

  /// The button disabled label color. This color is shown after the
  /// [SnackBarAction] is dismissed.
  @override
  final Color? disabledTextColor;

  /// The button disabled background color. This color is shown after the
  /// [SnackBarAction] is dismissed.
  ///
  /// If not provided, defaults to [SnackBarThemeData.disabledActionBackgroundColor].
  @override
  final Color? disabledBackgroundColor;

  /// The button label.
  @override
  final String label;

  /// The callback to be called when the button is pressed.
  ///
  /// This callback will be called at most once each time this action is
  /// displayed in a [SnackBar].
  @override
  // ignore: overridden_fields
  final AsyncActionCallback onPressed;

  final _SnackBarActionHandler handler;

  @override
  State<_SnackBarAction> createState() => _SnackBarActionState();
}

class _SnackBarActionHandler {
  VoidCallback? handlePressed;
}

class _SnackBarActionState extends State<_SnackBarAction> {
  @override
  void initState() {
    super.initState();
    widget.handler.handlePressed = _handlePressed;
  }

  bool _haveTriggeredAction = false;

  void _handlePressed() async {
    if (_haveTriggeredAction) {
      return;
    }
    setState(() {
      _haveTriggeredAction = true;
    });
    final msg = ScaffoldMessenger.of(context);
    try {
      await widget.onPressed();
    } catch (e, s) {
      logging.child('_SnackBarActionState').severe('Error in onPressed', e, s);
    }
    msg.hideCurrentSnackBar(reason: SnackBarClosedReason.action);
  }

  @override
  Widget build(BuildContext context) {
    final SnackBarThemeData defaults = _SnackbarDefaultsM3(context);
    final SnackBarThemeData snackBarTheme = Theme.of(context).snackBarTheme;

    WidgetStateColor resolveForegroundColor() {
      if (widget.textColor != null) {
        if (widget.textColor is WidgetStateColor) {
          return widget.textColor! as WidgetStateColor;
        }
      } else if (snackBarTheme.actionTextColor != null) {
        if (snackBarTheme.actionTextColor is WidgetStateColor) {
          return snackBarTheme.actionTextColor! as WidgetStateColor;
        }
      } else if (defaults.actionTextColor != null) {
        if (defaults.actionTextColor is WidgetStateColor) {
          return defaults.actionTextColor! as WidgetStateColor;
        }
      }

      return WidgetStateColor.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return widget.disabledTextColor ?? snackBarTheme.disabledActionTextColor ?? defaults.disabledActionTextColor!;
        }
        return widget.textColor ?? snackBarTheme.actionTextColor ?? defaults.actionTextColor!;
      });
    }

    WidgetStateColor? resolveBackgroundColor() {
      if (widget.backgroundColor is WidgetStateColor) {
        return widget.backgroundColor! as WidgetStateColor;
      }
      if (snackBarTheme.actionBackgroundColor is WidgetStateColor) {
        return snackBarTheme.actionBackgroundColor! as WidgetStateColor;
      }
      return WidgetStateColor.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return widget.disabledBackgroundColor ?? snackBarTheme.disabledActionBackgroundColor ?? Colors.transparent;
        }
        return widget.backgroundColor ?? snackBarTheme.actionBackgroundColor ?? Colors.transparent;
      });
    }

    return TextButton(
      style: TextButton.styleFrom(
        overlayColor: resolveForegroundColor(),
      ).copyWith(foregroundColor: resolveForegroundColor(), backgroundColor: resolveBackgroundColor()),
      onPressed: _haveTriggeredAction ? null : _handlePressed,
      child:
          _haveTriggeredAction
              ? SizedBox.square(dimension: 16, child: CircularProgressIndicator())
              : Text(widget.label),
    );
  }
}

class _SnackbarDefaultsM3 extends SnackBarThemeData {
  _SnackbarDefaultsM3(this.context);

  final BuildContext context;
  late final ThemeData _theme = Theme.of(context);
  late final ColorScheme _colors = _theme.colorScheme;

  @override
  Color get backgroundColor => _colors.inverseSurface;

  @override
  Color get actionTextColor => WidgetStateColor.resolveWith((Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return _colors.inversePrimary;
    }
    if (states.contains(WidgetState.pressed)) {
      return _colors.inversePrimary;
    }
    if (states.contains(WidgetState.hovered)) {
      return _colors.inversePrimary;
    }
    if (states.contains(WidgetState.focused)) {
      return _colors.inversePrimary;
    }
    return _colors.inversePrimary;
  });

  @override
  Color get disabledActionTextColor => _colors.inversePrimary;

  @override
  TextStyle get contentTextStyle => Theme.of(context).textTheme.bodyMedium!.copyWith(color: _colors.onInverseSurface);

  @override
  double get elevation => 6.0;

  @override
  ShapeBorder get shape => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0)));

  @override
  SnackBarBehavior get behavior => SnackBarBehavior.fixed;

  @override
  EdgeInsets get insetPadding => const EdgeInsets.fromLTRB(15.0, 5.0, 15.0, 10.0);

  @override
  bool get showCloseIcon => false;

  @override
  Color? get closeIconColor => _colors.onInverseSurface;

  @override
  double get actionOverflowThreshold => 0.25;
}
