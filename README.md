# Reclaim InApp Flutter SDK

A Flutter SDK for integrating Reclaim's verification system directly into your Flutter applications. This SDK allows you to verify user credentials and generate proofs in-app.

## Features

- In-app verification flow
- Customizable verification options
- ZK Proof generation

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  reclaim_inapp_flutter_sdk: ^latest_version
```

Or, when installing from git source, add the following to your `pubspec.yaml`:

```yaml
dependencies:
  reclaim_inapp_flutter_sdk:
    git:
      url: https://github.com/reclaimprotocol/reclaim-inapp-flutter-sdk.git
      ref: 0.12.0
```

#### Fixing performance issues on IOS physical devices

Your app performance will be severely impacted when you run debug executable on a physical device. Fixing this requires a simple change in your Xcode project xcscheme.

##### Update Environment Variables for XCScheme
1. Open your iOS project (*.xcworkspace) in Xcode.
2. Click on the project target.
3. Click on the **Scheme** dropdown.

<img src="https://github.com/reclaimprotocol/reclaim-inapp-ios-sdk/blob/83f23570a47828d011b713679852053acdba89c1/Screenshots/Install/10.png?raw=true" alt="Edit current xcscheme in Xcode" width="500">

4. Click on the **Edit Scheme** button.
5. Click on the **Run** tab.
6. Click on the **Arguments** tab and check the **Environment Variables** section.

<img src="https://github.com/reclaimprotocol/reclaim-inapp-ios-sdk/blob/83f23570a47828d011b713679852053acdba89c1/Screenshots/Install/12.png?raw=true" alt="Enable Debug executable in Xcode" width="500">

7. Add the following environment variable:
    - Key: `GODEBUG`
    - Value: `asyncpreemptoff=1`
8. Click on the **Close** button in the dialog and build the project.
9. Run the app on a physical device.

## Usage

### Basic Setup

1. Import the SDK in your Dart file:

```dart
import 'package:reclaim_inapp_flutter_sdk/reclaim_inapp_flutter_sdk.dart';
```

2. Initialize the SDK with your app credentials:

Following is an exmaple.

```dart
const String appId = String.fromEnvironment('APP_ID');
const String appSecret = String.fromEnvironment('APP_SECRET');
const String providerId = String.fromEnvironment('PROVIDER_ID');
```

### Starting Verification

```dart
final sdk = ReclaimInAppSdk.of(context);
final proofs = await sdk.startVerification(
  ReclaimVerificationRequest(
    appId: appId,
    providerId: providerId,
    secret: appSecret,
    sessionInformation: ReclaimSessionInformation.empty(),
    contextString: '',
    parameters: {},
    claimCreationType: ClaimCreationType.standalone,
  ),
);
```

#### Alternative way to start verification

- `sdk.startVerificationFromUrl`: You can also start a verification with a verification url generated with any reclaim backend sdk like [Reclaim Protocol: JS SDK](https://www.npmjs.com/package/@reclaimprotocol/js-sdk).
- `sdk.startVerificationFromJson`: Similar to starting verification with url, you can also start verification with the json config exported from the requested that's created with any backend SDK like [Reclaim Protocol: JS SDK](https://www.npmjs.com/package/@reclaimprotocol/js-sdk)'s `reclaimProofRequest.toJsonString()`.

### Configuration Options

The `ReclaimVerificationRequest` supports the following options:

- `appId`: Your Reclaim application ID
- `providerId`: The ID of the provider you want to verify against
- `secret`: Your application secret (optional if using session information)
- `sessionInformation`: Session information for authentication
- `contextString`: Additional context for the verification
- `parameters`: Custom parameters for the verification
- `claimCreationType`: Type of claim creation (standalone or meChain)
- `autoSubmit`: Whether to auto-submit the verification
- `hideCloseButton`: Whether to hide the close button
- `webhookUrl`: URL for webhook notifications
- `verificationOptions`: Additional verification options

### Error Handling

The SDK throws specific exceptions that you can handle:

```dart
try {
  final proofs = await sdk.startVerification(request);
} on ReclaimExpiredSessionException {
  // Handle expired session
} on ReclaimVerificationManualReviewException {
  // Handle manual review case
} catch (error) {
  // Handle other errors if required
}
```

### Pre-warming

For better performance, you can pre-warm the SDK:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ReclaimInAppSdk.preWarm();
  runApp(MyApp());
}
```

## Example

Check out the [example](example/lib/main.dart) for a complete implementation.

## Environment Variables

The Example requires the following dart runtime environment variables:

- `APP_ID`: Your Reclaim application ID
- `APP_SECRET`: Your application secret
- `PROVIDER_ID`: The ID of the provider to verify against

You can provide these values using:

- Dart Define Env file: `--dart-define-from-file=./.env`
- Hardcoded values (not recommended for production)

## Troubleshooting

### Cronet errors on android without play services

On android devices which don't have play services, you may get following errors in Android logs: `java.lang.RuntimeException: All available Cronet providers are disabled. A provider should be enabled before it can be used.`, `Google-Play-Services-Cronet-Provider is unavailable.`. This is because the Reclaim InApp SDK depends on cronet for making http requests.

To fix this, you need to use embedded cronet in your android app by adding the following dependency in your build.gradle dependencies block: 

```gradle
dependencies {
    // ... other dependencies (not shown for brevity)
    // Use embedded cronet
    implementation("org.chromium.net:cronet-embedded:113.5672.61")
}
```

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT