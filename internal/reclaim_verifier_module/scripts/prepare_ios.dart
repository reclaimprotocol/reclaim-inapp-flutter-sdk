import 'dart:io';
import 'package:path/path.dart' as path;

void main() {
  final currentPath = Directory.current.path;
  final buildPath = path.join(currentPath, 'build', 'ios');
  final iosSimulatorAppFrameworkDebug = path.join(buildPath, 'Debug', 'App.xcframework', 'ios-arm64_x86_64-simulator');
  final iosReleaseBuildPath = path.join(buildPath, 'Release');
  final iosSimulatorAppFrameworkRelease = path.join(
    iosReleaseBuildPath,
    'App.xcframework',
    'ios-arm64_x86_64-simulator',
  );
  Directory(iosSimulatorAppFrameworkRelease).deleteSync(recursive: true);
  Directory(iosSimulatorAppFrameworkDebug).renameSync(iosSimulatorAppFrameworkRelease);
  final iosOutputBuildPath = path.join(buildPath, 'ReclaimXCFrameworks');
  Directory(iosReleaseBuildPath).renameSync(iosOutputBuildPath);

  // // Cocoapods does not support xcframeworks to have a different name than the framework name mentioned in the Info.plist file.
  // // They are not smart enough.
  // final fsEntities = Directory(iosOutputBuildPath).listSync();

  // var count = 1;
  // for (final entity in fsEntities) {
  //   final entityPath = entity.absolute.path;
  //   if (entityPath.contains('FlutterPluginRegistrant.xcframework')) {
  //     entity.renameSync(path.canonicalize(path.join(
  //       entityPath,
  //       '..',
  //       'PluginRegistrant.xcframework',
  //     )));
  //   } else {
  //     entity.renameSync(path.canonicalize(path.join(
  //       entityPath,
  //       '..',
  //       '${count.toString().padLeft(2, '0')}${path.extension(entityPath)}',
  //     )));
  //     count++;
  //   }
  // }
}
