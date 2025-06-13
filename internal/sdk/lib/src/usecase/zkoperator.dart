import 'dart:async';

import '../../attestor.dart';

import '../data/identity.dart';
import '../exception/exception.dart';
import '../logging/logging.dart';

class ZkOperatorManager {
  final log = logging.child('ZkOperatorManager');

  Future<void> setupZkOperator(SessionIdentity identity, AttestorZkOperator? attestorZkOperator) async {
    try {
      Attestor.instance.setZkOperator(attestorZkOperator);
      unawaited(Attestor.instance.ensureReady());
    } catch (e, s) {
      logging.severe('Error setting up zk operator', e, s);
      throw const ReclaimAttestorException('Error initializing attestor');
    }
  }
}
