import 'device_capability.dart';

/// MG-Games 품질 설정
/// DEVICE_OPTIMIZATION_GUIDE.md 기반
class MGQualitySettings {
  // ============================================================
  // 그래픽 설정
  // ============================================================

  /// 파티클 품질 (0.0 ~ 1.0)
  final double particleQuality;

  /// 파티클 최대 개수
  final int maxParticles;

  /// 텍스처 품질
  final TextureQuality textureQuality;

  /// 그림자 활성화
  final bool shadowsEnabled;

  /// 그림자 품질 (0.0 ~ 1.0)
  final double shadowQuality;

  /// 포스트 프로세싱 활성화
  final bool postProcessingEnabled;

  /// 안티앨리어싱 활성화
  final bool antiAliasingEnabled;

  // ============================================================
  // 성능 설정
  // ============================================================

  /// 목표 FPS
  final int targetFps;

  /// 배경 업데이트 간격 (ms)
  final int backgroundUpdateInterval;

  /// 물리 업데이트 간격 (ms)
  final int physicsUpdateInterval;

  /// AI 업데이트 간격 (ms)
  final int aiUpdateInterval;

  // ============================================================
  // 메모리 설정
  // ============================================================

  /// 이미지 캐시 크기 (MB)
  final int imageCacheSizeMB;

  /// 텍스처 캐시 크기 (MB)
  final int textureCacheSizeMB;

  /// 오디오 캐시 크기 (MB)
  final int audioCacheSizeMB;

  const MGQualitySettings({
    // 그래픽
    this.particleQuality = 1.0,
    this.maxParticles = 500,
    this.textureQuality = TextureQuality.high,
    this.shadowsEnabled = true,
    this.shadowQuality = 1.0,
    this.postProcessingEnabled = true,
    this.antiAliasingEnabled = true,
    // 성능
    this.targetFps = 60,
    this.backgroundUpdateInterval = 16,
    this.physicsUpdateInterval = 16,
    this.aiUpdateInterval = 33,
    // 메모리
    this.imageCacheSizeMB = 100,
    this.textureCacheSizeMB = 50,
    this.audioCacheSizeMB = 20,
  });

  // ============================================================
  // 프리셋
  // ============================================================

  /// 저사양 프리셋
  static const MGQualitySettings low = MGQualitySettings(
    particleQuality: 0.3,
    maxParticles: 100,
    textureQuality: TextureQuality.low,
    shadowsEnabled: false,
    shadowQuality: 0.0,
    postProcessingEnabled: false,
    antiAliasingEnabled: false,
    targetFps: 30,
    backgroundUpdateInterval: 50,
    physicsUpdateInterval: 33,
    aiUpdateInterval: 100,
    imageCacheSizeMB: 30,
    textureCacheSizeMB: 15,
    audioCacheSizeMB: 10,
  );

  /// 중사양 프리셋
  static const MGQualitySettings medium = MGQualitySettings(
    particleQuality: 0.6,
    maxParticles: 300,
    textureQuality: TextureQuality.medium,
    shadowsEnabled: true,
    shadowQuality: 0.5,
    postProcessingEnabled: false,
    antiAliasingEnabled: true,
    targetFps: 45,
    backgroundUpdateInterval: 33,
    physicsUpdateInterval: 20,
    aiUpdateInterval: 50,
    imageCacheSizeMB: 60,
    textureCacheSizeMB: 30,
    audioCacheSizeMB: 15,
  );

  /// 고사양 프리셋
  static const MGQualitySettings high = MGQualitySettings(
    particleQuality: 1.0,
    maxParticles: 500,
    textureQuality: TextureQuality.high,
    shadowsEnabled: true,
    shadowQuality: 1.0,
    postProcessingEnabled: true,
    antiAliasingEnabled: true,
    targetFps: 60,
    backgroundUpdateInterval: 16,
    physicsUpdateInterval: 16,
    aiUpdateInterval: 33,
    imageCacheSizeMB: 100,
    textureCacheSizeMB: 50,
    audioCacheSizeMB: 20,
  );

  /// 배터리 절약 프리셋
  static const MGQualitySettings batterySaver = MGQualitySettings(
    particleQuality: 0.2,
    maxParticles: 50,
    textureQuality: TextureQuality.low,
    shadowsEnabled: false,
    shadowQuality: 0.0,
    postProcessingEnabled: false,
    antiAliasingEnabled: false,
    targetFps: 30,
    backgroundUpdateInterval: 100,
    physicsUpdateInterval: 50,
    aiUpdateInterval: 150,
    imageCacheSizeMB: 20,
    textureCacheSizeMB: 10,
    audioCacheSizeMB: 5,
  );

  /// 기기 티어에 맞는 프리셋 가져오기
  static MGQualitySettings forTier(DeviceTier tier) {
    switch (tier) {
      case DeviceTier.low:
        return low;
      case DeviceTier.mid:
        return medium;
      case DeviceTier.high:
        return high;
    }
  }

