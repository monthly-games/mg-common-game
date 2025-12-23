import 'package:flutter/material.dart';
import 'colorblind_colors.dart';

/// MG-Games 접근성 설정
/// ACCESSIBILITY_GUIDE.md 기반
class MGAccessibilitySettings {
  // ============================================================
  // 시각 접근성
  // ============================================================

  /// 색맹 모드 활성화
  final bool colorBlindModeEnabled;

  /// 색맹 유형
  final ColorBlindType colorBlindType;

  /// 고대비 모드 활성화
  final bool highContrastEnabled;

  /// 텍스트 크기 스케일
  final TextScaleOption textScaleOption;

  /// 줄임 동작 (모션 감소)
  final bool reduceMotion;

  /// 깜빡임 효과 비활성화
  final bool reduceFlashing;

  // ============================================================
  // 청각 접근성
  // ============================================================

  /// 자막 활성화
  final bool subtitlesEnabled;

  /// 자막 크기
  final SubtitleSize subtitleSize;

  /// 자막 배경 활성화
  final bool subtitleBackgroundEnabled;

  /// 화자 구분 표시
  final bool speakerIndicatorEnabled;

  /// 시각적 효과음 (화면 플래시 등)
  final bool visualSoundEffects;

  // ============================================================
  // 운동 접근성
  // ============================================================

  /// 터치 영역 크기
  final TouchAreaSize touchAreaSize;

  /// 한손 모드 활성화
  final bool oneHandedMode;

  /// 한손 모드 방향 (true: 오른손, false: 왼손)
  final bool oneHandedModeRightHand;

  /// 길게 누르기 대체 (더블탭으로 대체)
  final bool replaceLongPress;

  /// 드래그 대체 (탭 투 무브)
  final bool replaceDrag;

  /// 연속 탭 간격 (ms)
  final int multiTapInterval;

  // ============================================================
  // 인지 접근성
  // ============================================================

  /// QTE 타이밍 조절 배수 (1.0 = 기본)
  final double qteTimingMultiplier;

  /// 타이밍 허용 오차 배수 (1.0 = 기본)
  final double timingToleranceMultiplier;

  /// 자동 일시정지 활성화
  final bool autoPauseEnabled;

  /// 단순화 UI 활성화
  final bool simplifiedUIEnabled;

  /// 튜토리얼 상세 모드
  final bool detailedTutorials;

  // ============================================================
  // 햅틱 피드백
  // ============================================================

  /// 진동 피드백 활성화
  final bool hapticFeedbackEnabled;

  /// 진동 강도 (0.0 ~ 1.0)
  final double hapticIntensity;

  const MGAccessibilitySettings({
    // 시각
    this.colorBlindModeEnabled = false,
    this.colorBlindType = ColorBlindType.deuteranopia,
    this.highContrastEnabled = false,
    this.textScaleOption = TextScaleOption.medium,
    this.reduceMotion = false,
    this.reduceFlashing = false,
    // 청각
    this.subtitlesEnabled = false,
    this.subtitleSize = SubtitleSize.medium,
    this.subtitleBackgroundEnabled = true,
    this.speakerIndicatorEnabled = true,
    this.visualSoundEffects = false,
    // 운동
    this.touchAreaSize = TouchAreaSize.medium,
    this.oneHandedMode = false,
    this.oneHandedModeRightHand = true,
    this.replaceLongPress = false,
    this.replaceDrag = false,
    this.multiTapInterval = 300,
    // 인지
    this.qteTimingMultiplier = 1.0,
    this.timingToleranceMultiplier = 1.0,
    this.autoPauseEnabled = false,
    this.simplifiedUIEnabled = false,
    this.detailedTutorials = false,
    // 햅틱
    this.hapticFeedbackEnabled = true,
    this.hapticIntensity = 1.0,
  });

  /// 기본 설정
  static const MGAccessibilitySettings defaults = MGAccessibilitySettings();

  /// 저시력 사용자 프리셋
  static const MGAccessibilitySettings lowVision = MGAccessibilitySettings(
    highContrastEnabled: true,
    textScaleOption: TextScaleOption.large,
    reduceMotion: true,
    touchAreaSize: TouchAreaSize.large,
  );

  /// 색맹 사용자 프리셋
  static MGAccessibilitySettings colorBlind(ColorBlindType type) {
    return MGAccessibilitySettings(
      colorBlindModeEnabled: true,
      colorBlindType: type,
    );
  }

  /// 청각 장애 사용자 프리셋
  static const MGAccessibilitySettings deaf = MGAccessibilitySettings(
    subtitlesEnabled: true,
    subtitleSize: SubtitleSize.large,
    subtitleBackgroundEnabled: true,
    speakerIndicatorEnabled: true,
    visualSoundEffects: true,
    hapticFeedbackEnabled: true,
  );

  /// 운동 장애 사용자 프리셋
  static const MGAccessibilitySettings motorImpaired = MGAccessibilitySettings(
    touchAreaSize: TouchAreaSize.extraLarge,
    oneHandedMode: true,
    replaceLongPress: true,
    replaceDrag: true,
    multiTapInterval: 500,
    qteTimingMultiplier: 2.0,
    timingToleranceMultiplier: 1.5,
  );

