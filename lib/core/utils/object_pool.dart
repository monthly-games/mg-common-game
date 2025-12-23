import 'dart:collection';

/// Interface for objects that can be reset and reused.
mixin Poolable {
  /// Called when the object is retrieved from the pool.
  void onAcquire();

  /// Called when the object is returned to the pool.
  void onRelease();
}

/// A generic object pool to reduce Garbage Collection overhead.
class ObjectPool<T extends Poolable> {
  final Queue<T> _available = Queue<T>();
  final T Function() _factory;
  final int _maxSize;

  ObjectPool(this._factory, {int maxSize = 100}) : _maxSize = maxSize;

  /// Acquire an object from the pool. Creates new if empty.
  T acquire() {
    T object;
    if (_available.isEmpty) {
      object = _factory();
    } else {
      object = _available.removeLast();
    }
    object.onAcquire();
    return object;
  }

  /// Return an object to the pool.
  void release(T object) {
    if (_available.length < _maxSize) {
      object.onRelease();
      _available.addLast(object);
    }
    // Else: Let GC handle it (overflow)
  }

  /// Clear the pool.
  void clear() {
    _available.clear();
  }

  /// Current size of the pool.
  int get size => _available.length;
}
