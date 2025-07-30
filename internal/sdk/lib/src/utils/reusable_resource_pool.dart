import 'dart:async';
import 'dart:collection';

import 'package:logging/logging.dart';
import 'package:pool/pool.dart';

final _log = Logger('reclaim_inapp_sdk.ReusableResourcePool');

class ReusableResourcePool<RESOURCE> {
  Pool _pool;
  int _poolSize;

  int get poolSize => _poolSize;

  set poolSize(int value) {
    if (value < 0) {
      throw ArgumentError('poolSize cannot be negative');
    }
    if (value == _poolSize) return;
    if (_poolSize == 0) {
      disposeResources();
    }
    _poolSize = value;
    if (value == 0) return;
    _pool.close();
    _pool = Pool(value);
  }

  final FutureOr<RESOURCE> Function() _createResource;
  final FutureOr<void> Function(RESOURCE resource) _disposeResource;

  final List<RESOURCE> _availableResource = [];
  int get resourceCount => _availableResource.length;
  final Duration ageLimit;
  final Duration Function(RESOURCE resource) getResourceAge;
  final bool Function(RESOURCE resource) isResourceFaulty;

  ReusableResourcePool({
    required int initialPoolSize,
    required FutureOr<RESOURCE> Function() createResource,
    required FutureOr<void> Function(RESOURCE resource) disposeResource,
    required this.ageLimit,
    required this.getResourceAge,
    required this.isResourceFaulty,
  }) : _createResource = createResource,
       _disposeResource = disposeResource,
       _poolSize = initialPoolSize,
       _pool = Pool(initialPoolSize);

  FutureOr<RESOURCE> getResource() async {
    if (_availableResource.isEmpty) {
      // if no resource available, create new one
      return _createResource();
    }
    // reuse existing resource
    final r = _availableResource.removeAt(0);
    final age = getResourceAge(r);
    if (age >= ageLimit) {
      _log.info('disposing resource because it is older than age limit: $age, resource: $r');
      _disposeResource(r);
      return _createResource();
    }
    if (isResourceFaulty(r)) {
      _log.info('disposing resource because it is faulty: $r');
      _disposeResource(r);
      return _createResource();
    }
    return r;
  }

  void returnResource(RESOURCE resource) {
    final age = getResourceAge(resource);
    if (age >= ageLimit) {
      _log.info('disposing resource because it is older than age limit: $age');
      _disposeResource(resource);
      return;
    }
    if (isResourceFaulty(resource)) {
      _log.info('disposing resource because it is faulty: $resource');
      _disposeResource(resource);
      return;
    }
    if (_availableResource.contains(resource)) {
      return;
    }
    if (_availableResource.length >= _poolSize) {
      _disposeResource(resource);
      return;
    }
    _availableResource.add(resource);
  }

  FutureOr<RESOURCE> get peekResource async {
    if (_availableResource.isEmpty) {
      final resource = await _createResource();
      returnResource(resource);
      return resource;
    }
    return _availableResource[0];
  }

  List<RESOURCE> get resources => UnmodifiableListView(_availableResource);

  Future<T> compute<T>(FutureOr<T> Function(RESOURCE resouce) fn) async {
    Future<T> run() async {
      final resource = await getResource();
      try {
        return await fn(resource);
      } finally {
        returnResource(resource);
      }
    }

    if (_poolSize == 0) {
      return run();
    }

    return _pool.withResource(run);
  }

  Future<void> disposeResources() async {
    final futures = <Future<void>>[];
    for (final resource in _availableResource) {
      futures.add((() async => _disposeResource(resource))());
    }
    _availableResource.clear();
    await Future.wait(futures);
  }

  Future<void> close() {
    disposeResources();
    return _pool.close();
  }
}
