import 'package:flutter/material.dart';

import '../assets/assets.dart';
import '../controller.dart';
import 'svg_icon.dart';
import 'verification_review/controller.dart';

class ReclaimAddressBar extends StatelessWidget {
  const ReclaimAddressBar({super.key, required this.onPressed, required this.url, required this.isCloseButtonVisible});

  final void Function()? onPressed;
  final String url;
  final bool? isCloseButtonVisible;

  @override
  Widget build(BuildContext context) {
    final iconSize = IconTheme.of(context).size ?? 24;
    final visualDensity = VisualDensity(horizontal: 4.0, vertical: -4.0);
    final effectiveIconSize = iconSize + visualDensity.vertical;
    final minAddressBarHeight = effectiveIconSize * 2;
    final visualDensityHeightFactor = 1.2 + (visualDensity.vertical / 10);
    final adjustedAddressBarHeight = minAddressBarHeight * visualDensityHeightFactor;

    final isCloseButtonVisible =
        this.isCloseButtonVisible ?? VerificationController.of(context).options.isCloseButtonVisible;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Stack(
        fit: StackFit.passthrough,
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: onPressed,
              behavior: HitTestBehavior.translucent,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8 + visualDensity.horizontal),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.symmetric(horizontal: visualDensity.horizontal),
                      child: Builder(
                        builder: (context) {
                          final isVisible = VerificationReviewController.of(context).value.isVisible;
                          return AnimatedSwitcher(
                            duration: Durations.medium1,
                            child:
                                isVisible
                                    ? SizedBox(width: 16)
                                    : SvgImageIcon($ReclaimAssetImageProvider.lock, color: Colors.green, size: 16),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: visualDensity.horizontal),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.56),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 2.0),
                          child: Builder(
                            builder: (context) {
                              final isVisible = VerificationReviewController.of(context).value.isVisible;
                              return AnimatedSwitcher(
                                duration: Durations.medium1,
                                child: isVisible ? SizedBox(height: 19.04) : _AddressBarUrl(webviewUrl: url),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isCloseButtonVisible)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: IconButton(
                icon: const Icon(Icons.close),
                padding: EdgeInsets.zero,
                iconSize: effectiveIconSize,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                visualDensity: visualDensity,
                onPressed: Navigator.of(context).pop,
              ),
            ),
          SizedBox(height: adjustedAddressBarHeight),
        ],
      ),
    );
  }
}

class _AddressBarUrl extends StatelessWidget {
  const _AddressBarUrl({required this.webviewUrl});

  final String webviewUrl;

  static const _loading = Text(
    'loading..',
    overflow: TextOverflow.ellipsis,
    style: TextStyle(fontWeight: FontWeight.normal, color: Colors.grey, fontSize: 16, height: 1.19),
    textAlign: TextAlign.start,
  );

  @override
  Widget build(BuildContext context) {
    final url = webviewUrl.trim();

    if (url.isEmpty) {
      return _loading;
    }

    final uri = Uri.tryParse(url);

    if (uri == null) {
      return _loading;
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: uri.authority, style: TextStyle(color: Colors.black87)),
          TextSpan(text: uri.path),
          if (uri.query.isNotEmpty) TextSpan(text: '?${uri.query}'),
        ],
      ),
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontWeight: FontWeight.normal, color: Colors.grey, fontSize: 16, height: 1.19),
      textAlign: TextAlign.start,
    );
  }
}
