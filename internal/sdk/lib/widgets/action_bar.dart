import 'package:flutter/material.dart';
import 'package:reclaim_flutter_sdk/assets/assets.dart';
import 'package:reclaim_flutter_sdk/widgets/svg_icon.dart';

class ActionBar extends StatelessWidget {
  const ActionBar({
    super.key,
    required this.onPressed,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.isLoading = false,
  });

  final VoidCallback onPressed;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8.0),
          topRight: Radius.circular(8.0),
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  label,
                  style: TextStyle(color: foregroundColor),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: isLoading
                  ? SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(foregroundColor),
                        strokeWidth: 2,
                      ),
                    )
                  : SvgImageIcon(
                      $ReclaimAssetImageProvider.rightArrow,
                      size: 32,
                      color: foregroundColor,
                    ),
            )
          ],
        ),
      ),
    );
  }
}
