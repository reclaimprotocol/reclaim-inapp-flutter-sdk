import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reclaim_flutter_sdk/reclaim_flutter_sdk.dart';
import 'package:reclaim_flutter_sdk/screens/screens.dart';
import 'package:reclaim_flutter_sdk/utils/cancel/cancel.dart';
import 'package:reclaim_flutter_sdk/services/feature_flag.dart';
import 'package:reclaim_flutter_sdk/types/claim_creation_type.dart';

import 'data/providers.dart';
import 'inapp_sdk_route.dart';
import 'logging/logging.dart';
import 'utils/future.dart';
import 'widgets/reclaim_theme_provider.dart';
import 'widgets/safe_area.dart';
import 'widgets/webview_bar.dart';

export 'package:reclaim_flutter_sdk/types/create_claim.dart';
export 'exception/exception.dart';
export 'widgets/webview_bottom.dart';
export 'types/verification_options.dart';
export 'types/feature_flag_data.dart';

class ReclaimVerification extends ReclaimCancellable {
  final BuildContext buildContext;
  final String appId;
  final String providerId;
  final String secret;
  final ReclaimSessionInformation sessionInformation;
  final String context;
  final Map<String, String> parameters;
  final bool autoSubmit;
  final bool acceptAiProviders;
  final bool hideCloseButton;
  final String? webhookUrl;
  final ReclaimVerificationOptions? verificationOptions;
  final ClaimCreationType? claimCreationType;

  /// {@macro ComputeProofForAttestorCallback}
  final ComputeProofForAttestorCallback? computeAttestorProof;

  ReclaimVerification({
    required this.buildContext,
    required this.appId,
    required this.providerId,
    required this.secret,
    required this.context,
    required this.parameters,
    this.verificationOptions,
    this.computeAttestorProof,
    this.claimCreationType,
    this.autoSubmit = false,
    this.acceptAiProviders = false,
    this.hideCloseButton = false,
    this.webhookUrl,
  }) : sessionInformation = const ReclaimSessionInformation.empty();

  ReclaimVerification.withSession({
    required this.buildContext,
    required this.appId,
    required this.providerId,
    required this.context,
    required this.parameters,
    required this.sessionInformation,
    this.verificationOptions,
    this.computeAttestorProof,
    this.claimCreationType,
    this.autoSubmit = false,
    this.acceptAiProviders = false,
    this.hideCloseButton = false,
    this.webhookUrl,
  }) : secret = '';

  void _setupAttestors() {
    final callback = computeAttestorProof;
    if (callback != null) {
      Attestor.instance.setComputeAttestorProof(callback);
    }
    unawaited(Attestor.instance.ensureReady());
  }

  Future<List<CreateClaimOutput>?> startVerification() async {
    SessionIdentity.update(
      sessionId: sessionInformation.sessionId,
      providerId: providerId,
      appId: appId,
    );

    final logger = logging.child('ReclaimVerification.startVerification');
    initializeReclaimLogging();
    // If there's existing modal, pop it
    final currentRoute = ModalRoute.of(buildContext)?.settings.name;
    if (Navigator.canPop(buildContext) && currentRoute != null) {
      if (currentRoute.endsWith('ReclaimInAppSdk')) {
        logger.info('Popped existing modal');
        Navigator.pop(buildContext);
      }
    }

    onStart();
    _setupAttestors();

    final result = await Navigator.of(buildContext).push(
      CupertinoPageRoute(
        builder: (buildContext) {
          return _ReclaimVerificationPage(
            cancellable: this,
            appId: appId,
            providerId: providerId,
            secret: secret,
            reclaimContext: context,
            sessionInformation: sessionInformation,
            parameters: parameters,
            autoSubmit: autoSubmit,
            hideCloseButton: hideCloseButton,
            webhookUrl: webhookUrl,
            acceptAiProviders: acceptAiProviders,
            verificationOptions: verificationOptions,
            claimCreationType: claimCreationType,
          );
        },
        settings: reclaimInAppSDKRouteSettings,
        fullscreenDialog: true,
      ),
    );

    onFinished();

    if (result is List<CreateClaimOutput>) {
      return result;
    }

    // If the result is bool, it means manual verification submitted successfully
    if (result is bool) return null;

    return Future.error(ReclaimException.onError(result));
  }
}

class _ReclaimVerificationPage extends StatelessWidget {
  const _ReclaimVerificationPage({
    required this.cancellable,
    required this.appId,
    required this.providerId,
    required this.secret,
    required this.reclaimContext,
    required this.sessionInformation,
    required this.parameters,
    required this.autoSubmit,
    required this.hideCloseButton,
    required this.webhookUrl,
    required this.acceptAiProviders,
    required this.verificationOptions,
    required this.claimCreationType,
  });

