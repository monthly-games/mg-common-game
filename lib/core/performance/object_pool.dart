import 'dart:collection';

/// Generic object pool for reusing game objects
///
/// Reduces garbage collection overhead by reusing objects.
class ObjectPool<T> {
  final T Function() _factory;
  final void Function(T)? _reset;
  final int _maxSize;
  final Queue<T> _pool = Queue<T>();

  int _created = 0;
  int _reused = 0;

  ObjectPool({
    required T Function() factory,
    void Function(T)? reset,
    int maxSize = 100,
    int initialSize = 0,
  })  : _factory = factory,
        _reset = reset,
        _maxSize = maxSize {
    // Pre-populate pool
    for (int i = 0; i < initialSize; i++) {
      _pool.add(_factory());
      _created++;
    }
  }

  /// Get an object from the pool or create a new one
  T acquire() {
    if (_pool.isNotEmpty) {
      _reused++;
      return _pool.removeFirst();
    }
    _created++;
    return _factory();
  }

  /// Return an object to the pool
  void release(T object) {
    _reset?.call(object);
    if (_pool.length < _maxSize) {
      _pool.add(object);
    }
  }

  /// Release multiple objects
  void releaseAll(Iterable<T> objects) {
    for (final obj in objects) {
      release(obj);
    }
  }

  /// Clear the pool
  void clear() {
    _pool.clear();
  }

  /// Current pool size
  int get size => _pool.length;

  /// Total objects created
  int get totalCreated => _created;

  /// Total objects reused
  int get totalReused => _reused;

  /// Reuse ratio (0.0 - 1.0)
  double get reuseRatio {
    final total = _created + _reused;
    if (total == 0) return 0.0;
    return _reused / total;
  }

  /// Pool statistics
  Map<String, dynamic> get stats => {
        'poolSize': size,
        'maxSize': _maxSize,
        'created': _created,
        'reused': _reused,
        'reuseRatio': reuseRatio,
      };
}

/// Poolable interface for objects that can reset themselves
abstract class Poolable {
  void reset();
}

/// Object pool for Poolable objects
class AutoResetPool<T extends Poolable> extends ObjectPool<T> {
  AutoResetPool({
    required T Function() factory,
    int maxSize = 100,
    int initialSize = 0,
  }) : super(
          factory: factory,
          reset: (obj) => obj.reset(),
          maxSize: maxSize,
          initialSize: initialSize,
        );
}

/// Pool manager for managing multiple typed pools
class PoolManager {
  static final PoolManager _instance = PoolManager._();
  static PoolManager get instance => _instance;

  PoolManager._();

  final Map<Type, ObjectPool> _pools = {};

  /// Register a pool for a type
  void registerPool<T>(ObjectPool<T> pool) {
    _pools[T] = pool;
  }

  /// Get pool for a type
  ObjectPool<T>? getPool<T>() {
    return _pools[T] as ObjectPool<T>?;
  }

  /// Acquire object from registered pool
  T? acquire<T>() {
    final pool = getPool<T>();
    return pool?.acquire();
  }

  /// Release object to registered pool
  void release<T>(T object) {
    final pool = getPool<T>();
    pool?.release(object);
  }

  /// Clear all pools
  void clearAll() {
    for (final pool in _pools.values) {
      pool.clear();
    }
  }

  /// Get stats for all pools
  Map<String, Map<String, dynamic>> get allStats {
    return _pools.map((type, pool) => MapEntry(type.toString(), pool.stats));
  }
}

/// Common poolable game objects
class PoolableVector2 implements Poolable {
  double x = 0;
  double y = 0;

  PoolableVector2([this.x = 0, this.y = 0]);

  void set(double x, double y) {
    this.x = x;
    this.y = y;
  }

  @override
  void reset() {
    x = 0;
    y = 0;
  }
}

class PoolableRect implements Poolable {
  double left = 0;
  double top = 0;
  double width = 0;
  double height = 0;

  PoolableRect([this.left = 0, this.top = 0, this.width = 0, this.height = 0]);

  void set(double left, double top, double width, double height) {
    this.left = left;
    this.top = top;
    this.width = width;
    this.height = height;
  }

  double get right => left + width;
  double get bottom => top + height;

  bool contains(double x, double y) {
    return x >= left && x <= right && y >= top && y <= bottom;
  }

  bool intersects(PoolableRect other) {
    return left < other.right &&
        right > other.left &&
        top < other.bottom &&
        bottom > other.top;
  }

  @override
  void reset() {
    left = 0;
    top = 0;
    width = 0;
    height = 0;
  }
}

class PoolableList<T> implements Poolable {
  final List<T> items = [];

  void add(T item) => items.add(item);
  void addAll(Iterable<T> items) => this.items.addAll(items);
  T operator [](int index) => items[index];
  int get length => items.length;
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  @override
  void reset() {
    items.clear();
  }
}
