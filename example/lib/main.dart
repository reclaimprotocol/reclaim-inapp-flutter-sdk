import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reclaim_inapp_flutter_sdk/reclaim_inapp_flutter_sdk.dart';

void main() {
  runApp(MaterialApp(home: Start()));
}

class Start extends StatefulWidget {
  const Start({super.key});

  @override
  State<Start> createState() => _StartState();
}

class _StartState extends State<Start> {
  String _pingResponse = 'Unknown';
  final sdk = ReclaimVerification();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String pingResponse;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      pingResponse = await sdk.ping() ?? 'Unknown';
    } on PlatformException {
      pingResponse = 'Failed to get ping response.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _pingResponse = pingResponse;
    });
  }

  ReclaimVerificationResponse? response;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plugin example app')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(padding: const EdgeInsets.all(8.0), child: Text('Pinged: $_pingResponse\n')),
          ElevatedButton(
            onPressed: () async {
              final msg = ScaffoldMessenger.of(context);
              try {
                response = await sdk.startVerification(
                  ReclaimVerificationRequest(appId: 'appId', secret: 'secret', providerId: 'providerId'),
                );
              } on ReclaimVerificationException catch (e) {
                msg.showSnackBar(SnackBar(content: Text(e.reason)));
              } catch (e, s) {
                if (kDebugMode) {
                  debugPrintThrottled(e.toString());
                  debugPrintStack(stackTrace: s);
                }
                msg.showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Start Verification'),
          ),
          if (response != null) ListTile(title: Text('Result'), subtitle: SelectableText(json.encode(response))),
        ],
      ),
    );
  }
}
