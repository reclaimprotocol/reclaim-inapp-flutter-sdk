part of 'api.dart';

final _logger = Logger('reclaim_flutter_sdk.reclaim_verifier_module.api');

extension ReclaimSessionStatusExtension on ReclaimSessionStatus {
  static ReclaimSessionStatus fromSessionStatus(SessionStatus status) {
    return switch (status) {
      SessionStatus.PROOF_GENERATION_FAILED => ReclaimSessionStatus.PROOF_GENERATION_FAILED,
      SessionStatus.PROOF_GENERATION_SUCCESS => ReclaimSessionStatus.PROOF_GENERATION_SUCCESS,
      SessionStatus.PROOF_SUBMITTED => ReclaimSessionStatus.PROOF_SUBMITTED,
      SessionStatus.PROOF_SUBMISSION_FAILED => ReclaimSessionStatus.PROOF_SUBMISSION_FAILED,
      // This spelling mistake is intentional to match the backend.
      SessionStatus.PROOF_MANUAL_VERIFICATION_SUBMITED => ReclaimSessionStatus.PROOF_MANUAL_VERIFICATION_SUBMITTED,
      SessionStatus.USER_INIT_VERIFICATION => ReclaimSessionStatus.USER_INIT_VERIFICATION,
      SessionStatus.USER_STARTED_VERIFICATION => ReclaimSessionStatus.USER_STARTED_VERIFICATION,
      SessionStatus.PROOF_GENERATION_STARTED => ReclaimSessionStatus.PROOF_GENERATION_STARTED,
      SessionStatus.PROOF_GENERATION_RETRY => ReclaimSessionStatus.PROOF_GENERATION_RETRY,
      SessionStatus.AI_PROOF_SUBMITTED => ReclaimSessionStatus.AI_PROOF_SUBMITTED,
    };
  }
}

extension ClaimCreationTypeExtension on ClaimCreationTypeApi {
  ClaimCreationType get toClaimCreationType {
    return switch (this) {
      ClaimCreationTypeApi.standalone => ClaimCreationType.standalone,
      ClaimCreationTypeApi.meChain => ClaimCreationType.meChain,
    };
  }
}

bool _didAttemptPrecacheFonts = false;

void _precacheFonts() async {
  if (_didAttemptPrecacheFonts) return;
  _didAttemptPrecacheFonts = true;

  final log = _logger.child('_precacheFonts');
  try {
    await ReclaimThemeProvider.font.description.installFontIfRequired();
  } catch (e, s) {
    log.severe('Error precaching fonts', e, s);
  }
}

void _setReclaimEnv() {
  ReclaimEnv.CAPABILITY_ACCESS_TOKEN_VERIFICATION_KEY =
      'eyJraWQiOiI4NjgyNGJkMS04ZDU4LTQ5YWQtODVlMC03YzYxYWUyYTNjM2IiLCJrZXlfb3BzIjpbInZlcmlmeSJdLCJleHQiOnRydWUsImt0eSI6IkVDIiwieCI6Il80ekg2MFNJNEkyYXBuVlYzeUFTLWxQYWpwbzRHeTRmYV9NOFJYMGVaR0UiLCJ5IjoiSk5lWExnZ0JDdm9QZ1lYYTZxRGhCWHN6OGc1MkpHSDZPSHUyUmtpLXp5USIsImNydiI6IlAtMjU2In0';
  ReclaimEnv.IS_VERIFIER_INAPP_MODULE = true;
}

class _ReclaimModuleExternalApiImpl implements ReclaimModuleExternalApi {
  _ReclaimModuleExternalApiImpl() {
    _setReclaimEnv();
    _precacheFonts();
    startReclaimSdkLogging();
    ReclaimModuleApi.setUp(this);
    setSessionIdentityListener(_onSessionIdentityUpdate);
  }

  bool _isDisposed = false;
  void assertNotDisposed() {
    if (_isDisposed) throw StateError('ReclaimModuleExternalApiImpl is disposed');
  }

  late final _hostOverridesApi = ReclaimHostOverridesApi();
  ReclaimHostOverridesApi get hostOverridesApi {
    assertNotDisposed();
    return _hostOverridesApi;
  }

  late final _hostVerificationApi = ReclaimHostVerificationApi();
  ReclaimHostVerificationApi get hostVerificationApi {
    assertNotDisposed();
    return _hostVerificationApi;
  }

