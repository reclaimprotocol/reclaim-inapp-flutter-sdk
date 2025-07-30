import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:simple_shimmer/simple_shimmer.dart';

import '../utils/cache_manager.dart';

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

class LogoIcon extends StatelessWidget {
  const LogoIcon({super.key, required this.logoUrl, this.size = 50, this.borderRadius});

  final String logoUrl;
  final double size;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    final shimmerTheme = SimpleShimmerTheme.of(context);
    late final placeholder = SimpleShimmer(height: size, width: size);

    return SimpleShimmerTheme(
      data: shimmerTheme.copyWith(decoration: ShimmerDecoration(borderRadius: borderRadius)),
      child: ClipRRect(
        borderRadius: borderRadius ?? const BorderRadius.all(Radius.circular(16)),
        child: CachedNetworkImage(
          imageUrl: logoUrl,
          cacheManager: ReclaimCacheManager(),
          fit: BoxFit.cover,
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
