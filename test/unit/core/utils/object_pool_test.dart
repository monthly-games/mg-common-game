import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/utils/object_pool.dart';

class TestPoolable with Poolable {
  bool active = false;
  int id;

  TestPoolable(this.id);

  @override
  void onAcquire() {
    active = true;
  }

  @override
  void onRelease() {
    active = false;
  }
}

void main() {
  group('ObjectPool Tests', () {
    late ObjectPool<TestPoolable> pool;
    int counter = 0;

    setUp(() {
      counter = 0;
      pool = ObjectPool<TestPoolable>(
        () => TestPoolable(counter++),
        maxSize: 2,
      );
    });

    test('Acquire creates new object when empty', () {
      final obj = pool.acquire();
      expect(obj.id, 0);
      expect(obj.active, true);
      expect(pool.size, 0); // Pool is empty, object is out
    });

    test('Release returns object to pool', () {
      final obj = pool.acquire();
      pool.release(obj);
      expect(pool.size, 1);
      expect(obj.active, false);
    });

    test('Acquire reuses released object', () {
      final obj1 = pool.acquire();
      pool.release(obj1);

      final obj2 = pool.acquire();
      expect(obj2, equals(obj1)); // Should be same instance
      expect(obj2.active, true);
    });

    test('Pool respects maxSize', () {
      final obj1 = pool.acquire();
      final obj2 = pool.acquire();
      final obj3 = pool.acquire(); // Created fresh (id 2)

      // Pool size 0, objects out: 3. Max size is 2.
      pool.release(obj1);
      pool.release(obj2);
      pool.release(obj3); // This one should be discarded

      expect(pool.size, 2);
    });
  });
}
