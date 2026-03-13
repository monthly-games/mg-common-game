import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 성능 메트릭
class PerformanceMetrics {
  final int frameRate;
  final int frameTime;
  final int memoryUsage;
  final int cpuUsage;
  final DateTime timestamp;

  const PerformanceMetrics({
    required this.frameRate,
    required this.frameTime,
    required this.memoryUsage,
    required this.cpuUsage,
    required this.timestamp,
  });
}

/// 메모리 사용량
class MemoryUsage {
  final int heapUsed;
  final int heapTotal;
  final int external;

  const MemoryUsage({
    required this.heapUsed,
    required this.heapTotal,
    required this.external,
  });

  int get used => heapUsed + external;
  int get total => heapTotal + external;
  double get usagePercent => total > 0 ? (used / total) * 100 : 0;
}

/// 성능 프로필
class PerformanceProfile {
  final String name;
  final int targetFrameRate;
  final int maxFrameTime;
  final int maxMemoryUsage;
  final bool enableVSync;
  final bool enableTripleBuffering;

  const PerformanceProfile({
    required this.name,
    this.targetFrameRate = 60,
    this.maxFrameTime = 16,
    this.maxMemoryUsage = 512 * 1024 * 1024, // 512MB
    this.enableVSync = true,
    this.enableTripleBuffering = true,
  });

  /// 프리셋 프로필
  static const PerformanceProfile low = PerformanceProfile(
    name: 'Low',
    targetFrameRate: 30,
    maxFrameTime: 33,
    maxMemoryUsage: 256 * 1024 * 1024,
    enableVSync: true,
    enableTripleBuffering: false,
  );

  static const PerformanceProfile medium = PerformanceProfile(
    name: 'Medium',
    targetFrameRate: 60,
    maxFrameTime: 16,
    maxMemoryUsage: 512 * 1024 * 1024,
    enableVSync: true,
    enableTripleBuffering: true,
  );

  static const PerformanceProfile high = PerformanceProfile(
    name: 'High',
    targetFrameRate: 60,
    maxFrameTime: 16,
    maxMemoryUsage: 1024 * 1024 * 1024,
    enableVSync: true,
    enableTripleBuffering: true,
  );

  static const PerformanceProfile ultra = PerformanceProfile(
    name: 'Ultra',
    targetFrameRate: 120,
    maxFrameTime: 8,
    maxMemoryUsage: 2048 * 1024 * 1024,
    enableVSync: true,
    enableTripleBuffering: true,
  );
}

/// 성능 관리자
class PerformanceManager {
  static final PerformanceManager _instance = PerformanceManager._();
  static PerformanceManager get instance => _instance;

  PerformanceManager._() {
    _initialize();
  }

  final StreamController<PerformanceMetrics> _metricsController =
      StreamController<PerformanceMetrics>.broadcast();

  PerformanceProfile _currentProfile = PerformanceProfile.medium;
  Timer? _metricsTimer;

  Stream<PerformanceMetrics> get onMetricsUpdate => _metricsController.stream;

  void _initialize() {
    // 기본적으로 1초마다 메트릭 수집
    _startMetricsCollection();
  }

  void _startMetricsCollection() {
    _metricsTimer?.cancel();
    _metricsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _collectMetrics();
    });
  }

  void _collectMetrics() {
    final metrics = PerformanceMetrics(
      frameRate: _getCurrentFrameRate(),
      frameTime: _getCurrentFrameTime(),
      memoryUsage: _getCurrentMemoryUsage(),
      cpuUsage: _getCurrentCpuUsage(),
      timestamp: DateTime.now(),
    );

    _metricsController.add(metrics);
  }

  int _getCurrentFrameRate() {
    // 실제 구현에서는 프레임 레이트 측정
    return WidgetsBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks
        ? _currentProfile.targetFrameRate
        : 0;
  }

  int _getCurrentFrameTime() {
    // 실제 구현에서는 프레임 타임 측정
    return _currentProfile.maxFrameTime;
  }

  int _getCurrentMemoryUsage() {
    // 실제 구현에서는 메모리 사용량 측정
    return 0;
  }

  int _getCurrentCpuUsage() {
    // 실제 구현에서는 CPU 사용량 측정
    return 0;
  }

  /// 프로필 설정
  void setProfile(PerformanceProfile profile) {
    _currentProfile = profile;

    // 프레임 레이트 설정
    // 실제 구현에서는 네이티브 코드 호출
    debugPrint('[Performance] Profile set to: ${profile.name}');
  }

  /// 현재 프로필
  PerformanceProfile get currentProfile => _currentProfile;

  /// 메모리 사용량 가져오기
  MemoryUsage getMemoryUsage() {
    // 실제 구현에서는 메모리 정보 반환
    return const MemoryUsage(
      heapUsed: 0,
      heapTotal: 0,
      external: 0,
    );
  }

  /// 성능 최적화 제안
  List<String> getOptimizationSuggestions() {
    final suggestions = <String>[];
    final memory = getMemoryUsage();

    if (memory.usagePercent > 80) {
      suggestions.add('메모리 사용량이 높습니다. 낮은 프로필을 고려하세요.');
    }

    if (_getCurrentFrameRate() < _currentProfile.targetFrameRate * 0.8) {
      suggestions.add('프레임 레이트가 낮습니다. 그래픽 설정을 낮추세요.');
    }

    return suggestions;
  }

  void dispose() {
    _metricsTimer?.cancel();
    _metricsController.close();
  }
}

