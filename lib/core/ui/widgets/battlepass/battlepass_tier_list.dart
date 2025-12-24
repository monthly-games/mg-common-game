/// 배틀패스 티어 목록 위젯
library;

import 'package:flutter/material.dart';
import '../../../../systems/battlepass/battlepass_config.dart';
import '../../theme/mg_colors.dart';
import '../../theme/mg_spacing.dart';

/// 배틀패스 티어 목록 위젯
class BattlePassTierList extends StatelessWidget {
  final List<BPTier> tiers;
  final int currentLevel;
  final bool isPremium;
  final Set<int> claimedFreeLevels;
  final Set<int> claimedPremiumLevels;
  final void Function(int level, bool isPremium)? onClaimReward;

  const BattlePassTierList({
    super.key,
    required this.tiers,
    required this.currentLevel,
    required this.isPremium,
    this.claimedFreeLevels = const {},
    this.claimedPremiumLevels = const {},
    this.onClaimReward,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: tiers.length,
      itemBuilder: (context, index) {
        final tier = tiers[index];
        return _BattlePassTierCard(
          tier: tier,
          isUnlocked: currentLevel >= tier.level,
          isPremium: isPremium,
          isFreeClaimed: claimedFreeLevels.contains(tier.level),
          isPremiumClaimed: claimedPremiumLevels.contains(tier.level),
          onClaimFree: tier.freeReward != null && currentLevel >= tier.level
              ? () => onClaimReward?.call(tier.level, false)
              : null,
          onClaimPremium: tier.premiumReward != null &&
                          currentLevel >= tier.level &&
                          isPremium
              ? () => onClaimReward?.call(tier.level, true)
              : null,
        );
      },
    );
  }
}

class _BattlePassTierCard extends StatelessWidget {
  final BPTier tier;
  final bool isUnlocked;
  final bool isPremium;
  final bool isFreeClaimed;
  final bool isPremiumClaimed;
  final VoidCallback? onClaimFree;
  final VoidCallback? onClaimPremium;

