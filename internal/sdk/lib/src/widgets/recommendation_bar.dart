import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class RecommendationBar extends StatelessWidget {
  const RecommendationBar({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.isLoading = false,
    required this.onDismiss,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool isLoading;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.horizontal,
      onDismissed: (_) {
        onDismiss();
      },
      background: Container(
        color: Colors.grey.withAlpha(50),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Icon(Icons.arrow_back, color: foregroundColor),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Icon(Icons.arrow_forward, color: foregroundColor),
            ),
          ],
        ),
      ),
      child: Material(
        color: Colors.grey[300],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(2.0), topRight: Radius.circular(2.0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(label, style: TextStyle(color: foregroundColor)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: isLoading
                  ? SpinKitFadingCircle(color: foregroundColor, size: 24.0)
                  : Icon(Icons.swipe, color: foregroundColor),
            ),
          ],
        ),
      ),
    );
  }
}
