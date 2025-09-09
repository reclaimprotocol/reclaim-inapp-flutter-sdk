import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import 'http/http.dart';

Future<File> getFileForUrl(String url, Directory downloadDirectory, [String extension = '']) async {
  await downloadDirectory.create(recursive: true);
  final fileHash = sha1.convert(utf8.encode(url)).toString();
  final file = File('${downloadDirectory.path}/$fileHash$extension');
  return file;
}

Future<void> writeResponseToFile(http.StreamedResponse response, File file, {String extension = ''}) async {
  final logger = Logger('writeResponseToFile');

  final request = response.request;
  if (request == null) {
    throw Exception('request is null');
  }
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('response status code is not 2xx');
  }

  logger.info('writing response from ${request.url} to file: ${file.path}');

  final sink = file.openWrite(mode: FileMode.writeOnlyAppend);

  bool isFileClosed = false;

  try {
    final doneCompleter = Completer<void>();

    response.stream.listen(
      sink.add,
      onError: (e, s) {
        isFileClosed = false;
        doneCompleter.completeError(e, s);
        sink.close();
      },
      onDone: () async {
        try {
          await sink.flush();
          await sink.close();
          isFileClosed = true;
          doneCompleter.complete();
        } catch (e, s) {
          logger.severe('Error flushing file', e, s);
          doneCompleter.completeError(e, s);
        }
      },
      cancelOnError: true,
    );

    await doneCompleter.future;
  } catch (e, s) {
    logger.severe('Error downloading file', e, s);
    rethrow;
  } finally {
    try {
      if (!isFileClosed) {
        await sink.close();
      }
    } catch (e, s) {
      logger.severe('Error closing file', e, s);
    }
  }
}

final _client = ReclaimHttpClient();

typedef OnDownloadComplete = Future<void> Function(File file);

Future<File> _downloadFromUrl(
  Uri url, {
  String extension = '',
  required Directory downloadDirectory,

  /// Only called when file is downloaded from network
  required OnDownloadComplete onDownloadComplete,
}) async {
  final logger = Logger('_downloadFromUrl');

  final file = await getFileForUrl(url.toString(), downloadDirectory, extension);

  if (file.existsSync()) {
    return file;
  }

  await file.create(recursive: true);

  try {
    final response = await _client.send(http.Request('GET', url));
    await writeResponseToFile(response, file, extension: extension);
  } catch (e, s) {
    logger.severe('Error downloading file', e, s);
    file.deleteSync();
    rethrow;
  }

  await onDownloadComplete(file);

  return file;
}

final _downloads = <String, Future<File>>{};

Future<File> downloadFromUrl(Uri url, {required Directory downloadDirectory, String extension = ''}) async {
  final logger = Logger('downloadFromUrl');

  final key = url.toString();
  try {
    return await (_downloads[key] ??= _downloadFromUrl(
      url,
      extension: extension,
      downloadDirectory: downloadDirectory,
      onDownloadComplete: (file) async {
        logger.info('onDownloadComplete: ${file.path}');
        // clear old files
        try {
          final files = file.parent.listSync();
          for (final f in files) {
            if (path.basename(f.path) != path.basename(file.path)) {
              f.delete();
            }
          }
        } catch (e, s) {
          logger.severe('Error downloading file', e, s);
        }
      },
    ));
  } catch (_) {
    _downloads.remove(key);
    rethrow;
  }
}
