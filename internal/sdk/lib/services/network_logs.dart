import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:reclaim_flutter_sdk/logging/logging.dart';
import 'package:reclaim_flutter_sdk/types/manual_verification.dart';
import 'package:reclaim_flutter_sdk/utils/dio.dart';

final _networkLogsClient = buildDio();

class NetworkLogsService {
  final log = logging.child('NetworkLogsService');
  static final _chunkCount = <String, int>{};
  Future<bool> addToQueue(
    String sessionId,
    String providerId,
    List<RequestLog> requests, [
    bool canChunk = true,
  ]) async {
    final chunkId = _chunkCount[sessionId] ?? 1;
    _chunkCount[sessionId] = chunkId + 1;
    try {
      final data = json.encode({
        "sessionId": sessionId,
        "chunkId": chunkId,
        "providerId": providerId,
        "jobType": "manual_provider_creation",
        "requests": requests,
      });
      final response = await _networkLogsClient.post(
        'https://service.reclaimprotocol.org/api/network-requests/add-to-queue',
        options: Options(headers: const {'content-type': 'application/json'}),
        data: data,
      );
      final statusCode = response.statusCode;
      log.info('Network logs response: $statusCode');
      if (logging.isDebugging) {
        final requestBodySize = utf8.encode(data).lengthInBytes;
        log.info(
          'Network logs request body size: $requestBodySize bytes. Request content length: ${response.requestOptions.headers['content-length'] ?? response.requestOptions.headers['Content-Length']}.',
        );
      }
      if (statusCode != null && statusCode >= 200 && statusCode < 300) {
        return true;
      }
      if (statusCode == 413 && canChunk) {
        final requestBodySize = utf8.encode(data).lengthInBytes;
        // sajjad said 50 MB is the limit, but we'll not be generous and use 45 MB
        final maxBytes = (45 / 1e-6);
        if (requestBodySize > maxBytes) {
          final chunks = (requestBodySize / maxBytes).ceil();
          if (chunks > 1) {
            final chunkedRequests = splitListIntoMChunks(requests, chunks);
            for (final chunk in chunkedRequests) {
              await addToQueue(sessionId, providerId, chunk, false);
            }
            return true;
          }
        }
      }
      log.severe(
        'Failed to add to queue with status code $statusCode (${response.statusMessage})',
        response.data,
      );
    } catch (e, s) {
      log.severe('Failed to add to queue', e, s);
    }
    return false;
  }
}

/// Splits a list [list] into [m] chunks.
///
/// Distributes elements as evenly as possible. If [m] > list.length,
/// some chunks may be empty.
///
/// Throws [ArgumentError] if [m] is not positive.
List<List<T>> splitListIntoMChunks<T>(List<T> list, int m) {
  if (m <= 0) {
    throw ArgumentError('Number of chunks (m) must be positive.');
  }

  int n = list.length;
  List<List<T>> chunks = [];

  if (n == 0) {
    // If the input list is empty, return m empty lists.
    for (int i = 0; i < m; i++) {
      chunks.add(<T>[]);
    }
    return chunks;
  }

  // Calculate the base size of each chunk and the remainder.
  int baseSize = n ~/ m; // Integer division
  int remainder = n % m;

  int startIndex = 0;
  for (int i = 0; i < m; i++) {
    // Determine the size of the current chunk.
    // The first 'remainder' chunks get one extra element.
    int currentChunkSize = baseSize + (i < remainder ? 1 : 0);

    // Calculate the end index for the sublist.
    // Using min is a safeguard but theoretically not needed if logic is correct,
    // as the sum of currentChunkSize over m iterations will equal n.
    // int endIndex = min(startIndex + currentChunkSize, n);
    int endIndex = startIndex + currentChunkSize;

    // Add the sublist (chunk) to the result.
    chunks.add(list.sublist(startIndex, endIndex));

    // Update the starting index for the next chunk.
    startIndex = endIndex;
  }

  return chunks;
}
