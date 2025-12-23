import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'accessibility_settings.dart';

/// MG-Games 햅틱 피드백 관리자
/// ACCESSIBILITY_GUIDE.md 기반
class MGHapticFeedback {
  MGHapticFeedback._();

  // ============================================================
  // 표준 햅틱 피드백
  // ============================================================

  /// 가벼운 탭 (UI 상호작용)
  static Future<void> lightTap([BuildContext? context]) async {
    if (!_isEnabled(context)) return;
    await HapticFeedback.lightImpact();
  }

  /// 중간 탭 (확인, 선택)
  static Future<void> mediumTap([BuildContext? context]) async {
    if (!_isEnabled(context)) return;
    await HapticFeedback.mediumImpact();
  }

  /// 강한 탭 (경고, 오류)
  static Future<void> heavyTap([BuildContext? context]) async {
    if (!_isEnabled(context)) return;
    await HapticFeedback.heavyImpact();
  }

  /// 선택 변경 (탭, 슬라이더)
  static Future<void> selectionClick([BuildContext? context]) async {
    if (!_isEnabled(context)) return;
    await HapticFeedback.selectionClick();
  }

  /// 진동 (길게)
  static Future<void> vibrate([BuildContext? context]) async {
    if (!_isEnabled(context)) return;
    await HapticFeedback.vibrate();
  }

  // ============================================================
  // 게임 피드백
  // ============================================================

  /// 성공 (퀘스트 완료, 레벨업 등)
  static Future<void> success([BuildContext? context]) async {
    if (!_isEnabled(context)) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  /// 실패 (게임 오버, 미션 실패 등)
  static Future<void> failure([BuildContext? context]) async {
    if (!_isEnabled(context)) return;
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    await HapticFeedback.heavyImpact();
  }

  /// 경고 (위험, 주의 등)
  static Future<void> warning([BuildContext? context]) async {
    if (!_isEnabled(context)) return;
    await HapticFeedback.heavyImpact();
  }

  /// 보상 획득 (아이템, 코인 등)
  static Future<void> reward([BuildContext? context]) async {
    if (!_isEnabled(context)) return;
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.mediumImpact();
  }

  /// 타격감 (공격, 충돌 등)
  static Future<void> impact([BuildContext? context]) async {
    if (!_isEnabled(context)) return;
    await HapticFeedback.heavyImpact();
  }

  /// 연속 타격 (콤보 등)
  static Future<void> combo(int count, [BuildContext? context]) async {
    if (!_isEnabled(context)) return;

    for (int i = 0; i < count.clamp(1, 5); i++) {
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  /// 카운트다운
  static Future<void> countdown([BuildContext? context]) async {
    if (!_isEnabled(context)) return;
    await HapticFeedback.selectionClick();
  }

  /// 타이밍 피드백 (리듬 게임 등)
  static Future<void> timing(TimingFeedbackType type,
      [BuildContext? context]) async {
    if (!_isEnabled(context)) return;

    switch (type) {
      case TimingFeedbackType.perfect:
        await HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 50));
        await HapticFeedback.lightImpact();
        break;
      case TimingFeedbackType.great:
        await HapticFeedback.mediumImpact();
        break;
      case TimingFeedbackType.good:
        await HapticFeedback.lightImpact();
        break;
      case TimingFeedbackType.miss:
        await HapticFeedback.heavyImpact();
        break;
    }
  }

  // ============================================================
  // 커스텀 패턴
  // ============================================================

  /// 패턴 재생
  static Future<void> playPattern(
    List<HapticPattern> patterns, [
    BuildContext? context,
  ]) async {
    if (!_isEnabled(context)) return;

    for (final pattern in patterns) {
      switch (pattern.type) {
        case HapticType.light:
          await HapticFeedback.lightImpact();
          break;
        case HapticType.medium:
          await HapticFeedback.mediumImpact();
          break;
        case HapticType.heavy:
          await HapticFeedback.heavyImpact();
          break;
        case HapticType.selection:
          await HapticFeedback.selectionClick();
          break;
      }

      if (pattern.delayMs > 0) {
        await Future.delayed(Duration(milliseconds: pattern.delayMs));
      }
    }
  }

  // ============================================================
  // 유틸리티
  // ============================================================

  static bool _isEnabled(BuildContext? context) {
    if (context == null) return true;

    final settings = MGAccessibilityProvider.settingsOf(context);
    return settings.hapticFeedbackEnabled;
  }

  /// 강도 조절된 피드백
  static Future<void> withIntensity(
    HapticType type,
    double intensity, [
    BuildContext? context,
  ]) async {
    if (!_isEnabled(context)) return;

    // 강도에 따라 타입 조절
    HapticType adjustedType;
    if (intensity < 0.3) {
      adjustedType = HapticType.selection;
    } else if (intensity < 0.6) {
      adjustedType = HapticType.light;
    } else if (intensity < 0.8) {
      adjustedType = HapticType.medium;
    } else {
      adjustedType = type;
    }

    switch (adjustedType) {
      case HapticType.light:
        await HapticFeedback.lightImpact();
        break;
      case HapticType.medium:
        await HapticFeedback.mediumImpact();
        break;
      case HapticType.heavy:
        await HapticFeedback.heavyImpact();
        break;
      case HapticType.selection:
        await HapticFeedback.selectionClick();
        break;
    }
  }
}

/// 햅틱 타입
enum HapticType {
  light,
  medium,
  heavy,
  selection,
}

/// 타이밍 피드백 타입
enum TimingFeedbackType {
  perfect,
  great,
  good,
  miss,
}

/// 햅틱 패턴 정의
class HapticPattern {
  final HapticType type;
  final int delayMs;

