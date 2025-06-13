import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_inapp_sdk/src/utils/reusable_resource_pool.dart';

class TestResource {
  static int instanceCount = 0;
  final int id;
  bool isDisposed = false;

  TestResource() : id = ++instanceCount;

  void dispose() {
    isDisposed = true;
  }
}

void main() {
  group('ReusableResourcePool', () {
    late ReusableResourcePool<TestResource> pool;

    setUp(() {
      TestResource.instanceCount = 0;
    });

    tearDown(() {
      pool.close();
    });

    test('allocates resources up to pool size and reuses them', () async {
      pool = ReusableResourcePool<TestResource>(
        initialPoolSize: 2,
        createResource: () => TestResource(),
        disposeResource: (resource) => resource.dispose(),
      );

      // First use - creates new resource
      final resource1 = await pool.getResource();
      expect(resource1.id, 1);
      expect(pool.resourceCount, 0);

      // Return and reuse same resource
      pool.returnResource(resource1);
      expect(pool.resourceCount, 1);

      final resource2 = await pool.getResource();
      expect(resource2, same(resource1)); // Should reuse resource1
      expect(pool.resourceCount, 0);

      // Create second resource while first is in use
      final resource3 = await pool.getResource();
      expect(resource3.id, 2); // New resource created
      expect(resource3, isNot(same(resource1)));
      expect(pool.resourceCount, 0); // Both resources in use

      // Return both resources
      pool.returnResource(resource2); // resource2 is same as resource1
      pool.returnResource(resource3);
      expect(pool.resourceCount, 2);
      expect(TestResource.instanceCount, 2); // Only 2 resources created total

      // Verify no resources were disposed
      expect(resource1.isDisposed, false);
      expect(resource3.isDisposed, false);
    });

    test('disposes excess resources but keeps resources within pool size', () async {
      pool = ReusableResourcePool<TestResource>(
        initialPoolSize: 2,
        createResource: () => TestResource(),
        disposeResource: (resource) => resource.dispose(),
      );

      // Create and return 3 resources (one more than pool size)
      final resource1 = await pool.getResource();
      final resource2 = await pool.getResource();
      final resource3 = await pool.getResource();

      // Return all resources
      pool.returnResource(resource1);
      pool.returnResource(resource2);
      pool.returnResource(resource3);

      // Resource3 should be disposed as it exceeds pool size
      expect(resource1.isDisposed, false);
      expect(resource2.isDisposed, false);
      expect(
        resource3.isDisposed,
        true,
        reason:
            'resource3 should be disposed as it exceeds pool size. Pool size is ${pool.poolSize} and resource count is ${pool.resourceCount}',
      );
      expect(pool.resourceCount, 2);
    });

    test('compute reuses resources within pool size limit', () async {
      pool = ReusableResourcePool<TestResource>(
        initialPoolSize: 2,
        createResource: () => TestResource(),
        disposeResource: (resource) async => resource.dispose(),
      );

      // Run multiple computations
      await Future.wait([
        pool.compute((r) async {
          await Future.delayed(Duration(milliseconds: 100));
          return r.id;
        }),
        pool.compute((r) async {
          await Future.delayed(Duration(milliseconds: 50));
          return r.id;
        }),
        pool.compute((r) async {
          await Future.delayed(Duration(milliseconds: 75));
          return r.id;
        }),
      ]);

      // Should have created only 2 resources (pool size)
      expect(TestResource.instanceCount, 2);
      expect(pool.resourceCount, 2);

      // Verify no resources were disposed
      final resources = [await pool.getResource(), await pool.getResource()];
      expect(resources.every((r) => !r.isDisposed), true);
    });

    test('disposes all resources when pool is closed', () async {
      pool = ReusableResourcePool<TestResource>(
        initialPoolSize: 2,
        createResource: () => TestResource(),
        disposeResource: (resource) async => resource.dispose(),
      );

      final resource1 = await pool.getResource();
      final resource2 = await pool.getResource();

      pool.returnResource(resource1);
      pool.returnResource(resource2);

      await pool.close();

      expect(resource1.isDisposed, true);
      expect(resource2.isDisposed, true);
      expect(pool.resourceCount, 0);
    });
  });
}
