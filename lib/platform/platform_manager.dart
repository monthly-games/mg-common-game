import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 플랫폼 타입
enum PlatformType {
  android,        // 안드로이드
  ios,            // iOS
  web,            // 웹
  windows,        // 윈도우
  macos,          // macOS
  linux,          // 리눅스
}

/// 입력 타입
enum InputType {
  touch,          // 터치
  mouse,          // 마우스
  keyboard,       // 키보드
  gamepad,        // 게임패드
  gesture,        // 제스처
  voice,          // 음성
}

/// 화면 크기 카테고리
enum ScreenSize {
  small,          // 소형 (< 5인치)
  normal,         // 일반 (5-7인치)
  large,          // 대형 (7-10인치)
  xlarge,         // 초대형 (> 10인치)
}

/// 해상도 등급
enum Density {
  ldpi,           // ~120dpi
  mdpi,           // ~160dpi
  hdpi,           // ~240dpi
  xhdpi,          // ~320dpi
  xxhdpi,         // ~480dpi
  xxxhdpi,        // ~640dpi
}

/// 디바이스 성능 등급
enum PerformanceTier {
  low,            // 저성능
  medium,         // 중성능
  high,           // 고성능
  ultra,          // 초고성능
}

/// 플랫폼 기능
enum PlatformCapability {
  pushNotifications,     // 푸시 알림
  inAppPurchases,        // 인앱 결제
  biometricAuth,         // 생체 인증
  backgroundTasks,       // 백그라운드 작업
  fileAccess,            // 파일 접근
  camera,                // 카메라
  microphone,            // 마이크
  gps,                   // GPS
  bluetooth,             // 블루투스
  nfc,                   // NFC
  hapticFeedback,        // 햅틱 피드백
  pictureInPicture,      // PIP
  splitScreen,           // 분할 화면
  externalStorage,       // 외부 저장소
  cloudSave,             // 클라우드 저장
  crossPlatformSync,     // 크로스 플랫폼 동기화
}

/// 플랫폼 설정
class PlatformConfig {
  final PlatformType platform;
  final String platformVersion;
  final ScreenSize screenSize;
  final Density density;
  final PerformanceTier performanceTier;
  final List<InputType> supportedInputs;
  final List<PlatformCapability> capabilities;
  final Size resolution;
  final double devicePixelRatio;
  final int ramMB;
  final int cpuCores;
  final String? deviceModel;
  final Map<String, dynamic> customSettings;

  const PlatformConfig({
    required this.platform,
    required this.platformVersion,
    required this.screenSize,
    required this.density,
    required this.performanceTier,
    required this.supportedInputs,
    required this.capabilities,
    required this.resolution,
    required this.devicePixelRatio,
    required this.ramMB,
    required this.cpuCores,
    this.deviceModel,
    this.customSettings = const {},
  });

  /// 모바일 플랫폼인지
  bool get isMobile =>
      platform == PlatformType.android ||
      platform == PlatformType.ios;

  /// 데스크톱 플랫폼인지
  bool get isDesktop =>
      platform == PlatformType.windows ||
      platform == PlatformType.macos ||
      platform == PlatformType.linux;

  /// 터치 입력 지원 여부
  bool get hasTouch => supportedInputs.contains(InputType.touch);

  /// 기능 지원 여부
  bool hasCapability(PlatformCapability capability) =>
      capabilities.contains(capability);
}

/// 플랫폼별 최적화 설정
class OptimizationSettings {
  final PerformanceTier performanceTier;
  final bool enableHighQualityGraphics;
  final int maxTextureQuality;
  final bool enableParticles;
  final bool enableShadows;
  final int maxParticleCount;
  final double targetFrameRate;
  final bool enableVSync;
  final bool enableSoundEffects;
  final bool enableBackgroundMusic;
  final int maxConcurrentSounds;

  const OptimizationSettings({
    required this.performanceTier,
    required this.enableHighQualityGraphics,
    required this.maxTextureQuality,
    required this.enableParticles,
    required this.enableShadows,
    required this.maxParticleCount,
    required this.targetFrameRate,
    required this.enableVSync,
    required this.enableSoundEffects,
    required this.enableBackgroundMusic,
    required this.maxConcurrentSounds,
  });

