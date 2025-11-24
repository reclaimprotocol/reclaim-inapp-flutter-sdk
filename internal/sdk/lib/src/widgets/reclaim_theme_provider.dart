import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../assets/assets.dart';
import '../data/app_info.dart';
import '../l10n/provider.dart';
import '../theme/theme.dart';
import '../utils/locale.dart';
import '../utils/observable_notifier.dart';
import 'color_or_image.dart';
import 'reclaim_image_provider.dart';

class ReclaimThemeProvider extends StatelessWidget {
  const ReclaimThemeProvider({
    super.key,
    required this.builder,
    required this.applicationId,
    this.isApplicationLevel = false,
    this.locale,
  });

  final String? applicationId;
  final WidgetBuilder builder;
  final bool isApplicationLevel;
  final String? locale;

  static const font = $ReclaimFont.inter;

  static String? latestAppName;

  static ThemeData buildClientTheme(ReclaimAppThemeInfo clientThemeInfo, Brightness themeBrightness) {
    final ReclaimAppTheme? clientTheme =
        switch (clientThemeInfo.themeMode) {
          ReclaimAppThemeMode.dark => clientThemeInfo.darkTheme,
          ReclaimAppThemeMode.light => clientThemeInfo.theme,
          ReclaimAppThemeMode.system => switch (themeBrightness) {
            Brightness.dark => clientThemeInfo.darkTheme,
            Brightness.light => clientThemeInfo.theme,
          },
        } ??
        clientThemeInfo.theme ??
        clientThemeInfo.darkTheme;

    final isLightThemeUsed = switch (clientThemeInfo.themeMode) {
      ReclaimAppThemeMode.dark => false,
      ReclaimAppThemeMode.light => true,
      _ => clientTheme == null || clientTheme == clientThemeInfo.theme,
    };

    final themeColorInt = clientTheme?.colorScheme?.themeColor;
    final surfaceColorInt = clientTheme?.colorScheme?.surfaceColor;
    final onSurfaceColorInt = clientTheme?.colorScheme?.onSurfaceColor;
    final cardColorInt = clientTheme?.cardColor;
    final onCardColorInt = clientTheme?.onCardColor;
    final termsNoticeColorInt = clientTheme?.termsNoticeColor;
    final hyperlinkColorInt = clientTheme?.hyperlinkColor ?? clientTheme?.hyperlinkColorInt;
    final sessionChipSurfaceColorInt = clientTheme?.sessionChipSurfaceColor;
    final sessionChipOnSurfaceColorInt = clientTheme?.sessionChipOnSurfaceColor;
    final backgroundBlurColorInt = clientTheme?.backgroundBlurColor;
    final parameterStyleDividerColorInt = clientTheme?.parameterStyle?.dividerColor;

    final primaryColor = themeColorInt != null ? Color(themeColorInt) : const Color(0xFF000099);
    final secondaryColor = primaryColor;
    final surfaceColor = surfaceColorInt != null ? Color(surfaceColorInt) : null;
    final onSurfaceColor = onSurfaceColorInt != null ? Color(onSurfaceColorInt) : null;
    final cardColor = cardColorInt != null ? Color(cardColorInt) : null;
    final onCardColor = onCardColorInt != null ? Color(onCardColorInt) : null;
    final termsNoticeColor = termsNoticeColorInt != null ? Color(termsNoticeColorInt) : null;
    final hyperlinkColor = hyperlinkColorInt != null ? Color(hyperlinkColorInt) : null;
    final sessionChipSurfaceColor = sessionChipSurfaceColorInt != null ? Color(sessionChipSurfaceColorInt) : null;
    final sessionChipOnSurfaceColor = sessionChipOnSurfaceColorInt != null ? Color(sessionChipOnSurfaceColorInt) : null;
    final backgroundBlurColor = backgroundBlurColorInt != null ? Color(backgroundBlurColorInt) : null;
    final parameterStyleDividerColor = parameterStyleDividerColorInt != null
        ? Color(parameterStyleDividerColorInt)
        : null;

    final doneIconProvider = ReclaimGraphicProvider.fromImageInfo(clientTheme?.doneIcon);
    final fieldVerifiedIconProvider = ReclaimGraphicProvider.fromImageInfo(
      clientTheme?.verificationReviewScreenTheme?.fieldVerifiedIcon,
    );
    final fieldVerifyingIconProvider = ReclaimGraphicProvider.fromImageInfo(
      clientTheme?.verificationReviewScreenTheme?.fieldVerifyingIcon,
    );
    final verificationCompleteIconProvider = ReclaimGraphicProvider.fromImageInfo(
      clientTheme?.verificationReviewScreenTheme?.verificationCompleteIcon,
    );
    final verifyScreenAppIconProvider = ReclaimGraphicProvider.fromImageInfo(
      clientTheme?.verificationReviewScreenTheme?.verifyScreenAppIcon,
    );

    final providerToAppLoader =
        ColorOrImageDecorationProvider.from(clientTheme?.verificationReviewScreenTheme?.providerToAppLoader) ??
        ColorOrImageDecorationProvider.from(
          ColorOrImage(color: clientTheme?.verificationReviewScreenTheme?.providerToAppLoaderColor),
        );
    final loading =
        ColorOrImageDecorationProvider.from(clientTheme?.loading) ??
        ColorOrImageDecorationProvider.from(
          ColorOrImage(color: clientTheme?.verificationReviewScreenTheme?.providerToAppLoaderColor),
        );

    final background = ColorOrImageDecorationProvider.from(clientTheme?.background);

    final appName = clientThemeInfo.appName;

    final clientAppIconOptions = clientTheme?.appImageOptions;

    final appIconGraphicOptions = clientAppIconOptions != null
        ? ReclaimGraphicOptions.fromImageInfoOptions(clientAppIconOptions)
        : null;

    final effectiveThemeBrightness = isLightThemeUsed ? Brightness.light : Brightness.dark;

    ThemeData theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        surface: surfaceColor,
        onSurface: onSurfaceColor,
        brightness: effectiveThemeBrightness,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      ),
      // SDK only has light theme
      brightness: effectiveThemeBrightness,
      useMaterial3: true,
      fontFamily: font.description.name,
      extensions: {
        ReclaimTheme(
          primary: primaryColor,
          secondaryColor: secondaryColor,
          background: background != null
              ? BackgroundDecoration(
                  background: background,
                  blurStrength: clientTheme?.backgroundBlurStrength ?? 0,
                  blurColor: backgroundBlurColor,
                )
              : null,
          surfaceColor: surfaceColor ?? const Color(0xFFF7F7F8),
          providerToAppLoader: providerToAppLoader,
          doneIconProvider: doneIconProvider,
          loading: loading,
          fieldVerifiedIconProvider: fieldVerifiedIconProvider,
          fieldVerifyingIconProvider: fieldVerifyingIconProvider,
          verificationCompleteIconProvider: verificationCompleteIconProvider,
          verifyScreenAppIconProvider: verifyScreenAppIconProvider,
          appIconGraphicOptions: appIconGraphicOptions,
          cardColor: cardColor,
          onCardColor: onCardColor,
          termsNoticeColor: termsNoticeColor,
          hyperlinkColor: hyperlinkColor,
          cardElevation: clientTheme?.cardElevation,
          returnToAppMessage: clientThemeInfo.returnToAppMessage,
          dataSharedMessage: clientThemeInfo.dataSharedMessage,
          termsAndConditionsUri: Uri.tryParse(clientThemeInfo.termsAndConditionLink ?? ''),
          privacyPolicyUri: Uri.tryParse(clientThemeInfo.privacyPolicyLink ?? ''),
          sessionChipSurfaceColor: sessionChipSurfaceColor,
          sessionChipOnSurfaceColor: sessionChipOnSurfaceColor,
          parametersTheme: ParametersTheme(
            parameterListStyle: clientTheme?.parameterStyle?.displayStyle ?? ParametersDisplayStyle.compact,
            dividerColor: parameterStyleDividerColor,
            isValueShown: clientTheme?.parameterStyle?.isValueShown ?? true,
          ),
        ),
      },
    );

    if (appName != null && appName.isNotEmpty) {
      SystemChrome.setApplicationSwitcherDescription(
        ApplicationSwitcherDescription(label: appName, primaryColor: themeColorInt),
      );
      latestAppName = appName;
    }

    return theme;
  }

  static ThemeData buildTheme(ReclaimAppThemeInfo? clientThemeInfo, Brightness themeBrightness) {
    ThemeData theme = clientThemeInfo != null
        ? buildClientTheme(clientThemeInfo, themeBrightness)
        : ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF000099),
              primary: const Color(0xFF4444EE),
              secondary: const Color(0xFF2563EB),
              tertiary: const Color(0xFF1375f6),
              brightness: Brightness.light,
              dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
            ),
            // SDK only has light theme
            brightness: Brightness.light,
            useMaterial3: true,
            fontFamily: font.description.name,
            extensions: const {ReclaimTheme()},
          );

    theme = theme.copyWith(splashFactory: (kIsWeb || kIsWasm) ? null : InkSparkle.splashFactory);

    final textTheme = font.textTheme(theme.textTheme);

    theme = theme.copyWith(
      typography: Typography.material2021(
        platform: theme.platform,
        colorScheme: theme.colorScheme,
        black: textTheme,
        white: textTheme,
      ),
      primaryTextTheme: textTheme,
      textTheme: textTheme,
    );

    return theme;
  }

  @override
  Widget build(BuildContext context) {
    final applicationId = this.applicationId;
    final clientAppThemeFuture = applicationId != null ? AppInfo.fromAppId(applicationId) : null;

    return FutureBuilder<AppInfo?>(
      future: clientAppThemeFuture,
      builder: (context, snapshot) {
        final appInfo = snapshot.data;
        final appName = appInfo?.appName;
        var clientThemeInfo = appInfo?.theme;

        if (clientThemeInfo != null && clientThemeInfo.appName?.trim().isNotEmpty != true) {
          clientThemeInfo = clientThemeInfo.copyWith(appName: appName);
        }

        final themeBrightness = Theme.maybeBrightnessOf(context) ?? Brightness.light;

        final theme = buildTheme(clientThemeInfo, themeBrightness);

        final TextStyle fallbackTextStyle = TextStyle(
          color: Colors.white,
          fontFamily: font.description.name,
          fontSize: 16.0,
          fontWeight: FontWeight.normal,
          decoration: TextDecoration.none,
          debugLabel: 'fallback style',
        );

        final clientThemePreferredLocale = clientThemeInfo?.preferredLocale ?? '';

        final l10nProvider = ReclaimLocalizationProvider.find(context);

        final preferredLocale =
            // locale from ancestor reclaim l10n provider
            l10nProvider?.value ??
            parseLocaleName(locale) ??
            // locale from app localization
            Localizations.maybeLocaleOf(context) ??
            // locale from reclaim app api
            parseLocaleName(clientThemePreferredLocale);

        return Theme(
          data: theme,
          child: _ReclaimAppLocalizations(
            locale: preferredLocale,
            isApplicationLevel: isApplicationLevel,
            supportedLocales: ReclaimLocalizationProvider.supportedLocales,
            localizationsDelegates: ReclaimAppLocalizations.localizationsDelegates,
            child: DefaultTextStyle(
              // used as fallback for providing font family wherever text theme isn't used
              style: fallbackTextStyle,
              child: Builder(builder: builder),
            ),
          ),
        );
      },
    );
  }
}

