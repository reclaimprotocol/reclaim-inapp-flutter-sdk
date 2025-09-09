import 'dart:ui';

import '../data/reclaim_app_theme.dart';
import 'reclaim_image_provider.dart';

typedef OnColorCallback<T> = T Function(Color color);
typedef OnAssetProviderCallback<T> = T Function(ReclaimGraphicProvider assetProvider);

sealed class ColorOrImageDecorationProvider {
  const ColorOrImageDecorationProvider();

  static ColorOrImageDecorationProvider? from(ColorOrImage? data) {
    if (data == null) return null;

    final assetProvider = ReclaimGraphicProvider.fromImageInfo(data.image);
    if (assetProvider.asset != null) {
      return ImageDecorationProvider(assetProvider: assetProvider);
    }
    final colorInt = data.color;
    if (colorInt != null) {
      return ColorDecorationProvider(color: Color(colorInt));
    }
    return null;
  }

  T map<T>({required OnColorCallback<T> onColor, required OnAssetProviderCallback<T> onAssetProvider});
}

class ColorDecorationProvider extends ColorOrImageDecorationProvider {
  final Color color;

  const ColorDecorationProvider({required this.color});

  @override
  T map<T>({required OnColorCallback<T> onColor, required OnAssetProviderCallback<T> onAssetProvider}) {
    return onColor(color);
  }
}

class ImageDecorationProvider extends ColorOrImageDecorationProvider {
  final ReclaimGraphicProvider assetProvider;

  const ImageDecorationProvider({required this.assetProvider});

  @override
  T map<T>({required OnColorCallback<T> onColor, required OnAssetProviderCallback<T> onAssetProvider}) {
    return onAssetProvider(assetProvider);
  }
}