  const _BattlePassTierCard({
    required this.tier,
    required this.isUnlocked,
    required this.isPremium,
    required this.isFreeClaimed,
    required this.isPremiumClaimed,
    this.onClaimFree,
    this.onClaimPremium,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: EdgeInsets.symmetric(horizontal: MGSpacing.xs),
      child: Column(
        children: [
          // 레벨 표시
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: MGSpacing.sm,
              vertical: MGSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isUnlocked ? MGColors.primary : Colors.grey,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Lv.${tier.level}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: MGSpacing.xs),
          // 프리미엄 보상
          Expanded(
            child: _RewardCard(
              reward: tier.premiumReward,
              isLocked: !isPremium,
              isUnlocked: isUnlocked && isPremium,
              isClaimed: isPremiumClaimed,
              isPremium: true,
              onClaim: !isPremiumClaimed ? onClaimPremium : null,
            ),
          ),
          SizedBox(height: MGSpacing.xs),
          // 무료 보상
          Expanded(
            child: _RewardCard(
              reward: tier.freeReward,
              isLocked: false,
              isUnlocked: isUnlocked,
              isClaimed: isFreeClaimed,
              isPremium: false,
              onClaim: !isFreeClaimed ? onClaimFree : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final BPReward? reward;
  final bool isLocked;
  final bool isUnlocked;
  final bool isClaimed;
  final bool isPremium;
  final VoidCallback? onClaim;

  const _RewardCard({
    required this.reward,
    required this.isLocked,
    required this.isUnlocked,
    required this.isClaimed,
    required this.isPremium,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    if (reward == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    final canClaim = isUnlocked && !isClaimed && !isLocked;

    return GestureDetector(
      onTap: canClaim ? onClaim : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getGradientColors(),
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPremium ? MGColors.gold : Colors.white30,
            width: isPremium ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // 보상 내용
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getRewardIcon(),
                    color: isClaimed ? Colors.white38 : Colors.white,
                    size: 24,
                  ),
                  SizedBox(height: MGSpacing.xs / 2),
                  Text(
                    reward!.amount > 1 ? 'x${reward!.amount}' : '',
                    style: TextStyle(
                      color: isClaimed ? Colors.white38 : Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // 잠금 오버레이
            if (isLocked)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.lock, color: Colors.white54, size: 20),
                ),
              ),
            // 수령 완료 오버레이
            if (isClaimed)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    Icons.check_circle,
                    color: MGColors.success,
                    size: 24,
                  ),
                ),
              ),
            // 수령 가능 표시
            if (canClaim)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: MGColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Color> _getGradientColors() {
    if (isClaimed) {
      return [Colors.grey.shade800, Colors.grey.shade900];
    }
    if (isLocked) {
      return [Colors.grey.shade700, Colors.grey.shade800];
    }
    if (isPremium) {
      return [
        MGColors.gold.withValues(alpha: 0.3),
        MGColors.gold.withValues(alpha: 0.1),
      ];
    }
    return [Colors.white12, Colors.white.withValues(alpha: 0.05)];
  }

  IconData _getRewardIcon() {
    if (reward == null) return Icons.help_outline;
    switch (reward!.type) {
      case BPRewardType.currency:
        return Icons.monetization_on;
      case BPRewardType.gem:
        return Icons.diamond;
      case BPRewardType.item:
        return Icons.inventory_2;
      case BPRewardType.character:
        return Icons.person;
      case BPRewardType.skin:
        return Icons.palette;
      case BPRewardType.exp:
        return Icons.trending_up;
      case BPRewardType.ticket:
        return Icons.confirmation_number;
    }
  }
}

/// 배틀패스 헤더 위젯
class BattlePassHeader extends StatelessWidget {
  final String seasonName;
  final int currentLevel;
  final int maxLevel;
  final int currentExp;
  final int expToNextLevel;
  final int remainingDays;
  final bool isPremium;
  final VoidCallback? onPurchasePremium;

  const BattlePassHeader({
    super.key,
    required this.seasonName,
    required this.currentLevel,
    required this.maxLevel,
    required this.currentExp,
    required this.expToNextLevel,
    required this.remainingDays,
    required this.isPremium,
    this.onPurchasePremium,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(MGSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MGColors.primary.withValues(alpha: 0.3),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          // 시즌 이름 & 남은 시간
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    seasonName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isPremium) ...[
                    SizedBox(width: MGSpacing.sm),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: MGSpacing.sm,
                        vertical: MGSpacing.xs / 2,
                      ),
                      decoration: BoxDecoration(
                        color: MGColors.gold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PREMIUM',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: MGSpacing.sm,
                  vertical: MGSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: remainingDays <= 3 ? MGColors.error : Colors.white12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.white, size: 14),
                    SizedBox(width: MGSpacing.xs),
                    Text(
                      '$remainingDays일 남음',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: MGSpacing.md),
          // 레벨 & 경험치
          Row(
            children: [
              // 현재 레벨
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: MGColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Lv',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    Text(
                      '$currentLevel',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: MGSpacing.md),
              // 경험치 바
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'EXP',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          '$currentExp / $expToNextLevel',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: MGSpacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: expToNextLevel > 0
                            ? currentExp / expToNextLevel
                            : 0,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          MGColors.exp,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // 프리미엄 구매 버튼
          if (!isPremium) ...[
            SizedBox(height: MGSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onPurchasePremium,
                icon: const Icon(Icons.star, color: Colors.black),
                label: const Text(
                  '프리미엄 구매',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MGColors.gold,
                  padding: EdgeInsets.symmetric(vertical: MGSpacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 배틀패스 미션 목록 위젯
class BattlePassMissionList extends StatelessWidget {
  final List<BPMission> missions;
  final Map<String, int> missionProgress;
  final Set<String> claimedMissions;
  final void Function(String missionId)? onClaimMission;

  const BattlePassMissionList({
    super.key,
    required this.missions,
    this.missionProgress = const {},
    this.claimedMissions = const {},
    this.onClaimMission,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: missions.length,
      separatorBuilder: (_, __) => SizedBox(height: MGSpacing.sm),
      itemBuilder: (context, index) {
        final mission = missions[index];
        final progress = missionProgress[mission.trackingKey] ?? 0;
        final isClaimed = claimedMissions.contains(mission.id);
        final isComplete = progress >= mission.targetValue;

        return _MissionCard(
          mission: mission,
          progress: progress,
          isClaimed: isClaimed,
          isComplete: isComplete,
          onClaim: isComplete && !isClaimed
              ? () => onClaimMission?.call(mission.id)
              : null,
        );
      },
    );
  }
}

class _MissionCard extends StatelessWidget {
  final BPMission mission;
  final int progress;
  final bool isClaimed;
  final bool isComplete;
  final VoidCallback? onClaim;

  const _MissionCard({
    required this.mission,
    required this.progress,
    required this.isClaimed,
    required this.isComplete,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(MGSpacing.md),
      decoration: BoxDecoration(
        color: isClaimed ? Colors.white.withValues(alpha: 0.05) : Colors.white12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete && !isClaimed
              ? MGColors.success
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // 미션 아이콘
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getMissionTypeColor().withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getMissionTypeIcon(),
              color: _getMissionTypeColor(),
              size: 24,
            ),
          ),
          SizedBox(width: MGSpacing.md),
          // 미션 내용
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.titleKr,
                  style: TextStyle(
                    color: isClaimed ? Colors.white38 : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: MGSpacing.xs / 2),
                Text(
                  mission.descriptionKr,
                  style: TextStyle(
                    color: isClaimed ? Colors.white24 : Colors.white60,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: MGSpacing.xs),
                // 진행률 바
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: (progress / mission.targetValue).clamp(0.0, 1.0),
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isComplete ? MGColors.success : MGColors.primary,
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    SizedBox(width: MGSpacing.sm),
                    Text(
                      '$progress/${mission.targetValue}',
                      style: TextStyle(
                        color: isClaimed ? Colors.white24 : Colors.white60,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: MGSpacing.md),
          // 보상 & 수령 버튼
          Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.trending_up, color: Colors.amber, size: 14),
                  SizedBox(width: MGSpacing.xs / 2),
                  Text(
                    '+${mission.expReward}',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (isComplete && !isClaimed) ...[
                SizedBox(height: MGSpacing.xs),
                ElevatedButton(
                  onPressed: onClaim,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MGColors.success,
                    padding: EdgeInsets.symmetric(
                      horizontal: MGSpacing.sm,
                      vertical: MGSpacing.xs,
                    ),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    '수령',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ],
              if (isClaimed)
                Icon(
                  Icons.check_circle,
                  color: MGColors.success.withValues(alpha: 0.5),
                  size: 24,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getMissionTypeColor() {
    switch (mission.type) {
      case BPMissionType.daily:
        return MGColors.info;
      case BPMissionType.weekly:
        return MGColors.warning;
      case BPMissionType.seasonal:
        return MGColors.success;
    }
  }

  IconData _getMissionTypeIcon() {
    switch (mission.type) {
      case BPMissionType.daily:
        return Icons.today;
      case BPMissionType.weekly:
        return Icons.date_range;
      case BPMissionType.seasonal:
        return Icons.emoji_events;
    }
  }
}