class _ReclaimAppLocalizations extends StatefulWidget {
  final Locale? locale;
  final Iterable<Locale> supportedLocales;
  final List<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  final bool isApplicationLevel;
  final Widget child;

  const _ReclaimAppLocalizations({
    this.locale,
    this.localizationsDelegates,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    required this.isApplicationLevel,
    required this.child,
  });

  @override
  State<_ReclaimAppLocalizations> createState() => _ReclaimAppLocalizationsState();
}

class _ReclaimAppLocalizationsState extends State<_ReclaimAppLocalizations> {
  late ReclaimLocalizationProvider provider;
  late StreamSubscription subscription;
  late bool inheritedLocalizationProvider;
  @override
  void initState() {
    super.initState();
    final parentProvider = ReclaimLocalizationProvider.find(context);
    inheritedLocalizationProvider = parentProvider != null;
    provider = parentProvider ?? ReclaimLocalizationProvider(locale: widget.locale);
    subscription = provider.subscribe(_onProviderUpdate);
  }

  Locale? currentPreferredLocale;

  void _onProviderUpdate(ChangedValues<Locale?> change) {
    final (oldValue, newValue) = change.record;

    if (oldValue == newValue) {
      return;
    }
    if (!mounted) return;
    setState(() {
      currentPreferredLocale = newValue;
      _updateLocalizations(oldWidget: widget);
    });
  }

