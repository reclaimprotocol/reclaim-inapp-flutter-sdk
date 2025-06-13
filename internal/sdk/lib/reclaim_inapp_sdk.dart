import 'dart:async';

import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';

import 'src/controller.dart';
import 'src/data/verification/verification.dart';
import 'src/exception/exception.dart';
import 'src/logging/logging.dart';
import 'src/ui/verification/route.dart';

export 'src/data/data.dart';
export 'src/exception/exception.dart';
export 'src/services/services.dart';
export 'src/theme/theme.dart';
export 'src/usecase/usecase.dart';
export 'src/utils/dio.dart';
export 'src/utils/http/http.dart';
export 'src/utils/provider_performance_report.dart';

final _verificationStartLock = Lock(reentrant: true);

class _PendingVerifications {
  _PendingVerifications() {
    pending.add(this);
  }

  VerificationController? controller;
  Future<dynamic>? navigationResult;

  static final List<_PendingVerifications> pending = [];

  Future<bool> cancel() async {
    final log = logging.child('_PendingVerifications');

    pending.remove(this);

    log.info('cancelling pending verifications');

    final ctrl = controller;
    if (ctrl == null) {
      log.config('no previous verification controller found');
      return false;
    }

    ctrl.cancelVerification();

    final result = navigationResult;
    if (result != null) {
      // wait for verification view to close
      await result;
    } else {
      log.config('no previous verification navigation found');
    }

    return true;
  }

  void remove() {
    controller = null;
    navigationResult = null;
    pending.remove(this);
  }
}

class ReclaimVerification {
  final BuildContext context;
  final NavigatorState _navigatorState;
  final ScaffoldMessengerState _scaffoldMessengerState;

  ReclaimVerification.of(this.context)
    : _navigatorState = Navigator.of(context),
      _scaffoldMessengerState = ScaffoldMessenger.of(context);

  static final _log = logging.child('ReclaimVerification');

  Future<bool> cancelPendingVerifications() async {
    _log.info('cancelling pending verifications');

    final pending = [..._PendingVerifications.pending];
    if (pending.isEmpty) return false;

    await Future.wait(pending.map((v) => v.cancel()));

    return true;
  }

  Future<ReclaimVerificationResult> startVerification({
    required ReclaimVerificationRequest request,
    ReclaimVerificationOptions options = const ReclaimVerificationOptions(),
  }) async {
    _log.info('starting verification');

    late final _PendingVerifications attempt;
    late final VerificationController controller;
    late final Future<dynamic> navigationResultFuture;

    await _verificationStartLock.synchronized(() async {
      await cancelPendingVerifications();

      attempt = _PendingVerifications();

      controller = VerificationController(request: request, options: options);

      attempt.controller = controller;

      navigationResultFuture = _navigatorState.push(VerificationViewPageRoute(verificationController: controller));

      attempt.navigationResult = navigationResultFuture;

      // request to dismiss when verification view is closed but there is no result. dismiss request will be ignored if verification is already completed.
      unawaited(navigationResultFuture.then((_) => controller.dismissVerification()));

      try {
        await controller.initialize();
      } catch (e, s) {
        _log.severe('Error initializing verification', e, s);
        controller.updateException(
          ReclaimVerificationProviderLoadException('Error initializing verification. Cause: $e\nStack: $s'),
        );
      }
    });

    return controller.response.whenComplete(() async {
      // wait for verification view to close before disposing the controller because the controller may still be in use.
      await navigationResultFuture;
      try {
        _scaffoldMessengerState.clearSnackBars();
      } catch (e, s) {
        _log.severe('Error clearing snack bars', e, s);
      }
      attempt.remove();
      // The owner should dispose controller after consumer child is disposed.
      controller.dispose();
    });
  }
}
