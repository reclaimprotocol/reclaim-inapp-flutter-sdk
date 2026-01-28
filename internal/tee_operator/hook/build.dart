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
          // iOS: symbols are linked into the executable
          output.assets.code.add(
            CodeAsset(
              package: packageName,
              name: 'src/common/libreclaim/libreclaim.g.dart',
              linkMode: LookupInExecutable(),
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
