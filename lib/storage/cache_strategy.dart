import 'dart:convert';
import 'package:mg_common_game/storage/local_storage_service.dart';

/// Cache entry with metadata
class CacheEntry<T> {
  final T data;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int accessCount;
  final DateTime? lastAccessedAt;

  CacheEntry({
    required this.data,
    required this.createdAt,
    this.expiresAt,
    this.accessCount = 0,
    this.lastAccessedAt,
  });

  /// Check if cache entry is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if cache entry is stale (based on age)
  bool isStale(Duration maxAge) {
    return DateTime.now().difference(createdAt) > maxAge;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt?.millisecondsSinceEpoch,
      'accessCount': accessCount,
      'lastAccessedAt': lastAccessedAt?.millisecondsSinceEpoch,
    };
  }

  /// Create from JSON
  factory CacheEntry.fromJson(Map<String, dynamic> json, T Function(dynamic) dataDecoder) {
    return CacheEntry(
      data: dataDecoder(json['data']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      expiresAt: json['expiresAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['expiresAt'])
          : null,
      accessCount: json['accessCount'] ?? 0,
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastAccessedAt'])
          : null,
    );
  }
}

/// Cache configuration
class CacheConfig {
  final Duration ttl;
  final Duration? maxAge;
  final int maxSize;
  final bool persistToDisk;
  final evictionPolicy;

  const CacheConfig({
    this.ttl = const Duration(hours: 1),
    this.maxAge,
    this.maxSize = 100,
    this.persistToDisk = true,
    this.evictionPolicy = CacheEvictionPolicy.lru,
  });
}

/// Cache eviction policy
enum CacheEvictionPolicy {
  lru, // Least Recently Used
  lfu, // Least Frequently Used
  fifo, // First In First Out
  lifo, // Last In First Out
}

/// Cache strategy for managing in-memory and persistent caching
class CacheStrategy {
  static final CacheStrategy _instance = CacheStrategy._internal();
  static CacheStrategy get instance => _instance;

  CacheStrategy._internal();

  final LocalStorageService _storage = LocalStorageService.instance;
  final Map<String, CacheEntry> _memoryCache = {};
  final Map<String, CacheConfig> _configs = {};

  /// Initialize the cache strategy
  Future<void> initialize() async {
    await _storage.initialize();
  }

  /// Register cache configuration for a specific namespace
  void registerConfig(String namespace, CacheConfig config) {
    _configs[namespace] = config;
  }

  /// Get cache key with namespace
  String _getCacheKey(String namespace, String key) {
    return '${namespace}_$key';
  }

  /// Put data in cache
  Future<void> put<T>(
    String namespace,
    String key,
    T data, {
    Duration? ttl,
    bool persist = true,
  }) async {
    final config = _configs[namespace];
    final finalTtl = ttl ?? config?.ttl ?? const Duration(hours: 1);

    final cacheKey = _getCacheKey(namespace, key);
    final entry = CacheEntry(
      data: data,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(finalTtl),
    );

    // Add to memory cache
    _memoryCache[cacheKey] = entry;

    // Check if should persist to disk
    final shouldPersist = persist && (config?.persistToDisk ?? true);
    if (shouldPersist) {
      await _storage.setJson(cacheKey, entry.toJson());
    }

    // Enforce max size
    await _enforceMaxSize(namespace);
  }

  /// Get data from cache
  T? get<T>(String namespace, String key) {
    final cacheKey = _getCacheKey(namespace, key);
    final config = _configs[namespace];

    // Check memory cache first
    var entry = _memoryCache[cacheKey] as CacheEntry<T>?;

    // If not in memory, try loading from disk
    if (entry == null && config?.persistToDisk == true) {
      final json = _storage.getJson(cacheKey);
      if (json != null) {
        entry = CacheEntry.fromJson(json, (data) => data as T);
        if (entry != null) {
          _memoryCache[cacheKey] = entry;
        }
      }
    }

    // Return null if not found or expired
    if (entry == null || entry.isExpired) {
      if (entry?.isExpired == true) {
        remove(namespace, key);
      }
      return null;
    }

    // Update access statistics
    final updatedEntry = CacheEntry(
      data: entry.data,
      createdAt: entry.createdAt,
      expiresAt: entry.expiresAt,
      accessCount: entry.accessCount + 1,
      lastAccessedAt: DateTime.now(),
    );
    _memoryCache[cacheKey] = updatedEntry;

    return entry.data;
  }

  /// Check if data exists in cache and is valid
  bool has(String namespace, String key) {
    return get(namespace, key) != null;
  }

  /// Remove data from cache
  Future<void> remove(String namespace, String key) async {
    final cacheKey = _getCacheKey(namespace, key);
    _memoryCache.remove(cacheKey);
    await _storage.remove(cacheKey);
  }

  /// Clear all cache for a namespace
  Future<void> clear(String namespace) async {
    final keys = _memoryCache.keys.where((key) => key.startsWith('${namespace}_')).toList();
    for (final key in keys) {
      _memoryCache.remove(key);
      await _storage.remove(key);
    }
  }

  /// Clear all cache
  Future<void> clearAll() async {
    _memoryCache.clear();
    await _storage.clear();
  }

  /// Enforce maximum cache size
  Future<void> _enforceMaxSize(String namespace) async {
    final config = _configs[namespace];
    if (config == null) return;

    final namespaceKeys = _memoryCache.keys
        .where((key) => key.startsWith('${namespace}_'))
        .toList();

    if (namespaceKeys.length <= config.maxSize) return;

    // Sort based on eviction policy
    final entries = namespaceKeys.map((key) {
      return MapEntry(key, _memoryCache[key]!);
    }).toList();

    List<MapEntry<String, CacheEntry>> sortedEntries;
    switch (config.evictionPolicy) {
      case CacheEvictionPolicy.lru:
        sortedEntries = entries..sort((a, b) {
          final aTime = a.value.lastAccessedAt ?? a.value.createdAt;
          final bTime = b.value.lastAccessedAt ?? b.value.createdAt;
          return aTime.compareTo(bTime);
        });
        break;
      case CacheEvictionPolicy.lfu:
        sortedEntries = entries..sort((a, b) {
          return a.value.accessCount.compareTo(b.value.accessCount);
        });
        break;
      case CacheEvictionPolicy.fifo:
        sortedEntries = entries..sort((a, b) {
          return a.value.createdAt.compareTo(b.value.createdAt);
        });
        break;
      case CacheEvictionPolicy.lifo:
        sortedEntries = entries..sort((a, b) {
          return b.value.createdAt.compareTo(a.value.createdAt);
        });
        break;
    }

    // Remove oldest entries
    final toRemove = sortedEntries.take(namespaceKeys.length - config.maxSize);
    for (final entry in toRemove) {
      _memoryCache.remove(entry.key);
      await _storage.remove(entry.key);
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getStats(String namespace) {
    final namespaceKeys = _memoryCache.keys
        .where((key) => key.startsWith('${namespace}_'))
        .toList();

    final entries = namespaceKeys.map((key) => _memoryCache[key]!).toList();

    final now = DateTime.now();
    final expiredCount = entries.where((e) => e.isExpired).length;
    final totalAccesses = entries.fold<int>(0, (sum, e) => sum + e.accessCount);
    final avgAccessCount = entries.isEmpty ? 0 : totalAccesses / entries.length;

    return {
      'totalEntries': entries.length,
      'expiredEntries': expiredCount,
      'validEntries': entries.length - expiredCount,
      'totalAccesses': totalAccesses,
      'averageAccessCount': avgAccessCount,
      'memorySize': namespaceKeys.length,
    };
  }

  /// Prefetch data into cache
  Future<void> prefetch<T>(
    String namespace,
    Map<String, Future<T>> dataFetchers, {
    Duration? ttl,
  }) async {
    final futures = dataFetchers.entries.map((entry) async {
      final data = await entry.value;
      await put(namespace, entry.key, data, ttl: ttl);
    });

    await Future.wait(futures);
  }

  /// Invalidate cache based on predicate
  Future<void> invalidateWhere(String namespace, bool Function(String key, CacheEntry entry) predicate) async {
    final namespaceKeys = _memoryCache.keys
        .where((key) => key.startsWith('${namespace}_'))
        .toList();

    for (final key in namespaceKeys) {
      final entry = _memoryCache[key];
      if (entry != null && predicate(key, entry)) {
        await remove(namespace, key.replaceFirst('${namespace}_', ''));
      }
    }
  }

  /// Warm up cache with initial data
  Future<void> warmUp<T>(
    String namespace,
    Map<String, T> initialData, {
    Duration? ttl,
  }) async {
    for (final entry in initialData.entries) {
      await put(namespace, entry.key, entry.value, ttl: ttl);
    }
  }

  /// Get or compute pattern
  Future<T> getOrCompute<T>(
    String namespace,
    String key,
    Future<T> Function() compute, {
    Duration? ttl,
  }) async {
    final cached = get<T>(namespace, key);
    if (cached != null) {
      return cached;
    }

    final computed = await compute();
    await put(namespace, key, computed, ttl: ttl);
    return computed;
  }

  /// Refresh cache entry
  Future<void> refresh<T>(
    String namespace,
    String key,
    Future<T> Function() compute, {
    Duration? ttl,
  }) async {
    final computed = await compute();
    await put(namespace, key, computed, ttl: ttl);
  }

  /// Get all keys in namespace
  List<String> getKeys(String namespace) {
    return _memoryCache.keys
        .where((key) => key.startsWith('${namespace}_'))
        .map((key) => key.replaceFirst('${namespace}_', ''))
        .toList();
  }

  /// Get cache size in bytes (approximate)
  int getCacheSize(String namespace) {
    final namespaceKeys = _memoryCache.keys
        .where((key) => key.startsWith('${namespace}_'))
        .toList();

    return namespaceKeys.fold<int>(0, (sum, key) {
      final entry = _memoryCache[key];
      if (entry == null) return sum;
      return sum + jsonEncode(entry.toJson()).length;
    });
  }
}
