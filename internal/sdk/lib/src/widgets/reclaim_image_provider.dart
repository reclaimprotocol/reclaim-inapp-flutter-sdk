import 'package:flutter/cupertino.dart';

import '../data/reclaim_app_theme.dart';

typedef OnRasterAssetMapCallback<T> = T Function(ReclaimRasterGraphicAsset asset);
typedef OnVectorAssetMapCallback<T> = T Function(ReclaimVectorGraphicAsset asset);
typedef OnNoAssetMapCallback<T> = T Function();

final class ReclaimGraphicProvider {
  final ReclaimGraphicAsset? asset;

  const ReclaimGraphicProvider._({required this.asset});

  static const _none = ReclaimGraphicProvider._(asset: null);

  static ReclaimGraphicProvider fromImageInfo(ReclaimImageInfo? info) {
    if (info == null) return _none;
    final url = info.url;
    if (url == null || url.trim().isEmpty) return _none;
    final uri = Uri.tryParse(url);
    if (uri == null) return _none;
    final options = info.options ?? const ReclaimImageInfoOptions();

    final graphicOptions = ReclaimGraphicOptions.fromImageInfoOptions(options);

    final isSvgAsset = uri.path.toLowerCase().endsWith('svg');

    final ReclaimGraphicAsset asset;
    if (isSvgAsset) {
      asset = ReclaimVectorGraphicAsset(uri: uri, options: graphicOptions);
    } else {
      asset = ReclaimRasterGraphicAsset(uri: uri, options: graphicOptions);
    }

    return ReclaimGraphicProvider._(asset: asset);
  }

  static ReclaimGraphicProvider fromUrl(String? url, ReclaimGraphicOptions options) {
    if (url == null || url.trim().isEmpty) return _none;
    final uri = Uri.tryParse(url);
    if (uri == null) return _none;

    final isSvgAsset = uri.path.toLowerCase().endsWith('svg');

    final ReclaimGraphicAsset asset;
    if (isSvgAsset) {
      asset = ReclaimVectorGraphicAsset(uri: uri, options: options);
    } else {
      asset = ReclaimRasterGraphicAsset(uri: uri, options: options);
    }

    return ReclaimGraphicProvider._(asset: asset);
  }

  T map<T>({
    required OnRasterAssetMapCallback<T> raster,
    required OnVectorAssetMapCallback<T> vector,
    required OnNoAssetMapCallback<T> none,
  }) {
    final asset = this.asset;
    if (asset == null) return none();
    return asset.map(raster: raster, vector: vector);
  }
}

final class ReclaimGraphicOptions {
  final bool spin;
  final Alignment alignment;
  final double opacity;
  final Color? backgroundColor;
  final BoxFit fit;

  const ReclaimGraphicOptions({
    this.spin = false,
    this.alignment = Alignment.center,
    this.opacity = 1,
    this.backgroundColor,
    this.fit = BoxFit.cover,
  });

  factory ReclaimGraphicOptions.fromImageInfoOptions(ReclaimImageInfoOptions options) {
    final spin = options.spin;
    final alignment = Alignment((options.alignment?.x.toDouble()) ?? 0, (options.alignment?.y.toDouble()) ?? 0);
    final opacity = options.opacity.toDouble();
    final bgColorInt = options.backgroundColor;
    final BoxFit fit = switch (options.fit) {
      ImageBoxFit.cover => BoxFit.cover,
      ImageBoxFit.scaleDown => BoxFit.scaleDown,
      null => BoxFit.cover,
    };

    return ReclaimGraphicOptions(
      spin: spin,
      alignment: alignment,
      opacity: opacity,
      backgroundColor: bgColorInt != null ? Color(bgColorInt) : null,
      fit: fit,
    );
  }
}

sealed class ReclaimGraphicAsset {
  final Uri uri;
  final ReclaimGraphicOptions options;

  const ReclaimGraphicAsset({required this.uri, required this.options});

  T map<T>({required OnRasterAssetMapCallback<T> raster, required OnVectorAssetMapCallback<T> vector});
}

final class ReclaimRasterGraphicAsset extends ReclaimGraphicAsset {
  const ReclaimRasterGraphicAsset({required super.uri, required super.options});

  @override
  T map<T>({required OnRasterAssetMapCallback<T> raster, required OnVectorAssetMapCallback<T> vector}) {
    return raster(this);
  }
}

final class ReclaimVectorGraphicAsset extends ReclaimGraphicAsset {
  const ReclaimVectorGraphicAsset({required super.uri, required super.options});

  @override
  T map<T>({required OnRasterAssetMapCallback<T> raster, required OnVectorAssetMapCallback<T> vector}) {
    return vector(this);
  }
}
