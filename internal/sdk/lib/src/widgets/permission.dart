import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'params/string.dart';

class PermissionDialog extends StatelessWidget {
  const PermissionDialog({super.key, required this.request});

  final PermissionRequest request;

  static Future<bool> show({required BuildContext context, required PermissionRequest request}) async {
    return await showDialog(
      context: context,
      builder: (context) => PermissionDialog(request: request),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonStyle = TextButton.styleFrom(minimumSize: Size(100, 48), textStyle: TextStyle(fontSize: 16));

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      actionsPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      title: Text('Requesting permission', style: Theme.of(context).textTheme.titleLarge),
      content: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: request.origin.toString(),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: ' wants to access your '),
            TextSpan(
              text: request.resources.map((e) => formatParamsLabel(e.toString())).join(', '),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      actionsOverflowAlignment: OverflowBarAlignment.center,
      actionsOverflowButtonSpacing: 16,
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(style: buttonStyle, onPressed: () => Navigator.pop(context), child: Text('Don\'t Allow')),
        TextButton(
          style: buttonStyle,
          onPressed: () => Navigator.pop(context, true),
          child: Text('Allow', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
