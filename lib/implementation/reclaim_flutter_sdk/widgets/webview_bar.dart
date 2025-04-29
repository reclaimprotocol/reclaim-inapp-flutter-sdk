import 'package:flutter/material.dart';
import '../reclaim_flutter_sdk.dart';

import 'animated_progress.dart';
import 'svg_icon.dart';

const _loadingIndicatorHeight =
    3.0;

class WebviewBar
    extends StatelessWidget {
  const WebviewBar({
    super.key,
    required this.webviewUrl,
    this.webviewProgress,
    this.openDebugMenu,
    this.close,
  });

  final String
      webviewUrl;
  final double?
      webviewProgress;
  final void
          Function()?
      openDebugMenu;
  final void
          Function()?
      close;

  @override
  Widget build(
      BuildContext
          context) {
    final isWebviewProgressComplete =
        webviewProgress == 1.0;

    return Column(
      // Column for title and progress
      children: [
        Padding(
          padding: EdgeInsets.only(
            // adding a padding when loading completes to prevent webview viewport from shifting when loading is completed
            bottom: isWebviewProgressComplete ? _loadingIndicatorHeight : 0,
          ),
          child: _ReclaimAddressBar(
            openDebugMenu: openDebugMenu,
            webviewUrl: webviewUrl,
            close: close,
          ),
        ),
        if (!isWebviewProgressComplete)
          _ReclaimLinearProgress(
            webviewProgress: webviewProgress,
          ),
      ],
    );
  }
}

class _ReclaimLinearProgress
    extends StatelessWidget {
  const _ReclaimLinearProgress({
    required this.webviewProgress,
  });

  final double?
      webviewProgress;

  @override
  Widget build(
      BuildContext
          context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 18.0),
      child:
          AnimatedLinearProgressIndicator(
        progress: webviewProgress,
        backgroundColor: Colors.transparent,
        minHeight: _loadingIndicatorHeight,
      ),
    );
  }
}

class _ReclaimAddressBar
    extends StatelessWidget {
  const _ReclaimAddressBar({
    required this.openDebugMenu,
    required this.webviewUrl,
    required this.close,
  });

  final void
          Function()?
      openDebugMenu;
  final String
      webviewUrl;
  final void
          Function()?
      close;

  @override
  Widget build(
      BuildContext
          context) {
    final iconSize =
        IconTheme.of(context).size ?? 24;
    final visualDensity = VisualDensity(
        horizontal: 4.0,
        vertical: -4.0);
    final effectiveIconSize =
        iconSize + visualDensity.vertical;
    final minAddressBarHeight =
        effectiveIconSize * 2;
    final visualDensityHeightFactor =
        1.2 + (visualDensity.vertical / 10);
    final adjustedAddressBarHeight =
        minAddressBarHeight * visualDensityHeightFactor;

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 8.0),
      child:
          Stack(
        fit: StackFit.passthrough,
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: openDebugMenu,
              behavior: HitTestBehavior.translucent,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 8 + visualDensity.horizontal,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.symmetric(
                        horizontal: visualDensity.horizontal,
                      ),
                      child: SvgImageIcon(
                        $ReclaimAssetImageProvider.lock,
                        color: Colors.green,
                        size: 16,
                      ),
                    ),
                    SizedBox(
                      width: visualDensity.horizontal,
                    ),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.56,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 2.0),
                          child: _AddressBarUrl(webviewUrl: webviewUrl),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (close != null)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: IconButton(
                icon: const Icon(Icons.close),
                padding: EdgeInsets.zero,
                iconSize: effectiveIconSize,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                visualDensity: visualDensity,
                onPressed: close,
              ),
            ),
          SizedBox(
            height: adjustedAddressBarHeight,
          )
        ],
      ),
    );
  }
}

class _AddressBarUrl
    extends StatelessWidget {
  const _AddressBarUrl({
    required this.webviewUrl,
  });

  final String
      webviewUrl;

  @override
  Widget build(
      BuildContext
          context) {
    final uri =
        Uri.parse(webviewUrl.trim());

    return Text
        .rich(
      TextSpan(
        children: [
          TextSpan(
            text: uri.authority,
            style: TextStyle(
              color: Colors.black87,
            ),
          ),
          TextSpan(
            text: uri.path,
          ),
          if (uri.query.isNotEmpty)
            TextSpan(
              text: '?${uri.query}',
            ),
        ],
      ),
      overflow:
          TextOverflow.ellipsis,
      style:
          TextStyle(
        fontWeight: FontWeight.normal,
        color: Colors.grey,
        fontSize: 16,
        height: 1.19,
      ),
      textAlign:
          TextAlign.start,
    );
  }
}
