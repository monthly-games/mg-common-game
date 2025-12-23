import 'dart:math';
import 'package:flutter/material.dart';
import 'mg_spacing.dart';

/// MG-Games Safe Area 위젯
/// SAFE_AREA_GUIDE.md 기반
class MGSafeArea extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;
  final double topPadding;
  final double bottomPadding;
  final double leftPadding;
  final double rightPadding;

  const MGSafeArea({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
    this.topPadding = MGSpacing.hudMargin,
    this.bottomPadding = MGSpacing.hudMargin,
    this.leftPadding = 0,
    this.rightPadding = 0,
  });

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;

    return Padding(
      padding: EdgeInsets.only(
        top: top ? padding.top + topPadding : 0,
        bottom: bottom ? padding.bottom + bottomPadding : 0,
        left: left ? padding.left + leftPadding : 0,
        right: right ? padding.right + rightPadding : 0,
      ),
      child: child,
    );
  }
}

/// Safe Area 설정 상수
class MGSafeAreaConfig {
  MGSafeAreaConfig._();

  // ============================================================
  // HUD와 Safe Area 경계 사이 여백
  // ============================================================
  static const double hudMargin = 8.0;

  // ============================================================
  // 터치 버튼과 Safe Area 경계 사이 여백
  // ============================================================
  static const double buttonMargin = 16.0;

  // ============================================================
  // 텍스트와 Safe Area 경계 사이 여백
  // ============================================================
  static const double textMargin = 16.0;

  // ============================================================
  // 모달과 Safe Area 경계 사이 여백
  // ============================================================
  static const double modalMargin = 24.0;

  // ============================================================
  // 권장 여백 (dp)
  // ============================================================

  // Portrait
  static const double topNoNotch = 24;
  static const double topWithNotch = 44; // ~ 62
  static const double bottomGestureBar = 34; // ~ 48
  static const double bottomNavigation = 48; // ~ 56

  // Landscape
  static const double sideWithNotch = 24; // ~ 44
}

/// Safe Area 값 계산 유틸리티
class MGSafeAreaUtils {
  MGSafeAreaUtils._();

  /// Safe Area padding 가져오기
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// 키보드 높이를 포함한 하단 패딩 가져오기
  static double getBottomPaddingWithKeyboard(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final viewInsets = MediaQuery.of(context).viewInsets;
    return max(padding.bottom, viewInsets.bottom);
  }

  /// HUD 상단 오프셋 계산
  static double getTopHudOffset(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return padding.top + MGSafeAreaConfig.hudMargin;
  }

  /// HUD 하단 오프셋 계산
  static double getBottomHudOffset(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return padding.bottom + MGSafeAreaConfig.hudMargin;
  }

  /// 버튼 하단 오프셋 계산
  static double getBottomButtonOffset(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return padding.bottom + MGSafeAreaConfig.buttonMargin;
  }
}

/// Safe Area를 무시하고 풀스크린 콘텐츠를 표시하는 위젯
class MGFullScreen extends StatelessWidget {
  final Widget child;

  const MGFullScreen({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      removeLeft: true,
      removeRight: true,
      child: child,
    );
  }
}
