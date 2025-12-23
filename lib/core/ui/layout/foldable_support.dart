import 'dart:ui' show DisplayFeature, DisplayFeatureType;
import 'package:flutter/material.dart';

/// MG-Games 폴더블 기기 지원
/// DEVICE_OPTIMIZATION_GUIDE.md 기반
class MGFoldableSupport {
  MGFoldableSupport._();

  // ============================================================
  // 폴더블 기기 감지
  // ============================================================

  /// 폴더블 기기 여부 확인
  static bool isFoldableDevice(BuildContext context) {
    final displayFeatures = MediaQuery.of(context).displayFeatures;
    return displayFeatures.isNotEmpty;
  }

  /// 힌지 영역 정보 가져오기
  static List<DisplayFeature> getHingeFeatures(BuildContext context) {
    return MediaQuery.of(context)
        .displayFeatures
        .where((feature) => feature.type == DisplayFeatureType.hinge)
        .toList();
  }

  /// 힌지 영역 Rect 가져오기 (첫 번째 힌지)
  static Rect? getHingeRect(BuildContext context) {
    final hinges = getHingeFeatures(context);
    if (hinges.isEmpty) return null;
    return hinges.first.bounds;
  }

  /// 힌지가 수직인지 확인
  static bool isHingeVertical(BuildContext context) {
    final hingeRect = getHingeRect(context);
    if (hingeRect == null) return false;
    return hingeRect.height > hingeRect.width;
  }

  /// 힌지가 수평인지 확인
  static bool isHingeHorizontal(BuildContext context) {
    final hingeRect = getHingeRect(context);
    if (hingeRect == null) return false;
    return hingeRect.width > hingeRect.height;
  }

  // ============================================================
  // 폴더블 레이아웃 상태
  // ============================================================

  /// 현재 폴더블 상태 가져오기
  static FoldableState getFoldableState(BuildContext context) {
    if (!isFoldableDevice(context)) {
      return FoldableState.notFoldable;
    }

    final hingeRect = getHingeRect(context);
    if (hingeRect == null) {
      return FoldableState.folded;
    }

    // 힌지 너비가 0이면 완전히 펼쳐진 상태
    if (hingeRect.width == 0 || hingeRect.height == 0) {
      return FoldableState.flat;
    }

    return FoldableState.halfOpen;
  }
}

/// 폴더블 상태
enum FoldableState {
  /// 폴더블 기기가 아님
  notFoldable,

  /// 접힌 상태
  folded,

  /// 반쯤 열린 상태 (텐트/북 모드)
  halfOpen,

  /// 완전히 펼쳐진 상태
  flat,
}

/// 폴더블 인식 레이아웃 위젯
class MGFoldableLayout extends StatelessWidget {
  /// 일반 기기용 레이아웃
  final Widget child;

  /// 폴더블 기기 펼침 상태용 레이아웃 (null이면 child 사용)
  final Widget? expandedChild;

  /// 힌지 영역 회피 여부
  final bool avoidHinge;

  const MGFoldableLayout({
    super.key,
    required this.child,
    this.expandedChild,
    this.avoidHinge = true,
  });

  @override
  Widget build(BuildContext context) {
    final state = MGFoldableSupport.getFoldableState(context);

    // 일반 기기
    if (state == FoldableState.notFoldable) {
      return child;
    }

    // 폴더블 기기 - 펼침 상태
    if (state == FoldableState.flat || state == FoldableState.halfOpen) {
      final content = expandedChild ?? child;

      if (!avoidHinge) {
        return content;
      }

      // 힌지 영역 회피
      return _buildHingeAwareLayout(context, content);
    }

    // 접힌 상태
    return child;
  }

