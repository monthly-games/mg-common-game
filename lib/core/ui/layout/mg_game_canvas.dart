import 'package:flutter/material.dart';
import 'mg_spacing.dart';

/// MG-Games 게임 캔버스 위젯
/// 풀스크린 게임 영역 + Safe Area HUD 슬롯
class MGGameCanvas extends StatelessWidget {
  /// 게임 콘텐츠 (풀스크린)
  final Widget gameContent;

  /// 상단 HUD (Safe Area 내부)
  final Widget? topHud;

  /// 하단 HUD (Safe Area 내부)
  final Widget? bottomHud;

  /// 좌측 HUD (Safe Area 내부)
  final Widget? leftHud;

  /// 우측 HUD (Safe Area 내부)
  final Widget? rightHud;

  /// 중앙 오버레이 (모달, 팝업 등)
  final Widget? centerOverlay;

  /// HUD 배경색 (null이면 투명)
  final Color? hudBackgroundColor;

  /// 상단 HUD 높이 (null이면 자동)
  final double? topHudHeight;

  /// 하단 HUD 높이 (null이면 자동)
  final double? bottomHudHeight;

  /// 좌측 HUD 너비 (null이면 자동)
  final double? leftHudWidth;

  /// 우측 HUD 너비 (null이면 자동)
  final double? rightHudWidth;

  const MGGameCanvas({
    super.key,
    required this.gameContent,
    this.topHud,
    this.bottomHud,
    this.leftHud,
    this.rightHud,
    this.centerOverlay,
    this.hudBackgroundColor,
    this.topHudHeight,
    this.bottomHudHeight,
    this.leftHudWidth,
    this.rightHudWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 게임 콘텐츠 (풀스크린)
        Positioned.fill(
          child: gameContent,
        ),

        // HUD 레이어
        Positioned.fill(
          child: _buildHudLayer(context),
        ),

        // 중앙 오버레이
        if (centerOverlay != null)
          Positioned.fill(
            child: centerOverlay!,
          ),
      ],
    );
  }

  Widget _buildHudLayer(BuildContext context) {
    final padding = MediaQuery.of(context).padding;

    return Column(
      children: [
        // 상단 HUD
        if (topHud != null)
          Container(
            color: hudBackgroundColor,
            padding: EdgeInsets.only(
              top: padding.top + MGSpacing.hudMargin,
              left: padding.left + MGSpacing.hudMargin,
              right: padding.right + MGSpacing.hudMargin,
            ),
            height: topHudHeight != null
                ? topHudHeight! + padding.top + MGSpacing.hudMargin
                : null,
            child: topHud,
          ),

        // 중앙 영역 (좌/우 HUD)
        Expanded(
          child: Row(
            children: [
              // 좌측 HUD
              if (leftHud != null)
                Container(
                  color: hudBackgroundColor,
                  padding: EdgeInsets.only(
                    left: padding.left + MGSpacing.hudMargin,
                  ),
                  width: leftHudWidth != null
                      ? leftHudWidth! + padding.left + MGSpacing.hudMargin
                      : null,
                  child: leftHud,
                ),

              // 빈 공간 (게임 영역)
              const Expanded(child: SizedBox()),

              // 우측 HUD
              if (rightHud != null)
                Container(
                  color: hudBackgroundColor,
                  padding: EdgeInsets.only(
                    right: padding.right + MGSpacing.hudMargin,
                  ),
                  width: rightHudWidth != null
                      ? rightHudWidth! + padding.right + MGSpacing.hudMargin
                      : null,
                  child: rightHud,
                ),
            ],
          ),
        ),

        // 하단 HUD
        if (bottomHud != null)
          Container(
            color: hudBackgroundColor,
            padding: EdgeInsets.only(
              bottom: padding.bottom + MGSpacing.hudMargin,
              left: padding.left + MGSpacing.hudMargin,
              right: padding.right + MGSpacing.hudMargin,
            ),
            height: bottomHudHeight != null
                ? bottomHudHeight! + padding.bottom + MGSpacing.hudMargin
                : null,
            child: bottomHud,
          ),
      ],
    );
  }
}

/// 타워 디펜스 HUD 레이아웃 (MG-0001)
/// 상단: 웨이브/자원 | 하단: 타워 선택 | 우측: 게임 속도
class MGTowerDefenseCanvas extends StatelessWidget {
  final Widget gameContent;
  final Widget waveInfo;
  final Widget resourceBar;
  final Widget towerSelection;
  final Widget speedControl;
  final Widget? pauseMenu;

  const MGTowerDefenseCanvas({
    super.key,
    required this.gameContent,
    required this.waveInfo,
    required this.resourceBar,
    required this.towerSelection,
    required this.speedControl,
    this.pauseMenu,
  });