  final ReclaimCancellable cancellable;
  final String appId;
  final String providerId;
  final String secret;
  final String reclaimContext;
  final ReclaimSessionInformation sessionInformation;
  final Map<String, String> parameters;
  final bool autoSubmit;
  final bool hideCloseButton;
  final bool acceptAiProviders;
  final String? webhookUrl;
  final ReclaimVerificationOptions? verificationOptions;
  final ClaimCreationType? claimCreationType;
  @override
  Widget build(BuildContext context) {
    const backgroundColor = ReclaimTheme.grayBackground;
    return Material(
      color: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: ReclaimThemeProvider(
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark.copyWith(
            // let top bar take care of color
            statusBarColor: Colors.transparent,
            // on some devices, the color behind system navigation overlay could become black (and flutter's choice for bg color is also black)
            systemNavigationBarColor: backgroundColor,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: MediaQuery.fromView(
            view: View.of(context),
            child: FractionallyPaddedSafeArea(
              bottomFraction:
                  Theme.of(context).platform == TargetPlatform.iOS
                      // Eyeballed on iphone that ~32% of safe area bottom padding should be safe
                      ? 0.32
                      // Androids always provide bottom padding as 0.
                      : 1,
              child: ReclaimVerificationModal(
                cancellable: cancellable,
                appId: appId,
                providerId: providerId,
                secret: secret,
                context: reclaimContext,
                sessionInformation: sessionInformation,
                parameters: parameters,
                autoSubmit: autoSubmit,
                hideCloseButton: hideCloseButton,
                webhookUrl: webhookUrl,
                acceptAiProviders: acceptAiProviders,
                verificationOptions: verificationOptions,
                claimCreationType: claimCreationType,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ReclaimVerificationModal extends StatefulWidget {
  final ReclaimCancellable cancellable;
  final String appId;
  final String providerId;
  final String secret;
  final String context;
  final ReclaimSessionInformation sessionInformation;
  final Map<String, String> parameters;
  final bool autoSubmit;
  final bool hideCloseButton;
  final bool acceptAiProviders;
  final ReclaimVerificationOptions? verificationOptions;
  final ClaimCreationType? claimCreationType;

  final String? webhookUrl;

  const ReclaimVerificationModal({
    super.key,
    required this.cancellable,
    required this.appId,
    required this.providerId,
    required this.secret,
    required this.context,
    required this.parameters,
    required this.sessionInformation,
    required this.acceptAiProviders,
    this.autoSubmit = false,
    this.hideCloseButton = false,
    this.webhookUrl,
    this.verificationOptions,
    this.claimCreationType,
  });

  @override
  ReclaimVerificationModalState createState() =>
      ReclaimVerificationModalState();
}

class ReclaimVerificationModalState extends State<ReclaimVerificationModal> {
  late String privateKey = generatePrivateKey();
  late ReclaimSessionInformation sessionInformation = widget.sessionInformation;

  late VoidCallback _onCancelledListenerRemover;

  @override
  void initState() {
    super.initState();
    _initializeSession();
    logging.finest(
      '[ReclaimCancellable] initstate - ${widget.cancellable.hashCode}',
    );
    _onCancelledListenerRemover = widget.cancellable.addCancellationListener(
      _onCancelled,
    );
  }

  late final _loadingProgressNotifier = ValueNotifier<double>(0.01);

  void setInitProgress(double progress) {
    if (!mounted) return;
    _loadingProgressNotifier.value = progress;
  }

  @override
  void dispose() {
    _onCancelledListenerRemover();
    _loadingProgressNotifier.dispose();
    super.dispose();
  }

  void _onCancelled() {
    if (!mounted) return;
    final logger = logging.child('ReclaimVerificationModal._onCancelled');
    logger.info('Cancelling modal $hashCode');
    Navigator.of(context).pop(const ReclaimVerificationCancelledException());
  }

  void _initializeSession() async {
    final logger = logging.child('ReclaimVerificationModal._initializeSession');
    final navigator = Navigator.of(context);
    try {
      await _validateAndCreateNewSessionIfRequired();
      setInitProgress(0.02);

      final sessionIdentity = SessionIdentity.update(
        sessionId: sessionInformation.sessionId,
        providerId: widget.providerId,
        appId: widget.appId,
      );

      try {
        final flags = await FeatureFlagService.getFeatureFlagsWithOverrides(
          sessionIdentity,
        );
        logger.info('Feature flags: $flags');
        setInitProgress(0.03);
        await Flags.setFlagsLocally(flags);
      } catch (e, s) {
        logger.severe('Error getting feature flags', e, s);
      }
      setInitProgress(0.04);

      try {
        await ReclaimSession.updateSession(
          sessionInformation.sessionId,
          SessionStatus.USER_STARTED_VERIFICATION,
        );
        setInitProgress(0.05);
      } on ReclaimSessionException {
        rethrow;
      } catch (e, s) {
        logging.severe('Error updating session', e, s);
        // ignoring other exceptions to silently continue verification
      }

      final provider = await _fetchReclaimProvider();
      if (provider != null) {
        final handler = widget.verificationOptions?.canContinueVerification;
        if (handler != null) {
          final canContinue = await handler(provider);
          if (!canContinue) {
            navigator.pop(ReclaimVerificationCancelledException());
            return;
          }
        }
      }

      setInitProgress(0.08);

      await _onFetchAttestorAuthenticationRequest();

      setInitProgress(1);
      if (mounted) {
        setState(() {
          _isReady = true;
        });
      }
    } catch (error, stacktrace) {
      if (!mounted) return;
      Future.microtask(() {
        if (mounted) {
          if (error is ReclaimException) {
            logger.info('Closing because session expired $hashCode');
            navigator.pop(error);
          } else {
            logger.severe('Closing because of error', error, stacktrace);
            navigator.pop(error.toString());
          }
        }
      });
    }
  }

  Future<void> _validateAndCreateNewSessionIfRequired() async {
    if (sessionInformation.isValid) return;

    sessionInformation = await ReclaimSessionInformation.generateNew(
      providerId: widget.providerId,
      applicationSecret: widget.secret,
      applicationId: widget.appId,
    );

    setState(() {});
  }

  ReclaimDataProviders? dataProviders;
  AttestorAuthenticationRequest? _attestorAuthenticationRequest;

  Future<void> _fetchAttestorAuthenticationRequest(
    HttpProvider provider,
    ReclaimAttestorAuthenticationRequestCallback callback,
  ) async {
    final logger = logging.child(
      'ReclaimVerificationModal._fetchAttestorAuthenticationRequest',
    );
    try {
      _attestorAuthenticationRequest = await callback(provider);
      logger.info('Using attestor authentication request');
    } catch (e, s) {
      logger.severe('Error fetching attestor authentication request', e, s);
    }
  }

  Future<void> _onFetchAttestorAuthenticationRequest() async {
    final attestorAuthRequestCallback =
        widget.verificationOptions?.attestorAuthenticationRequest;
    if (attestorAuthRequestCallback != null) {
      final httpProvider = dataProviders?.httpProvider?.firstOrNull;
      if (httpProvider != null) {
        await _fetchAttestorAuthenticationRequest(
          httpProvider,
          attestorAuthRequestCallback,
        );
      } else {
        logging.warning(
          'No provider found to fetch attestor authentication request',
        );
      }
    }
  }

  Future<HttpProvider?> _fetchReclaimProvider() async {
    unawaitedSequence([
      ReclaimSession.sendLogs(
        appId: widget.appId,
        providerId: widget.providerId,
        sessionId: sessionInformation.sessionId,
        logType: "FETCHED_PROVIDERS",
      ),
    ]);

    setInitProgress(0.06);

    final response = await ReclaimProviderService().getProviders(
      widget.appId,
      widget.providerId,
      sessionInformation.sessionId,
      sessionInformation.signature,
      sessionInformation.timestamp,
    );

    setInitProgress(0.07);

    dataProviders = response?.providers;

    return dataProviders?.httpProvider?.firstOrNull;
  }

  bool _isReady = false;

  @override
  Widget build(BuildContext context) {
    final providerData = dataProviders?.httpProvider?.firstOrNull;
    final loginUrl = providerData?.loginUrl ?? 'loading...';

    if (!_isReady) {
      return _PageNoDataView(
        webviewUrl: loginUrl,
        hideCloseButton: widget.hideCloseButton,
        progress: _loadingProgressNotifier,
      );
    }

    // assuming parent updates Session Identity
    final identity = SessionIdentity.update(
      sessionId: sessionInformation.sessionId,
      providerId: widget.providerId,
      appId: widget.appId,
    );

    final child = WebviewScreen(
      providerData: providerData,
      sessionId: identity.sessionId,
      context: widget.context,
      privateKey: privateKey,
      parameters: widget.parameters,
      appId: identity.appId,
      autoSubmit: widget.autoSubmit,
      hideCloseButton: widget.hideCloseButton,
      webhookUrl: widget.webhookUrl,
      acceptAiProviders: widget.acceptAiProviders,
      verificationOptions: widget.verificationOptions,
      createClaimOptions: AttestorClaimOptions(
        attestorAuthenticationRequest: _attestorAuthenticationRequest,
        claimCreationType:
            widget.claimCreationType ?? ClaimCreationType.standalone,
      ),
    );

    return child;
  }
}

class _PageNoDataView extends StatelessWidget {
  const _PageNoDataView({
    required this.webviewUrl,
    required this.hideCloseButton,
    this.progress,
  });

  final String webviewUrl;
  final bool hideCloseButton;
  final ValueNotifier<double>? progress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          AnimatedBuilder(
            animation: progress ?? AlwaysStoppedAnimation(null),
            builder: (context, snapshot) {
              return WebviewBar(
                webviewUrl: webviewUrl,
                webviewProgress: progress?.value,
                close:
                    !hideCloseButton
                        ? () {
                          Navigator.maybePop(context);
                        }
                        : null,
              );
            },
          ),
        ],
      ),
    );
  }
}
