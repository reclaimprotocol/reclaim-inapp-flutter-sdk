import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../controller.dart';
import '../../data/providers.dart';
import '../../exception/exception.dart';
import '../../logging/logging.dart';
import '../../usecase/login_detection.dart';
import '../../utils/observable_notifier.dart';
import '../../widgets/ai_flow_coordinator_widget.dart';
import '../../widgets/claim_creation/claim_creation.dart';
import '../../widgets/debug_bottom_sheet.dart';
import '../../widgets/reclaim_appbar.dart';
import '../../widgets/verification_review/controller.dart';
import '../../widgets/webview_bottom.dart';
import '../claim_creation_webview/view.dart';
import '../claim_creation_webview/view_model.dart';
import 'route.dart';

/// A widget where the verification flow happens.
class VerificationView extends StatefulWidget {
  const VerificationView({super.key});

  @override
  State<VerificationView> createState() => _VerificationViewState();
}

class _VerificationViewState extends State<VerificationView> {
  late final ReclaimAppBarController appBarController;
  late final ClaimCreationWebClientViewModel _clientViewModel;
  late final StreamSubscription _controllerSubscription;
  late final StreamSubscription _webViewModelSubscription;
  late final ClaimCreationController _claimCreationController = ClaimCreationController();
  late final VerificationReviewController _reviewController;

  late final _log = logging.child('VerificationViewState.$hashCode');

  @override
  void initState() {
    super.initState();
    _log.info('Initializing verification view');
    _reviewController = VerificationReviewController();
    final controller = VerificationController.readOf(context);
    final initialWebAppBarValue = WebAppBarValue(url: '', progress: controller.value.initializationProgress);
    appBarController = ReclaimAppBarController(initialWebAppBarValue);
    _clientViewModel = ClaimCreationWebClientViewModel(initialWebAppBarValue);
    _controllerSubscription = controller.subscribe(_onVerificationStateChanged);
    _webViewModelSubscription = _clientViewModel.subscribe(_onClientValueChanged);
    _claimCreationController.subscribe(_onClaimCreationControllerChanges);
    unawaited(controller.response.whenComplete(_onCompleted));
  }

  bool _didPop = false;

  void _onCompleted() {
    _log.config('onCompleted, mounted: $mounted, _didPop: $_didPop');
    if (!mounted) {
      return;
    }
    if (_didPop) return;
    _didPop = true;
    final navigatorState = Navigator.of(context);
    navigatorState.popUntil(ModalRoute.withName(verificationViewRouteSettings.name!));
    navigatorState.pop();
  }

  final _usedProviderAndScripts = <(HttpProvider, UnmodifiableListView<UserScript>)>{};

  void _onVerificationStateChanged(ChangedValues<VerificationState> change) {
    final (oldValue, value) = change.record;
    if (!mounted) return;

    if (oldValue?.initializationProgress != value.initializationProgress && value.initializationProgress <= 0.1) {
      appBarController.value = WebAppBarValue(
        url: value.provider?.loginUrl ?? '',
        progress: value.initializationProgress,
      );
    }

    final provider = value.provider;
    final userScripts = value.userScripts;
    if (provider != null && userScripts != null) {
      final clientRequirements = (provider, userScripts);
      if (!_usedProviderAndScripts.contains(clientRequirements)) {
        _usedProviderAndScripts.add(clientRequirements);

        _onLoadWebClientWithProvider(provider, userScripts);
        return;
      }
    }
  }

  void _onLoadWebClientWithProvider(HttpProvider provider, UnmodifiableListView<UserScript> userScripts) {
    _claimCreationController.setHttpProvider(provider);
    _clientViewModel.load(provider: provider, userScripts: userScripts).catchError((e, s) {
      if (mounted) {
        _log.severe('Failed to load client web', e, s);
        VerificationController.readOf(
          context,
        ).updateException(ReclaimVerificationProviderLoadException('Failed to load scripts'));
      }
    });
  }

  void _onClientValueChanged(ChangedValues<ClaimCreationWebState> change) {
    final (oldValue, value) = change.record;
    if (!mounted) return;

    if (oldValue?.webAppBarValue != value.webAppBarValue) {
      appBarController.value = value.webAppBarValue;
    }
  }

  void _onClaimCreationControllerChanges(ChangedValues<ClaimCreationControllerState> changes) {
    if (changes.oldValue?.status != changes.value.status &&
        changes.value.status == ClaimCreationStatus.retryRequested) {
      _onRetryRequested();
    }
  }

  void _onRetryRequested() {
    final controller = VerificationController.readOf(context);
    final provider = controller.value.provider;
    final userScripts = controller.value.userScripts;
    if (provider == null || userScripts == null) {
      _log.warning('Failed to retry, provider or userScripts is null');
      _clientViewModel.refresh();
      return;
    }
    _onLoadWebClientWithProvider(controller.value.provider!, controller.value.userScripts!);
  }

  @override
  void dispose() {
    _log.info('Disposing verification view');
    _webViewModelSubscription.cancel();
    _clientViewModel.dispose();
    _controllerSubscription.cancel();
    appBarController.dispose();
    _claimCreationController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  final verificationViewKey = GlobalKey();

  void _showDebugMenu() {
    DebugBottomSheet.show(
      context: context,
      refreshPage: () {
        _clientViewModel.refresh();
      },
      copySessionId: () {
        final ctrl = VerificationController.readOf(context);
        Clipboard.setData(ClipboardData(text: ctrl.sessionInformation.sessionId));
        Fluttertoast.showToast(msg: "Copied to your clipboard");
      },
    );
  }

  late final bool _isAutoSubmitEnabled = VerificationController.readOf(context).options.canAutoSubmit;
  late final String _applicationId = VerificationController.readOf(context).request.applicationId;

  @override
  Widget build(BuildContext context) {
    return _claimCreationController.wrap(
      child: PopScope(
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            _didPop = true;
          }
        },
        child: _clientViewModel.wrap(
          child: _reviewController.wrap(
            child: ClaimCreationUIScope(
              uiDelegateOptions: ClaimCreationUIDelegateOptions(
                autoSubmit: _isAutoSubmitEnabled,
                appId: _applicationId,
                onSubmitProofs: (proofs) {
                  VerificationController.readOf(context).onSubmitProofs(proofs);
                },
                onContinue: (nextLocation) {
                  final webContext = AIFlowCoordinatorWidget.of(context).webContext;
                  final loginDetection = LoginDetection.readOf(context);
                  final isAIProvider = VerificationController.readOf(context).value.provider?.isAIProvider == true;
                  return _clientViewModel.onContinue(webContext, loginDetection, nextLocation, isAIProvider);
                },
                onException: (e) {
                  VerificationController.readOf(context).updateException(e);
                },
              ),
              child: Scaffold(
                key: verificationViewKey,
                appBar: ReclaimAppBar(controller: appBarController, onPressed: _showDebugMenu),
                body: const ClaimCreationWebClient(),
                bottomNavigationBar: const WebviewBottomBar(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