  StreamSubscription<SessionIdentity?>? _sessionIdentityUpdateListener;

  @override
  void dispose() {
    _isDisposed = true;
    _sessionIdentityUpdateListener?.cancel();
    ReclaimModuleApi.setUp(null);
  }

  @override
  Future<void> setSessionIdentityListener(void Function(SessionIdentity?)? onSessionIdentity) async {
    _sessionIdentityUpdateListener?.cancel();
    _sessionIdentityUpdateListener = SessionIdentity.onChanged.listen(onSessionIdentity);
  }

  @override
  Future<void> clearAllOverrides() async {
    return ReclaimOverride.clearAll();
  }

  @override
  Future<bool> ping() async {
    return true;
  }

  @override
  Future<bool> sendLog(LogEntryApi entry) async {
    final level = Level.LEVELS.firstWhere((it) => it.value == entry.level, orElse: () => Level.INFO);
    final buffer = StringBuffer(entry.message);
    final stackTrace = entry.stackTraceAsString;
    if (stackTrace != null && stackTrace.isNotEmpty) {
      buffer.write('\nSTACKTRACE: $stackTrace');
    }
    final givenSessionId = entry.sessionId;
    final latestSessionId = SessionIdentity.latest?.sessionId;
    if (givenSessionId != null && givenSessionId.isNotEmpty && (latestSessionId == null || latestSessionId.isEmpty)) {
      SessionIdentity.updateLatest(SessionIdentity(appId: '', providerId: '', sessionId: givenSessionId));
    }
    _logger.child(entry.source).log(level, buffer.toString(), entry.error);
    return true;
  }

  @override
  Future<void> setConsoleLogging(bool enabled) async {
    final old = ReclaimOverride.get<LogConsumerOverride>();
    ReclaimOverride.set(
      LogConsumerOverride(
        // Setting this to true will print logs from reclaim_flutter_sdk to the console.
        canPrintLogs: enabled,
        onRecord: old?.onRecord,
        levelChangeHandler: old?.levelChangeHandler,
      ),
    );
  }

