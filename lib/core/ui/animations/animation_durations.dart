import 'package:flutter/animation.dart';

/// MG-Games 애니메이션 상수
/// UI_UX_MASTER_GUIDE.md 기반
class MGAnimationDurations {
  MGAnimationDurations._();

  // ============================================================
  // 표준 듀레이션 (ms)
  // ============================================================

  /// 마이크로 애니메이션 (100ms)
  /// 버튼 탭, 토글, 매우 작은 전환
  static const Duration micro = Duration(milliseconds: 100);

  /// 짧은 애니메이션 (200ms)
  /// 페이드, 작은 이동
  static const Duration short = Duration(milliseconds: 200);

  /// 중간 애니메이션 (300ms)
  /// 페이지 전환, 모달 열기
  static const Duration medium = Duration(milliseconds: 300);

  /// 긴 애니메이션 (500ms)
  /// 복잡한 전환, 큰 요소 이동
  static const Duration long = Duration(milliseconds: 500);

  /// 매우 긴 애니메이션 (800ms)
  /// 특수 효과, 복잡한 애니메이션
  static const Duration extraLong = Duration(milliseconds: 800);

  // ============================================================
  // 특수 듀레이션
  // ============================================================

  /// 페이지 전환
  static const Duration pageTransition = medium;

  /// 모달 열기/닫기
  static const Duration modal = medium;

  /// 바텀 시트 열기/닫기
  static const Duration bottomSheet = medium;

  /// 스낵바
  static const Duration snackbar = Duration(milliseconds: 250);

  /// 버튼 탭 피드백
  static const Duration buttonTap = micro;

  /// 토글 전환
  static const Duration toggle = short;

  /// 색상 변경
  static const Duration colorChange = short;

  /// 스케일 변환
  static const Duration scale = short;

  /// 회전
  static const Duration rotate = medium;

  /// 슬라이드
  static const Duration slide = medium;

  /// 팝업 효과
  static const Duration popup = Duration(milliseconds: 350);

  /// 게임 결과 표시
  static const Duration gameResult = long;

  /// 보상 획득 효과
  static const Duration reward = extraLong;

  /// 스플래시 화면 최소 시간
  static const Duration splash = Duration(milliseconds: 1500);
}

/// MG-Games 이징 곡선
class MGCurves {
  MGCurves._();

  // ============================================================
  // 표준 커브
  // ============================================================

  /// 기본 이징 (자연스러운 감속)
  static const Curve standard = Curves.easeOutCubic;

  /// 입장 애니메이션 (처음에 빠르게)
  static const Curve enter = Curves.easeOutQuart;

  /// 퇴장 애니메이션 (끝에 빠르게)
  static const Curve exit = Curves.easeInCubic;

  /// 강조 효과 (탄성)
  static const Curve emphasis = Curves.elasticOut;

  /// 부드러운 전환
  static const Curve smooth = Curves.easeInOut;

  // ============================================================
  // 특수 커브
  // ============================================================

  /// 버튼 탭 피드백
  static const Curve buttonTap = Curves.easeOutBack;

  /// 팝업 등장
  static const Curve popup = Curves.easeOutBack;

  /// 바운스 효과
  static const Curve bounce = Curves.bounceOut;

  /// 오버슈트 (약간 넘어갔다 돌아옴)
  static const Curve overshoot = Curves.easeOutBack;

  /// 선형 (등속)
  static const Curve linear = Curves.linear;

  /// 빠른 시작
  static const Curve fastStart = Curves.easeIn;

  /// 빠른 종료
  static const Curve fastEnd = Curves.easeOut;

  /// 느린 시작 느린 종료
  static const Curve slowInOut = Curves.easeInOutSine;

  /// 스프링 효과
  static const Curve spring = Curves.elasticOut;

  /// 감속 (급격한 감속)
  static const Curve decelerate = Curves.decelerate;
}

/// 애니메이션 설정 헬퍼
class MGAnimationConfig {
  final Duration duration;
  final Curve curve;

  const MGAnimationConfig({
    required this.duration,
    required this.curve,
  });

  // ============================================================
  // 사전 정의된 설정
  // ============================================================

  /// 페이드 인
  static const fadeIn = MGAnimationConfig(
    duration: MGAnimationDurations.short,
    curve: MGCurves.enter,
  );

  /// 페이드 아웃
  static const fadeOut = MGAnimationConfig(
    duration: MGAnimationDurations.short,
    curve: MGCurves.exit,
  );

  /// 슬라이드 업
  static const slideUp = MGAnimationConfig(
    duration: MGAnimationDurations.medium,
    curve: MGCurves.standard,
  );

  /// 슬라이드 다운
  static const slideDown = MGAnimationConfig(
    duration: MGAnimationDurations.medium,
    curve: MGCurves.standard,
  );

  /// 팝업
  static const popup = MGAnimationConfig(
    duration: MGAnimationDurations.popup,
    curve: MGCurves.popup,
  );

  /// 스케일 인
  static const scaleIn = MGAnimationConfig(
    duration: MGAnimationDurations.short,
    curve: MGCurves.popup,
  );

  /// 흔들기
  static const shake = MGAnimationConfig(
    duration: MGAnimationDurations.medium,
    curve: MGCurves.linear,
  );

  /// 바운스
  static const bounce = MGAnimationConfig(
    duration: MGAnimationDurations.long,
    curve: MGCurves.bounce,
  );

  /// 스프링
  static const spring = MGAnimationConfig(
    duration: MGAnimationDurations.long,
    curve: MGCurves.spring,
  );

  /// 모달 열기
  static const modalOpen = MGAnimationConfig(
    duration: MGAnimationDurations.modal,
    curve: MGCurves.enter,
  );

  /// 모달 닫기
  static const modalClose = MGAnimationConfig(
    duration: MGAnimationDurations.modal,
    curve: MGCurves.exit,
  );
}
