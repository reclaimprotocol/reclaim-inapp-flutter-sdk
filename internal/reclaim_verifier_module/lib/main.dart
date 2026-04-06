import 'package:flutter/material.dart';

import 'reclaim_verifier_module.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sdk = ReclaimInAppSdk();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ReclaimInAppSdkUIScope(sdk: sdk, child: ReclaimModuleApp()),
    ),
  );
}

class ReclaimModuleApp extends StatelessWidget {
  const ReclaimModuleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return PopScope(
      canPop: true,
      child: Scaffold(
        body: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          child: Center(child: ClaimTriggerIndicator(color: colorScheme.primary)),
        ),
      ),
    );
  }
}
