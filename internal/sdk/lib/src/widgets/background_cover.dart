import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:rive/rive.dart';
import 'package:simple_shimmer/simple_shimmer.dart';

import '../logging/logging.dart';
import '../theme/theme.dart';
import '../utils/cache_manager.dart';
import 'color_or_image.dart';
import 'reclaim_image_provider.dart';

class BackgroundCover extends StatelessWidget {
  const BackgroundCover({super.key, required this.builder, this.graphicKeyValue});

  final Widget Function(BuildContext context, Widget? cover) builder;
  final String? graphicKeyValue;

  @override
  Widget build(BuildContext context) {
    final reclaimTheme = ReclaimTheme.of(context);
    final mediaQuerySize = MediaQuery.sizeOf(context);
    late final placeholder = SimpleShimmer(height: mediaQuerySize.height, width: mediaQuerySize.width);

    Widget? backgroundGraphic;

    final Key graphicKey = ValueKey(graphicKeyValue ?? 'background-cover-default');

    switch (reclaimTheme.background?.background) {
      case ImageDecorationProvider(assetProvider: final assetProvider):
        switch (assetProvider.asset) {
          case ReclaimVectorGraphicAsset(uri: final uri, options: final options):
            backgroundGraphic = SvgPicture.network(
              key: graphicKey,
              uri.toString(),
              fit: BoxFit.cover,
              height: mediaQuerySize.height,
              width: mediaQuerySize.width,
              placeholderBuilder: (context) => placeholder,
              alignment: options.alignment,
              errorBuilder: (BuildContext context, Object error, stacktrace) {
                return const SizedBox();
              },
            );
          case ReclaimRasterGraphicAsset(uri: final uri, options: final options):
            backgroundGraphic = CachedNetworkImage(
              imageUrl: uri.toString(),
              cacheManager: ReclaimCacheManager(),
              fit: BoxFit.cover,
              height: mediaQuerySize.height,
              width: mediaQuerySize.width,
              alignment: options.alignment,
              placeholder: (context, url) => placeholder,
              errorWidget: (BuildContext context, String url, Object error) {
                return const SizedBox();
              },
            );
          case ReclaimRiveGraphicAsset(uri: final uri, options: final options):
            backgroundGraphic = _RiveBackgroundCover(
              graphicKey: graphicKey,
              uri: uri,
              placeholder: placeholder,
              mediaQuerySize: mediaQuerySize,
              graphicKeyValue: graphicKeyValue,
              options: options,
            );
          case null:
            break;
        }
        final options = assetProvider.asset?.options;
        final opacity = options?.opacity;
        final backgroundColor = options?.backgroundColor;

        if (opacity == 0.0) {
          backgroundGraphic = null;
        } else if (opacity != null && opacity != 1.0) {
          backgroundGraphic = Opacity(opacity: opacity, child: backgroundGraphic);
        }
        if (backgroundColor != null) {
          backgroundGraphic = DecoratedBox(
            decoration: BoxDecoration(color: backgroundColor),
            child: backgroundGraphic,
          );
        }
      case ColorDecorationProvider(color: final color):
        backgroundGraphic = DecoratedBox(decoration: BoxDecoration(color: color));
      default:
        break;
    }

    final background = reclaimTheme.background;
    final double blurStrength = background?.blurStrength ?? 0;
    if (blurStrength != 0) {
      backgroundGraphic = Stack(
        children: [
          ?backgroundGraphic,
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength),
              child: Container(color: background?.blurColor),
            ),
          ),
        ],
      );
    }

    return builder(context, backgroundGraphic);
  }
}

class _RiveBackgroundCover extends StatefulWidget {
  const _RiveBackgroundCover({
    required this.graphicKey,
    required this.uri,
    required this.placeholder,
    required this.mediaQuerySize,
    required this.graphicKeyValue,
    required this.options,
  });

  final Key graphicKey;
  final Uri uri;
  final SimpleShimmer placeholder;
  final Size mediaQuerySize;
  final String? graphicKeyValue;
  final ReclaimGraphicOptions options;

  @override
  State<_RiveBackgroundCover> createState() => _RiveBackgroundCoverState();
}

class _RiveBackgroundCoverState extends State<_RiveBackgroundCover> {
  late final fileLoader = FileLoader.fromUrl(widget.uri.toString(), riveFactory: Factory.rive);

  @override
  void dispose() {
    fileLoader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RiveWidgetBuilder(
      key: widget.graphicKey,
      fileLoader: fileLoader,
      builder: (context, state) {
        switch (state) {
          case RiveLoading():
            return widget.placeholder;
          case RiveFailed():
            logging.child('BackgroundCover').severe('Failed to load rive asset', state.error, state.stackTrace);
            return const SizedBox();
          case RiveLoaded():
            return SizedBox(
              height: widget.mediaQuerySize.height,
              width: widget.mediaQuerySize.width,
              child: RiveWidget(
                key: widget.graphicKeyValue != null ? ValueKey('rive-${widget.graphicKeyValue}') : null,
                controller: state.controller,
                fit: Fit.cover,
                alignment: widget.options.alignment,
              ),
            );
        }
      },
    );
  }
}
