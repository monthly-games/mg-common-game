import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// MG-Games 스크린 리더 지원
/// ACCESSIBILITY_GUIDE.md 기반
class MGScreenReaderSupport {
  MGScreenReaderSupport._();

  /// 스크린 리더 활성화 여부 확인
  static bool isScreenReaderEnabled(BuildContext context) {
    return MediaQuery.of(context).accessibleNavigation;
  }

  /// 스크린 리더에 메시지 알림
  static void announce(String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// 스크린 리더에 한국어 메시지 알림
  static void announceKr(String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }
}

/// 시맨틱 버튼 래퍼
/// 버튼에 명확한 접근성 레이블 추가
class MGSemanticButton extends StatelessWidget {
  final Widget child;
  final String label;
  final String? hint;
  final VoidCallback? onTap;
  final bool enabled;

  const MGSemanticButton({
    super.key,
    required this.child,
    required this.label,
    this.hint,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      hint: hint,
      onTap: enabled ? onTap : null,
      child: child,
    );
  }
}

/// 시맨틱 이미지 래퍼
class MGSemanticImage extends StatelessWidget {
  final Widget child;
  final String label;
  final bool isDecorative;

  const MGSemanticImage({
    super.key,
    required this.child,
    required this.label,
    this.isDecorative = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isDecorative) {
      return ExcludeSemantics(child: child);
    }

    return Semantics(
      image: true,
      label: label,
      child: child,
    );
  }
}

/// 시맨틱 텍스트 래퍼
class MGSemanticText extends StatelessWidget {
  final Widget child;
  final String? label;
  final bool header;
  final int? headingLevel;

  const MGSemanticText({
    super.key,
    required this.child,
    this.label,
    this.header = false,
    this.headingLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      header: header,
      child: child,
    );
  }
}

/// 시맨틱 슬라이더 래퍼
class MGSemanticSlider extends StatelessWidget {
  final Widget child;
  final String label;
  final double value;
  final double min;
  final double max;
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;

  const MGSemanticSlider({
    super.key,
    required this.child,
    required this.label,
    required this.value,
    this.min = 0,
    this.max = 100,
    this.onIncrease,
    this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = ((value - min) / (max - min) * 100).round();
    return Semantics(
      slider: true,
      label: label,
      value: '$percentage%',
      increasedValue: '${(percentage + 10).clamp(0, 100)}%',
      decreasedValue: '${(percentage - 10).clamp(0, 100)}%',
      onIncrease: onIncrease,
      onDecrease: onDecrease,
      child: child,
    );
  }
}

/// 시맨틱 진행률 래퍼
class MGSemanticProgress extends StatelessWidget {
  final Widget child;
  final String label;
  final double value; // 0.0 ~ 1.0
  final bool indeterminate;

  const MGSemanticProgress({
    super.key,
    required this.child,
    required this.label,
    required this.value,
    this.indeterminate = false,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (value * 100).round();
    return Semantics(
      label: indeterminate ? '$label, 로딩 중' : '$label, $percentage%',
      child: child,
    );
  }
}

/// 시맨틱 토글 래퍼
class MGSemanticToggle extends StatelessWidget {
  final Widget child;
  final String label;
  final bool toggled;
  final VoidCallback? onTap;

  const MGSemanticToggle({
    super.key,
    required this.child,
    required this.label,
    required this.toggled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: toggled,
      label: label,
      onTap: onTap,
      child: child,
    );
  }
}

/// 시맨틱 그룹 래퍼
/// 관련 요소들을 하나의 그룹으로 묶음
class MGSemanticGroup extends StatelessWidget {
  final Widget child;
  final String? label;
  final bool container;
  final bool explicitChildNodes;

  const MGSemanticGroup({
    super.key,
    required this.child,
    this.label,
    this.container = true,
    this.explicitChildNodes = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: container,
      explicitChildNodes: explicitChildNodes,
      label: label,
      child: child,
    );
  }
}

/// 시맨틱 라이브 영역
/// 실시간 업데이트되는 콘텐츠 (점수, 타이머 등)
class MGSemanticLiveRegion extends StatelessWidget {
  final Widget child;
  final String label;
  final bool polite;

  const MGSemanticLiveRegion({
    super.key,
    required this.child,
    required this.label,
    this.polite = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: label,
      child: child,
    );
  }
}

/// 탐색 순서 래퍼
/// 포커스 순서를 명시적으로 지정
class MGSemanticOrder extends StatelessWidget {
  final Widget child;
  final double order;

  const MGSemanticOrder({
    super.key,
    required this.child,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      sortKey: OrdinalSortKey(order),
      child: child,
    );
  }
}

/// 포커스 가능 래퍼
class MGFocusable extends StatelessWidget {
  final Widget child;
  final String? label;
  final bool canRequestFocus;
  final ValueChanged<bool>? onFocusChange;

  const MGFocusable({
    super.key,
    required this.child,
    this.label,
    this.canRequestFocus = true,
    this.onFocusChange,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: canRequestFocus,
      onFocusChange: onFocusChange,
      child: Semantics(
        focusable: canRequestFocus,
        label: label,
        child: child,
      ),
    );
  }
}

/// 게임 요소 시맨틱 래퍼
/// 게임 내 요소에 대한 접근성 정보 제공
class MGGameElementSemantic extends StatelessWidget {
  final Widget child;
  final String elementType; // 타워, 적, 자원 등
  final String elementName;
  final String? state; // 상태 정보
  final String? action; // 가능한 동작

  const MGGameElementSemantic({
    super.key,
    required this.child,
    required this.elementType,
    required this.elementName,
    this.state,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    String label = '$elementType: $elementName';
    if (state != null) {
      label += ', $state';
    }

    return Semantics(
      label: label,
      hint: action,
      child: child,
    );
  }
}

/// 게임 HUD 요소 시맨틱
class MGHudSemantic extends StatelessWidget {
  final Widget child;
  final String hudType; // 자원, 점수, 웨이브 등
  final String value;
  final bool liveUpdate;

  const MGHudSemantic({
    super.key,
    required this.child,
    required this.hudType,
    required this.value,
    this.liveUpdate = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: liveUpdate,
      label: '$hudType: $value',
      child: child,
    );
  }
}

/// 접근성 헬퍼 Extension
extension AccessibilityExtension on Widget {
  /// 버튼 시맨틱 추가
  Widget semanticButton(String label, {String? hint, VoidCallback? onTap}) {
    return MGSemanticButton(
      label: label,
      hint: hint,
      onTap: onTap,
      child: this,
    );
  }

  /// 이미지 시맨틱 추가
  Widget semanticImage(String label) {
    return MGSemanticImage(label: label, child: this);
  }

  /// 장식용 요소 (스크린 리더 제외)
  Widget decorative() {
    return ExcludeSemantics(child: this);
  }

  /// 탐색 순서 지정
  Widget semanticOrder(double order) {
    return MGSemanticOrder(order: order, child: this);
  }

  /// 라이브 영역 지정
  Widget liveRegion(String label) {
    return MGSemanticLiveRegion(label: label, child: this);
  }
}