  @override
  Future<void> setOverrides(
    ClientProviderInformationOverride? provider,
    ClientFeatureOverrides? feature,
    ClientLogConsumerOverride? logConsumer,
    ClientReclaimSessionManagementOverride? sessionManagement,
    ClientReclaimAppInfoOverride? appInfo,
    String? capabilityAccessToken, {
    ReclaimHostOverridesApi? overridesHandlerApi,
  }) async {
    final overridesHandler = overridesHandlerApi ?? hostOverridesApi;
    if (capabilityAccessToken != null) {
      try {
        ReclaimOverride.set(CapabilityAccessToken.import(capabilityAccessToken));
      } on CapabilityAccessTokenException catch (e, s) {
        _logger.severe('Failed to set capability access token', e, s);
        throw ReclaimVerificationCancelledException(e.message);
      }
    }

    if (logConsumer?.canSdkPrintLogs == true) {
      await _assertCanUseAnyCapability(['overrides_v1', 'sdk_console_logging_v1']);
    }

    if (feature?.attestorBrowserRpcUrl != null) {
      await _assertCanUseAnyCapability(['overrides_v1', 'sdk_attestor_browser_rpc_v1']);
    }

    if (provider != null ||
        logConsumer?.canSdkPrintLogs == true ||
        logConsumer?.canSdkCollectTelemetry == false ||
        sessionManagement?.enableSdkSessionManagement == true) {
      await _assertCanUseCapability('overrides_v1');
    }

    ReclaimOverride.setAll([
      if (feature != null)
        ReclaimFeatureFlagData(
          cookiePersist: feature.cookiePersist,
          singleReclaimRequest: feature.singleReclaimRequest,
          attestor3BrowserRpcUrl: feature.attestorBrowserRpcUrl,
          idleTimeThresholdForManualVerificationTrigger: feature.idleTimeThresholdForManualVerificationTrigger,
          sessionTimeoutForManualVerificationTrigger: feature.sessionTimeoutForManualVerificationTrigger,
          canUseAiFlow: feature.isAIFlowEnabled ?? false,
          manualReviewMessage: feature.manualReviewMessage,
          loginPromptMessage: feature.loginPromptMessage,
          useTEE: feature.useTEE,
          interceptorOptions: feature.interceptorOptions,
          claimCreationTimeoutDurationInMins: feature.claimCreationTimeoutDurationInMins,
          sessionNoActivityTimeoutDurationInMins: feature.sessionNoActivityTimeoutDurationInMins,
          aiProviderNoActivityTimeoutDurationInSecs: feature.aiProviderNoActivityTimeoutDurationInSecs,
          pageLoadedCompletedDebounceTimeoutMs: feature.pageLoadedCompletedDebounceTimeoutMs,
          potentialLoginTimeoutS: feature.potentialLoginTimeoutS,
          screenshotCaptureIntervalSeconds: feature.screenshotCaptureIntervalSeconds,
          teeUrls: feature.teeUrls,
          privacyPolicyUrl: feature.privacyPolicyUrl,
          termsOfServiceUrl: feature.termsOfServiceUrl,
          potentialFailureReasonsUrl: feature.potentialFailureReasonsUrl,
        ),
      if (provider != null)
        ReclaimProviderOverride(
          fetchProviderInformation:
              ({
                required String appId,
                required String providerId,
                required String sessionId,
                required String signature,
                required String timestamp,
                required String resolvedVersion,
              }) async {
                Map<String, dynamic> providerInformation = {};
                try {
                  if (provider.providerInformationUrl != null) {
                    final response = await downloadWithHttp(
                      provider.providerInformationUrl!,
                      cacheDirName: 'inapp_sdk_provider_information',
                    );

                    if (response == null) {
                      throw ReclaimVerificationCancelledException(
                        'Failed to fetch provider information from ${provider.providerInformationUrl}',
                      );
                    }

                    providerInformation = json.decode(utf8.decode(response));
                  } else if (provider.providerInformationJsonString != null) {
                    providerInformation = json.decode(provider.providerInformationJsonString!);
                  } else if (provider.canFetchProviderInformationFromHost) {
                    final String rawProviderInformation = await overridesHandler.fetchProviderInformation(
                      appId: appId,
                      providerId: providerId,
                      sessionId: sessionId,
                      signature: signature,
                      timestamp: timestamp,
                      resolvedVersion: resolvedVersion,
                    );
                    providerInformation = json.decode(rawProviderInformation);
                  }
                } catch (e, s) {
                  _logger.severe('Failed to fetch provider information', e, s);
                  if (e is ReclaimException) {
                    rethrow;
                  }
                  throw ReclaimVerificationCancelledException('Failed to fetch provider information due to $e');
                }

                try {
                  return HttpProvider.fromJson(providerInformation);
                } catch (e, s) {
                  _logger.severe('Failed to parse provider information', e, s);
                  throw ReclaimVerificationCancelledException('Failed to parse provider information: ${e.toString()}');
                }
              },
        ),
      if (logConsumer != null)
        LogConsumerOverride(
          // Setting this to true will print logs from reclaim_flutter_sdk to the console.
          canPrintLogs: logConsumer.canSdkPrintLogs == true,
          onRecord: logConsumer.enableLogHandler
              ? (record) {
                  _sendLogsToHost(record, overridesHandler);
                  return logConsumer.canSdkCollectTelemetry;
                }
              : (!logConsumer.canSdkCollectTelemetry ? (_) => false : null),
        ),
      // A handler has been provided. We'll not let SDK manage sessions in this case.
      // Disabling [enableSdkSessionManagement] lets the host manage sessions.
      if (sessionManagement != null && !sessionManagement.enableSdkSessionManagement)
        ReclaimSessionOverride.session(
          createSession:
              ({
                required String appId,
                required String providerId,
                required String timestamp,
                required String signature,
                required String providerVersion,
              }) async {
                final response = await overridesHandler.createSession(
                  appId: appId,
                  providerId: providerId,
                  timestamp: timestamp,
                  signature: signature,
                  providerVersion: providerVersion,
                );
                return SessionInitResponse(
                  sessionId: response.sessionId,
                  resolvedProviderVersion: response.resolvedProviderVersion,
                );
              },
          updateSession: (sessionId, status, metadata) async {
            return overridesHandler.updateSession(
              sessionId: sessionId,
              status: ReclaimSessionStatusExtension.fromSessionStatus(status),
              metadata: ensureMap<String>(metadata),
            );
          },
          logRecord:
              ({
                required appId,
                required logType,
                required providerId,
                required sessionId,
                Map<String, dynamic>? metadata,
              }) {
                overridesHandler.logSession(
                  appId: appId,
                  providerId: providerId,
                  sessionId: sessionId,
                  logType: logType,
                  metadata: ensureMap<String>(metadata),
                );
              },
        ),
      if (appInfo != null)
        AppInfo(
          appName: appInfo.appName,
          appImage: appInfo.appImageUrl,
          isRecurring: appInfo.isRecurring,
          theme: appInfo.theme != null
              ? fromStringToObject(
                  content: appInfo.theme!,
                  fromJson: ReclaimAppThemeInfo.fromJson,
                  onInvalidContent: (e, s) {
                    _logger.severe('Failed to parse app theme', e, s);
                  },
                )
              : null,
        ),
    ]);
  }

