import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 캐시 레벨
enum CacheLevel {
  memory,         // 메모리 캐시
  disk,           // 디스크 캐시
  network,        // 네트워크 캐시
}

/// 캐시 전략
enum CacheStrategy {
  lru,            // Least Recently Used
  lfu,            // Least Frequently Used
  fifo,           // First In First Out
  lifo,           // Last In First Out
}

/// 캐시 항목
class CacheEntry<T> {
  final String key;
  final T value;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int accessCount;
  final DateTime? lastAccessedAt;
  final int size; // bytes

  const CacheEntry({
    required this.key,
    required this.value,
    required this.createdAt,
    this.expiresAt,
    required this.accessCount,
    this.lastAccessedAt,
    required this.size,
  });

  /// 만료 여부
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// 유효 여부
  bool get isValid => !isExpired;

  /// 남은 수명
  Duration? get timeToLive {
    if (expiresAt == null) return null;
    final diff = expiresAt!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  /// 액세스 시 업데이트
  CacheEntry<T> withAccess() {
    return CacheEntry(
      key: key,
      value: value,
      createdAt: createdAt,
      expiresAt: expiresAt,
      accessCount: accessCount + 1,
      lastAccessedAt: DateTime.now(),
      size: size,
    );
  }
}

/// 캐시 통계
class CacheStatistics {
  final int totalHits;
  final int totalMisses;
  final int totalEntries;
  final int totalSize;
  final double hitRate;
  final double avgEntrySize;
  final Map<String, int> categoryDistribution;

  const CacheStatistics({
    required this.totalHits,
    required this.totalMisses,
    required this.totalEntries,
    required this.totalSize,
    required this.hitRate,
    required this.avgEntrySize,
    required this.categoryDistribution,
  });

  /// 전체 요청 수
  int get totalRequests => totalHits + totalMisses;
}

/// 캐시 설정
class CacheConfig {
  final int maxSize; // 최대 크기 (bytes)
  final int maxEntries; // 최대 항목 수
  final Duration defaultTTL; // 기본 수명
  final CacheStrategy strategy;
  final bool enableCompression;
  final bool enablePersistence;
  final Duration cleanupInterval;

  const CacheConfig({
    this.maxSize = 50 * 1024 * 1024, // 50MB
    this.maxEntries = 1000,
    this.defaultTTL = const Duration(hours: 1),
    this.strategy = CacheStrategy.lru,
    this.enableCompression = false,
    this.enablePersistence = true,
    this.cleanupInterval = const Duration(minutes: 5),
  });
}

/// 캐시 관리자
class CacheManager {
  static final CacheManager _instance = CacheManager._();
  static CacheManager get instance => _instance;

  CacheManager._();

  SharedPreferences? _prefs;

  final Map<String, CacheEntry> _memoryCache = {};
  final Map<String, CacheEntry> _diskCache = {};

  CacheConfig _config = const CacheConfig();
  int _currentMemorySize = 0;
  int _currentDiskSize = 0;

  int _totalHits = 0;
  int _totalMisses = 0;

  final StreamController<String> _evictionController =
      StreamController<String>.broadcast();
  final StreamController<CacheStatistics> _statsController =
      StreamController<CacheStatistics>.broadcast();

  Stream<String> get onEviction => _evictionController.stream;
  Stream<CacheStatistics> get onStatsUpdate => _statsController.stream;

  Timer? _cleanupTimer;

  /// 초기화
  Future<void> initialize({CacheConfig? config}) async {
    _prefs = await SharedPreferences.getInstance();

    if (config != null) {
      _config = config;
    }

    // 영구 캐시 로드
    if (_config.enablePersistence) {
      await _loadPersistedCache();
    }

    // 청소 타이머 시작
    _startCleanupTimer();

    debugPrint('[Cache] Initialized');
  }

