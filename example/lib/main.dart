import 'dart:convert';

import 'package:flutter/material.dart';
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
  @override
  void initState() {
    super.initState();
  }

  ReclaimApiVerificationResponse? result;

  void startVerification() async {
    final msg = ScaffoldMessenger.of(context);
    try {
      final sdk = ReclaimInAppSdk(context);
      result = await sdk.startVerification(
        ReclaimApiVerificationRequest(
          appId: '0x486dD3B9C8DF7c9b263C75713c79EC1cf8F592F2',
          secret: '0x1f86678fe5ec8c093e8647d5eb72a65b5b2affb7ee12b70f74e519a77b295887',
          providerId: 'example',
        ),
      );
      final e = result?.exception;
      if (e != null) {
        msg.showSnackBar(SnackBar(content: Text(e.toString())));
        return;
      }
      setState(() {
        //
      });
    } catch (e) {
      msg.showSnackBar(SnackBar(content: Text(e.toString())));
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plugin example app')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          TextButton(onPressed: startVerification, child: Text('Start Verification')),
          if (result != null) ListTile(title: Text('Result'), subtitle: Text(json.encode(result?.proofs))),
        ],
      ),
    );
  }
}