  final _defaultReclaimVerificationOptions = ReclaimVerificationOptions(
    canAutoSubmit: true,
    isCloseButtonVisible: true,
  );

  late ReclaimVerificationOptions _reclaimVerificationOptions = _defaultReclaimVerificationOptions;

  @override
  Future<void> setVerificationOptions(ReclaimApiVerificationOptions? options) async {
    final log = _logger.child('setVerificationOptions');
    if (options == null) {
      log.info('Setting verification options to null');
      _reclaimVerificationOptions = _defaultReclaimVerificationOptions;
    } else {
      log.info({
        'reason': 'Setting verification options',
        'canAutoSubmit': options.canAutoSubmit,
        'canDeleteCookiesBeforeVerificationStarts': options.canDeleteCookiesBeforeVerificationStarts,
        'canUseAttestorAuthenticationRequest': options.canUseAttestorAuthenticationRequest,
        'claimCreationType': options.claimCreationType,
        'isCloseButtonVisible': options.isCloseButtonVisible,
        'locale': options.locale,
        'useTeeOperator': options.useTeeOperator,
      });
      _reclaimVerificationOptions = _reclaimVerificationOptions.copyWith(
        canAutoSubmit: options.canAutoSubmit,
        canClearWebStorage: options.canDeleteCookiesBeforeVerificationStarts,
        attestorAuthenticationRequest: options.canUseAttestorAuthenticationRequest
            ? _requestAttestorAuthenticationRequestFromHost
            : null,
        claimCreationType: options.claimCreationType.toClaimCreationType,
        isCloseButtonVisible: options.isCloseButtonVisible,
        locale: options.locale,
        useTeeOperator: options.useTeeOperator,
      );
    }
  }

  late BuildContext? _verificationContext;

  @override
  void setVerificationContext(BuildContext context) {
    _verificationContext = context;
  }

  @override
  Future<ReclaimApiVerificationResponse> startVerification(ReclaimApiVerificationRequest request) {
    final usePreGeneratedSession =
        request.signature.isNotEmpty &&
        request.timestamp != null &&
        request.timestamp!.isNotEmpty &&
        request.sessionId.isNotEmpty;

    return _startVerification(
      ReclaimVerificationRequest(
        sessionProvider: () {
          final version = ProviderVersionExact(
            request.providerVersion?.resolvedVersion ?? '',
            versionExpression: request.providerVersion?.versionExpression,
          );
          if (usePreGeneratedSession) {
            return ReclaimSessionInformation(
              signature: request.signature,
              timestamp: request.timestamp ?? '',
              sessionId: request.sessionId,
              version: version,
            );
          }
          return ReclaimSessionInformation.generateNew(
            applicationId: request.appId,
            applicationSecret: request.secret,
            providerId: request.providerId,
            providerVersion: version.versionExpression,
          );
        },
        applicationId: request.appId,
        providerId: request.providerId,
        contextString: request.context,
        parameters: request.parameters,
      ),
      request.sessionId,
    );
  }

