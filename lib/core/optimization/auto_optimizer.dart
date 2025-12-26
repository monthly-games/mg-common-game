import 'dart:async';
import 'package:flutter/foundation.dart';
import 'device_capability.dart';
import 'quality_settings.dart';
import 'performance_monitor.dart';

/// 자동 최적화 모드
enum OptimizationMode {
  /// 수동 (사용자가 직접 설정)
  manual,

  /// 자동 (성능에 따라 자동 조절)
  automatic,

  /// 배터리 절약 (최저 품질)
  batterySaver,

  /// 성능 우선 (최고 품질)
  performance,
}

/// 자동 최적화 설정
class AutoOptimizerConfig {
  /// 성능 체크 간격 (초)
  final int checkIntervalSeconds;

  /// FPS 목표
  final int targetFps;

  /// 품질 낮춤 트리거 FPS
  final int downgradeThresholdFps;

  /// 품질 높임 트리거 FPS
  final int upgradeThresholdFps;

  /// 드롭 프레임 비율 허용치
  final double maxDropRate;

  /// 연속 체크 횟수 (품질 변경 전)
  final int requiredConsecutiveChecks;

  const AutoOptimizerConfig({
    this.checkIntervalSeconds = 5,
    this.targetFps = 60,
    this.downgradeThresholdFps = 45,
    this.upgradeThresholdFps = 58,
    this.maxDropRate = 0.05,
    this.requiredConsecutiveChecks = 3,
  });
}

/// 자동 최적화 매니저
/// 실시간 성능 모니터링 및 품질 자동 조절
class MGAutoOptimizer extends ChangeNotifier {
  MGAutoOptimizer._();

  static MGAutoOptimizer? _instance;
  static MGAutoOptimizer get instance {
    _instance ??= MGAutoOptimizer._();
    return _instance!;
  }

  // 설정
  AutoOptimizerConfig _config = const AutoOptimizerConfig();
  OptimizationMode _mode = OptimizationMode.automatic;
  MGQualitySettings _currentSettings = MGQualitySettings.medium;

  // 상태
  bool _isRunning = false;
  Timer? _checkTimer;
  int _consecutiveLowFps = 0;
  int _consecutiveHighFps = 0;
  final List<double> _fpsHistory = [];
  static const int _historySize = 10;

  // 콜백
  Function(MGQualitySettings)? onSettingsChanged;
  Function(String)? onOptimizationEvent;

  // Getters
  AutoOptimizerConfig get config => _config;
  OptimizationMode get mode => _mode;
  MGQualitySettings get currentSettings => _currentSettings;
  bool get isRunning => _isRunning;
  List<double> get fpsHistory => List.unmodifiable(_fpsHistory);

  /// 설정 업데이트
  void updateConfig(AutoOptimizerConfig config) {
    _config = config;
    notifyListeners();
  }

  /// 모드 설정
  void setMode(OptimizationMode mode) {
    _mode = mode;

    switch (mode) {
      case OptimizationMode.manual:
        stop();
        break;
      case OptimizationMode.automatic:
        start();
        break;
      case OptimizationMode.batterySaver:
        stop();
        _applySettings(MGQualitySettings.batterySaver);
        break;
      case OptimizationMode.performance:
        stop();
        _applySettings(MGQualitySettings.high);
        break;
    }

    notifyListeners();
  }

  /// 자동 최적화 시작
  void start() {
    if (_isRunning) return;
    _isRunning = true;

    // 성능 모니터 시작
    MGPerformanceMonitor.instance.start();

    // 초기 설정 (기기 티어 기반)
    _currentSettings = MGQualitySettings.forCurrentDevice();
    _applySettings(_currentSettings);

    // 정기 체크 시작
    _checkTimer = Timer.periodic(
      Duration(seconds: _config.checkIntervalSeconds),
      (_) => _performCheck(),
    );

    onOptimizationEvent?.call('Auto-optimization started');
    notifyListeners();
  }

  /// 자동 최적화 중지
  void stop() {
    if (!_isRunning) return;
    _isRunning = false;

    _checkTimer?.cancel();
    _checkTimer = null;

    _consecutiveLowFps = 0;
    _consecutiveHighFps = 0;
    _fpsHistory.clear();

    onOptimizationEvent?.call('Auto-optimization stopped');
    notifyListeners();
  }

  /// 성능 체크 및 최적화
  void _performCheck() {
    if (_mode != OptimizationMode.automatic) return;

    final monitor = MGPerformanceMonitor.instance;
    final fps = monitor.averageFps;
    final dropRate = monitor.dropRate;

    // FPS 히스토리 업데이트
    _fpsHistory.add(fps);
    if (_fpsHistory.length > _historySize) {
      _fpsHistory.removeAt(0);
    }

    // 평균 FPS 계산
    final avgFps = _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;

    // 품질 다운그레이드 체크
    if (avgFps < _config.downgradeThresholdFps ||
        dropRate > _config.maxDropRate) {
      _consecutiveLowFps++;
      _consecutiveHighFps = 0;

      if (_consecutiveLowFps >= _config.requiredConsecutiveChecks) {
        _downgradeQuality();
        _consecutiveLowFps = 0;
      }
    }
    // 품질 업그레이드 체크
    else if (avgFps >= _config.upgradeThresholdFps && dropRate < 0.02) {
      _consecutiveHighFps++;
      _consecutiveLowFps = 0;

      if (_consecutiveHighFps >= _config.requiredConsecutiveChecks) {
        _upgradeQuality();
        _consecutiveHighFps = 0;
      }
    }
    // 안정 상태
    else {
      _consecutiveLowFps = 0;
      _consecutiveHighFps = 0;
    }

    notifyListeners();
  }

