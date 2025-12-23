import 'package:flutter/material.dart';

/// MG-Games 간격 시스템
/// UI_UX_MASTER_GUIDE.md 기반
class MGSpacing {
  MGSpacing._();

  // ============================================================
  // 간격 상수 (dp)
  // ============================================================

  /// 미세 간격 (4dp)
  static const double xxs = 4;

  /// 아이콘 내부 간격 (8dp)
  static const double xs = 8;

  /// 관련 요소 간격 (12dp)
  static const double sm = 12;

  /// 섹션 내부 간격 (16dp)
  static const double md = 16;

  /// 섹션 간 간격 (24dp)
  static const double lg = 24;

  /// 주요 영역 간격 (32dp)
  static const double xl = 32;

  /// 화면 섹션 간격 (48dp)
  static const double xxl = 48;

  // ============================================================
  // 마진 상수
  // ============================================================

  /// Portrait 화면 좌우 마진
  static const double screenMarginPortrait = 16;

  /// Landscape 화면 좌우 마진
  static const double screenMarginLandscape = 24;

  /// 카드 내부 패딩
  static const double cardPadding = 16;

  /// 버튼 내부 패딩 (수평)
  static const double buttonPaddingH = 16;

  /// 버튼 내부 패딩 (수직)
  static const double buttonPaddingV = 12;

  // ============================================================
  // 그리드 시스템
  // ============================================================

  /// Portrait 컬럼 수
  static const int columnsPortrait = 4;

  /// Landscape 컬럼 수
  static const int columnsLandscape = 6;

  /// 컬럼 간격 (Portrait)
  static const double columnGapPortrait = 8;

  /// 컬럼 간격 (Landscape)
  static const double columnGapLandscape = 12;

  // ============================================================
  // Safe Area 권장 여백
  // ============================================================

  /// HUD와 Safe Area 경계 여백
  static const double hudMargin = 8;

  /// 터치 버튼과 Safe Area 경계 여백
  static const double buttonMargin = 16;

  /// 텍스트와 Safe Area 경계 여백
  static const double textMargin = 16;

  /// 모달과 Safe Area 경계 여백
  static const double modalMargin = 24;

  // ============================================================
  // EdgeInsets 헬퍼
  // ============================================================

  /// 모든 방향 패딩
  static EdgeInsets all(double value) => EdgeInsets.all(value);

  /// 수평 패딩
  static EdgeInsets horizontal(double value) =>
      EdgeInsets.symmetric(horizontal: value);

  /// 수직 패딩
  static EdgeInsets vertical(double value) =>
      EdgeInsets.symmetric(vertical: value);

  /// 수평/수직 패딩
  static EdgeInsets symmetric({double horizontal = 0, double vertical = 0}) =>
      EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);

  /// 화면 마진 (Portrait)
  static EdgeInsets get screenPaddingPortrait =>
      horizontal(screenMarginPortrait);

  /// 화면 마진 (Landscape)
  static EdgeInsets get screenPaddingLandscape =>
      horizontal(screenMarginLandscape);

  /// 카드 패딩
  static EdgeInsets get cardEdgePadding => all(cardPadding);

  /// 버튼 패딩
  static EdgeInsets get buttonEdgePadding =>
      symmetric(horizontal: buttonPaddingH, vertical: buttonPaddingV);

  // ============================================================
  // SizedBox 헬퍼
  // ============================================================

  /// 수평 간격
  static SizedBox horizontalSpace(double width) => SizedBox(width: width);

  /// 수직 간격
  static SizedBox verticalSpace(double height) => SizedBox(height: height);

  /// xxs 수평 간격
  static SizedBox get hXxs => horizontalSpace(xxs);

  /// xs 수평 간격
  static SizedBox get hXs => horizontalSpace(xs);

  /// sm 수평 간격
  static SizedBox get hSm => horizontalSpace(sm);

  /// md 수평 간격
  static SizedBox get hMd => horizontalSpace(md);

  /// lg 수평 간격
  static SizedBox get hLg => horizontalSpace(lg);

  /// xxs 수직 간격
  static SizedBox get vXxs => verticalSpace(xxs);

  /// xs 수직 간격
  static SizedBox get vXs => verticalSpace(xs);

  /// sm 수직 간격
  static SizedBox get vSm => verticalSpace(sm);

  /// md 수직 간격
  static SizedBox get vMd => verticalSpace(md);

  /// lg 수직 간격
  static SizedBox get vLg => verticalSpace(lg);

  /// xl 수직 간격
  static SizedBox get vXl => verticalSpace(xl);

  /// xxl 수직 간격
  static SizedBox get vXxl => verticalSpace(xxl);
}