  @override
  Future<ReclaimApiVerificationResponse> startVerificationFromJson(Map<dynamic, dynamic> template) {
    try {
      final debugMessage = 'Starting verification with json: ${json.encode(template)}';
      if (kDebugMode) {
        debugPrint(debugMessage);
      } else {
        _logger.config(debugMessage);
      }

      if (template.containsKey('reclaimProofRequestConfig')) {
        final config = template['reclaimProofRequestConfig'];
        if (config is String) {
          return startVerificationFromJson(json.decode(config));
        }
        if (config is Map) {
          return startVerificationFromJson(<String, dynamic>{
            for (final entry in config.entries) (entry.key?.toString() ?? ''): entry.value,
          });
        }
      }
      if (template.containsKey('context')) {
        final context = template['context'];
        if (context is Map) {
          return startVerificationFromJson(<String, dynamic>{...template, 'context': json.encode(context)});
        }
      }
      if (template.containsKey('timeStamp')) {
        template['timestamp'] = template['timeStamp'];
      }

      final request = ClientSdkVerificationRequest.fromJson(json.decode(json.encode(template)));
      return _startVerification(ReclaimVerificationRequest.fromSdkRequest(request), request.sessionId ?? '');
    } catch (e, s) {
      _logger.severe('Failed to start verification from json', e, s);
      return Future.value(
        ReclaimApiVerificationResponse(
          sessionId: 'unknown',
          didSubmitManualVerification: false,
          proofs: const [],
          exception: ReclaimApiVerificationException(
            message: 'Failed to parse verification request from json. Caused by: $e',
            stackTraceAsString: s.toString(),
            type: ReclaimApiVerificationExceptionType.verificationCancelled,
          ),
        ),
      );
    }
  }

  @override
  Future<ReclaimApiVerificationResponse> startVerificationFromUrl(String url) async {
    try {
      final request = await ClientSdkVerificationRequest.fromUrl(url);
      final debugMessage = 'Starting verification with url: $url';
      if (kDebugMode) {
        debugPrint(debugMessage);
      } else {
        _logger.info(debugMessage);
      }
      return _startVerification(ReclaimVerificationRequest.fromSdkRequest(request), request.sessionId ?? '');
    } catch (e, s) {
      _logger.severe('Failed to start verification from url', e, s);
      return Future.value(
        ReclaimApiVerificationResponse(
          sessionId: 'unknown',
          didSubmitManualVerification: false,
          proofs: const [],
          exception: ReclaimApiVerificationException(
            message: 'Failed to parse verification request from url. Caused by: $e',
            stackTraceAsString: s.toString(),
            type: ReclaimApiVerificationExceptionType.verificationCancelled,
          ),
        ),
      );
    }
  }

  void _onSessionIdentityUpdate(SessionIdentity? identity) {
    try {
      if (identity == null) {
        hostOverridesApi.onSessionIdentityUpdate(null);
      } else {
        hostOverridesApi.onSessionIdentityUpdate(
          ReclaimSessionIdentityUpdate(
            appId: identity.appId,
            providerId: identity.providerId,
            sessionId: identity.sessionId,
          ),
        );
      }
    } catch (e, s) {
      _logger.warning(
        'Could not send session identity update to host. Likely no listener is set to receive this event.',
        e,
        s,
      );
    }
  }

  void _sendLogsToHost(LogEntry entry, ReclaimHostOverridesApi overridesHandler) {
    overridesHandler.onLogs(json.encode(entry));
  }

  Future<bool> _assertCanUseCapability(String capabilityName) async {
    final capabilityAccessVerifier = CapabilityAccessVerifier();

    if (await capabilityAccessVerifier.canUse(capabilityName)) {
      return true;
    }

    throw ReclaimVerificationCancelledException('Unauthorized use of capability: $capabilityName');
  }

  Future<bool> _assertCanUseAnyCapability(List<String> capabilityNames) async {
    final capabilityAccessVerifier = CapabilityAccessVerifier();
    for (final capabilityName in capabilityNames) {
      if (await capabilityAccessVerifier.canUse(capabilityName)) {
        return true;
      }
    }

    throw ReclaimVerificationCancelledException('Unauthorized use of capability: $capabilityNames');
  }

  Future<AttestorAuthenticationRequest> _requestAttestorAuthenticationRequestFromHost(HttpProvider provider) async {
    final providerMap = ensureMap<Object?>(provider.toJson())!;
    final result = await hostVerificationApi.fetchAttestorAuthenticationRequest(providerMap);
    try {
      final map = json.decode(result);
      if (map is! Map) {
        throw ReclaimVerificationCancelledException('Invalid attestor authentication request');
      }
      return AttestorAuthenticationRequest.fromJson(map as Map<String, dynamic>);
    } catch (e, s) {
      _logger.severe('Failed to parse attestor authentication request', e, s);
      throw ReclaimVerificationCancelledException('Failed to parse attestor authentication request: ${e.toString()}');
    }
  }

