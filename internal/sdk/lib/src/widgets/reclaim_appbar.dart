import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';
import 'addressbar.dart';
import 'progress_indicator.dart';
import 'verification_review/controller.dart';

class WebAppBarValue {
  final String url;
  final double progress;

  const WebAppBarValue({required this.url, required this.progress});

  WebAppBarValue copyWith({String? url, double? progress}) {
    return WebAppBarValue(url: url ?? this.url, progress: progress ?? this.progress);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is WebAppBarValue) {
      return url == other.url && progress == other.progress;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(url, progress);

  static const empty = WebAppBarValue(url: '', progress: 0);

  @override
  String toString() {
    return 'WebAppBarValue(url: $url, progress: $progress)';
  }
}

class ReclaimAppBarController extends ValueNotifier<WebAppBarValue> {
  ReclaimAppBarController([super.value = WebAppBarValue.empty]);

  void updateUrl(String url) {
    value = value.copyWith(url: url);
  }

  void updateProgress(double progress) {
    value = value.copyWith(progress: progress);
  }
}

class ReclaimAppBar extends StatefulWidget implements PreferredSizeWidget {
  const ReclaimAppBar({super.key, required this.controller, required this.onPressed, this.isCloseButtonVisible});

  final ReclaimAppBarController controller;
  final VoidCallback? onPressed;
  final bool? isCloseButtonVisible;

  @override
  State<StatefulWidget> createState() => _ReclaimAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight - 10);
}

class _ReclaimAppBarState extends State<ReclaimAppBar> {
  @override
  Widget build(BuildContext context) {
    final backgroundColor = ReclaimTheme.of(context).grayBackground;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        // let top bar take care of color
        statusBarColor: Colors.transparent,
        // on some devices, the color behind system navigation overlay could become black (and flutter's choice for bg color is also black)
        systemNavigationBarColor: backgroundColor,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: SafeArea(
        top: true,
        child: ValueListenableBuilder(
          valueListenable: widget.controller,
          builder: (context, value, _) {
            return Stack(
              alignment: Alignment.bottomCenter,
              children: [
                ReclaimAddressBar(
                  url: value.url,
                  onPressed: widget.onPressed,
                  isCloseButtonVisible: widget.isCloseButtonVisible,
                ),
                Builder(
                  builder: (context) {
                    final isVisible = VerificationReviewController.of(context).value.isVisible;
                    return ReclaimLinearProgress(progress: isVisible ? 1 : value.progress);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