  /// 성능 등급별 설정 생성
  factory OptimizationSettings.forTier(PerformanceTier tier) {
    switch (tier) {
      case PerformanceTier.low:
        return const OptimizationSettings(
          performanceTier: PerformanceTier.low,
          enableHighQualityGraphics: false,
          maxTextureQuality: 512,
          enableParticles: false,
          enableShadows: false,
          maxParticleCount: 10,
          targetFrameRate: 30,
          enableVSync: false,
          enableSoundEffects: true,
          enableBackgroundMusic: false,
          maxConcurrentSounds: 4,
        );

      case PerformanceTier.medium:
        return const OptimizationSettings(
          performanceTier: PerformanceTier.medium,
          enableHighQualityGraphics: false,
          maxTextureQuality: 1024,
          enableParticles: true,
          enableShadows: false,
          maxParticleCount: 50,
          targetFrameRate: 60,
          enableVSync: true,
          enableSoundEffects: true,
          enableBackgroundMusic: true,
          maxConcurrentSounds: 8,
        );

      case PerformanceTier.high:
        return const OptimizationSettings(
          performanceTier: PerformanceTier.high,
          enableHighQualityGraphics: true,
          maxTextureQuality: 2048,
          enableParticles: true,
          enableShadows: true,
          maxParticleCount: 100,
          targetFrameRate: 60,
          enableVSync: true,
          enableSoundEffects: true,
          enableBackgroundMusic: true,
          maxConcurrentSounds: 16,
        );

      case PerformanceTier.ultra:
        return const OptimizationSettings(
          performanceTier: PerformanceTier.ultra,
          enableHighQualityGraphics: true,
          maxTextureQuality: 4096,
          enableParticles: true,
          enableShadows: true,
          maxParticleCount: 200,
          targetFrameRate: 120,
          enableVSync: true,
          enableSoundEffects: true,
          enableBackgroundMusic: true,
          maxConcurrentSounds: 32,
        );
    }
  }
}

/// 크로스 플랫폼 저장소
class CrossPlatformStorage {
  final String platformId;
  final Map<String, dynamic> data;
  final DateTime lastSynced;

  const CrossPlatformStorage({
    required this.platformId,
    required this.data,
    required this.lastSynced,
  });
}

/// 플랫폼 관리자
class PlatformManager {
  static final PlatformManager _instance = PlatformManager._();
  static PlatformManager get instance => _instance;

  PlatformManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  PlatformConfig? _currentConfig;
  OptimizationSettings? _optimizationSettings;

  final Map<String, CrossPlatformStorage> _cloudSaves = {};

  final StreamController<PlatformConfig> _configController =
      StreamController<PlatformConfig>.broadcast();
  final StreamController<OptimizationSettings> _optimizationController =
      StreamController<OptimizationSettings>.broadcast();

  Stream<PlatformConfig> get onConfigUpdate => _configController.stream;
  Stream<OptimizationSettings> get onOptimizationChange =>
      _optimizationController.stream;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 플랫폼 감지
    await _detectPlatform();

    // 설정 로드
    await _loadSettings();

    // 최적화 설정 적용
    _applyOptimizationSettings();

