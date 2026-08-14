import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rive/rive.dart';
import 'package:simple_shimmer/simple_shimmer.dart';

import '../logging/logging.dart';
import '../services/base_http.dart';
import '../utils/cache_manager.dart';
import 'reclaim_image_provider.dart';

class VerifiedIcon extends StatelessWidget {
  const VerifiedIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF22C55E),
        border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 1.6)),
      ),
      child: Padding(
        padding: EdgeInsets.all(3.2),
        child: Icon(Icons.check_rounded, size: 10.4, color: Colors.white),
      ),
    );
  }
}

class TransparentPlaceholder extends StatelessWidget {
  const TransparentPlaceholder({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: SizedBox.square(dimension: size),
    );
  }
}

class LogoIcon extends StatelessWidget {
  const LogoIcon({
    super.key,
    required this.logoUrl,
    this.size = 50,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  final String logoUrl;
  final double size;
  final BorderRadiusGeometry? borderRadius;
  final BoxFit fit;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final shimmerTheme = SimpleShimmerTheme.of(context);
    late final placeholder = this.placeholder ?? SimpleShimmer(height: size, width: size);

    return SimpleShimmerTheme(
      data: shimmerTheme.copyWith(decoration: ShimmerDecoration(borderRadius: borderRadius)),
      child: ClipRRect(
        borderRadius: borderRadius ?? const BorderRadius.all(Radius.circular(16)),
        child: CachedNetworkImage(
          imageUrl: logoUrl,
          cacheManager: ReclaimCacheManager(),
          fit: fit,
          height: size,
          width: size,
          placeholder: (context, url) => placeholder,
          errorWidget: (BuildContext context, String url, Object error) {
            return Padding(
              padding: EdgeInsets.all(size * 0.1),
              child: Icon(Icons.error, size: size * 0.8),
            );
          },
        ),
      ),
    );
  }
}

class LogoSvgIcon extends StatelessWidget {
  const LogoSvgIcon({
    super.key,
    required this.logoUrl,
    this.size = 50,
    this.borderRadius,
    this.fit = BoxFit.cover,
    required this.placeholder,
  });

  final String logoUrl;
  final double size;
  final BorderRadiusGeometry? borderRadius;
  final BoxFit fit;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final shimmerTheme = SimpleShimmerTheme.of(context);
    late final placeholder = this.placeholder ?? SimpleShimmer(height: size, width: size);

    return SimpleShimmerTheme(
      data: shimmerTheme.copyWith(decoration: ShimmerDecoration(borderRadius: borderRadius)),
      child: ClipRRect(
        borderRadius: borderRadius ?? const BorderRadius.all(Radius.circular(16)),
        child: SvgPicture.network(
          logoUrl,
          httpClient: reclaimHttpBaseClient,
          fit: fit,
          height: size,
          width: size,
          placeholderBuilder: (context) => placeholder,
          errorBuilder: (BuildContext context, Object error, stackTrace) {
            return Padding(
              padding: EdgeInsets.all(size * 0.1),
              child: Icon(Icons.error, size: size * 0.8),
            );
          },
        ),
      ),
    );
  }
}

class LogoRiveIcon extends StatefulWidget {
  const LogoRiveIcon({
    super.key,
    required this.logoUrl,
    this.size = 50,
    this.borderRadius,
    this.fit = BoxFit.cover,
    required this.placeholder,
  });

  final String logoUrl;
  final double size;
  final BorderRadiusGeometry? borderRadius;
  final BoxFit fit;
  final Widget? placeholder;

  @override
  State<LogoRiveIcon> createState() => _LogoRiveIconState();
}

class _LogoRiveIconState extends State<LogoRiveIcon> {
  late final fileLoader = FileLoader.fromUrl(widget.logoUrl, riveFactory: Factory.rive);

  @override
  void dispose() {
    fileLoader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shimmerTheme = SimpleShimmerTheme.of(context);
    late final placeholder = widget.placeholder ?? SimpleShimmer(height: widget.size, width: widget.size);

    return SimpleShimmerTheme(
      data: shimmerTheme.copyWith(decoration: ShimmerDecoration(borderRadius: widget.borderRadius)),
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? const BorderRadius.all(Radius.circular(16)),
        child: RiveWidgetBuilder(
          fileLoader: fileLoader,
          builder: (context, state) {
            return switch (state) {
              RiveLoading() => placeholder,
              RiveFailed() => () {
                logging.child('_LogoRiveIconState').severe('Failed to load rive asset', state.error, state.stackTrace);
                return Padding(
                  padding: EdgeInsets.all(widget.size * 0.1),
                  child: Icon(Icons.error, size: widget.size * 0.8),
                );
              }(),
              RiveLoaded() => SizedBox.square(
                dimension: widget.size,
                child: RiveWidget(
                  controller: state.controller,
                  fit: () {
                    switch (widget.fit) {
                      case BoxFit.fill:
                        return Fit.fill;
                      case BoxFit.contain:
                        return Fit.contain;
                      case BoxFit.cover:
                        return Fit.cover;
                      case BoxFit.fitWidth:
                        return Fit.fitWidth;
                      case BoxFit.fitHeight:
                        return Fit.fitHeight;
                      case BoxFit.none:
                        return Fit.none;
                      case BoxFit.scaleDown:
                        return Fit.scaleDown;
                    }
                  }(),
                ),
              ),
            };
          },
        ),
      ),
    );
  }
}

class ReclaimGraphicIcon extends StatelessWidget {
  const ReclaimGraphicIcon({
    super.key,
    this.placeholder,
    this.borderRadius = BorderRadius.zero,
    this.size,
    this.provider,
    this.fit,
    this.fallback,
  });

  final double? size;

  /// A placeholder to display when nothing else is displayed. See [TransparentPlaceholder]. Defaults to a [SimpleShimmer] widget.
  final Widget? placeholder;
  final BorderRadiusGeometry? borderRadius;
  final ReclaimGraphicProvider? provider;
  final BoxFit? fit;

  /// A fallback widget to display if no provider is given or if the provider's asset is null. Defaults to the placeholder if not provided.
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? IconTheme.of(context).size ?? 24.0;

    return switch (provider?.asset) {
      ReclaimRasterGraphicAsset(uri: final uri, options: final options) => LogoIcon(
        logoUrl: uri.toString(),
        size: effectiveSize,
        borderRadius: borderRadius,
        placeholder: placeholder,
        fit: fit ?? options.fit,
      ),
      ReclaimVectorGraphicAsset(uri: final uri, options: final options) => LogoSvgIcon(
        logoUrl: uri.toString(),
        size: effectiveSize,
        borderRadius: borderRadius,
        placeholder: placeholder,
        fit: fit ?? options.fit,
      ),
      ReclaimRiveGraphicAsset(uri: final uri, options: final options) => LogoRiveIcon(
        logoUrl: uri.toString(),
        size: effectiveSize,
        borderRadius: borderRadius,
        placeholder: placeholder,
        fit: fit ?? options.fit,
      ),
      null => fallback ?? placeholder ?? TransparentPlaceholder(size: effectiveSize),
    };
  }
}
