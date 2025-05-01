part of '../../reclaim_gnark_zkoperator.dart';

extension _GoSliceExtension on GoSlice {
  static Pointer<GoSlice> fromUint8List(Uint8List bytes) {
    final Pointer<GoSlice> slice = calloc<GoSlice>();
    final pointerOfBytes = bytes.allocatePointer();
    slice.ref.data = pointerOfBytes;
    slice.ref.len = bytes.length;
    slice.ref.cap = bytes.length;
    return slice;
  }
}

extension _Uint8ListBlobConversion on Uint8List {
  /// Allocates a pointer filled with the Uint8List data.
  Pointer<Uint8> allocatePointer() {
    final blob = calloc<Uint8>(length);
    final blobBytes = blob.asTypedList(length);
    blobBytes.setAll(0, this);
    return blob;
  }
}
