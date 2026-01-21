import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'libreclaim.g.dart' as libreclaim hide calloc;
export 'libreclaim.g.dart' hide calloc;

typedef ZKInitCallback = Void Function(UnsignedChar);

final class ReclaimBindings {
  const ReclaimBindings._();

  static const instance = ReclaimBindings._();

  libreclaim.reclaim_error_t executeProtocol(
    Pointer<Char> requestJson,
    Pointer<Char> configJson,
    Pointer<Pointer<Char>> claimJson,
    Pointer<Int> claimLength,
  ) {
    return libreclaim.reclaim_execute_protocol(requestJson, configJson, claimJson, claimLength);
  }

  Pointer<Char> getErrorMessage(libreclaim.reclaim_error_t error) {
    return libreclaim.reclaim_get_error_message(error);
  }

  void freeString(Pointer<Char> str) {
    return libreclaim.reclaim_free_string(str);
  }

  void free(Pointer<Void> pointer) {
    return libreclaim.Free(pointer);
  }

  Pointer<Char> get version {
    return libreclaim.reclaim_get_version();
  }

  int initializeAlgorithm(int algorithmID, libreclaim.GoSlice provingKey, libreclaim.GoSlice r1cs) {
    return libreclaim.InitAlgorithm(algorithmID, provingKey, r1cs);
  }

  libreclaim.ExtractJSONValueIndexes_return extractJSONValueIndexes(libreclaim.GoSlice params) {
    return libreclaim.ExtractJSONValueIndexes(params);
  }

  libreclaim.ExtractHTMLElementsIndexes_return extractHTMLElementsIndexes(libreclaim.GoSlice params) {
    return libreclaim.ExtractHTMLElementsIndexes(params);
  }

  libreclaim.TOPRFFinalize_return executeTOPRFFinalize(libreclaim.GoSlice params) {
    return libreclaim.TOPRFFinalize(params);
  }

  libreclaim.GenerateOPRFRequestData_return generateOPRFRequestData(libreclaim.GoSlice params) {
    return libreclaim.GenerateOPRFRequestData(params);
  }

  libreclaim.Prove_return prove(libreclaim.GoSlice params) {
    return libreclaim.Prove(params);
  }

  void setZKInitCallback(Pointer<NativeFunction<ZKInitCallback>> callback) {
    return libreclaim.SetZKInitCallback(callback);
  }

  void markZKInitComplete(int algorithmID, bool success) {
    return libreclaim.MarkZKInitComplete(algorithmID, success);
  }

  bool isAlgorithmInitialized(int algorithmID) {
    return libreclaim.IsAlgorithmInitialized(algorithmID);
  }
}

extension GoSliceExtension on libreclaim.GoSlice {
  static Pointer<libreclaim.GoSlice> fromUint8List(Uint8List bytes) {
    final Pointer<libreclaim.GoSlice> slice = calloc<libreclaim.GoSlice>();
    final Pointer<Uint8> data = calloc<Uint8>(bytes.length);
    final list = data.asTypedList(bytes.length);
    list.setAll(0, bytes);
    slice.ref.data = data.cast();
    slice.ref.len = bytes.length;
    slice.ref.cap = bytes.length;
    return slice;
  }
}

/// Helper extension for converting C strings to Dart strings in worker isolate
extension WorkerPointerCharExt on Pointer<Char> {
  String toDartString([int? length]) {
    if (address == 0) return '';

    if (length != null) {
      return cast<Utf8>().toDartString(length: length);
    } else {
      return cast<Utf8>().toDartString();
    }
  }
}
