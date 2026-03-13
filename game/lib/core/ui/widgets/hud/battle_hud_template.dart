import 'package:flutter/material.dart';
import 'package:mg_common_game/core/ui/mg_ui.dart';

/// Match-3/Battle RPG Game HUD
/// Displays stage, turn, unit counts, and battle results
class MGMatch3BattleHud extends StatelessWidget {
  final String? stageLabel;
  final int turn;
  final int playerAlive;
  final int playerTotal;
  final int enemyAlive;
  final int enemyTotal;
  final bool isBattleOver;
  final bool isVictory;
  final Color? themeColor;
  final IconData playerIcon;
  final IconData enemyIcon;

  const MGMatch3BattleHud({
    super.key,
    this.stageLabel,
    required this.turn,
    required this.playerAlive,
    required this.playerTotal,
    required this.enemyAlive,
    required this.enemyTotal,
    this.isBattleOver = false,
    this.isVictory = false,
    this.themeColor,
    this.playerIcon = Icons.shield,
    this.enemyIcon = Icons.dangerous,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(MGSpacing.sm),
        child: Column(
          children: [
            // Top HUD
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MGSpacing.md,
                vertical: MGSpacing.xs,
              ),
              child: _buildStageInfo(),
            ),
            const Spacer(),
            // Unit status
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MGSpacing.md,
                vertical: MGSpacing.xs,
              ),
              child: _buildUnitStatus(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageInfo() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MGSpacing.md,
        vertical: MGSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: MGColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: MGColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'STAGE ${stageLabel ?? "1"}/$turn',
            style: MGTextStyles.h1.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitStatus() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.shield,
          color: MGColors.success,
          size: 20,
        ),
        SizedBox(width: MGSpacing.xs),
        Text(
          'PLAYER: $playerAlive/$playerTotal',
          style: MGTextStyles.bodySmall.copyWith(
            color: MGColors.success,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    return number.toString();
  }
}
