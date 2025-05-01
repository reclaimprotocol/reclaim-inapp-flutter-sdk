import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'widgets.dart';

class WindowPopup extends StatefulWidget {
  final CreateWindowAction createWindowAction;
  final void Function() closePopup;

  const WindowPopup(
      {super.key, required this.createWindowAction, required this.closePopup});

  @override
  State<WindowPopup> createState() => _WindowPopupState();
}

class _WindowPopupState extends State<WindowPopup> {
  String _webviewUrl = '';
  double _webviewProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.all(0),
      contentPadding: const EdgeInsets.all(0),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WebviewBar(
              webviewUrl: _webviewUrl,
              webviewProgress: _webviewProgress,
              close: widget.closePopup,
            ),
            Expanded(
              child: InAppWebView(
                initialSettings: InAppWebViewSettings(
                    userAgent:
                        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.3 Mobile/15E137 Safari/604.1"),
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
                windowId: widget.createWindowAction.windowId,
                onLoadStart: (controller, url) => {
                  setState(() {
                    _webviewProgress = 0.0;
                  })
                },
                onTitleChanged: (controller, title) {
                  setState(() {
                    _webviewUrl = title ?? "";
                  });
                },
                onProgressChanged: (controller, progress) => {
                  setState(() {
                    _webviewProgress = progress / 100.0;
                  })
                },
                onCloseWindow: (controller) {
                  widget.closePopup();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