  @override
  Widget build(BuildContext context) {
    return MGGameCanvas(
      gameContent: gameContent,
      topHud: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          waveInfo,
          resourceBar,
        ],
      ),
      bottomHud: towerSelection,
      rightHud: speedControl,
      centerOverlay: pauseMenu,
    );
  }
}

/// 퍼즐 게임 HUD 레이아웃
/// 상단: 레벨/점수 | 하단: 남은 이동/힌트
class MGPuzzleCanvas extends StatelessWidget {
  final Widget gameContent;
  final Widget levelInfo;
  final Widget scoreDisplay;
  final Widget movesLeft;
  final Widget? hintButton;
  final Widget? overlay;

  const MGPuzzleCanvas({
    super.key,
    required this.gameContent,
    required this.levelInfo,
    required this.scoreDisplay,
    required this.movesLeft,
    this.hintButton,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    return MGGameCanvas(
      gameContent: gameContent,
      topHud: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          levelInfo,
          scoreDisplay,
        ],
      ),
      bottomHud: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          movesLeft,
          if (hintButton != null) hintButton!,
        ],
      ),
      centerOverlay: overlay,
    );
  }
}

/// 아이들 게임 HUD 레이아웃
/// 상단: 자원 바 | 하단: 주요 버튼
class MGIdleCanvas extends StatelessWidget {
  final Widget gameContent;
  final Widget resourceBar;
  final Widget actionButtons;
  final Widget? overlay;

  const MGIdleCanvas({
    super.key,
    required this.gameContent,
    required this.resourceBar,
    required this.actionButtons,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    return MGGameCanvas(
      gameContent: gameContent,
      topHud: resourceBar,
      bottomHud: actionButtons,
      centerOverlay: overlay,
    );
  }
}

/// 카드 게임 HUD 레이아웃 (Landscape)
/// 상단: 상대방 정보 | 하단: 내 카드/액션 | 좌측: 덱 | 우측: 턴 정보
class MGCardGameCanvas extends StatelessWidget {
  final Widget gameContent;
  final Widget opponentInfo;
  final Widget myHand;
  final Widget deckInfo;
  final Widget turnInfo;
  final Widget? overlay;

  const MGCardGameCanvas({
    super.key,
    required this.gameContent,
    required this.opponentInfo,
    required this.myHand,
    required this.deckInfo,
    required this.turnInfo,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    return MGGameCanvas(
      gameContent: gameContent,
      topHud: opponentInfo,
      bottomHud: myHand,
      leftHud: deckInfo,
      rightHud: turnInfo,
      centerOverlay: overlay,
    );
  }
}

/// HUD 포지션 열거형
enum HudPosition {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  center,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

/// 커스텀 HUD 배치를 위한 위젯
class MGHudElement extends StatelessWidget {
  final Widget child;
  final HudPosition position;
  final EdgeInsets? margin;

  const MGHudElement({
    super.key,
    required this.child,
    required this.position,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final safeArea = MediaQuery.of(context).padding;
    final defaultMargin = EdgeInsets.only(
      top: safeArea.top + MGSpacing.hudMargin,
      bottom: safeArea.bottom + MGSpacing.hudMargin,
      left: safeArea.left + MGSpacing.hudMargin,
      right: safeArea.right + MGSpacing.hudMargin,
    );

    final effectiveMargin = margin ?? defaultMargin;

    Alignment alignment;
    switch (position) {
      case HudPosition.topLeft:
        alignment = Alignment.topLeft;
        break;
      case HudPosition.topCenter:
        alignment = Alignment.topCenter;
        break;
      case HudPosition.topRight:
        alignment = Alignment.topRight;
        break;
      case HudPosition.centerLeft:
        alignment = Alignment.centerLeft;
        break;
      case HudPosition.center:
        alignment = Alignment.center;
        break;
      case HudPosition.centerRight:
        alignment = Alignment.centerRight;
        break;
      case HudPosition.bottomLeft:
        alignment = Alignment.bottomLeft;
        break;
      case HudPosition.bottomCenter:
        alignment = Alignment.bottomCenter;
        break;
      case HudPosition.bottomRight:
        alignment = Alignment.bottomRight;
        break;
    }

    return Align(
      alignment: alignment,
      child: Padding(
        padding: effectiveMargin,
        child: child,
      ),
    );
  }
}

/// 자유 배치 HUD 캔버스
class MGFreeformCanvas extends StatelessWidget {
  final Widget gameContent;
  final List<MGHudElement> hudElements;
  final Widget? overlay;

  const MGFreeformCanvas({
    super.key,
    required this.gameContent,
    this.hudElements = const [],
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 게임 콘텐츠
        Positioned.fill(child: gameContent),

        // HUD 요소들
        ...hudElements.map((element) => Positioned.fill(child: element)),

        // 오버레이
        if (overlay != null) Positioned.fill(child: overlay!),
      ],
    );
  }
}
