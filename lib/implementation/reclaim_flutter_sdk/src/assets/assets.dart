import 'package:flutter/services.dart'
    show
        rootBundle;
import 'package:flutter/widgets.dart';

class ReclaimAssetProvider {
  final String
      assetName;

  static const _packageName =
      'reclaim_flutter_sdk';

  const ReclaimAssetProvider(
      {required this.assetName});

  AssetBundle
      _resolveBundle(BuildContext? context) {
    if (context !=
        null) {
      return DefaultAssetBundle.of(context);
    }
    return rootBundle;
  }

  static final _cache =
      <String,
          String>{};

  Future<String>
      getString(BuildContext? context) async {
    final cached =
        _cache[assetName];
    if (cached !=
        null) {
      return cached;
    }

    final data =
        await _resolveBundle(
      context,
    ).loadString('packages/$_packageName/$assetName');

    _cache[assetName] =
        data;

    return data;
  }
}