/// 객체 풀
class ObjectPool<T> {
  final List<T> _pool = [];
  final T Function() _factory;
  final void Function(T)? _reset;

  ObjectPool({
    required T Function() factory,
    void Function(T)? reset,
  }) : _factory = factory, _reset = reset;

  /// 객체 획득
  T acquire() {
    if (_pool.isEmpty) {
      return _factory();
    }

    return _pool.removeLast();
  }

  /// 객체 반환
  void release(T object) {
    _reset?.call(object);
    _pool.add(object);
  }

  /// 풀 크기
  int get size => _pool.length;

  /// 풀 비우기
  void clear() {
    _pool.clear();
  }
}

/// 자원 관리자
class ResourceManager {
  final Map<String, dynamic> _resources = {};
  final Map<Type, ObjectPool> _pools = {};

  /// 자원 등록
  void register<T>(String key, T resource) {
    _resources[key] = resource;
  }

  /// 자원 가져오기
  T? get<T>(String key) {
    return _resources[key] as T?;
  }

  /// 자원 해제
  void release(String key) {
    _resources.remove(key);
  }

  /// 모든 자원 해제
  void releaseAll() {
    _resources.clear();
  }

  /// 객체 풀 등록
  void registerPool<T>(ObjectPool<T> pool) {
    _pools[T] = pool;
  }

  /// 객체 풀 가져오기
  ObjectPool<T>? getPool<T>() {
    return _pools[T] as ObjectPool<T>?;
  }

  /// 모든 풀 비우기
  void clearPools() {
    for (final pool in _pools.values) {
      pool.clear();
    }
  }
}

/// 캐시 관리자
class CacheManager {
  final Map<String, CacheEntry> _cache = {};
  final int maxSize;
  final Duration defaultTTL;

  int _currentSize = 0;

  CacheManager({
    this.maxSize = 100 * 1024 * 1024, // 100MB
    this.defaultTTL = const Duration(minutes: 5),
  });

  /// 캐시 저장
  void put(String key, dynamic data, {Duration? ttl, int? size}) {
    _removeExpired();

    if (_currentSize >= maxSize && !_cache.containsKey(key)) {
      _evictLRU();
    }

    final entry = CacheEntry(
      data: data,
      ttl: ttl ?? defaultTTL,
      size: size ?? 1024,
      lastAccess: DateTime.now(),
    );

    if (_cache.containsKey(key)) {
      _currentSize -= _cache[key]!.size;
    }

    _cache[key] = entry;
    _currentSize += entry.size;
  }

  /// 캐시 가져오기
  T? get<T>(String key) {
    final entry = _cache[key];

    if (entry == null) return null;

    if (entry.isExpired) {
      remove(key);
      return null;
    }

    entry.lastAccess = DateTime.now();
    return entry.data as T?;
  }

  /// 캐시 제거
  void remove(String key) {
    final entry = _cache.remove(key);
    if (entry != null) {
      _currentSize -= entry.size;
    }
  }

  /// 캐시 비우기
  void clear() {
    _cache.clear();
    _currentSize = 0;
  }

  void _removeExpired() {
    final now = DateTime.now();
    final expiredKeys = _cache.entries
        .where((e) => e.value.isExpired)
        .map((e) => e.key)
        .toList();

    for (final key in expiredKeys) {
      remove(key);
    }
  }

  void _evictLRU() {
    if (_cache.isEmpty) return;

    final lruKey = _cache.entries
        .reduce((a, b) => a.value.lastAccess.isBefore(b.value.lastAccess) ? a : b)
        .key;

    remove(lruKey);
  }

  /// 캐시 통계
  Map<String, dynamic> get stats => {
        'size': _currentSize,
        'maxSize': maxSize,
        'entries': _cache.length,
        'usagePercent': (_currentSize / maxSize * 100).toStringAsFixed(2),
      };
}

/// 캐시 항목
class CacheEntry {
  final dynamic data;
  final Duration ttl;
  final int size;
  DateTime lastAccess;

  CacheEntry({
    required this.data,
    required this.ttl,
    required this.size,
    required this.lastAccess,
  });

  bool get isExpired {
    return DateTime.now().difference(lastAccess) > ttl;
  }
}

/// 레이지 로딩 관리자
class LazyLoadManager {
  final Map<String, Future> _loading = {};
  final Map<String, dynamic> _loaded = {};

  /// 레이지 로드
  Future<T> load<T>(
    String key,
    Future<T> Function() loader, {
    bool forceReload = false,
  }) async {
    if (!forceReload && _loaded.containsKey(key)) {
      return _loaded[key] as T;
    }

    if (_loading.containsKey(key)) {
      return await _loading[key] as T;
    }

    final future = loader();
    _loading[key] = future;

    try {
      final result = await future;
      _loaded[key] = result;
      _loading.remove(key);
      return result;
    } catch (e) {
      _loading.remove(key);
      rethrow;
    }
  }

  /// 캐시 무시하고 로드
  Future<T> reload<T>(
    String key,
    Future<T> Function() loader,
  ) async {
    return load(key, loader, forceReload: true);
  }

  /// 로드된 항목 제거
  void unload(String key) {
    _loaded.remove(key);
    _loading.remove(key);
  }

  /// 모든 항목 제거
  void clear() {
    _loaded.clear();
    _loading.clear();
  }
}