  Widget _buildHingeAwareLayout(BuildContext context, Widget content) {
    final hingeRect = MGFoldableSupport.getHingeRect(context);
    if (hingeRect == null) return content;

    final isVertical = MGFoldableSupport.isHingeVertical(context);

    if (isVertical) {
      // 수직 힌지 - 좌우 분할
      return Row(
        children: [
          Expanded(
            child: ClipRect(
              child: Align(
                alignment: Alignment.centerRight,
                widthFactor: 0.5,
                child: content,
              ),
            ),
          ),
          SizedBox(width: hingeRect.width),
          Expanded(
            child: ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: 0.5,
                child: content,
              ),
            ),
          ),
        ],
      );
    } else {
      // 수평 힌지 - 상하 분할
      return Column(
        children: [
          Expanded(
            child: ClipRect(
              child: Align(
                alignment: Alignment.bottomCenter,
                heightFactor: 0.5,
                child: content,
              ),
            ),
          ),
          SizedBox(height: hingeRect.height),
          Expanded(
            child: ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: 0.5,
                child: content,
              ),
            ),
          ),
        ],
      );
    }
  }
}

/// 폴더블 듀얼 패널 레이아웃
/// 펼쳐진 상태에서 좌우/상하 두 개의 패널로 분할
class MGDualPaneLayout extends StatelessWidget {
  /// 첫 번째 패널 (좌측 또는 상단)
  final Widget firstPane;

  /// 두 번째 패널 (우측 또는 하단)
  final Widget secondPane;

  /// 일반 기기에서 표시할 위젯 (null이면 firstPane)
  final Widget? singlePane;

  /// 첫 번째 패널 비율 (0.0 ~ 1.0)
  final double firstPaneRatio;

  const MGDualPaneLayout({
    super.key,
    required this.firstPane,
    required this.secondPane,
    this.singlePane,
    this.firstPaneRatio = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    final state = MGFoldableSupport.getFoldableState(context);

    // 일반 기기 또는 접힌 상태
    if (state == FoldableState.notFoldable || state == FoldableState.folded) {
      return singlePane ?? firstPane;
    }

    // 펼쳐진 상태
    final hingeRect = MGFoldableSupport.getHingeRect(context);
    final isVertical = MGFoldableSupport.isHingeVertical(context);

    if (isVertical) {
      // 수직 힌지 - 좌우 분할
      return Row(
        children: [
          Flexible(
            flex: (firstPaneRatio * 100).toInt(),
            child: firstPane,
          ),
          if (hingeRect != null) SizedBox(width: hingeRect.width),
          Flexible(
            flex: ((1 - firstPaneRatio) * 100).toInt(),
            child: secondPane,
          ),
        ],
      );
    } else {
      // 수평 힌지 - 상하 분할
      return Column(
        children: [
          Flexible(
            flex: (firstPaneRatio * 100).toInt(),
            child: firstPane,
          ),
          if (hingeRect != null) SizedBox(height: hingeRect.height),
          Flexible(
            flex: ((1 - firstPaneRatio) * 100).toInt(),
            child: secondPane,
          ),
        ],
      );
    }
  }
}

/// 폴더블 게임 캔버스
/// 펼쳐진 상태에서 게임 + 정보 패널 분할
class MGFoldableGameCanvas extends StatelessWidget {
  /// 게임 콘텐츠
  final Widget gameContent;

  /// 정보 패널 (지도, 인벤토리 등)
  final Widget? infoPanel;

  /// 일반 기기에서 게임만 표시할지
  final bool gameOnlyOnSingle;

  const MGFoldableGameCanvas({
    super.key,
    required this.gameContent,
    this.infoPanel,
    this.gameOnlyOnSingle = true,
  });

  @override
  Widget build(BuildContext context) {
    if (infoPanel == null) {
      return gameContent;
    }

    return MGDualPaneLayout(
      firstPane: gameContent,
      secondPane: infoPanel!,
      singlePane: gameOnlyOnSingle ? gameContent : null,
      firstPaneRatio: 0.6,
    );
  }
}

/// 폴더블 상태 감지 빌더
class MGFoldableBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, FoldableState state) builder;

  const MGFoldableBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final state = MGFoldableSupport.getFoldableState(context);
    return builder(context, state);
  }
}