  @override
  void didUpdateWidget(_ReclaimAppLocalizations oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locale != widget.locale && widget.locale != null) {
      currentPreferredLocale = widget.locale;
      provider.updateSilently(widget.locale);
    }
    _updateLocalizations(oldWidget: oldWidget);
  }

  @override
  void dispose() {
    subscription.cancel();
    if (!inheritedLocalizationProvider) {
      provider.dispose();
    }
    super.dispose();
  }

  Iterable<LocalizationsDelegate<Object?>>? get effectiveLocalizationDelegates {
    // TODO: Update with RemoteLocalizations with appId and providerId query
    return widget.localizationsDelegates;
  }

  late final LocalizationsResolver _localizationsResolver = LocalizationsResolver(
    locale: currentPreferredLocale,
    localizationsDelegates: effectiveLocalizationDelegates,
    supportedLocales: widget.supportedLocales,
    localeListResolutionCallback: null,
    localeResolutionCallback: null,
  );

  void _updateLocalizations({_ReclaimAppLocalizations? oldWidget}) {
    _localizationsResolver.update(
      locale: currentPreferredLocale,
      supportedLocales: widget.supportedLocales,
      localizationsDelegates: effectiveLocalizationDelegates,
      localeListResolutionCallback: null,
      localeResolutionCallback: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return provider.wrap(
      child: ListenableBuilder(
        listenable: _localizationsResolver,
        builder: (BuildContext context, _) {
          return Localizations(
            isApplicationLevel: widget.isApplicationLevel,
            locale: _localizationsResolver.locale,
            delegates: _localizationsResolver.localizationsDelegates.toList(),
            child: widget.child,
          );
        },
      ),
    );
  }
}
