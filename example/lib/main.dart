// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reclaim_inapp_flutter_sdk/reclaim_inapp_flutter_sdk.dart';

// For this example, we are using dart define to provide constant values for sdk
// You can use any other method to provide these values i.e config file, .env file or just hard code them.
//
// To provide a value, set a [defaultValue] in below [fromEnvironment] methods or use `--dart-define-from-file=./.env`
// to get values from an env file or json file.
//
// Check example.env, and https://dart.dev/guides/environment-declarations for more details.
const String appId = String.fromEnvironment('APP_ID');
const String appSecret = String.fromEnvironment('APP_SECRET');
const providerId = String.fromEnvironment(
  'PROVIDER_ID',
  // Using github username's http provider id as default.
  defaultValue: '6d3f6753-7ee6-49ee-a545-62f1b1822ae5',
);

void main() async {
  // Asserting to check if the environment variables are set.
  //
  // Note: To provide a value, set a default value or use `--dart-define-from-file=./.env`
  // to get values from an env file or json file. Check example.env, and Makefile for more details.
  assert(appId.isNotEmpty, 'APP_ID is not set');
  assert(appSecret.isNotEmpty, 'APP_SECRET is not set');
  assert(providerId.isNotEmpty, 'PROVIDER_ID is not set');

  runApp(const ReclaimExampleApp());
}

class ReclaimExampleApp extends StatelessWidget {
  const ReclaimExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: Example());
  }
}

class Example extends StatefulWidget {
  const Example({super.key});

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  late final _providerIdController = TextEditingController(text: providerId);

  String get effectiveProviderId => _providerIdController.text.trim();

  @override
  void dispose() {
    _providerIdController.dispose();
    super.dispose();
  }

  ReclaimApiVerificationResponse? response;

  void onStartClaimButtonPressed(BuildContext context) async {
    setState(() {
      response = null;
    });
    final msg = ScaffoldMessenger.of(context);
    try {
      print("Starting proof for provider: $effectiveProviderId");
      final sdk = ReclaimInAppSdk.of(context);
      response = await sdk.startVerification(
        ReclaimVerificationRequest(
          applicationId: appId,
          providerId: effectiveProviderId,
          sessionProvider: () {
            return ReclaimSessionInformation.generateNew(
              applicationId: appId,
              applicationSecret: appSecret,
              providerId: providerId,
            );
          },
          contextString: '',
          parameters: {},
        ),
      );
      setState(() {
        // trigger rebuild to show received proofs
      });
      print({'proof.length': response?.proofs.length, 'proofs': json.encode(response)});
      msg.removeCurrentSnackBar();
      final proofs = response?.proofs;
      if (proofs == null || proofs.isEmpty) {
        msg.showSnackBar(const SnackBar(content: Text('example verification closed')));
      } else {
        msg.showSnackBar(const SnackBar(content: Text('example verification completed')));
      }
    } on ReclaimExpiredSessionException {
      msg.removeCurrentSnackBar();
      msg.showSnackBar(const SnackBar(content: Text('Session expired')));
    } on ReclaimVerificationManualReviewException {
      // You'll only get this exception if manual review is enabled for the provider or app you used (disabled by default)
      msg.removeCurrentSnackBar();
      msg.showSnackBar(const SnackBar(content: Text('Awaiting manual review, no action needed on your end')));
    } catch (error, stackTrace) {
      print("Failed to start verification\n$error\n$stackTrace");
      msg.removeCurrentSnackBar();
      msg.showSnackBar(const SnackBar(content: Text('Failed example verification')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reclaim SDK Example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: TextFormField(
              controller: _providerIdController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Provider ID',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste_rounded),
                  onPressed: () async {
                    final clipboardData = await Clipboard.getData('text/plain');
                    final copiedProviderId = clipboardData?.text;
                    if (copiedProviderId == null || copiedProviderId.isEmpty) {
                      return;
                    }
                    _providerIdController.text = copiedProviderId;
                  },
                ),
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              onStartClaimButtonPressed(context);
            },
            child: const Text('Start Claim'),
          ),
          if (response != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    readOnly: true,
                    maxLines: 10,
                    style: TextStyle(fontFamily: "monospace", fontFamilyFallback: <String>["Courier"]),
                    controller: TextEditingController.fromValue(TextEditingValue(text: json.encode(response))),
                    decoration: InputDecoration(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [Icon(Icons.key), SizedBox(width: 10), Text('Proofs')],
                      ),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: json.encode(response)));
                    },
                    label: Text('Copy Proof'),
                    icon: const Icon(Icons.copy),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