    debugPrint('[Platform] Initialized: ${_currentConfig?.platform.name}');
  }

  Future<void> _detectPlatform() async {
    PlatformType platform;
    String version = 'unknown';

    if (Platform.isAndroid) {
      platform = PlatformType.android;
      // 안드로이드 버전 가져오기
      version = '13'; // 예시
    } else if (Platform.isIOS) {
      platform = PlatformType.ios;
      version = '16'; // 예시
    } else if (Platform.isWindows) {
      platform = PlatformType.windows;
      version = '10';
    } else if (Platform.isMacOS) {
      platform = PlatformType.macos;
      version = '13';
    } else if (Platform.isLinux) {
      platform = PlatformType.linux;
      version = 'unknown';
    } else {
      platform = PlatformType.web;
      version = 'latest';
    }

    // 디바이스 정보 수집 (실제로는 platform_info 패키지 등 사용)
    final screenSize = await _detectScreenSize();
    final density = await _detectDensity();
    final performanceTier = await _detectPerformanceTier();
    final supportedInputs = await _detectSupportedInputs(platform);
    final capabilities = await _detectCapabilities(platform);
    final resolution = await _detectResolution();
    final devicePixelRatio = await _detectDevicePixelRatio();
    final ramMB = await _detectRAM();
    final cpuCores = await _detectCPUCores();

    _currentConfig = PlatformConfig(
      platform: platform,
      platformVersion: version,
      screenSize: screenSize,
      density: density,
      performanceTier: performanceTier,
      supportedInputs: supportedInputs,
      capabilities: capabilities,
      resolution: resolution,
      devicePixelRatio: devicePixelRatio,
      ramMB: ramMB,
      cpuCores: cpuCores,
      deviceModel: platform.name,
    );
  }

  Future<ScreenSize> _detectScreenSize() async {
    // 실제로는 MediaQuery 등 사용
    return ScreenSize.normal;
  }

  Future<Density> _detectDensity() async {
    // 실제로는 devicePixelRatio 사용
    return Density.xhdpi;
  }

  Future<PerformanceTier> _detectPerformanceTier() async {
    // RAM, CPU, GPU 등 기반 판별
    final ramMB = await _detectRAM();
    final cpuCores = await _detectCPUCores();

    if (ramMB >= 8192 && cpuCores >= 8) {
      return PerformanceTier.ultra;
    } else if (ramMB >= 6144 && cpuCores >= 6) {
      return PerformanceTier.high;
    } else if (ramMB >= 3072 && cpuCores >= 4) {
      return PerformanceTier.medium;
    } else {
      return PerformanceTier.low;
    }
  }

  Future<List<InputType>> _detectSupportedInputs(PlatformType platform) async {
    final inputs = <InputType>[];

    if (platform == PlatformType.android || platform == PlatformType.ios) {
      inputs.addAll([InputType.touch, InputType.gesture]);
      inputs.add(InputType.keyboard); // 가상 키보드
    } else {
      inputs.addAll([InputType.mouse, InputType.keyboard]);
    }

    // 게임패드 지원 (모든 플랫폼)
    inputs.add(InputType.gamepad);

    return inputs;
  }

  Future<List<PlatformCapability>> _detectCapabilities(
      PlatformType platform) async {
    final capabilities = <PlatformCapability>[];

    switch (platform) {
      case PlatformType.android:
      case PlatformType.ios:
        capabilities.addAll([
          PlatformCapability.pushNotifications,
          PlatformCapability.inAppPurchases,
          PlatformCapability.biometricAuth,
          PlatformCapability.camera,
          PlatformCapability.microphone,
          PlatformCapability.gps,
          PlatformCapability.bluetooth,
          PlatformCapability.hapticFeedback,
          PlatformCapability.cloudSave,
        ]);
        break;

      case PlatformType.web:
        capabilities.addAll([
          PlatformCapability.pushNotifications,
          PlatformCapability.camera,
          PlatformCapability.microphone,
          PlatformCapability.gps,
          PlatformCapability.cloudSave,
          PlatformCapability.crossPlatformSync,
        ]);
        break;

      case PlatformType.windows:
      case PlatformType.macos:
      case PlatformType.linux:
        capabilities.addAll([
          PlatformCapability.fileAccess,
          PlatformCapability.camera,
          PlatformCapability.microphone,
          PlatformCapability.cloudSave,
          PlatformCapability.crossPlatformSync,
          PlatformCapability.pictureInPicture,
        ]);
        break;
    }

    return capabilities;
  }

  Future<Size> _detectResolution() async {
    // 실제로는 MediaQuery 사용
    return const Size(1920, 1080);
  }

  Future<double> _detectDevicePixelRatio() async {
    // 실제로는 MediaQuery 사용
    return 2.0;
  }

  Future<int> _detectRAM() async {
    // 실제로는 device_info 등 사용
    return 4096; // MB
  }

  Future<int> _detectCPUCores() async {
    // 실제로는 device_info 등 사용
    return 4;
  }

  Future<void> _loadSettings() async {
    // 저장된 설정 로드
    final json = _prefs?.getString('platform_settings');

    if (json != null) {
      try {
        final data = jsonDecode(json) as Map<String, dynamic>;
        // 파싱
      } catch (e) {
        debugPrint('[Platform] Error loading settings: $e');
      }
    }
  }

  void _applyOptimizationSettings() {
    if (_currentConfig == null) return;

    _optimizationSettings =
        OptimizationSettings.forTier(_currentConfig!.performanceTier);

    _optimizationController.add(_optimizationSettings!);
  }

  /// 현재 플랫폼 설정
  PlatformConfig? get currentConfig => _currentConfig;

  /// 최적화 설정
  OptimizationSettings? get optimizationSettings => _optimizationSettings;

  /// 플랫폼별 UI 조정
  double getScaledFontSize(double baseFontSize) {
    if (_currentConfig == null) return baseFontSize;

    final scale = switch (_currentConfig!.screenSize) {
      ScreenSize.small => 0.85,
      ScreenSize.normal => 1.0,
      ScreenSize.large => 1.15,
      ScreenSize.xlarge => 1.3,
    };

    return baseFontSize * scale;
  }

  /// 플랫폼별 패딩 조정
  EdgeInsets getScaledPadding(EdgeInsets basePadding) {
    if (_currentConfig == null) return basePadding;

    final scale = switch (_currentConfig!.screenSize) {
      ScreenSize.small => 0.8,
      ScreenSize.normal => 1.0,
      ScreenSize.large => 1.2,
      ScreenSize.xlarge => 1.4,
    };

    return EdgeInsets.fromLTRB(
      basePadding.left * scale,
      basePadding.top * scale,
      basePadding.right * scale,
      basePadding.bottom * scale,
    );
  }

  /// 입력 타입 지원 여부
  bool supportsInput(InputType inputType) {
    return _currentConfig?.supportedInputs.contains(inputType) ?? false;
  }

  /// 기능 지원 여부
  bool supportsCapability(PlatformCapability capability) {
    return _currentConfig?.hasCapability(capability) ?? false;
  }

  /// 성능 등급 변경
  Future<void> setPerformanceTier(PerformanceTier tier) async {
    if (_currentConfig == null) return;

    _optimizationSettings = OptimizationSettings.forTier(tier);

    await _prefs?.setString('performance_tier', tier.name);

    _optimizationController.add(_optimizationSettings!);

    debugPrint('[Platform] Performance tier: ${tier.name}');
  }

  /// 크로스 플랫폼 저장소 동기화
  Future<void> syncToCloud(Map<String, dynamic> data) async {
    if (_currentConfig == null) return;
    if (_currentUserId == null) return;

    final storage = CrossPlatformStorage(
      platformId: _currentConfig!.platform.name,
      data: data,
      lastSynced: DateTime.now(),
    );

    _cloudSaves['$_currentUserId:${_currentConfig!.platform.name}'] = storage;

    await _saveCloudStorage();

    debugPrint('[Platform] Synced to cloud');
  }

  /// 클라우드에서 저장소 로드
  Future<Map<String, dynamic>?> loadFromCloud() async {
    if (_currentUserId == null) return null;

    await _loadCloudStorage();

    // 현재 플랫폼 저장소 찾기
    for (final entry in _cloudSaves.entries) {
      if (entry.key.startsWith(_currentUserId!)) {
        return entry.value.data;
      }
    }

    return null;
  }

  /// 모든 플랫폼 저장소 목록
  Future<List<CrossPlatformStorage>> getAllCloudSaves() async {
    if (_currentUserId == null) return [];

    await _loadCloudStorage();

    return _cloudSaves.entries
        .where((e) => e.key.startsWith(_currentUserId!))
        .map((e) => e.value)
        .toList();
  }

  Future<void> _saveCloudStorage() async {
    final data = _cloudSaves.map((key, value) => MapEntry(
      key,
      {
        'platformId': value.platformId,
        'data': value.data,
        'lastSynced': value.lastSynced.toIso8601String(),
      },
    ));

    await _prefs?.setString('cloud_saves', jsonEncode(data));
  }

  Future<void> _loadCloudStorage() async {
    final json = _prefs?.getString('cloud_saves');

    if (json != null) {
      try {
        final data = jsonDecode(json) as Map<String, dynamic>;
        // 파싱
      } catch (e) {
        debugPrint('[Platform] Error loading cloud saves: $e');
      }
    }
  }

  /// 플랫폼별 특수 처리
  Map<String, dynamic> getPlatformSpecificOverrides() {
    if (_currentConfig == null) return {};

    switch (_currentConfig!.platform) {
      case PlatformType.android:
        return {
          'use_material_you': true,
          'back_button_behavior': 'system',
          'navigation_bar': 'gesture',
        };

      case PlatformType.ios:
        return {
          'use_cupertino': true,
          'back_button_behavior': 'swipe',
          'safe_area': true,
        };

      case PlatformType.web:
        return {
          'pwa_supported': true,
          'keyboard_shortcuts': true,
        };

      case PlatformType.windows:
      case PlatformType.macos:
      case PlatformType.linux:
        return {
          'keyboard_shortcuts': true,
          'mouse_hover': true,
          'window_resizeable': true,
        };
    }
  }

  void dispose() {
    _configController.close();
    _optimizationController.close();
  }
}
