import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Asset priority levels for loading
enum AssetPriority {
  critical, // Must load immediately (splash, essential UI)
  high, // Load soon (current scene assets)
  medium, // Load when idle (next scene assets)
  low, // Load in background (optional/future assets)
}

/// Asset loading state
enum AssetState {
  pending,
  loading,
  loaded,
  failed,
}

/// Asset entry with metadata
class AssetEntry {
  final String key;
  final String path;
  final AssetPriority priority;
  AssetState state;
  Object? data;
  DateTime? loadedAt;
  DateTime? lastAccessedAt;
  int accessCount;
  int sizeBytes;

  AssetEntry({
    required this.key,
    required this.path,
    this.priority = AssetPriority.medium,
    this.state = AssetState.pending,
    this.data,
    this.loadedAt,
    this.lastAccessedAt,
    this.accessCount = 0,
    this.sizeBytes = 0,
  });

  bool get isLoaded => state == AssetState.loaded && data != null;
}

/// Progress callback for asset loading
typedef AssetLoadProgressCallback = void Function(
  int loaded,
  int total,
  String currentAsset,
);

/// Asset loading and caching optimizer
class AssetOptimizer extends ChangeNotifier {
  static final AssetOptimizer _instance = AssetOptimizer._();
  static AssetOptimizer get instance => _instance;

  AssetOptimizer._();

  final Map<String, AssetEntry> _assets = {};
  final Queue<String> _loadQueue = Queue<String>();
  final Set<String> _loadingSet = {};

  bool _isPreloading = false;
  int _maxConcurrentLoads = 3;
  int _maxCacheSize = 100; // Max number of assets
  int _maxCacheSizeBytes = 50 * 1024 * 1024; // 50 MB
  int _currentCacheSizeBytes = 0;

  /// Initialize optimizer
  void initialize({
    int maxConcurrentLoads = 3,
    int maxCacheSize = 100,
    int maxCacheSizeMB = 50,
  }) {
    _maxConcurrentLoads = maxConcurrentLoads;
    _maxCacheSize = maxCacheSize;
    _maxCacheSizeBytes = maxCacheSizeMB * 1024 * 1024;
  }

  /// Register an asset for management
  void registerAsset(
    String key,
    String path, {
    AssetPriority priority = AssetPriority.medium,
  }) {
    if (_assets.containsKey(key)) return;

    _assets[key] = AssetEntry(
      key: key,
      path: path,
      priority: priority,
    );
  }

  /// Register multiple assets
  void registerAssets(Map<String, String> assets,
      {AssetPriority priority = AssetPriority.medium}) {
    for (final entry in assets.entries) {
      registerAsset(entry.key, entry.value, priority: priority);
    }
  }

  /// Preload assets by priority
  Future<void> preloadByPriority(
    AssetPriority priority, {
    AssetLoadProgressCallback? onProgress,
  }) async {
    final assetsToLoad = _assets.values
        .where((a) => a.priority == priority && !a.isLoaded)
        .map((a) => a.key)
        .toList();

    await preloadAssets(assetsToLoad, onProgress: onProgress);
  }

  /// Preload specific assets
  Future<void> preloadAssets(
    List<String> keys, {
    AssetLoadProgressCallback? onProgress,
  }) async {
    if (_isPreloading) return;
    _isPreloading = true;

    final validKeys = keys.where((k) => _assets.containsKey(k)).toList();
    int loaded = 0;

    try {
      // Process in batches
      for (int i = 0; i < validKeys.length; i += _maxConcurrentLoads) {
        final batch = validKeys.skip(i).take(_maxConcurrentLoads);
        await Future.wait(
          batch.map((key) async {
            await _loadAsset(key);
            loaded++;
            onProgress?.call(loaded, validKeys.length, key);
          }),
        );
      }
    } finally {
      _isPreloading = false;
    }
  }

  Future<void> _loadAsset(String key) async {
    final entry = _assets[key];
    if (entry == null || entry.isLoaded || _loadingSet.contains(key)) return;

    _loadingSet.add(key);
    entry.state = AssetState.loading;

    try {
      // Determine asset type and load
      final path = entry.path;
      Object? data;
      int size = 0;

      if (_isImagePath(path)) {
        // Load image as bytes
        final bytes = await rootBundle.load(path);
        data = bytes;
        size = bytes.lengthInBytes;
      } else if (_isJsonPath(path)) {
        // Load JSON as string
        final string = await rootBundle.loadString(path);
        data = string;
        size = string.length * 2; // Rough estimate
      } else {
        // Load as bytes
        final bytes = await rootBundle.load(path);
        data = bytes;
        size = bytes.lengthInBytes;
      }

      entry.data = data;
      entry.state = AssetState.loaded;
      entry.loadedAt = DateTime.now();
      entry.lastAccessedAt = DateTime.now();
      entry.sizeBytes = size;
      _currentCacheSizeBytes += size;

      // Check cache limits
      _enforceCacheLimits();
    } catch (e) {
      entry.state = AssetState.failed;
      debugPrint('Failed to load asset $key: $e');
    } finally {
      _loadingSet.remove(key);
    }
  }

