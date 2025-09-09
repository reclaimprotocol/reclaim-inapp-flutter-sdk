import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../assets/assets.dart';
import '../data/app_info.dart';
import '../data/reclaim_app_theme.dart';
import '../theme/theme.dart';
import 'color_or_image.dart';
import 'reclaim_image_provider.dart';

class ReclaimThemeProvider extends StatelessWidget {
  const ReclaimThemeProvider({super.key, required this.builder, required this.applicationId});

  final String? applicationId;
  final WidgetBuilder builder;

  static const font = $ReclaimFont.inter;

  static String? latestAppName;

  static ThemeData buildClientTheme(ReclaimAppThemeInfo clientThemeInfo) {
    final clientTheme = clientThemeInfo.theme;

    final themeColorInt = clientTheme?.colorScheme?.themeColor;
    final surfaceColorInt = clientTheme?.colorScheme?.surfaceColor;
    final onSurfaceColorInt = clientTheme?.colorScheme?.onSurfaceColor;
    final loadingIconColorInt = clientTheme?.loadingIconColor;
    final cardColorInt = clientTheme?.cardColor;
    final onCardColorInt = clientTheme?.onCardColor;

    final primaryColor = themeColorInt != null ? Color(themeColorInt) : const Color(0xFF000099);
    final secondaryColor = primaryColor;
    final surfaceColor = surfaceColorInt != null ? Color(surfaceColorInt) : null;
    final onSurfaceColor = onSurfaceColorInt != null ? Color(onSurfaceColorInt) : null;
    final loadingIconColor = loadingIconColorInt != null ? Color(loadingIconColorInt) : null;
    final cardColor = cardColorInt != null ? Color(cardColorInt) : null;
    final onCardColor = onCardColorInt != null ? Color(onCardColorInt) : null;

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
    final providerToAppLoaderColorInt = clientTheme?.verificationReviewScreenTheme?.providerToAppLoaderColor;

    final providerToAppLoaderColor = providerToAppLoaderColorInt != null ? Color(providerToAppLoaderColorInt) : null;

    final background = ColorOrImageDecorationProvider.from(clientTheme?.background);

    final appName = clientThemeInfo.appName;

    final clientAppIconOptions = clientTheme?.appImageOptions;

    final appIconGraphicOptions = clientAppIconOptions != null
        ? ReclaimGraphicOptions.fromImageInfoOptions(clientAppIconOptions)
        : null;

    ThemeData theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        surface: surfaceColor,
        onSurface: onSurfaceColor,
        brightness: Brightness.light,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      ),
      // SDK only has light theme
      brightness: Brightness.light,
      useMaterial3: true,
      fontFamily: font.description.name,
      extensions: {
        ReclaimTheme(
          primary: primaryColor,
          secondaryColor: secondaryColor,
          background: background,
          surfaceColor: surfaceColor ?? const Color(0xFFF7F7F8),
          providerToAppLoaderColor: providerToAppLoaderColor,
          doneIconProvider: doneIconProvider,
          loadingIconColor: loadingIconColor,
          fieldVerifiedIconProvider: fieldVerifiedIconProvider,
          fieldVerifyingIconProvider: fieldVerifyingIconProvider,
          verificationCompleteIconProvider: verificationCompleteIconProvider,
          verifyScreenAppIconProvider: verifyScreenAppIconProvider,
          appIconGraphicOptions: appIconGraphicOptions,
          cardColor: cardColor,
          onCardColor: onCardColor,
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

  static ThemeData buildTheme(ReclaimAppThemeInfo? clientThemeInfo) {
    ThemeData theme = clientThemeInfo != null
        ? buildClientTheme(clientThemeInfo)
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

        final theme = buildTheme(clientThemeInfo);

        final TextStyle fallbackTextStyle = TextStyle(
          color: Colors.white,
          fontFamily: font.description.name,
          fontSize: 16.0,
          fontWeight: FontWeight.normal,
          decoration: TextDecoration.none,
          debugLabel: 'fallback style',
        );

        return Theme(
          data: theme,
          child: DefaultTextStyle(
            // used as fallback for providing font family wherever text theme isn't used
            style: fallbackTextStyle,
            child: Builder(builder: builder),
          ),
        );
      },
    );
  }
}
