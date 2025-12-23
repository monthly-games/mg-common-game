import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/systems/quests/weekly_challenge.dart';
import 'package:mg_common_game/systems/settings/settings_manager.dart';

class WeeklyChallengeScreen extends StatefulWidget {
  final WeeklyChallengeManager challengeManager;
  final String title;
  final Color accentColor;
  final Function(String challengeId, int goldReward, int xpReward, int prestigeReward) onClaimReward;
  final VoidCallback onClose;

  const WeeklyChallengeScreen({
    super.key,
    required this.challengeManager,
    required this.title,
    required this.accentColor,
    required this.onClaimReward,
    required this.onClose,
  });

  @override
  State<WeeklyChallengeScreen> createState() => _WeeklyChallengeScreenState();
}

class _WeeklyChallengeScreenState extends State<WeeklyChallengeScreen> {
  @override
  void initState() {
    super.initState();
    widget.challengeManager.addListener(_onChallengeUpdate);
  }

  @override
  void dispose() {
    widget.challengeManager.removeListener(_onChallengeUpdate);
    super.dispose();
  }

  void _onChallengeUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = widget.challengeManager.completedChallengeCount;
    final totalCount = widget.challengeManager.totalChallengeCount;
    final rewards = widget.challengeManager.getTotalRewardsSummary();

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: widget.accentColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onClose,
        ),
      ),
      body: Column(
        children: [
          // Header with progress and timer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.accentColor.withValues(alpha: 0.3),
                  widget.accentColor.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                    SizedBox(width: 12),
                    Text(
                      'Weekly Challenges',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Timer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer, color: Colors.white70, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        widget.challengeManager.timeUntilResetFormatted,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Progress
                Text(
                  'Completed: $completedCount / $totalCount',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: totalCount > 0 ? completedCount / totalCount : 0,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                  minHeight: 8,
                ),
                const SizedBox(height: 12),

                // Total rewards summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _TotalRewardBadge(
                      icon: Icons.monetization_on,
                      value: '${rewards['gold']}',
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 16),
                    _TotalRewardBadge(
                      icon: Icons.star,
                      value: '${rewards['xp']}',
                      color: Colors.purple,
                    ),
                    if (rewards['prestige']! > 0) ...[
                      const SizedBox(width: 16),
                      _TotalRewardBadge(
                        icon: Icons.auto_awesome,
                        value: '${rewards['prestige']}',
                        color: Colors.cyan,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Challenge list grouped by tier
          Expanded(
            child: widget.challengeManager.allChallenges.isEmpty
                ? const Center(
                    child: Text(
                      'No challenges available',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 18,
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Build sections by tier
                      ..._buildTierSections(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTierSections() {
    final widgets = <Widget>[];

    for (final tier in ChallengeTier.values) {
      final challenges = widget.challengeManager.getChallengesByTier(tier);
      if (challenges.isEmpty) continue;

      widgets.add(_TierHeader(tier: tier));
      widgets.add(const SizedBox(height: 8));

      for (final challenge in challenges) {
        widgets.add(_ChallengeCard(
          challenge: challenge,
          accentColor: widget.accentColor,
          onClaimReward: () => _claimReward(challenge),
        ));
      }

      widgets.add(const SizedBox(height: 16));
    }

    return widgets;
  }

  void _claimReward(WeeklyChallenge challenge) {
    final success = widget.challengeManager.claimChallengeReward(challenge.id);
    if (success) {
      // Haptic feedback on challenge reward claim
      _triggerHaptic(VibrationIntensity.heavy);

      widget.onClaimReward(
        challenge.id,
        challenge.effectiveGoldReward,
        challenge.effectiveXpReward,
        challenge.prestigePointReward,
      );

      final prestigeText = challenge.prestigePointReward > 0
          ? ', +${challenge.prestigePointReward} PP'
          : '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Claimed! +${challenge.effectiveGoldReward} Gold, +${challenge.effectiveXpReward} XP$prestigeText',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      setState(() {});
    }
  }

  void _triggerHaptic(VibrationIntensity intensity) {
    if (GetIt.I.isRegistered<SettingsManager>()) {
      GetIt.I<SettingsManager>().triggerVibration(intensity: intensity);
    }
  }
}

class _TotalRewardBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _TotalRewardBadge({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TierHeader extends StatelessWidget {
  final ChallengeTier tier;

  const _TierHeader({required this.tier});

  Color get tierColor {
    switch (tier) {
      case ChallengeTier.bronze:
        return const Color(0xFFCD7F32);
      case ChallengeTier.silver:
        return const Color(0xFFC0C0C0);
      case ChallengeTier.gold:
        return const Color(0xFFFFD700);
      case ChallengeTier.platinum:
        return const Color(0xFFE5E4E2);
    }
  }

  IconData get tierIcon {
    switch (tier) {
      case ChallengeTier.bronze:
        return Icons.military_tech;
      case ChallengeTier.silver:
        return Icons.military_tech;
      case ChallengeTier.gold:
        return Icons.emoji_events;
      case ChallengeTier.platinum:
        return Icons.workspace_premium;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tierColor.withValues(alpha: 0.3),
            tierColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tierColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(tierIcon, color: tierColor, size: 24),
          const SizedBox(width: 8),
          Text(
            '${tier.displayName} Challenges',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: tierColor,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: tierColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'x${tier.rewardMultiplier.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: tierColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final WeeklyChallenge challenge;
  final Color accentColor;
  final VoidCallback onClaimReward;

  const _ChallengeCard({
    required this.challenge,
    required this.accentColor,
    required this.onClaimReward,
  });

  Color get tierColor {
    switch (challenge.tier) {
      case ChallengeTier.bronze:
        return const Color(0xFFCD7F32);
      case ChallengeTier.silver:
        return const Color(0xFFC0C0C0);
      case ChallengeTier.gold:
        return const Color(0xFFFFD700);
      case ChallengeTier.platinum:
        return const Color(0xFFE5E4E2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = challenge.isCompleted;
    final isClaimed = challenge.isClaimedReward;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isClaimed
          ? Colors.grey.shade800.withValues(alpha: 0.5)
          : const Color(0xFF2d2d44),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isClaimed ? Colors.transparent : tierColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    challenge.title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isClaimed ? Colors.white54 : Colors.white,
                      decoration: isClaimed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (isCompleted && !isClaimed)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  ),
                if (isClaimed)
                  const Icon(
                    Icons.done_all,
                    color: Colors.white54,
                    size: 24,
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Description
            Text(
              challenge.description,
              style: TextStyle(
                fontSize: 13,
                color: isClaimed ? Colors.white38 : Colors.white70,
              ),
            ),
            const SizedBox(height: 12),

            // Progress bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${challenge.currentProgress} / ${challenge.targetValue}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isClaimed ? Colors.white38 : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: challenge.progressPercentage,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isClaimed ? Colors.grey : tierColor,
                        ),
                        minHeight: 6,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Rewards and claim button
            Row(
              children: [
                // Rewards
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _RewardChip(
                        icon: Icons.monetization_on,
                        label: '+${challenge.effectiveGoldReward}',
                        color: Colors.amber,
                        isGrayed: isClaimed,
                      ),
                      _RewardChip(
                        icon: Icons.star,
                        label: '+${challenge.effectiveXpReward}',
                        color: Colors.purple,
                        isGrayed: isClaimed,
                      ),
                      if (challenge.prestigePointReward > 0)
                        _RewardChip(
                          icon: Icons.auto_awesome,
                          label: '+${challenge.prestigePointReward} PP',
                          color: Colors.cyan,
                          isGrayed: isClaimed,
                        ),
                    ],
                  ),
                ),

                // Claim button
                if (isCompleted && !isClaimed)
                  ElevatedButton(
                    onPressed: onClaimReward,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: const Text(
                      'CLAIM',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isGrayed;

  const _RewardChip({
    required this.icon,
    required this.label,
    required this.color,
    this.isGrayed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isGrayed
            ? Colors.grey.withValues(alpha: 0.3)
            : color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isGrayed ? Colors.grey : color,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isGrayed ? Colors.grey : color,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isGrayed ? Colors.grey : color,
            ),
          ),
        ],
      ),
    );
  }
}
