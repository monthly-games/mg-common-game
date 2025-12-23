import 'dart:io';
import 'package:flutter/foundation.dart';

/// MG-Games 기기 성능 감지
/// DEVICE_OPTIMIZATION_GUIDE.md 기반
class MGDeviceCapability {
  MGDeviceCapability._();

  // ============================================================
  // 기기 정보 캐시
  // ============================================================

  static DeviceTier? _cachedTier;
  static DeviceInfo? _cachedInfo;

  /// 기기 티어 가져오기 (캐시됨)
  static DeviceTier get tier {
    _cachedTier ??= _detectTier();
    return _cachedTier!;
  }

  /// 기기 정보 가져오기 (캐시됨)
  static DeviceInfo get info {
    _cachedInfo ??= _detectInfo();
    return _cachedInfo!;
  }

  /// 캐시 초기화
  static void clearCache() {
    _cachedTier = null;
    _cachedInfo = null;
  }

  // ============================================================
  // 기기 감지
  // ============================================================

  static DeviceTier _detectTier() {
    final deviceInfo = info;

    // RAM 기반 티어 분류
    if (deviceInfo.ramGB >= 8) {
      return DeviceTier.high;
    } else if (deviceInfo.ramGB >= 4) {
      return DeviceTier.mid;
    } else {
      return DeviceTier.low;
    }
  }

  static DeviceInfo _detectInfo() {
    // 플랫폼별 기본값
    if (kIsWeb) {
      return const DeviceInfo(
        platform: DevicePlatform.web,
        ramGB: 4,
        isTablet: false,
        screenDensity: 2.0,
      );
    }

    if (Platform.isAndroid) {
      return _detectAndroidInfo();
    } else if (Platform.isIOS) {
      return _detectIOSInfo();
    }

    return const DeviceInfo(
      platform: DevicePlatform.other,
      ramGB: 4,
      isTablet: false,
      screenDensity: 2.0,
    );
  }

  static DeviceInfo _detectAndroidInfo() {
    // Android 기기 정보 (실제로는 device_info_plus 패키지 사용 권장)
    // 여기서는 기본값 반환
    return const DeviceInfo(
      platform: DevicePlatform.android,
      ramGB: 4, // 기본 4GB 가정
      isTablet: false,
      screenDensity: 2.0,
    );
  }

  static DeviceInfo _detectIOSInfo() {
    // iOS 기기 정보
    return const DeviceInfo(
      platform: DevicePlatform.ios,
      ramGB: 4, // iPhone 기본 4GB 가정
      isTablet: false,
      screenDensity: 3.0, // Retina
    );
  }

  // ============================================================
  // 성능 추정
  // ============================================================

  /// GPU 성능 추정 (0.0 ~ 1.0)
  static double get estimatedGpuPerformance {
    switch (tier) {
      case DeviceTier.high:
        return 1.0;
      case DeviceTier.mid:
        return 0.6;
      case DeviceTier.low:
        return 0.3;
    }
  }

  /// CPU 성능 추정 (0.0 ~ 1.0)
  static double get estimatedCpuPerformance {
    switch (tier) {
      case DeviceTier.high:
        return 1.0;
      case DeviceTier.mid:
        return 0.6;
      case DeviceTier.low:
        return 0.3;
    }
  }

  /// 권장 FPS
  static int get recommendedFps {
    switch (tier) {
      case DeviceTier.high:
        return 60;
      case DeviceTier.mid:
        return 45;
      case DeviceTier.low:
        return 30;
    }
  }

  /// 권장 텍스처 품질
  static TextureQuality get recommendedTextureQuality {
    switch (tier) {
      case DeviceTier.high:
        return TextureQuality.high;
      case DeviceTier.mid:
        return TextureQuality.medium;
      case DeviceTier.low:
        return TextureQuality.low;
    }
  }
}

/// 기기 티어
enum DeviceTier {
  /// 저사양 (RAM < 4GB)
  low,

  /// 중사양 (4GB <= RAM < 8GB)
  mid,

  /// 고사양 (RAM >= 8GB)
  high,
}

extension DeviceTierExtension on DeviceTier {
  /// 티어 이름
  String get displayName {
    switch (this) {
      case DeviceTier.low:
        return '저사양';
      case DeviceTier.mid:
        return '중사양';
      case DeviceTier.high:
        return '고사양';
    }
  }

  /// 티어 인덱스 (0 = low, 1 = mid, 2 = high)
  int get index {
    switch (this) {
      case DeviceTier.low:
        return 0;
      case DeviceTier.mid:
        return 1;
      case DeviceTier.high:
        return 2;
    }
  }

  /// 성능 배수 (low = 0.5, mid = 1.0, high = 1.5)
  double get performanceMultiplier {
    switch (this) {
      case DeviceTier.low:
        return 0.5;
      case DeviceTier.mid:
        return 1.0;
      case DeviceTier.high:
        return 1.5;
    }
  }
}

/// 기기 플랫폼
enum DevicePlatform {
  android,
  ios,
  web,
  other,
}

/// 기기 정보
class DeviceInfo {
  final DevicePlatform platform;
  final double ramGB;
  final bool isTablet;
  final double screenDensity;

  const DeviceInfo({
    required this.platform,
    required this.ramGB,
    required this.isTablet,
    required this.screenDensity,
  });

  /// 메모리 충분 여부 (4GB 이상)
  bool get hasEnoughMemory => ramGB >= 4;

  /// 고해상도 화면 여부
  bool get isHighDensity => screenDensity >= 2.5;

  /// 모바일 플랫폼 여부
  bool get isMobile =>
      platform == DevicePlatform.android || platform == DevicePlatform.ios;
}

/// 텍스처 품질
enum TextureQuality {
  low,
  medium,
  high,
}

extension TextureQualityExtension on TextureQuality {
  /// 품질 배수
  double get scaleFactor {
    switch (this) {
      case TextureQuality.low:
        return 0.5;
      case TextureQuality.medium:
        return 0.75;
      case TextureQuality.high:
        return 1.0;
    }
  }

  /// 표시 이름
  String get displayName {
    switch (this) {
      case TextureQuality.low:
        return '낮음';
      case TextureQuality.medium:
        return '중간';
      case TextureQuality.high:
        return '높음';
    }
  }
}

/// 기기 성능 테스트 결과
class PerformanceTestResult {
  final double averageFps;
  final double minFps;
  final double maxFps;
  final int droppedFrames;
  final Duration testDuration;

  const PerformanceTestResult({
    required this.averageFps,
    required this.minFps,
    required this.maxFps,
    required this.droppedFrames,
    required this.testDuration,
  });

  /// 권장 티어 계산
  DeviceTier get recommendedTier {
    if (averageFps >= 55 && minFps >= 45) {
      return DeviceTier.high;
    } else if (averageFps >= 40 && minFps >= 25) {
      return DeviceTier.mid;
    } else {
      return DeviceTier.low;
    }
  }
}