  /// 인지 장애 사용자 프리셋
  static const MGAccessibilitySettings cognitiveImpaired =
      MGAccessibilitySettings(
    reduceMotion: true,
    reduceFlashing: true,
    autoPauseEnabled: true,
    simplifiedUIEnabled: true,
    detailedTutorials: true,
    qteTimingMultiplier: 2.0,
    timingToleranceMultiplier: 2.0,
  );

  /// 설정 복사
  MGAccessibilitySettings copyWith({
    bool? colorBlindModeEnabled,
    ColorBlindType? colorBlindType,
    bool? highContrastEnabled,
    TextScaleOption? textScaleOption,
    bool? reduceMotion,
    bool? reduceFlashing,
    bool? subtitlesEnabled,
    SubtitleSize? subtitleSize,
    bool? subtitleBackgroundEnabled,
    bool? speakerIndicatorEnabled,
    bool? visualSoundEffects,
    TouchAreaSize? touchAreaSize,
    bool? oneHandedMode,
    bool? oneHandedModeRightHand,
    bool? replaceLongPress,
    bool? replaceDrag,
    int? multiTapInterval,
    double? qteTimingMultiplier,
    double? timingToleranceMultiplier,
    bool? autoPauseEnabled,
    bool? simplifiedUIEnabled,
    bool? detailedTutorials,
    bool? hapticFeedbackEnabled,
    double? hapticIntensity,
  }) {
    return MGAccessibilitySettings(
      colorBlindModeEnabled:
          colorBlindModeEnabled ?? this.colorBlindModeEnabled,
      colorBlindType: colorBlindType ?? this.colorBlindType,
      highContrastEnabled: highContrastEnabled ?? this.highContrastEnabled,
      textScaleOption: textScaleOption ?? this.textScaleOption,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      reduceFlashing: reduceFlashing ?? this.reduceFlashing,
      subtitlesEnabled: subtitlesEnabled ?? this.subtitlesEnabled,
      subtitleSize: subtitleSize ?? this.subtitleSize,
      subtitleBackgroundEnabled:
          subtitleBackgroundEnabled ?? this.subtitleBackgroundEnabled,
      speakerIndicatorEnabled:
          speakerIndicatorEnabled ?? this.speakerIndicatorEnabled,
      visualSoundEffects: visualSoundEffects ?? this.visualSoundEffects,
      touchAreaSize: touchAreaSize ?? this.touchAreaSize,
      oneHandedMode: oneHandedMode ?? this.oneHandedMode,
      oneHandedModeRightHand:
          oneHandedModeRightHand ?? this.oneHandedModeRightHand,
      replaceLongPress: replaceLongPress ?? this.replaceLongPress,
      replaceDrag: replaceDrag ?? this.replaceDrag,
      multiTapInterval: multiTapInterval ?? this.multiTapInterval,
      qteTimingMultiplier: qteTimingMultiplier ?? this.qteTimingMultiplier,
      timingToleranceMultiplier:
          timingToleranceMultiplier ?? this.timingToleranceMultiplier,
      autoPauseEnabled: autoPauseEnabled ?? this.autoPauseEnabled,
      simplifiedUIEnabled: simplifiedUIEnabled ?? this.simplifiedUIEnabled,
      detailedTutorials: detailedTutorials ?? this.detailedTutorials,
      hapticFeedbackEnabled:
          hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
      hapticIntensity: hapticIntensity ?? this.hapticIntensity,
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'colorBlindModeEnabled': colorBlindModeEnabled,
      'colorBlindType': colorBlindType.index,
      'highContrastEnabled': highContrastEnabled,
      'textScaleOption': textScaleOption.index,
      'reduceMotion': reduceMotion,
      'reduceFlashing': reduceFlashing,
      'subtitlesEnabled': subtitlesEnabled,
      'subtitleSize': subtitleSize.index,
      'subtitleBackgroundEnabled': subtitleBackgroundEnabled,
      'speakerIndicatorEnabled': speakerIndicatorEnabled,
      'visualSoundEffects': visualSoundEffects,
      'touchAreaSize': touchAreaSize.index,
      'oneHandedMode': oneHandedMode,
      'oneHandedModeRightHand': oneHandedModeRightHand,
      'replaceLongPress': replaceLongPress,
      'replaceDrag': replaceDrag,
      'multiTapInterval': multiTapInterval,
      'qteTimingMultiplier': qteTimingMultiplier,
      'timingToleranceMultiplier': timingToleranceMultiplier,
      'autoPauseEnabled': autoPauseEnabled,
      'simplifiedUIEnabled': simplifiedUIEnabled,
      'detailedTutorials': detailedTutorials,
      'hapticFeedbackEnabled': hapticFeedbackEnabled,
      'hapticIntensity': hapticIntensity,
    };
  }

