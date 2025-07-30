part of 'claim_creation.dart';

typedef OnSubmitProofsCallback = void Function(Iterable<CreateClaimOutput>);
typedef OnContinuePressedCallback = Future<bool> Function(String nextLocation);
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

  static ClaimCreationUIDelegateOptions? of(BuildContext context, {bool listen = true}) {
    late ClaimCreationUIDelegateInheritedWidget? widget;
    if (!listen) {
      widget = context.getInheritedWidgetOfExactType<ClaimCreationUIDelegateInheritedWidget>();
    } else {
      widget = context.dependOnInheritedWidgetOfExactType<ClaimCreationUIDelegateInheritedWidget>();
    }
    return widget?.options;
  }
}

class ClaimCreationUIDelegateInheritedWidget extends InheritedWidget {
  const ClaimCreationUIDelegateInheritedWidget({super.key, required this.options, required super.child});

  final ClaimCreationUIDelegateOptions options;

  @override
  bool updateShouldNotify(covariant ClaimCreationUIDelegateInheritedWidget oldWidget) {
    return options != oldWidget.options;
  }
}

class ClaimCreationUIScope extends StatefulWidget {
  const ClaimCreationUIScope({super.key, required this.uiDelegateOptions, required this.child});

  final ClaimCreationUIDelegateOptions uiDelegateOptions;
  final Widget child;

  @override
  State<ClaimCreationUIScope> createState() => ClaimCreationUIScopeState();
}

class ClaimCreationUIScopeState extends State<ClaimCreationUIScope> {
  late final ClaimCreationUIDelegateOptions claimCreationUIDelegateOptions = widget.uiDelegateOptions;
  late StreamSubscription _claimCreationControllerSubscription;

  @override
  @mustCallSuper
  void initState() {
    super.initState();
    final controller = ClaimCreationController.of(context, listen: false);
    _claimCreationControllerSubscription = controller.changesStream.listen(_onClaimCreationControllerChange);
    controller._setDelegate(this);
  }

  void _onClaimCreationControllerChange(ChangedValues<ClaimCreationControllerState> change) {
    final (oldValue, value) = change.record;
    if ((oldValue?.hasError != value.hasError && value.hasError) ||
        (oldValue?.providerError != value.providerError && value.providerError != null) ||
        (oldValue?.isFinished != value.isFinished && value.isFinished)) {
      logging.info('notifying error');
      final messenger = actionBarMessengerKey.currentState;
      messenger?.show(ActionBarMessage(type: ActionMessageType.claim));
      showReview();
    }
  }

  @override
  @mustCallSuper
  void dispose() {
    _claimCreationControllerSubscription.cancel();
    super.dispose();
  }

  bool get isReviewVisible => VerificationReviewController.readOf(context).value.isVisible;

  Future<void> showReview() async {
    if (isReviewVisible) return;
    if (!mounted) return;
    actionBarMessengerKey.currentState?.clear();
    final verificationReviewController = VerificationReviewController.readOf(context);

    try {
      // incase snackbar is still shown in the ui
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.clearSnackBars();
    } catch (e, s) {
      logging.severe('Failed to clear snack bars', e, s);
    }

    verificationReviewController.setIsVisible(true);
  }

  void hideReview() {
    final claimCreationController = ClaimCreationController.of(context, listen: false);
    if (claimCreationController.value.hasProviderScriptError) {
      // don't discard review screen if there's a provider script error
      return;
    }
    VerificationReviewController.readOf(context).setIsVisible(false);
  }

  Future<void> _onClaimUpdate(Map<dynamic, dynamic> step, ClaimRequestIdentifier requestIdentifier) async {
    final logger = logging.child('ClaimCreationDelegate._onClaimUpdate.step.$requestIdentifier');
    logger.finer(step);
    if (!mounted) {
      logger.finest('Not mounted');
      return;
    }

    // show bottom sheet when waiting for response
    return showReview();
  }

  final actionBarMessengerKey = GlobalKey<ActionBarMessengerStateImpl>();

  @override
  Widget build(BuildContext context) {
    return ClaimCreationUIDelegateInheritedWidget(
      options: claimCreationUIDelegateOptions,
      child: ActionBarMessenger(key: actionBarMessengerKey, child: widget.child),
    );
  }
}
