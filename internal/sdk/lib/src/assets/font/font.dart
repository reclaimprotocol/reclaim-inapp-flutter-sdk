// ignore_for_file: avoid_print

import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import '../../logging/logging.dart';
import '../../utils/dio.dart';
import 'file_io_stub.dart' // Stubbed implementation by default.
    // Concrete implementation if File IO is available.
    if (dart.library.io) 'file_io.dart'
    as file_io;

class TargetFontDescription {
  final String name;
  final String url;
  final int expectedFileLength;
  final String expectedFileHash;

  const TargetFontDescription({
    required this.name,
    required this.url,
    required this.expectedFileLength,
    required this.expectedFileHash,
  });

  /// Installs font in flutter app based on the description.
  /// Downloads from network will be cached.
  Future<void> installFontIfRequired() async {
    if (_loadedFonts.contains(name)) {
      // font already loaded or loading
      return;
    } else {
      _loadedFonts.add(name);
    }

    try {
      // load font from device
      ByteData? byteData = await file_io.loadFontFromDeviceFileSystem(name: name, fileHash: expectedFileHash);

      // If device doesn't have the font, then download from network, cache it on device, and then return the file.
      byteData ??= await _downloadFontDataFromNetwork(this);

      // Load font in the flutter engine
      await _loadFontInFlutter(name, byteData);
    } catch (e, s) {
      logging
          .child('installFontIfRequired')
          .info('We were unable to load font $name required in reclaim_inapp_sdk package', e, s);
      _loadedFonts.remove(name);

      rethrow;
    }
  }
}

final _loadedFonts = <String>{};

final _httpClient = buildDio();

Future<ByteData> _downloadFontDataFromNetwork(TargetFontDescription font) async {
  final uri = Uri.tryParse(font.url);
  if (uri == null) {
    throw Exception('Invalid fontUrl: ${font.url}');
  }

  Response response;
  try {
    response = await _httpClient.getUri(uri, options: Options(responseType: ResponseType.bytes));
  } catch (e) {
    throw Exception('Failed to load font with url ${font.url}: $e');
  }
  if (response.statusCode == 200) {
    final Uint8List bytes = Uint8List.fromList(response.data);
    if (!_isFileSecure(bytes, font)) {
      throw Exception('File from ${font.url} did not match expected length and checksum.');
    }

    unawaited(file_io.saveFontToDeviceFileSystem(name: font.name, fileHash: font.expectedFileHash, bytes: bytes));

    return ByteData.view(bytes.buffer);
  } else {
    // If that call was not successful, throw an error.
    throw Exception('Failed to load font with url: ${font.url}');
  }
}

Future<void> _loadFontInFlutter(String familyWithVariantString, ByteData fontData) async {
  final fontLoader = FontLoader(familyWithVariantString);
  fontLoader.addFont(Future.value(fontData));
  await fontLoader.load();
}

bool _isFileSecure(Uint8List bytes, TargetFontDescription font) {
  final actualFileLength = bytes.length;
  final actualFileHash = sha256.convert(bytes).toString();
  return font.expectedFileLength == actualFileLength && font.expectedFileHash == actualFileHash;
}
