part of 'claim_creation.dart';

typedef OnSubmitProofsCallback = void Function(Iterable<CreateClaimOutput>);
typedef OnContinuePressedCallback = void Function(String nextLocation);
typedef OnExceptionCallback = void Function(ReclaimException e);

class ClaimCreationUIDelegateOptions {
  final bool autoSubmit;
  final String appId;
  final OnSubmitProofsCallback onSubmitProofs;
  final OnContinuePressedCallback onContinue;
  final OnExceptionCallback onException;

  const ClaimCreationUIDelegateOptions({
    required this.autoSubmit,
    required this.appId,
    required this.onSubmitProofs,
    required this.onContinue,
    required this.onException,
  });

  static ClaimCreationUIDelegateOptions? of(
    BuildContext context, {
    bool listen = true,
  }) {
    late ClaimCreationUIDelegateInheritedWidget? widget;
    if (!listen) {
      widget =
          context
              .getInheritedWidgetOfExactType<
                ClaimCreationUIDelegateInheritedWidget
              >();
    } else {
      widget =
          context
              .dependOnInheritedWidgetOfExactType<
                ClaimCreationUIDelegateInheritedWidget
              >();
    }
    return widget?.options;
  }
}

class ClaimCreationUIDelegateInheritedWidget extends InheritedWidget {
  const ClaimCreationUIDelegateInheritedWidget({
    super.key,
    required this.options,
    required super.child,
  });

  final ClaimCreationUIDelegateOptions options;

  @override
  bool updateShouldNotify(
    covariant ClaimCreationUIDelegateInheritedWidget oldWidget,
  ) {
    return options != oldWidget.options;
  }
}

abstract class ClaimCreationUIDelegate extends State<ClaimCreationScope> {
  late final ClaimTriggerIndicatorController _claimTriggerIndicatorController;

  @override
  @mustCallSuper
  void initState() {
    super.initState();
    widget.controller._setDelegate(this);
    _claimTriggerIndicatorController = ClaimTriggerIndicatorController();
  }

  @override
  @mustCallSuper
  void didUpdateWidget(covariant ClaimCreationScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller._setDelegate(null);
      widget.controller._setDelegate(this);
    }
  }

  ClaimCreationUIDelegateOptions get claimCreationUIDelegateOptions;

  @override
  @mustCallSuper
  void dispose() {
    widget.controller._setDelegate(null);
    _claimTriggerIndicatorController.dispose();
    super.dispose();
  }

  bool _isBottomSheetOpen = false;

  bool get isBottomSheetOpen => _isBottomSheetOpen;

  Future<void> _showBottomSheet() async {
    _claimTriggerIndicatorController.remove();
    if (isBottomSheetOpen) return;
    _isBottomSheetOpen = true;
    if (mounted) {
      await ClaimCreationBottomSheet.open(
        context,
        claimCreationController: widget.controller,
        options: claimCreationUIDelegateOptions,
      );
    }
    _isBottomSheetOpen = false;
  }

  Future<void> _onClaimUpdate(
    Map<dynamic, dynamic> step,
    ClaimRequestIdentifier requestIdentifier,
  ) async {
    final logger = logging.child(
      'ClaimCreationDelegate._onClaimUpdate.step.$requestIdentifier',
    );
    logger.finer(step);
    if (!mounted) {
      logger.finest('Not mounted');
      return;
    }

    // show bottom sheet when waiting for response
    return _showBottomSheet();
  }
}
