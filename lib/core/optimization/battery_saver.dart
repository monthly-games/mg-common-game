import 'package:flutter/material.dart';
import 'quality_settings.dart';

/// MG-Games 배터리 절약 관리자
/// DEVICE_OPTIMIZATION_GUIDE.md 기반
class MGBatterySaver {
  MGBatterySaver._();

  static MGBatterySaver? _instance;
  static MGBatterySaver get instance {
    _instance ??= MGBatterySaver._();
    return _instance!;
  }

  // ============================================================
  // 상태
  // ============================================================

  bool _batterySaverEnabled = false;
  BatteryState _batteryState = BatteryState.normal;
  int _batteryLevel = 100;

  /// 배터리 절약 모드 활성화 여부
  bool get isBatterySaverEnabled => _batterySaverEnabled;

  /// 현재 배터리 상태
  BatteryState get batteryState => _batteryState;

  /// 현재 배터리 레벨 (0-100)
  int get batteryLevel => _batteryLevel;

  // ============================================================
  // 설정
  // ============================================================

  /// 배터리 절약 모드 활성화
  void enableBatterySaver() {
    _batterySaverEnabled = true;
    _onBatterySaverChanged();
  }

  /// 배터리 절약 모드 비활성화
  void disableBatterySaver() {
    _batterySaverEnabled = false;
    _onBatterySaverChanged();
  }

  /// 배터리 절약 모드 토글
  void toggleBatterySaver() {
    _batterySaverEnabled = !_batterySaverEnabled;
    _onBatterySaverChanged();
  }

  /// 배터리 레벨 업데이트
  void updateBatteryLevel(int level) {
    _batteryLevel = level.clamp(0, 100);
    _updateBatteryState();
  }

  void _updateBatteryState() {
    if (_batteryLevel <= 10) {
      _batteryState = BatteryState.critical;
    } else if (_batteryLevel <= 20) {
      _batteryState = BatteryState.low;
    } else if (_batteryLevel <= 40) {
      _batteryState = BatteryState.medium;
    } else {
      _batteryState = BatteryState.normal;
    }

    // 배터리 부족 시 자동 절약 모드
    if (_batteryState == BatteryState.critical && !_batterySaverEnabled) {
      enableBatterySaver();
    }
  }

  void _onBatterySaverChanged() {
    // 리스너 통지 (필요시 구현)
  }

  // ============================================================
  // 품질 설정 가져오기
  // ============================================================

  /// 현재 상태에 맞는 품질 설정 반환
  MGQualitySettings getQualitySettings(MGQualitySettings baseSettings) {
    if (!_batterySaverEnabled) {
      return baseSettings;
    }

    // 배터리 절약 모드 설정 적용
    return MGQualitySettings.batterySaver;
  }

  /// 권장 FPS 반환
  int getRecommendedFps(int baseFps) {
    if (!_batterySaverEnabled) {
      return baseFps;
    }

    switch (_batteryState) {
      case BatteryState.critical:
        return 20;
      case BatteryState.low:
        return 30;
      case BatteryState.medium:
        return 30;
      case BatteryState.normal:
        return baseFps;
    }
  }

  /// 백그라운드 작업 허용 여부
  bool get allowBackgroundTasks {
    if (!_batterySaverEnabled) return true;
    return _batteryState == BatteryState.normal;
  }

  /// 애니메이션 허용 여부
  bool get allowAnimations {
    if (!_batterySaverEnabled) return true;
    return _batteryState != BatteryState.critical;
  }

  /// 파티클 효과 허용 여부
  bool get allowParticles {
    if (!_batterySaverEnabled) return true;
    return _batteryState == BatteryState.normal;
  }

  // ============================================================
  // 최적화 권장 사항
  // ============================================================

  /// 현재 상태에 대한 권장 사항
  List<String> get recommendations {
    if (!_batterySaverEnabled) {
      return [];
    }

    final list = <String>[];

    switch (_batteryState) {
      case BatteryState.critical:
        list.add('게임을 일시정지하고 충전하세요');
        list.add('FPS가 20으로 제한됩니다');
        list.add('모든 효과가 비활성화됩니다');
        break;
      case BatteryState.low:
        list.add('배터리 절약 모드 활성화');
        list.add('FPS가 30으로 제한됩니다');
        list.add('파티클 효과가 감소됩니다');
        break;
      case BatteryState.medium:
        list.add('배터리 절약 모드 활성화');
        list.add('일부 효과가 감소됩니다');
        break;
      case BatteryState.normal:
        list.add('배터리 절약 모드가 활성화되어 있습니다');
        break;
    }

    return list;
  }
}

/// 배터리 상태
enum BatteryState {
  /// 정상 (40%+)
  normal,

  /// 중간 (20-40%)
  medium,

  /// 낮음 (10-20%)
  low,

  /// 심각 (0-10%)
  critical,
}

extension BatteryStateExtension on BatteryState {
  /// 표시 이름
  String get displayName {
    switch (this) {
      case BatteryState.normal:
        return '정상';
      case BatteryState.medium:
        return '보통';
      case BatteryState.low:
        return '부족';
      case BatteryState.critical:
        return '위험';
    }
  }

  /// 색상
  Color get color {
    switch (this) {
      case BatteryState.normal:
        return Colors.green;
      case BatteryState.medium:
        return Colors.yellow;
      case BatteryState.low:
        return Colors.orange;
      case BatteryState.critical:
        return Colors.red;
    }
  }

  /// 아이콘
  IconData get icon {
    switch (this) {
      case BatteryState.normal:
        return Icons.battery_full;
      case BatteryState.medium:
        return Icons.battery_3_bar;
      case BatteryState.low:
        return Icons.battery_2_bar;
      case BatteryState.critical:
        return Icons.battery_alert;
    }
  }
}

/// 배터리 상태 위젯
class MGBatteryIndicator extends StatelessWidget {
  final bool showLabel;
  final double iconSize;

  const MGBatteryIndicator({
    super.key,
    this.showLabel = true,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final saver = MGBatterySaver.instance;
    final state = saver.batteryState;
    final level = saver.batteryLevel;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          state.icon,
          color: state.color,
          size: iconSize,
        ),
        if (showLabel) ...[
          const SizedBox(width: 4),
          Text(
            '$level%',
            style: TextStyle(
              color: state.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}

/// 배터리 절약 모드 토글 위젯
class MGBatterySaverToggle extends StatefulWidget {
  final ValueChanged<bool>? onChanged;

  const MGBatterySaverToggle({
    super.key,
    this.onChanged,
  });

  @override
  State<MGBatterySaverToggle> createState() => _MGBatterySaverToggleState();
}

class _MGBatterySaverToggleState extends State<MGBatterySaverToggle> {
  @override
  Widget build(BuildContext context) {
    final saver = MGBatterySaver.instance;

    return SwitchListTile(
      title: const Text('배터리 절약 모드'),
      subtitle: Text(
        saver.isBatterySaverEnabled
            ? '활성화됨 - FPS 및 효과 감소'
            : '비활성화됨',
      ),
      secondary: Icon(
        saver.isBatterySaverEnabled
            ? Icons.battery_saver
            : Icons.battery_std,
        color: saver.isBatterySaverEnabled ? Colors.green : null,
      ),
      value: saver.isBatterySaverEnabled,
      onChanged: (value) {
        setState(() {
          if (value) {
            saver.enableBatterySaver();
          } else {
            saver.disableBatterySaver();
          }
        });
        widget.onChanged?.call(value);
      },
    );
  }
}
