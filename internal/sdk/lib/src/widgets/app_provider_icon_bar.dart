import 'package:flutter/material.dart';
import 'package:simple_shimmer/simple_shimmer.dart';

import '../theme/theme.dart';
import 'claim_creation/claim_creation.dart';
import 'claim_creation/trigger_indicator.dart';
import 'color_or_image.dart';
import 'icon.dart';
import 'item_alignment.dart';
import 'reclaim_image_provider.dart';
import 'verification_review/controller.dart';

class AppProviderIconsBar extends StatelessWidget {
  const AppProviderIconsBar({
    super.key,
    required this.itemAlignment,
    required this.appImageUrl,
    required this.appName,
    required this.providerImageUrl,
    required this.providerName,
    required this.hasProviderData,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.useInheritedVerificationInformation = false,
    this.logoSize = 70.0,
  });

  final ItemAlignment itemAlignment;
  final String? appImageUrl;
  final String? appName;
  final String? providerImageUrl;
  final String? providerName;
  final BorderRadius borderRadius;
  final bool hasProviderData;
  final bool useInheritedVerificationInformation;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final double defaultIconSize = logoSize;

    final appImageUrl = this.appImageUrl;

    final reclaimTheme = ReclaimTheme.of(context);

    final providerImageUrl = this.providerImageUrl;

    final theme = ReclaimTheme.of(context);
    final appIconProvider = theme.verifyScreenAppIconProvider;

    final placeholder = TransparentPlaceholder(size: logoSize);

    final mainAppImageProvider = ReclaimGraphicProvider.fromUrl(
      appImageUrl,
      reclaimTheme.appIconGraphicOptions ?? const ReclaimGraphicOptions(),
    );

    // Provider hasn't loaded yet or we don't have app icon provider in theme
    final isUsingMainAppIcon = !hasProviderData || appIconProvider?.asset == null;

    final applicationIcon = InkWell(
      onDoubleTap: useInheritedVerificationInformation
          ? () {
              VerificationReviewController.readOf(context).setIsVisible(false);
            }
          : null,
      borderRadius: borderRadius,
      child: AnimatedSwitcher(
        duration: Durations.medium1,
        child: switch (isUsingMainAppIcon ? mainAppImageProvider.asset : appIconProvider?.asset) {
          ReclaimRasterGraphicAsset(uri: final uri, options: final options) => LogoIcon(
            key: ValueKey('app-${isUsingMainAppIcon ? 'main-' : ''}icon.raster'),
            logoUrl: uri.toString(),
            size: logoSize,
            borderRadius: borderRadius,
            placeholder: placeholder,
            fit: options.fit,
          ),
          ReclaimVectorGraphicAsset(uri: final uri, options: final options) => LogoSvgIcon(
            key: ValueKey('app-${isUsingMainAppIcon ? 'main-' : ''}icon.vector'),
            logoUrl: uri.toString(),
            size: logoSize,
            borderRadius: borderRadius,
            placeholder: placeholder,
            fit: options.fit,
          ),
          ReclaimRiveGraphicAsset(uri: final uri, options: final options) => LogoRiveIcon(
            key: ValueKey('app-${isUsingMainAppIcon ? 'main-' : ''}icon.rive'),
            logoUrl: uri.toString(),
            size: logoSize,
            borderRadius: borderRadius,
            placeholder: placeholder,
            fit: options.fit,
          ),
          null => placeholder,
        },
      ),
    );

    final isStartAligned = itemAlignment.isStarting;

    final movementTransitionDuration = Durations.long4;
    final maxWidth = (logoSize * 2) + defaultIconSize + (isStartAligned ? 1 : 2);

    return Row(
      mainAxisAlignment: isStartAligned ? MainAxisAlignment.start : MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: logoSize, maxWidth: maxWidth),
          child: Stack(
            alignment: AlignmentDirectional.center,
            fit: StackFit.expand,
            children: [
              AnimatedPositioned(
                top: 0,
                right: providerImageUrl == null
                    ? (isStartAligned ? maxWidth - logoSize : ((maxWidth / 2) - (logoSize / 2)))
                    : 0,
                height: logoSize,
                width: logoSize,
                curve: Curves.fastEaseInToSlowEaseOut,
                duration: movementTransitionDuration,
                child: applicationIcon,
              ),
              AnimatedPositioned(
                top: 0,
                left: 0,
                height: logoSize,
                width: logoSize + defaultIconSize,
                curve: Curves.easeIn,
                duration: movementTransitionDuration,
                child: AnimatedSwitcher(
                  duration: movementTransitionDuration,
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  child: providerImageUrl == null && providerName == null
                      ? SizedBox(height: logoSize)
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Tooltip(
                              message: providerName ?? 'Provider',
                              child: providerImageUrl != null && providerImageUrl.isNotEmpty
                                  ? LogoIcon(logoUrl: providerImageUrl, size: logoSize, borderRadius: borderRadius)
                                  : SimpleShimmer(height: logoSize, width: logoSize),
                            ),
                            _AppVerificationTransferIcon(
                              size: defaultIconSize,
                              useInheritedVerificationInformation: useInheritedVerificationInformation,
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AppVerificationTransferIcon extends StatelessWidget {
  const _AppVerificationTransferIcon({required this.size, this.useInheritedVerificationInformation = false});

  final double size;
  final bool useInheritedVerificationInformation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appTheme = ReclaimTheme.of(context);

    if (useInheritedVerificationInformation) {
      final controller = ClaimCreationController.of(context);
      final claimCreationValue = controller.value;

      if (!claimCreationValue.isFinished ||
          // show only image if we have one
          appTheme.providerToAppLoader?.map(
                onColor: (color) => false,
                onAssetProvider: (provider) => provider.asset != null,
              ) ==
              true) {
        Color? providerToAppLoaderColor;
        switch (appTheme.providerToAppLoader) {
          case null:
            break;
          case ColorDecorationProvider(color: final color):
            providerToAppLoaderColor = color;
            break;
          case ImageDecorationProvider(assetProvider: final assetProvider):
            const placeholder = SizedBox();
            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: size),
              child: ReclaimGraphicIcon(
                provider: assetProvider,
                size: size,
                placeholder: placeholder,
                fit: BoxFit.scaleDown,
              ),
            );
        }
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: size),
          child: ClaimTriggerIndicator(
            key: const ValueKey('aicon-progress-indicator'),
            color: claimCreationValue.hasError ? colorScheme.error : (providerToAppLoaderColor ?? colorScheme.primary),
            progress: claimCreationValue.progress ?? 0.0,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
            thickness: 3,
          ),
        );
      }
    }

    final iconSize = size / 1.6;
    final horizontalPadding = (size - iconSize) / 2;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Icon(Icons.arrow_forward_rounded, color: Colors.black, size: iconSize),
    );
  }
}