  bool _isImagePath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
  }

  bool _isJsonPath(String path) {
    return path.toLowerCase().endsWith('.json');
  }

  /// Get a loaded asset
  T? getAsset<T>(String key) {
    final entry = _assets[key];
    if (entry == null) return null;

    if (entry.isLoaded) {
      entry.accessCount++;
      entry.lastAccessedAt = DateTime.now();
      return entry.data as T?;
    }

    // Queue for loading if not loaded
    if (entry.state == AssetState.pending) {
      _queueLoad(key);
    }

    return null;
  }

  /// Get asset or load synchronously
  Future<T?> getAssetAsync<T>(String key) async {
    final entry = _assets[key];
    if (entry == null) return null;

    if (!entry.isLoaded) {
      await _loadAsset(key);
    }

    if (entry.isLoaded) {
      entry.accessCount++;
      entry.lastAccessedAt = DateTime.now();
      return entry.data as T?;
    }

    return null;
  }

  void _queueLoad(String key) {
    if (!_loadQueue.contains(key)) {
      _loadQueue.add(key);
      _processQueue();
    }
  }

  void _processQueue() async {
    while (_loadQueue.isNotEmpty && _loadingSet.length < _maxConcurrentLoads) {
      final key = _loadQueue.removeFirst();
      _loadAsset(key); // Don't await, process concurrently
    }
  }

  void _enforceCacheLimits() {
    // Remove assets if over size limit
    while (_currentCacheSizeBytes > _maxCacheSizeBytes ||
        _assets.values.where((a) => a.isLoaded).length > _maxCacheSize) {
      _evictLeastUsed();
    }
  }

  void _evictLeastUsed() {
    AssetEntry? lruEntry;
    DateTime? lruTime;

    for (final entry in _assets.values) {
      if (!entry.isLoaded) continue;
      if (entry.priority == AssetPriority.critical) continue;

      final accessTime = entry.lastAccessedAt;
      if (accessTime == null) continue;

      if (lruTime == null || accessTime.isBefore(lruTime)) {
        lruEntry = entry;
        lruTime = accessTime;
      }
    }

    if (lruEntry != null) {
      _unloadAsset(lruEntry.key);
    }
  }

  void _unloadAsset(String key) {
    final entry = _assets[key];
    if (entry == null || !entry.isLoaded) return;

    _currentCacheSizeBytes -= entry.sizeBytes;
    entry.data = null;
    entry.state = AssetState.pending;
    entry.sizeBytes = 0;
  }

  /// Unload assets by priority
  void unloadByPriority(AssetPriority priority) {
    for (final entry in _assets.values) {
      if (entry.priority == priority) {
        _unloadAsset(entry.key);
      }
    }
  }

  /// Unload specific assets
  void unloadAssets(List<String> keys) {
    for (final key in keys) {
      _unloadAsset(key);
    }
  }

  /// Clear all loaded assets
  void clearCache() {
    for (final entry in _assets.values) {
      if (entry.isLoaded) {
        _unloadAsset(entry.key);
      }
    }
  }

  /// Get loading state
  bool isLoaded(String key) => _assets[key]?.isLoaded ?? false;
  bool isLoading(String key) => _loadingSet.contains(key);

  /// Get statistics
  Map<String, dynamic> get stats {
    final loaded = _assets.values.where((a) => a.isLoaded).length;
    final pending = _assets.values.where((a) => a.state == AssetState.pending).length;
    final failed = _assets.values.where((a) => a.state == AssetState.failed).length;

    return {
      'totalAssets': _assets.length,
      'loadedAssets': loaded,
      'pendingAssets': pending,
      'failedAssets': failed,
      'loadingAssets': _loadingSet.length,
      'cacheSizeMB': _currentCacheSizeBytes / (1024 * 1024),
      'maxCacheSizeMB': _maxCacheSizeBytes / (1024 * 1024),
      'queueSize': _loadQueue.length,
    };
  }

  /// Get asset stats
  List<Map<String, dynamic>> getAssetStats() {
    return _assets.values.map((e) => {
      'key': e.key,
      'path': e.path,
      'priority': e.priority.name,
      'state': e.state.name,
      'accessCount': e.accessCount,
      'sizeKB': e.sizeBytes / 1024,
    }).toList();
  }
}

/// Asset bundle for grouping related assets
class AssetBundle {
  final String name;
  final AssetPriority priority;
  final Map<String, String> assets;

  const AssetBundle({
    required this.name,
    required this.assets,
    this.priority = AssetPriority.medium,
  });

  /// Register this bundle
  void register() {
    AssetOptimizer.instance.registerAssets(assets, priority: priority);
  }

  /// Preload this bundle
  Future<void> preload({AssetLoadProgressCallback? onProgress}) async {
    await AssetOptimizer.instance.preloadAssets(
      assets.keys.toList(),
      onProgress: onProgress,
    );
  }

  /// Unload this bundle
  void unload() {
    AssetOptimizer.instance.unloadAssets(assets.keys.toList());
  }
}