  const HapticPattern({
    required this.type,
    this.delayMs = 0,
  });

  /// 가벼운 탭
  static const light = HapticPattern(type: HapticType.light);

  /// 중간 탭
  static const medium = HapticPattern(type: HapticType.medium);

  /// 강한 탭
  static const heavy = HapticPattern(type: HapticType.heavy);

  /// 선택 클릭
  static const selection = HapticPattern(type: HapticType.selection);

  /// 딜레이 추가
  HapticPattern withDelay(int ms) {
    return HapticPattern(type: type, delayMs: ms);
  }
}

/// 사전 정의된 햅틱 패턴
class MGHapticPatterns {
  MGHapticPatterns._();

  /// 성공 패턴
  static const List<HapticPattern> success = [
    HapticPattern(type: HapticType.medium, delayMs: 100),
    HapticPattern(type: HapticType.light),
  ];

  /// 실패 패턴
  static const List<HapticPattern> failure = [
    HapticPattern(type: HapticType.heavy, delayMs: 150),
    HapticPattern(type: HapticType.heavy),
  ];

  /// 보상 패턴
  static const List<HapticPattern> reward = [
    HapticPattern(type: HapticType.light, delayMs: 50),
    HapticPattern(type: HapticType.medium, delayMs: 50),
    HapticPattern(type: HapticType.light),
  ];

  /// 레벨업 패턴
  static const List<HapticPattern> levelUp = [
    HapticPattern(type: HapticType.medium, delayMs: 100),
    HapticPattern(type: HapticType.medium, delayMs: 100),
    HapticPattern(type: HapticType.heavy),
  ];

  /// 카운트다운 패턴 (3초)
  static const List<HapticPattern> countdown = [
    HapticPattern(type: HapticType.selection, delayMs: 1000),
    HapticPattern(type: HapticType.selection, delayMs: 1000),
    HapticPattern(type: HapticType.selection, delayMs: 1000),
    HapticPattern(type: HapticType.medium),
  ];

  /// 하트비트 패턴
  static const List<HapticPattern> heartbeat = [
    HapticPattern(type: HapticType.medium, delayMs: 100),
    HapticPattern(type: HapticType.light, delayMs: 700),
  ];

  /// 알림 패턴
  static const List<HapticPattern> notification = [
    HapticPattern(type: HapticType.light, delayMs: 100),
    HapticPattern(type: HapticType.light),
  ];
}

/// 햅틱 피드백 믹스인
/// StatefulWidget에서 사용
mixin MGHapticMixin<T extends StatefulWidget> on State<T> {
  /// 가벼운 탭
  void hapticLight() => MGHapticFeedback.lightTap(context);

  /// 중간 탭
  void hapticMedium() => MGHapticFeedback.mediumTap(context);

  /// 강한 탭
  void hapticHeavy() => MGHapticFeedback.heavyTap(context);

  /// 선택
  void hapticSelection() => MGHapticFeedback.selectionClick(context);

  /// 성공
  void hapticSuccess() => MGHapticFeedback.success(context);

  /// 실패
  void hapticFailure() => MGHapticFeedback.failure(context);

  /// 보상
  void hapticReward() => MGHapticFeedback.reward(context);

  /// 타격
  void hapticImpact() => MGHapticFeedback.impact(context);
}
