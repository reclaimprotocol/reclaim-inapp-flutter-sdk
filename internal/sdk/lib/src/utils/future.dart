import 'dart:async';

import '../logging/logging.dart';

/// Runs a collection of futures in sequence and stops on error. Used to not let consumers await results or catch errors of a future.
void unawaitedSequence(Iterable<Future> futures) async {
  final logger = logging.child('unawaitedSequence');
  for (int i = 0; i < futures.length; i++) {
    try {
      await futures.elementAt(i);
    } catch (e, s) {
      logger.severe('future[$i] completed with an error', e, s);
      return;
    }
  }
}

/// Awaits completion of a collection of futures and logs any errors.
Future<void> awaitFuturesCompletion(Iterable<Future> futures) async {
  if (futures.isEmpty) return;
  final logger = logging.child('awaitFuturesCompletion');
  try {
    await Future.wait(futures);
  } catch (e, s) {
    logger.severe('some future completed with an error', e, s);
  }
}