  /// 현재 기기에 맞는 프리셋 가져오기
  static MGQualitySettings forCurrentDevice() {
    return forTier(MGDeviceCapability.tier);
  }

  // ============================================================
  // 복사
  // ============================================================

  MGQualitySettings copyWith({
    double? particleQuality,
    int? maxParticles,
    TextureQuality? textureQuality,
    bool? shadowsEnabled,
    double? shadowQuality,
    bool? postProcessingEnabled,
    bool? antiAliasingEnabled,
    int? targetFps,
    int? backgroundUpdateInterval,
    int? physicsUpdateInterval,
    int? aiUpdateInterval,
    int? imageCacheSizeMB,
    int? textureCacheSizeMB,
    int? audioCacheSizeMB,
  }) {
    return MGQualitySettings(
      particleQuality: particleQuality ?? this.particleQuality,
      maxParticles: maxParticles ?? this.maxParticles,
      textureQuality: textureQuality ?? this.textureQuality,
      shadowsEnabled: shadowsEnabled ?? this.shadowsEnabled,
      shadowQuality: shadowQuality ?? this.shadowQuality,
      postProcessingEnabled:
          postProcessingEnabled ?? this.postProcessingEnabled,
      antiAliasingEnabled: antiAliasingEnabled ?? this.antiAliasingEnabled,
      targetFps: targetFps ?? this.targetFps,
      backgroundUpdateInterval:
          backgroundUpdateInterval ?? this.backgroundUpdateInterval,
      physicsUpdateInterval:
          physicsUpdateInterval ?? this.physicsUpdateInterval,
      aiUpdateInterval: aiUpdateInterval ?? this.aiUpdateInterval,
      imageCacheSizeMB: imageCacheSizeMB ?? this.imageCacheSizeMB,
      textureCacheSizeMB: textureCacheSizeMB ?? this.textureCacheSizeMB,
      audioCacheSizeMB: audioCacheSizeMB ?? this.audioCacheSizeMB,
    );
  }

  // ============================================================
  // JSON 변환
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'particleQuality': particleQuality,
      'maxParticles': maxParticles,
      'textureQuality': textureQuality.index,
      'shadowsEnabled': shadowsEnabled,
      'shadowQuality': shadowQuality,
      'postProcessingEnabled': postProcessingEnabled,
      'antiAliasingEnabled': antiAliasingEnabled,
      'targetFps': targetFps,
      'backgroundUpdateInterval': backgroundUpdateInterval,
      'physicsUpdateInterval': physicsUpdateInterval,
      'aiUpdateInterval': aiUpdateInterval,
      'imageCacheSizeMB': imageCacheSizeMB,
      'textureCacheSizeMB': textureCacheSizeMB,
      'audioCacheSizeMB': audioCacheSizeMB,
    };
  }

  factory MGQualitySettings.fromJson(Map<String, dynamic> json) {
    return MGQualitySettings(
      particleQuality: json['particleQuality'] ?? 1.0,
      maxParticles: json['maxParticles'] ?? 500,
      textureQuality: TextureQuality.values[json['textureQuality'] ?? 2],
      shadowsEnabled: json['shadowsEnabled'] ?? true,
      shadowQuality: json['shadowQuality'] ?? 1.0,
      postProcessingEnabled: json['postProcessingEnabled'] ?? true,
      antiAliasingEnabled: json['antiAliasingEnabled'] ?? true,
      targetFps: json['targetFps'] ?? 60,
      backgroundUpdateInterval: json['backgroundUpdateInterval'] ?? 16,
      physicsUpdateInterval: json['physicsUpdateInterval'] ?? 16,
      aiUpdateInterval: json['aiUpdateInterval'] ?? 33,
      imageCacheSizeMB: json['imageCacheSizeMB'] ?? 100,
      textureCacheSizeMB: json['textureCacheSizeMB'] ?? 50,
      audioCacheSizeMB: json['audioCacheSizeMB'] ?? 20,
    );
  }
}

/// 품질 레벨
enum QualityLevel {
  low,
  medium,
  high,
  ultra,
}

extension QualityLevelExtension on QualityLevel {
  /// 표시 이름
  String get displayName {
    switch (this) {
      case QualityLevel.low:
        return '낮음';
      case QualityLevel.medium:
        return '중간';
      case QualityLevel.high:
        return '높음';
      case QualityLevel.ultra:
        return '최고';
    }
  }

  /// 품질 설정 가져오기
  MGQualitySettings get settings {
    switch (this) {
      case QualityLevel.low:
        return MGQualitySettings.low;
      case QualityLevel.medium:
        return MGQualitySettings.medium;
      case QualityLevel.high:
        return MGQualitySettings.high;
      case QualityLevel.ultra:
        return MGQualitySettings.high.copyWith(
          maxParticles: 1000,
          targetFps: 120,
        );
    }
  }
}
