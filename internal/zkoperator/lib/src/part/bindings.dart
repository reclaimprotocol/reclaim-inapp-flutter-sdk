part of '../../reclaim_gnark_zkoperator.dart';

/// The dynamic library in which the symbols for [GnarkProverBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isIOS) {
    const iosLibName = 'reclaim_gnark_zkoperator';
    return DynamicLibrary.open('$iosLibName.framework/$iosLibName');
  }
  if (Platform.isAndroid) {
    const String androidlibName = 'gnarkprover';
    return DynamicLibrary.open('lib$androidlibName.so');
  }
  throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
}();

/// The bindings to the native functions in [_dylib].
final GnarkProverBindings _bindings = GnarkProverBindings(_dylib);