  BuildContext _requireVerificationContext() {
    final ctx = _verificationContext;
    if (ctx == null) {
      throw ReclaimVerificationCancelledException(
        'BuildContext for verification is not set. Please call setVerificationContext before starting verification from a widget which is mounted in widget tree.',
      );
    }
    if (!ctx.mounted) {
      throw ReclaimVerificationCancelledException(
        'BuildContext for verification is not mounted. Please call setVerificationContext before starting verification from a widget which is mounted in widget tree.',
      );
    }
    return ctx;
  }

  Future<ReclaimApiVerificationResponse> _startVerification(
    ReclaimVerificationRequest request,
    String requestSessionId,
  ) async {
    try {
      final context = _requireVerificationContext();
      final reclaimVerification = ReclaimVerification.of(context);

      _logger.event(
        Level.INFO.withEvent(LogEventType.IS_RECLAIM_INAPPSDK),
        'Starting verification with request applicationId: ${request.applicationId}, provider: ${request.providerId}, context: ${request.contextString}, params: ${json.encode(request.parameters)}',
      );

      final response = await reclaimVerification.startVerification(
        request: request,
        options: _reclaimVerificationOptions,
      );

      final effectiveSessionId = SessionIdentity.latest?.sessionId ?? requestSessionId;

      if (response.proofs.isNotEmpty) {
        _logger.event(Level.INFO.withEvent(LogEventType.SUBMITTING_PROOF), 'submitting proof');
      }

      final encodableProofs = (json.decode(json.encode(response.proofs)) as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      if (response.proofs.isNotEmpty) {
        final isAIProofs = () {
          try {
            return areParamsFromAIProofs(response.proofs);
          } catch (e, s) {
            _logger.severe('Failed to check whether proof is AI proof', e, s);
            return false;
          }
        }();

        _logger.event(Level.INFO.withEvent(LogEventType.SUBMITTING_PROOF), 'submitted proof');

        final sessionManager = SessionManager();
        sessionManager.onProofSubmitted(
          applicationId: request.applicationId,
          providerId: request.providerId,
          sessionId: effectiveSessionId,
          isAIProofs: isAIProofs,
          isInAppSdk: true,
        );
      } else {
        _logger.event(Level.SEVERE.withEvent(LogEventType.PROOF_SUBMISSION_FAILED), 'proof submission failed');

        final sessionManager = SessionManager();
        sessionManager.onProofSubmissionFailed(
          applicationId: request.applicationId,
          providerId: request.providerId,
          sessionId: effectiveSessionId,
          isInAppSdk: true,
        );
      }

      return ReclaimApiVerificationResponse(
        sessionId: effectiveSessionId,
        didSubmitManualVerification: false,
        proofs: encodableProofs,
        exception: null,
      );
    } catch (e, s) {
      final effectiveSessionId = SessionIdentity.latest?.sessionId ?? requestSessionId;
      _logger.event(Level.SEVERE.withEvent(LogEventType.PROOF_SUBMISSION_FAILED), 'Failed verification response', e, s);

      final sessionManager = SessionManager();
      sessionManager.onProofSubmissionFailed(
        applicationId: request.applicationId,
        providerId: request.providerId,
        sessionId: effectiveSessionId,
        isInAppSdk: true,
      );

      return ReclaimApiVerificationResponse(
        sessionId: effectiveSessionId,
        didSubmitManualVerification: e is ReclaimVerificationManualReviewException,
        proofs: const [],
        exception: ReclaimApiVerificationException(
          message: e.toString(),
          stackTraceAsString: s.toString(),
          type: _fromExceptionToApiExceptionType(e),
        ),
      );
    }
  }

  ReclaimApiVerificationExceptionType _fromExceptionToApiExceptionType(Object e) {
    if (e is ReclaimException) {
      switch (e) {
        case ReclaimVerificationCancelledException():
          return ReclaimApiVerificationExceptionType.verificationCancelled;
        case ReclaimVerificationDismissedException():
        case ReclaimVerificationSkippedException():
          return ReclaimApiVerificationExceptionType.verificationDismissed;
        case ReclaimExpiredSessionException():
        case ReclaimInitSessionException():
          return ReclaimApiVerificationExceptionType.sessionExpired;
        case ReclaimVerificationProviderScriptException():
        case ReclaimVerificationNoActivityDetectedException():
        case ReclaimVerificationRequirementException():
        case ReclaimVerificationProviderLoadException():
        case ReclaimAttestorException():
          return ReclaimApiVerificationExceptionType.verificationFailed;
      }
    }
    return ReclaimApiVerificationExceptionType.unknown;
  }
}