  Future<void> _loadPersistedCache() async {
    // 디스크 캐시 로드
    final cacheJson = _prefs?.getString('disk_cache');
    if (cacheJson != null) {
      try {
        final data = jsonDecode(cacheJson) as Map<String, dynamic>;
        // 파싱
      } catch (e) {
        debugPrint('[Cache] Error loading persisted cache: $e');
      }
    }
  }

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_config.cleanupInterval, (_) {
      cleanup();
    });
  }

  /// 캐시에 저장
  Future<bool> set<T>({
    required String key,
    required T value,
    CacheLevel level = CacheLevel.memory,
    Duration? ttl,
    String? category,
  }) async {
    final size = _calculateSize(value);
    final now = DateTime.now();
    final expiresAt = ttl != null
        ? now.add(ttl)
        : now.add(_config.defaultTTL);

    final entry = CacheEntry(
      key: key,
      value: value,
      createdAt: now,
      expiresAt: expiresAt,
      accessCount: 0,
      size: size,
    );

    switch (level) {
      case CacheLevel.memory:
        return _setMemoryCache(entry);
      case CacheLevel.disk:
        return await _setDiskCache(entry);
      case CacheLevel.network:
        // 네트워크 캐시는 별도 처리
        return false;
    }
  }

  bool _setMemoryCache(CacheEntry entry) {
    // 용량 체크
    if (_currentMemorySize + entry.size > _config.maxSize) {
      _evictMemory(entry.size);
    }

    // 항목 수 체크
    if (_memoryCache.length >= _config.maxEntries) {
      _evictMemory(entry.size);
    }

    // 기존 항목 제거
    final existing = _memoryCache[entry.key];
    if (existing != null) {
      _currentMemorySize -= existing.size;
    }

    _memoryCache[entry.key] = entry;
    _currentMemorySize += entry.size;

    return true;
  }

  Future<bool> _setDiskCache(CacheEntry entry) async {
    // 용량 체크
    if (_currentDiskSize + entry.size > _config.maxSize) {
      _evictDisk(entry.size);
    }

    // 직렬화
    final json = jsonEncode({
      'key': entry.key,
      'value': entry.value,
      'createdAt': entry.createdAt.toIso8601String(),
      'expiresAt': entry.expiresAt?.toIso8601String(),
      'size': entry.size,
    });

    // 저장
    final success = await _prefs?.setString('cache_${entry.key}', json) ?? false;

    if (success) {
      final existing = _diskCache[entry.key];
      if (existing != null) {
        _currentDiskSize -= existing.size;
      }

      _diskCache[entry.key] = entry;
      _currentDiskSize += entry.size;
    }

    return success;
  }

  /// 캐시에서 조회
  T? get<T>({
    required String key,
    CacheLevel level = CacheLevel.memory,
  }) {
    switch (level) {
      case CacheLevel.memory:
        return _getMemoryCache<T>(key);
      case CacheLevel.disk:
        return _getDiskCache<T>(key);
      case CacheLevel.network:
        return null; // 네트워크 캐시는 별도 처리
    }
  }

  T? _getMemoryCache<T>(String key) {
    final entry = _memoryCache[key];

    if (entry == null) {
      _totalMisses++;
      _updateStats();
      return null;
    }

    if (!entry.isValid) {
      _removeMemory(key);
      _totalMisses++;
      _updateStats();
      return null;
    }

    // 액세스 업데이트
    _memoryCache[key] = entry.withAccess();
    _totalHits++;
    _updateStats();

    return entry.value as T;
  }

  T? _getDiskCache<T>(String key) {
    final entry = _diskCache[key];

    if (entry == null) {
      _totalMisses++;
      _updateStats();
      return null;
    }

    if (!entry.isValid) {
      _removeDisk(key);
      _totalMisses++;
      _updateStats();
      return null;
    }

    _diskCache[key] = entry.withAccess();
    _totalHits++;
    _updateStats();

    return entry.value as T;
  }

  /// 캐시 삭제
  void remove({
    required String key,
    CacheLevel? level,
  }) {
    if (level == null || level == CacheLevel.memory) {
      _removeMemory(key);
    }
    if (level == null || level == CacheLevel.disk) {
      _removeDisk(key);
    }
  }

  void _removeMemory(String key) {
    final entry = _memoryCache.remove(key);
    if (entry != null) {
      _currentMemorySize -= entry.size;
      _evictionController.add(key);
    }
  }

  void _removeDisk(String key) {
    final entry = _diskCache.remove(key);
    if (entry != null) {
      _currentDiskSize -= entry.size;
      _prefs?.remove('cache_$key');
      _evictionController.add(key);
    }
  }

  /// 캐시 초기화
  void clear({CacheLevel? level}) {
    if (level == null || level == CacheLevel.memory) {
      _memoryCache.clear();
      _currentMemorySize = 0;
    }
    if (level == null || level == CacheLevel.disk) {
      _diskCache.clear();
      _currentDiskSize = 0;
      _prefs?.remove('disk_cache');
    }

    debugPrint('[Cache] Cleared');
  }

  /// 메모리 캐시 제거
  void _evictMemory(int requiredSize) {
    var freed = 0;

    switch (_config.strategy) {
      case CacheStrategy.lru:
        // LRU: 가장 오랫동안 액세스하지 않은 항목 제거
        final entries = _memoryCache.values.toList()
          ..sort((a, b) {
            final aTime = a.lastAccessedAt ?? a.createdAt;
            final bTime = b.lastAccessedAt ?? b.createdAt;
            return aTime.compareTo(bTime);
          });

        for (final entry in entries) {
          if (freed >= requiredSize) break;
          _removeMemory(entry.key);
          freed += entry.size;
        }
        break;

      case CacheStrategy.lfu:
        // LFU: 가장 적게 액세스한 항목 제거
        final entries = _memoryCache.values.toList()
          ..sort((a, b) => a.accessCount.compareTo(b.accessCount));

        for (final entry in entries) {
          if (freed >= requiredSize) break;
          _removeMemory(entry.key);
          freed += entry.size;
        }
        break;

      case CacheStrategy.fifo:
        // FIFO: 먼저 들어온 항목 제거
        final entries = _memoryCache.values.toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        for (final entry in entries) {
          if (freed >= requiredSize) break;
          _removeMemory(entry.key);
          freed += entry.size;
        }
        break;

      case CacheStrategy.lifo:
        // LIFO: 가장 최근에 들어온 항목 제거
        final entries = _memoryCache.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        for (final entry in entries) {
          if (freed >= requiredSize) break;
          _removeMemory(entry.key);
          freed += entry.size;
        }
        break;
    }
  }

  /// 디스크 캐시 제거
  void _evictDisk(int requiredSize) {
    var freed = 0;

    final entries = _diskCache.values.toList()
      ..sort((a, b) {
        final aTime = a.lastAccessedAt ?? a.createdAt;
        final bTime = b.lastAccessedAt ?? b.createdAt;
        return aTime.compareTo(bTime);
      });

    for (final entry in entries) {
      if (freed >= requiredSize) break;
      _removeDisk(entry.key);
      freed += entry.size;
    }
  }

  /// 청소 (만료 항목 제거)
  Future<void> cleanup() async {
    final now = DateTime.now();

    // 메모리 청소
    final memoryKeysToRemove = _memoryCache.entries
        .where((e) => e.value.expiresAt != null && now.isAfter(e.value.expiresAt!))
        .map((e) => e.key)
        .toList();

    for (final key in memoryKeysToRemove) {
      _removeMemory(key);
    }

    // 디스크 청소
    final diskKeysToRemove = _diskCache.entries
        .where((e) => e.value.expiresAt != null && now.isAfter(e.value.expiresAt!))
        .map((e) => e.key)
        .toList();

    for (final key in diskKeysToRemove) {
      _removeDisk(key);
    }

    if (memoryKeysToRemove.isNotEmpty || diskKeysToRemove.isNotEmpty) {
      debugPrint('[Cache] Cleaned up ${memoryKeysToRemove.length + diskKeysToRemove.length} entries');
    }
  }

  /// 캐시 항목 존재 여부
  bool exists({
    required String key,
    CacheLevel? level,
  }) {
    if (level == null || level == CacheLevel.memory) {
      final entry = _memoryCache[key];
      if (entry != null && entry.isValid) return true;
    }
    if (level == null || level == CacheLevel.disk) {
      final entry = _diskCache[key];
      if (entry != null && entry.isValid) return true;
    }
    return false;
  }

  /// 크기 계산
  int _calculateSize<T>(T value) {
    // 간단 계산 (실제로는 더 정확하게)
    return jsonEncode(value).length;
  }

  /// 통계 업데이트
  void _updateStats() {
    final stats = getStatistics();
    _statsController.add(stats);
  }

  /// 통계 조회
  CacheStatistics getStatistics() {
    final totalRequests = _totalHits + _totalMisses;
    final hitRate = totalRequests > 0 ? _totalHits / totalRequests : 0.0;

    final avgSize = (_memoryCache.length + _diskCache.length) > 0
        ? (_currentMemorySize + _currentDiskSize) / (_memoryCache.length + _diskCache.length)
        : 0.0;

    return CacheStatistics(
      totalHits: _totalHits,
      totalMisses: _totalMisses,
      totalEntries: _memoryCache.length + _diskCache.length,
      totalSize: _currentMemorySize + _currentDiskSize,
      hitRate: hitRate,
      avgEntrySize: avgSize,
      categoryDistribution: {},
    );
  }

  /// 캐시 미리가져오기 (Prefetch)
  Future<void> prefetch<T>({
    required String key,
    required Future<T?> Function() loader,
    CacheLevel level = CacheLevel.memory,
    Duration? ttl,
  }) async {
    if (exists(key: key, level: level)) return;

    final value = await loader();
    if (value != null) {
      await set(key: key, value: value, level: level, ttl: ttl);
    }
  }

  /// 일괄 캐시 (Batch)
  Future<Map<String, T>> getAll<T>({
    required List<String> keys,
    CacheLevel level = CacheLevel.memory,
  }) async {
    final result = <String, T>{};

    for (final key in keys) {
      final value = get<T>(key: key, level: level);
      if (value != null) {
        result[key] = value;
      }
    }

    return result;
  }

  /// 일괄 캐시 저장
  Future<void> setAll<T>({
    required Map<String, T> entries,
    CacheLevel level = CacheLevel.memory,
    Duration? ttl,
  }) async {
    for (final entry in entries.entries) {
      await set(
        key: entry.key,
        value: entry.value,
        level: level,
        ttl: ttl,
      );
    }
  }

  void dispose() {
    _evictionController.close();
    _statsController.close();
    _cleanupTimer?.cancel();
  }
}
