import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';

final logger = Logger('')
  ..level = Level.INFO
  ..onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (input.config.buildCodeAssets) {
      final packageName = input.packageName;
      final targetOS = input.config.code.targetOS;

      switch (targetOS) {
        case .iOS:
          // iOS: bundled as its own dynamic library (not merged into the
          // executable). Flutter's own iOS native-assets tooling lipos,
          // strips and codesigns this dylib and wraps it in a framework at
          // build time, independent of whatever STRIP_STYLE the consuming
          // app's Xcode project uses -- so the Go symbols reliably survive
          // App Store archive/export, unlike LookupInExecutable which
          // depended on the app target's own strip settings.
          final iosDirName = getIOSLibraryDirectoryName(input.config.code);
          if (iosDirName == null) {
            Logger.root.warning(
              'Building without native library linked',
              UnsupportedError(
                'Unsupported iOS target architecture/SDK: ${input.config.code.targetArchitecture.name}.',
              ),
            );
            return;
          }
          final iosLibPath = input.packageRoot.resolve('assets/ios/$iosDirName/libreclaim.dylib');
          output.assets.code.add(
            CodeAsset(
              package: packageName,
              name: 'src/common/libreclaim/libreclaim.g.dart',
              linkMode: DynamicLoadingBundled(),
              file: iosLibPath,
            ),
          );
        case .android:
          final libDirName = getAndroidArchitectureDirectoryName(input.config.code);
          if (libDirName == null) {
            Logger.root.warning(
              'Building without native library linked',
              UnsupportedError(
                'Unsupported Platform architecture of $targetOS: ${input.config.code.targetArchitecture.name}.',
              ),
            );
            return;
          }
          final libPath = input.packageRoot.resolve('assets/android/$libDirName/libreclaim.so');
          output.assets.code.add(
            CodeAsset(
              package: packageName,
              name: 'src/common/libreclaim/libreclaim.g.dart',
              linkMode: DynamicLoadingBundled(),
              file: libPath,
            ),
          );
        case final os:
          Logger.root.warning(
            'Building without native library linked',
            UnsupportedError('Unsupported OS: ${os.name}.'),
          );
      }
    }
  });
}

String? getAndroidArchitectureDirectoryName(CodeConfig code) {
  return switch (code.targetArchitecture) {
    Architecture.arm64 => 'arm64-v8a',
    Architecture.x64 => 'x86_64',
    _ => null,
  };
}

String? getIOSLibraryDirectoryName(CodeConfig code) {
  final isSimulator = code.iOS.targetSdk == IOSSdk.iPhoneSimulator;
  return switch (code.targetArchitecture) {
    Architecture.arm64 => isSimulator ? 'ios-arm64-simulator' : 'ios-arm64',
    Architecture.x64 when isSimulator => 'ios-x86_64-simulator',
    _ => null,
  };
}
