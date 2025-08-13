import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../data/providers.dart';
import '../../data/web_context.dart';
import '../../exception/exception.dart';
import '../../logging/logging.dart';
import '../../usecase/login_detection.dart';
import '../../utils/detection/login.dart';
import '../../utils/observable_notifier.dart';
import '../../utils/url.dart' as url_util;
import '../../utils/user_agent.dart';
import '../../utils/webview_state_mixin.dart';
import '../../widgets/reclaim_appbar.dart';

class ClaimCreationWebState {
  const ClaimCreationWebState({
    this.webAppBarValue = const WebAppBarValue(url: '', progress: 0.0),
    InAppWebViewController? controller,
    this.requestedUrl,
    this.lastLoadStopTime,
    this.isLoading = true,
    this.hasLoadedRequestedUrl = false,
  }) : _controller = controller;

  final WebAppBarValue webAppBarValue;
  final String? requestedUrl;
  final InAppWebViewController? _controller;
  final DateTime? lastLoadStopTime;
  final bool isLoading;
  final bool hasLoadedRequestedUrl;

  ClaimCreationWebState copyWith({
    WebAppBarValue? webAppBarValue,
    InAppWebViewController? controller,
    String? requestedUrl,
    DateTime? lastLoadStopTime,
    bool? isLoading,
    bool? hasLoadedRequestedUrl,
  }) {
    return ClaimCreationWebState(
      webAppBarValue: webAppBarValue ?? this.webAppBarValue,
      controller: controller ?? _controller,
      requestedUrl: requestedUrl ?? this.requestedUrl,
      lastLoadStopTime: lastLoadStopTime ?? this.lastLoadStopTime,
      isLoading: isLoading ?? this.isLoading,
      hasLoadedRequestedUrl: hasLoadedRequestedUrl ?? this.hasLoadedRequestedUrl,
    );
  }
}

class ClaimCreationWebClientViewModel extends ObservableNotifier<ClaimCreationWebState> {
  ClaimCreationWebClientViewModel(WebAppBarValue initialWebAppBarValue)
    : super(ClaimCreationWebState(webAppBarValue: initialWebAppBarValue));

  Widget wrap({required Widget child}) {
    return _Provider(notifier: this, child: child);
  }

  static ClaimCreationWebClientViewModel readOf(BuildContext context) {
    final widget = context.getInheritedWidgetOfExactType<_Provider>();
    assert(
      widget != null,
      'No ClaimCreationWebViewModel provider found in the widget tree. Ensure you are using [ClaimCreationWebViewModel.wrap] in an ancestor to provider the [ClaimCreationWebViewModel].',
    );
    return widget!.notifier!;
  }

