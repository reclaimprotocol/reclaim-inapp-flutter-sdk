import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_ui/material_ui.dart';

import '../../reclaim_inapp_sdk.dart';
import '../assets/assets.dart';
import '../l10n/provider.dart';
import 'fonts_loaded.dart';
import 'shadow.dart';
import 'svg_icon.dart';

class SessionIdLabelChip extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  /// If null, the sessionId will be fetched from [VerificationController.of(context).request.sessionInformation.sessionId].
  final String? sessionId;

  const SessionIdLabelChip({super.key, this.padding = const EdgeInsets.all(6.0), this.sessionId});

  static const double estimateHeight = 32.0;

  @override
  Widget build(BuildContext context) {
    final sessionId = this.sessionId?.isNotEmpty == true ? this.sessionId : null;

    final theme = Theme.of(context);
    final appTheme = ReclaimTheme.of(context);
    final cardElevation = appTheme.cardElevation;
    final backgroundColor = appTheme.sessionChipSurfaceColor ?? appTheme.cardColor ?? appTheme.surfaceColor;
    final foregroundColor = appTheme.sessionChipOnSurfaceColor ?? appTheme.onCardColor ?? theme.colorScheme.onSurface;

    final sessionLabelStyle = TextStyle(
      fontSize: 12,
      color: foregroundColor,
      fontWeight: FontWeight.w400,
      height: 1.35,
    );

    return GestureDetector(
      onTap: () {
        if (sessionId == null) return;
        Clipboard.setData(ClipboardData(text: sessionId)).then((_) {
          if (!context.mounted) return;
          Fluttertoast.showToast(msg: context.l10n.copiedToYourClipboard);
        });
      },
      behavior: HitTestBehavior.translucent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(6.0)),
          color: appTheme.sessionChipSurfaceColor != null ? backgroundColor : backgroundColor.withValues(alpha: 0.5),
          boxShadow: cardElevation == 0 ? null : reclaimBoxShadow,
        ),
        child: Padding(
          padding: padding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgImageIcon($ReclaimAssetImageProvider.shieldTick, color: foregroundColor, size: 19),
              const SizedBox(width: 8),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 15),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AnimatedSwitcher(
                      duration: Durations.short4,
                      switchInCurve: Curves.easeIn,
                      switchOutCurve: Curves.easeOut,
                      child: FontsLoaded(
                        child: Text.rich(
                          TextSpan(
                            text: (sessionId != null && sessionId.isNotEmpty)
                                ? sessionId // fmt
                                : context.l10n.proofsGeneratedByReclaimProtocolAreSecureAndPrivate,
                            children: [
                              if (sessionId != null && sessionId.isNotEmpty)
                                WidgetSpan(
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional.only(start: 4.0),
                                    child: SvgImageIcon(
                                      $ReclaimAssetImageProvider.copy,
                                      color: foregroundColor,
                                      size: 14,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          key: ValueKey('${context.hashCode}-$sessionId'),
                          style: sessionLabelStyle,
                          textAlign: TextAlign.start,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
