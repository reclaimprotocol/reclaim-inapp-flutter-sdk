import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:simple_shimmer/simple_shimmer.dart';

import '../theme/theme.dart';
import '../utils/cache_manager.dart';
import 'color_or_image.dart';
import 'reclaim_image_provider.dart';

class BackgroundCover extends StatelessWidget {
  const BackgroundCover({super.key, required this.builder});

  final Widget Function(BuildContext context, Widget? cover) builder;

  @override
  Widget build(BuildContext context) {
    final reclaimTheme = ReclaimTheme.of(context);
    final mediaQuerySize = MediaQuery.sizeOf(context);
    late final placeholder = SimpleShimmer(height: mediaQuerySize.height, width: mediaQuerySize.width);

    Widget? backgroundGraphic;

    switch (reclaimTheme.background) {
      case ImageDecorationProvider(assetProvider: final assetProvider):
        switch (assetProvider.asset) {
          case ReclaimVectorGraphicAsset(uri: final uri, options: final options):
            backgroundGraphic = SvgPicture.network(
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
          default:
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
      default:
        break;
    }

    return builder(context, backgroundGraphic);
  }
}