  static ClaimCreationWebClientViewModel of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<_Provider>();
    assert(
      widget != null,
      'No ClaimCreationWebViewModel provider found in the widget tree. Ensure you are using [ClaimCreationWebViewModel.wrap] in an ancestor to provider the [ClaimCreationWebViewModel].',
    );
    return widget!.notifier!;
  }

  Future<void> Function()? _onUpdateWebView;

  set onUpdateWebView(Future<void> Function()? cb) {
    if (cb == null) {
      _onUpdateWebView = null;
    } else {
      _onUpdateWebView = () async {
        final oldController = value._controller;
        log.info('Older controller was: $oldController');
        try {
          await cb();
        } catch (e, s) {
          log.severe('Error updating webview', e, s);
          // ignore because the webview is being updated and it could be a problem with the webview
        }
        // Dispose of the old controller in next microtask
        Future.microtask(() {
          try {
            if (oldController != value._controller && oldController != null) {
              oldController.dispose();
            }
          } catch (e, s) {
            log.severe('Error disposing old controller', e, s);
          }
        });
      };
    }
  }

  Future<void> load({
    required HttpProvider provider,
    required UnmodifiableListView<UserScript> userScripts,
    int followCount = 0,
  }) async {
    final initialUrl = provider.loginUrl ?? provider.requestData.firstOrNull?.url;

    if (initialUrl == null) {
      throw ReclaimVerificationProviderLoadException('No initial URL found for provider');
    }

    log.info('load with provider and user scripts');
    log.debug('waiting for webview to initialize');
    final initializationTimeout = Duration(seconds: 5);
    try {
      await ensureInitialized().timeout(initializationTimeout);
      await Future.delayed(Duration(seconds: 2));
    } catch (e, s) {
      final progress = (await value._controller?.getProgress() ?? 0) / 100;
      log.info('progress: $progress');
      if (progress > 0.3 && followCount < 3) {
        log.info('progress is greater than 0.3, skipping update webview');
        return load(provider: provider, userScripts: userScripts, followCount: followCount + 1);
      }
      log.severe('Failed to initialize webview with controller: ${value._controller}', e, s);
      log.info('Trying to update webview with $_onUpdateWebView');
      await _onUpdateWebView?.call();
      await Future.delayed(Duration(seconds: 2));
      try {
        await ensureInitialized().timeout(initializationTimeout);
      } catch (e, s) {
        log.severe('Failed to reinitialize webview with controller: ${value._controller}', e, s);
        rethrow;
      }
    }

    log.debug('webview initialized');

    log.debug('setting user agent');
    log.info('using incognito webview: ${provider.useIncognitoWebview}');

    await setWebViewSettings((settings) async {
      final String userAgentString = await WebViewUserAgentUtil.getEffectiveUserAgent(provider.userAgent);
      settings.userAgent = userAgentString;
      settings.incognito = provider.useIncognitoWebview;
      return settings;
    });

    log.info('Updating user scripts ${userScripts.length}');
    await controller.removeAllUserScripts();
    log.debug('removed all user scripts ${userScripts.length}');
    await controller.addUserScripts(userScripts: userScripts);
    log.debug('added ${userScripts.length} user scripts');

    try {
      final loadUrlTimeout = Duration(seconds: 20);
      // Adding a delay to ensure the webview is ready to load the url
      await Future.delayed(Duration(milliseconds: 100));
      log.info('loading url $initialUrl');
      log.info({'hasLoadedRequestedUrl': value.hasLoadedRequestedUrl, 'lastLoadStopTime': value.lastLoadStopTime});
      await controller.loadUrl(urlRequest: URLRequest(url: WebUri(initialUrl))).timeout(loadUrlTimeout);
      log.info('loaded url $initialUrl');
      await Future.delayed(initializationTimeout);
      log.info({'hasLoadedRequestedUrl': value.hasLoadedRequestedUrl, 'lastLoadStopTime': value.lastLoadStopTime});
      if (!value.hasLoadedRequestedUrl) {
        log.warning({
          'reason': "Request url hasn't loaded in the webview",
          'isLoading': value.isLoading,
          'progress': value.webAppBarValue.progress,
        });
        log.info({'isControllerLoading': await controller.isLoading()});
      }
    } catch (e, s) {
      log.severe('Failed to load url $initialUrl', e, s);
    }

    if (isDisposed) return;

    value = value.copyWith(requestedUrl: initialUrl);
  }

  Future<InAppWebViewSettings?> getSettings() async {
    return await controller.getSettings();
  }

  Future<void> refresh() async {
    final url = value.requestedUrl ?? (await controller.getUrl())?.toString();
    if (url == null) {
      throw ReclaimVerificationProviderLoadException('No URL found for provider');
    }
    await controller.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  void setDisplayUrl(String url) {
    value = value.copyWith(webAppBarValue: value.webAppBarValue.copyWith(url: url));
  }

  void setDisplayProgress(double progress) {
    value = value.copyWith(webAppBarValue: value.webAppBarValue.copyWith(progress: progress));
  }

  void onLoadStart() {
    value = value.copyWith(isLoading: true, hasLoadedRequestedUrl: true);
  }

  void onLoadStop() {
    value = value.copyWith(isLoading: false, lastLoadStopTime: DateTime.now());
  }

  final _webviewInitializationCompleter = Completer<void>();

  void setController(InAppWebViewController controller) {
    if (value._controller != controller) {
      value = value.copyWith(controller: controller);
    }

    if (!_webviewInitializationCompleter.isCompleted) {
      _webviewInitializationCompleter.complete();
    }
  }

  Future<void> ensureInitialized() async {
    await _webviewInitializationCompleter.future;
  }

  @protected
  InAppWebViewController get controller {
    assert(value._controller != null, 'Controller is not set');
    return value._controller!;
  }

  Future<void> setWebViewSettings(FutureOr<InAppWebViewSettings?> Function(InAppWebViewSettings) update) async {
    await ensureInitialized();

    final currentSettings = ((await controller.getSettings()) ?? defaultWebViewSettings).copy();
    log.fine(() => 'old webview settings: ${json.encode(currentSettings)}');
    final newSettings = await update(currentSettings);
    if (newSettings == null) {
      return;
    }
    log.fine(() => 'Setting webview settings: ${json.encode(newSettings)}');
    await controller.setSettings(settings: newSettings);
  }

  final log = logging.child('ClaimCreationWebViewModel');

  Future<bool> canContinueWithExpectedUrl(
    WebContext webContext,
    LoginDetection loginDetection,
    String expectedPageUrl,
    bool isAIProvider,
  ) async {
    final log = this.log.child('_canContinueWithExpectedUrl');
    final currentUrl = await controller.getUrl().then((value) {
      return value?.toString();
    });
    if (currentUrl == null) return true;
    // Check if login interaction is required based on provider type
    bool requiresLogin = false;
    if (isAIProvider) {
      requiresLogin = requiresLoginInteraction(webContext);
    } else {
      requiresLogin = await loginDetection.maybeRequiresLoginInteraction(currentUrl, controller);
    }

    if (requiresLogin) {
      log.finer(
        'Cannot continue to expected page "$expectedPageUrl" because current url is a login url: "$currentUrl". isAIProvider: $isAIProvider',
      );
      return false;
    }
    if (url_util.isUrlsEqual(currentUrl, expectedPageUrl)) {
      log.finer('Cannot continue to expected page "$expectedPageUrl" because current url is "$currentUrl"');
      return false;
    }
    return true;
  }

  Future<bool> onContinue(
    WebContext webContext,
    LoginDetection loginDetection,
    String nextLocation,
    bool isAIProvider,
  ) async {
    await ensureInitialized();
    final currentUrl = await controller.getUrl().then((value) => value?.toString());
    final fullExpectedUrl = url_util.createUrlFromLocation(nextLocation, currentUrl);
    if (!await canContinueWithExpectedUrl(webContext, loginDetection, fullExpectedUrl, isAIProvider)) {
      return false;
    }

    log.info('Navigating to expected page "$fullExpectedUrl" from "$currentUrl"');
    await controller.loadUrl(urlRequest: URLRequest(url: WebUri(fullExpectedUrl)));
    return true;
  }

  Future<String> getWebViewUserAgent() async {
    return controller.getSettings().then((value) => value?.userAgent ?? '');
  }

  Future<String> getCurrentRefererUrl(String defaultUrl) async {
    String url = defaultUrl;
    try {
      final webUri = await controller.getUrl().then((e) => e?.toString());
      if (webUri != null && webUri.isNotEmpty) {
        url = webUri;
      }
    } catch (e, s) {
      log.severe('Failed to get current referer url', e, s);
    }
    return url_util.createRefererUrl(url) ?? defaultUrl;
  }

  void navigateToUrl(String url) {
    controller.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  void evaluateJavascript(String source) {
    controller.evaluateJavascript(source: source);
  }

  Future<void> goBack() async {
    if (await controller.canGoBack()) {
      await controller.goBack();
    } else {
      log.warning('Cannot go back, current url: ${await controller.getUrl()}');
    }
  }

  Future<String?> getCurrentWebPageUrl() async {
    await ensureInitialized();
    return (await controller.getUrl())?.toString();
  }

  Future<bool> maybeCurrentPageRequiresLogin(LoginDetection loginDetection) async {
    final url = await getCurrentWebPageUrl();
    log.finest('checking whether isCurrentPageLogin: $url');
    if (await loginDetection.maybeRequiresLoginInteraction(url, controller)) {
      return true;
    }
    return false;
  }
}

class _Provider extends InheritedNotifier<ClaimCreationWebClientViewModel> {
  const _Provider({required super.child, required ClaimCreationWebClientViewModel super.notifier});

  @override
  bool updateShouldNotify(covariant _Provider oldWidget) {
    return oldWidget.notifier?.value != notifier?.value;
  }
}