  /// 품질 다운그레이드
  void _downgradeQuality() {
    MGQualitySettings? newSettings;

    // 현재 설정에서 한 단계 낮춤
    if (_currentSettings.targetFps >= 60) {
      newSettings = _currentSettings.copyWith(
        targetFps: 45,
        particleQuality: (_currentSettings.particleQuality * 0.7).clamp(0.2, 1.0),
        maxParticles: (_currentSettings.maxParticles * 0.7).toInt(),
        shadowsEnabled: false,
        postProcessingEnabled: false,
      );
    } else if (_currentSettings.targetFps >= 45) {
      newSettings = _currentSettings.copyWith(
        targetFps: 30,
        particleQuality: (_currentSettings.particleQuality * 0.5).clamp(0.2, 1.0),
        maxParticles: (_currentSettings.maxParticles * 0.5).toInt(),
        antiAliasingEnabled: false,
      );
    } else {
      // 이미 최저 품질
      newSettings = MGQualitySettings.batterySaver;
    }

    _applySettings(newSettings);
    onOptimizationEvent?.call('Quality downgraded due to low FPS');
  }

  /// 품질 업그레이드
  void _upgradeQuality() {
    final deviceTier = MGDeviceCapability.tier;
    final maxSettings = MGQualitySettings.forTier(deviceTier);

    // 현재 설정이 이미 최대인 경우 스킵
    if (_currentSettings.targetFps >= maxSettings.targetFps &&
        _currentSettings.particleQuality >= maxSettings.particleQuality) {
      return;
    }

    MGQualitySettings newSettings;

    // 현재 설정에서 한 단계 높임
    if (_currentSettings.targetFps <= 30) {
      newSettings = _currentSettings.copyWith(
        targetFps: 45,
        particleQuality: (_currentSettings.particleQuality * 1.3).clamp(0.2, maxSettings.particleQuality),
        maxParticles: (_currentSettings.maxParticles * 1.3).toInt().clamp(50, maxSettings.maxParticles),
      );
    } else if (_currentSettings.targetFps <= 45) {
      newSettings = _currentSettings.copyWith(
        targetFps: 60,
        particleQuality: (_currentSettings.particleQuality * 1.3).clamp(0.2, maxSettings.particleQuality),
        maxParticles: (_currentSettings.maxParticles * 1.3).toInt().clamp(50, maxSettings.maxParticles),
        antiAliasingEnabled: maxSettings.antiAliasingEnabled,
      );
    } else {
      // 60 FPS에서 추가 업그레이드
      newSettings = _currentSettings.copyWith(
        shadowsEnabled: maxSettings.shadowsEnabled,
        postProcessingEnabled: maxSettings.postProcessingEnabled,
        particleQuality: maxSettings.particleQuality,
        maxParticles: maxSettings.maxParticles,
      );
    }

    _applySettings(newSettings);
    onOptimizationEvent?.call('Quality upgraded due to stable FPS');
  }

  /// 설정 적용
  void _applySettings(MGQualitySettings settings) {
    _currentSettings = settings;
    onSettingsChanged?.call(settings);
    notifyListeners();
  }

  /// 수동으로 품질 설정
  void setQualityManually(MGQualitySettings settings) {
    if (_mode != OptimizationMode.manual) {
      _mode = OptimizationMode.manual;
    }
    _applySettings(settings);
  }

  /// 현재 최적화 상태 보고서
  OptimizationReport generateReport() {
    final monitor = MGPerformanceMonitor.instance;

    return OptimizationReport(
      mode: _mode,
      currentSettings: _currentSettings,
      averageFps: monitor.averageFps,
      dropRate: monitor.dropRate,
      deviceTier: MGDeviceCapability.tier,
      isOptimal: monitor.performanceState == PerformanceState.good ||
          monitor.performanceState == PerformanceState.excellent,
      recommendations: _generateRecommendations(),
    );
  }

  List<String> _generateRecommendations() {
    final recommendations = <String>[];
    final monitor = MGPerformanceMonitor.instance;

    if (monitor.averageFps < 30) {
      recommendations.add('Consider lowering graphics quality');
    }
    if (monitor.dropRate > 0.1) {
      recommendations.add('High frame drop rate detected');
    }
    if (MGDeviceCapability.tier == DeviceTier.low) {
      recommendations.add('Using Battery Saver mode is recommended');
    }
    if (_currentSettings.postProcessingEnabled &&
        monitor.averageFps < 50) {
      recommendations.add('Disable post-processing for better performance');
    }

    return recommendations;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

/// 최적화 보고서
class OptimizationReport {
  final OptimizationMode mode;
  final MGQualitySettings currentSettings;
  final double averageFps;
  final double dropRate;
  final DeviceTier deviceTier;
  final bool isOptimal;
  final List<String> recommendations;
  final DateTime timestamp;

  OptimizationReport({
    required this.mode,
    required this.currentSettings,
    required this.averageFps,
    required this.dropRate,
    required this.deviceTier,
    required this.isOptimal,
    required this.recommendations,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'targetFps': currentSettings.targetFps,
      'particleQuality': currentSettings.particleQuality,
      'averageFps': averageFps,
      'dropRate': dropRate,
      'deviceTier': deviceTier.name,
      'isOptimal': isOptimal,
      'recommendations': recommendations,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
