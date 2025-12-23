import 'package:flutter/painting.dart';
import 'quality_settings.dart';
import 'device_capability.dart';

/// MG-Games 메모리 관리자
/// DEVICE_OPTIMIZATION_GUIDE.md 기반
class MGMemoryManager {
  MGMemoryManager._();

  static MGMemoryManager? _instance;
  static MGMemoryManager get instance {
    _instance ??= MGMemoryManager._();
    return _instance!;
  }

  // ============================================================
  // 이미지 캐시 설정
  // ============================================================

  /// 이미지 캐시 설정 적용
  static void configureImageCache(MGQualitySettings settings) {
    final sizeBytes = settings.imageCacheSizeMB * 1024 * 1024;
    final maxImages = settings.imageCacheSizeMB * 10; // 약 10개/MB

    PaintingBinding.instance.imageCache.maximumSizeBytes = sizeBytes;
    PaintingBinding.instance.imageCache.maximumSize = maxImages;
  }

  /// 기기 티어에 맞게 이미지 캐시 자동 설정
  static void configureForCurrentDevice() {
    final settings = MGQualitySettings.forCurrentDevice();
    configureImageCache(settings);
  }

  /// 이미지 캐시 정리
  static void clearImageCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  // ============================================================
  // 메모리 상태
  // ============================================================

  /// 현재 이미지 캐시 사용량 (bytes)
  static int get currentImageCacheSize {
    return PaintingBinding.instance.imageCache.currentSizeBytes;
  }

  /// 이미지 캐시 최대 크기 (bytes)
  static int get maxImageCacheSize {
    return PaintingBinding.instance.imageCache.maximumSizeBytes;
  }

  /// 이미지 캐시 사용률 (0.0 ~ 1.0)
  static double get imageCacheUsage {
    if (maxImageCacheSize == 0) return 0;
    return currentImageCacheSize / maxImageCacheSize;
  }

  /// 캐시된 이미지 수
  static int get cachedImageCount {
    return PaintingBinding.instance.imageCache.currentSize;
  }

  // ============================================================
  // 메모리 최적화
  // ============================================================

  /// 메모리 부족 시 정리
  static void onMemoryPressure() {
    // 이미지 캐시 절반 정리
    final cache = PaintingBinding.instance.imageCache;
    cache.maximumSizeBytes = cache.maximumSizeBytes ~/ 2;
    cache.maximumSize = cache.maximumSize ~/ 2;
  }

  /// 메모리 상태 복원
  static void restoreMemory() {
    final settings = MGQualitySettings.forCurrentDevice();
    configureImageCache(settings);
  }

  /// 백그라운드 진입 시 처리
  static void onEnterBackground() {
    // 캐시 크기 축소
    final cache = PaintingBinding.instance.imageCache;
    cache.maximumSizeBytes = cache.maximumSizeBytes ~/ 4;
    cache.maximumSize = cache.maximumSize ~/ 4;
  }

  /// 포그라운드 복귀 시 처리
  static void onEnterForeground() {
    restoreMemory();
  }

  // ============================================================
  // 티어별 권장 설정
  // ============================================================

  /// 티어별 권장 이미지 캐시 크기 (MB)
  static int getRecommendedImageCacheSize(DeviceTier tier) {
    switch (tier) {
      case DeviceTier.low:
        return 30;
      case DeviceTier.mid:
        return 60;
      case DeviceTier.high:
        return 100;
    }
  }

  /// 티어별 권장 텍스처 캐시 크기 (MB)
  static int getRecommendedTextureCacheSize(DeviceTier tier) {
    switch (tier) {
      case DeviceTier.low:
        return 15;
      case DeviceTier.mid:
        return 30;
      case DeviceTier.high:
        return 50;
    }
  }
}

/// 메모리 사용 정보
class MemoryUsageInfo {
  final int imageCacheSizeBytes;
  final int imageCacheMaxBytes;
  final int cachedImageCount;
  final int maxCachedImages;

  const MemoryUsageInfo({
    required this.imageCacheSizeBytes,
    required this.imageCacheMaxBytes,
    required this.cachedImageCount,
    required this.maxCachedImages,
  });

  /// 현재 상태 가져오기
  factory MemoryUsageInfo.current() {
    final cache = PaintingBinding.instance.imageCache;
    return MemoryUsageInfo(
      imageCacheSizeBytes: cache.currentSizeBytes,
      imageCacheMaxBytes: cache.maximumSizeBytes,
      cachedImageCount: cache.currentSize,
      maxCachedImages: cache.maximumSize,
    );
  }

  /// 이미지 캐시 사용률
  double get imageCacheUsage {
    if (imageCacheMaxBytes == 0) return 0;
    return imageCacheSizeBytes / imageCacheMaxBytes;
  }

  /// 이미지 캐시 MB
  double get imageCacheMB => imageCacheSizeBytes / (1024 * 1024);

  /// 최대 이미지 캐시 MB
  double get maxImageCacheMB => imageCacheMaxBytes / (1024 * 1024);
}

/// 리소스 로더 유틸리티
class MGResourceLoader {
  MGResourceLoader._();

  /// 우선순위 기반 로딩 큐
  static final List<_LoadRequest> _loadQueue = [];
  static bool _isProcessing = false;

  /// 우선순위 기반 리소스 로딩 요청
  static Future<void> load({
    required Future<void> Function() loader,
    int priority = 0,
  }) async {
    _loadQueue.add(_LoadRequest(loader: loader, priority: priority));
    _loadQueue.sort((a, b) => b.priority.compareTo(a.priority));

    if (!_isProcessing) {
      _processQueue();
    }
  }

  static Future<void> _processQueue() async {
    _isProcessing = true;

    while (_loadQueue.isNotEmpty) {
      final request = _loadQueue.removeAt(0);
      try {
        await request.loader();
      } catch (e) {
        // 로딩 실패 무시
      }
    }

    _isProcessing = false;
  }

  /// 로딩 큐 정리
  static void clearQueue() {
    _loadQueue.clear();
  }
}

class _LoadRequest {
  final Future<void> Function() loader;
  final int priority;

  _LoadRequest({
    required this.loader,
    required this.priority,
  });
}