  /// JSON에서 생성
  factory MGAccessibilitySettings.fromJson(Map<String, dynamic> json) {
    return MGAccessibilitySettings(
      colorBlindModeEnabled: json['colorBlindModeEnabled'] ?? false,
      colorBlindType:
          ColorBlindType.values[json['colorBlindType'] ?? 0],
      highContrastEnabled: json['highContrastEnabled'] ?? false,
      textScaleOption:
          TextScaleOption.values[json['textScaleOption'] ?? 1],
      reduceMotion: json['reduceMotion'] ?? false,
      reduceFlashing: json['reduceFlashing'] ?? false,
      subtitlesEnabled: json['subtitlesEnabled'] ?? false,
      subtitleSize: SubtitleSize.values[json['subtitleSize'] ?? 1],
      subtitleBackgroundEnabled: json['subtitleBackgroundEnabled'] ?? true,
      speakerIndicatorEnabled: json['speakerIndicatorEnabled'] ?? true,
      visualSoundEffects: json['visualSoundEffects'] ?? false,
      touchAreaSize: TouchAreaSize.values[json['touchAreaSize'] ?? 1],
      oneHandedMode: json['oneHandedMode'] ?? false,
      oneHandedModeRightHand: json['oneHandedModeRightHand'] ?? true,
      replaceLongPress: json['replaceLongPress'] ?? false,
      replaceDrag: json['replaceDrag'] ?? false,
      multiTapInterval: json['multiTapInterval'] ?? 300,
      qteTimingMultiplier: json['qteTimingMultiplier'] ?? 1.0,
      timingToleranceMultiplier: json['timingToleranceMultiplier'] ?? 1.0,
      autoPauseEnabled: json['autoPauseEnabled'] ?? false,
      simplifiedUIEnabled: json['simplifiedUIEnabled'] ?? false,
      detailedTutorials: json['detailedTutorials'] ?? false,
      hapticFeedbackEnabled: json['hapticFeedbackEnabled'] ?? true,
      hapticIntensity: json['hapticIntensity'] ?? 1.0,
    );
  }
}

/// 텍스트 크기 옵션
enum TextScaleOption {
  small,
  medium,
  large,
  extraLarge,
  huge,
}

extension TextScaleOptionExtension on TextScaleOption {
  /// 스케일 값
  double get scale {
    switch (this) {
      case TextScaleOption.small:
        return 0.85;
      case TextScaleOption.medium:
        return 1.0;
      case TextScaleOption.large:
        return 1.15;
      case TextScaleOption.extraLarge:
        return 1.3;
      case TextScaleOption.huge:
        return 1.5;
    }
  }

  /// 표시 이름
  String get displayName {
    switch (this) {
      case TextScaleOption.small:
        return '작게';
      case TextScaleOption.medium:
        return '보통';
      case TextScaleOption.large:
        return '크게';
      case TextScaleOption.extraLarge:
        return '매우 크게';
      case TextScaleOption.huge:
        return '최대';
    }
  }
}

/// 자막 크기
enum SubtitleSize {
  small,
  medium,
  large,
  extraLarge,
}

extension SubtitleSizeExtension on SubtitleSize {
  /// 폰트 크기
  double get fontSize {
    switch (this) {
      case SubtitleSize.small:
        return 14;
      case SubtitleSize.medium:
        return 18;
      case SubtitleSize.large:
        return 22;
      case SubtitleSize.extraLarge:
        return 28;
    }
  }

  /// 표시 이름
  String get displayName {
    switch (this) {
      case SubtitleSize.small:
        return '작게';
      case SubtitleSize.medium:
        return '보통';
      case SubtitleSize.large:
        return '크게';
      case SubtitleSize.extraLarge:
        return '매우 크게';
    }
  }
}

/// 터치 영역 크기
enum TouchAreaSize {
  small,
  medium,
  large,
  extraLarge,
}

extension TouchAreaSizeExtension on TouchAreaSize {
  /// 최소 터치 영역 크기 (dp)
  double get minSize {
    switch (this) {
      case TouchAreaSize.small:
        return 36;
      case TouchAreaSize.medium:
        return 44;
      case TouchAreaSize.large:
        return 56;
      case TouchAreaSize.extraLarge:
        return 72;
    }
  }

  /// 표시 이름
  String get displayName {
    switch (this) {
      case TouchAreaSize.small:
        return '작게';
      case TouchAreaSize.medium:
        return '보통';
      case TouchAreaSize.large:
        return '크게';
      case TouchAreaSize.extraLarge:
        return '매우 크게';
    }
  }
}

/// 접근성 설정 Provider (InheritedWidget)
class MGAccessibilityProvider extends InheritedWidget {
  final MGAccessibilitySettings settings;
  final void Function(MGAccessibilitySettings) onSettingsChanged;

  const MGAccessibilityProvider({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    required super.child,
  });

  static MGAccessibilityProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MGAccessibilityProvider>();
  }

  static MGAccessibilitySettings settingsOf(BuildContext context) {
    return of(context)?.settings ?? MGAccessibilitySettings.defaults;
  }

  @override
  bool updateShouldNotify(MGAccessibilityProvider oldWidget) {
    return settings != oldWidget.settings;
  }
}
