import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Memory pressure levels
enum MemoryPressure {
  none,
  low,
  moderate,
  high,
  critical,
}

/// Callback type for memory pressure events
typedef MemoryPressureCallback = void Function(MemoryPressure pressure);

/// Memory management utilities
class MemoryManager extends ChangeNotifier {
  static final MemoryManager _instance = MemoryManager._();
  static MemoryManager get instance => _instance;

  MemoryManager._();

  final List<MemoryPressureCallback> _pressureListeners = [];
  final Map<String, WeakReference<Object>> _weakCache = {};
  final Map<String, Object> _strongCache = {};
  final Map<String, int> _cacheAccessCount = {};
  final Map<String, DateTime> _cacheAccessTime = {};

  Timer? _cleanupTimer;
  MemoryPressure _currentPressure = MemoryPressure.none;

  int _maxStrongCacheSize = 50;
  Duration _cacheExpiry = const Duration(minutes: 5);
  Duration _cleanupInterval = const Duration(seconds: 30);

  /// Current memory pressure level
  MemoryPressure get currentPressure => _currentPressure;

  /// Initialize memory manager
  void initialize({
    int maxStrongCacheSize = 50,
    Duration cacheExpiry = const Duration(minutes: 5),
    Duration cleanupInterval = const Duration(seconds: 30),
  }) {
    _maxStrongCacheSize = maxStrongCacheSize;
    _cacheExpiry = cacheExpiry;
    _cleanupInterval = cleanupInterval;

    _startCleanupTimer();
    _listenToSystemMemoryPressure();
  }

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      _performCleanup();
    });
  }

  void _listenToSystemMemoryPressure() {
    // Listen to platform memory pressure on Android/iOS
    SystemChannels.lifecycle.setMessageHandler((message) async {
      if (message == AppLifecycleState.paused.toString()) {
        // App going to background - reduce memory
        _handleMemoryPressure(MemoryPressure.moderate);
      }
      return null;
    });
  }

  /// Add memory pressure listener
  void addPressureListener(MemoryPressureCallback callback) {
    _pressureListeners.add(callback);
  }

  /// Remove memory pressure listener
  void removePressureListener(MemoryPressureCallback callback) {
    _pressureListeners.remove(callback);
  }

  /// Report memory pressure (from system or manual)
  void reportMemoryPressure(MemoryPressure pressure) {
    _handleMemoryPressure(pressure);
  }

  void _handleMemoryPressure(MemoryPressure pressure) {
    if (_currentPressure == pressure) return;

    _currentPressure = pressure;
    notifyListeners();

    // Notify all listeners
    for (final listener in _pressureListeners) {
      listener(pressure);
    }

    // Take action based on pressure level
    switch (pressure) {
      case MemoryPressure.none:
        break;
      case MemoryPressure.low:
        _cleanupExpiredCache();
        break;
      case MemoryPressure.moderate:
        _cleanupExpiredCache();
        _trimStrongCache(0.5);
        break;
      case MemoryPressure.high:
        _clearWeakCache();
        _trimStrongCache(0.75);
        break;
      case MemoryPressure.critical:
        clearAllCaches();
        break;
    }
  }

  // ============================================================
  // Weak Cache - Objects that can be garbage collected
  // ============================================================

  /// Store object in weak cache
  void cacheWeak(String key, Object value) {
    _weakCache[key] = WeakReference(value);
  }

  /// Get object from weak cache (may return null if GC'd)
  T? getWeak<T>(String key) {
    final ref = _weakCache[key];
    if (ref == null) return null;

    final target = ref.target;
    if (target == null) {
      _weakCache.remove(key);
      return null;
    }

    return target as T?;
  }

  /// Check if weak cache has valid reference
  bool hasWeak(String key) {
    final ref = _weakCache[key];
    if (ref == null) return false;
    if (ref.target == null) {
      _weakCache.remove(key);
      return false;
    }
    return true;
  }

  void _clearWeakCache() {
    _weakCache.clear();
  }

  // ============================================================
  // Strong Cache - Objects kept in memory with LRU eviction
  // ============================================================

  /// Store object in strong cache
  void cacheStrong(String key, Object value) {
    _strongCache[key] = value;
    _cacheAccessCount[key] = 0;
    _cacheAccessTime[key] = DateTime.now();

    // Evict if over size
    if (_strongCache.length > _maxStrongCacheSize) {
      _evictLeastUsed();
    }
  }

  /// Get object from strong cache
  T? getStrong<T>(String key) {
    final value = _strongCache[key];
    if (value != null) {
      _cacheAccessCount[key] = (_cacheAccessCount[key] ?? 0) + 1;
      _cacheAccessTime[key] = DateTime.now();
      return value as T?;
    }
    return null;
  }

  /// Check if strong cache has key
  bool hasStrong(String key) => _strongCache.containsKey(key);

  /// Remove from strong cache
  void removeStrong(String key) {
    _strongCache.remove(key);
    _cacheAccessCount.remove(key);
    _cacheAccessTime.remove(key);
  }

  void _evictLeastUsed() {
    if (_strongCache.isEmpty) return;

    // Find least recently used
    String? lruKey;
    DateTime? lruTime;

    for (final entry in _cacheAccessTime.entries) {
      if (lruTime == null || entry.value.isBefore(lruTime)) {
        lruKey = entry.key;
        lruTime = entry.value;
      }
    }

    if (lruKey != null) {
      removeStrong(lruKey);
    }
  }

  void _trimStrongCache(double fraction) {
    final targetSize = (_strongCache.length * (1 - fraction)).round();
    while (_strongCache.length > targetSize) {
      _evictLeastUsed();
    }
  }

  void _cleanupExpiredCache() {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    for (final entry in _cacheAccessTime.entries) {
      if (now.difference(entry.value) > _cacheExpiry) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      removeStrong(key);
    }
  }

  // ============================================================
  // Cleanup and Stats
  // ============================================================

  void _performCleanup() {
    // Clean up null weak references
    final nullWeakKeys = <String>[];
    for (final entry in _weakCache.entries) {
      if (entry.value.target == null) {
        nullWeakKeys.add(entry.key);
      }
    }
    for (final key in nullWeakKeys) {
      _weakCache.remove(key);
    }

    // Clean up expired strong cache
    _cleanupExpiredCache();
  }

  /// Clear all caches
  void clearAllCaches() {
    _weakCache.clear();
    _strongCache.clear();
    _cacheAccessCount.clear();
    _cacheAccessTime.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> get stats => {
        'weakCacheSize': _weakCache.length,
        'strongCacheSize': _strongCache.length,
        'maxStrongCacheSize': _maxStrongCacheSize,
        'currentPressure': _currentPressure.name,
      };

  /// Dispose memory manager
  void dispose() {
    _cleanupTimer?.cancel();
    clearAllCaches();
    _pressureListeners.clear();
    super.dispose();
  }
}

/// Mixin for widgets that respond to memory pressure
mixin MemoryPressureAware<T extends StatefulWidget> on State<T> {
  @protected
  void onMemoryPressure(MemoryPressure pressure);

  @override
  void initState() {
    super.initState();
    MemoryManager.instance.addPressureListener(_handlePressure);
  }

  @override
  void dispose() {
    MemoryManager.instance.removePressureListener(_handlePressure);
    super.dispose();
  }

  void _handlePressure(MemoryPressure pressure) {
    if (mounted) {
      onMemoryPressure(pressure);
    }
  }
}

/// Disposable resource tracker
class ResourceTracker {
  final List<Function> _disposers = [];

  /// Track a disposable resource
  void track(Function dispose) {
    _disposers.add(dispose);
  }

  /// Dispose all tracked resources
  void disposeAll() {
    for (final dispose in _disposers) {
      try {
        dispose();
      } catch (e) {
        debugPrint('Error disposing resource: $e');
      }
    }
    _disposers.clear();
  }
}
