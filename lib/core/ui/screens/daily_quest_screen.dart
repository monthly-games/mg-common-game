import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/systems/quests/daily_quest.dart';
import 'package:mg_common_game/systems/settings/settings_manager.dart';

class DailyQuestScreen extends StatefulWidget {
  final DailyQuestManager questManager;
  final String title;
  final Color accentColor;
  final Function(String questId, int goldReward, int xpReward) onClaimReward;
  final VoidCallback onClose;

  const DailyQuestScreen({
    super.key,
    required this.questManager,
    required this.title,
    required this.accentColor,
    required this.onClaimReward,
    required this.onClose,
  });

  @override
  State<DailyQuestScreen> createState() => _DailyQuestScreenState();
}

class _DailyQuestScreenState extends State<DailyQuestScreen> {
  @override
  void initState() {
    super.initState();
    widget.questManager.addListener(_onQuestUpdate);
  }

  @override
  void dispose() {
    widget.questManager.removeListener(_onQuestUpdate);
    super.dispose();
  }

  void _onQuestUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = widget.questManager.completedQuestCount;
    final totalCount = widget.questManager.totalQuestCount;

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
          // Header with progress
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
                    Icon(Icons.assignment_turned_in, color: Colors.amber, size: 32),
                    SizedBox(width: 12),
                    Text(
                      'Daily Quests',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
              ],
            ),
          ),

          // Quest list
          Expanded(
            child: widget.questManager.allQuests.isEmpty
                ? const Center(
                    child: Text(
                      'No quests available',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 18,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.questManager.allQuests.length,
                    itemBuilder: (context, index) {
                      final quest = widget.questManager.allQuests[index];
                      return _QuestCard(
                        quest: quest,
                        accentColor: widget.accentColor,
                        onClaimReward: () => _claimReward(quest),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _claimReward(DailyQuest quest) {
    final success = widget.questManager.claimQuestReward(quest.id);
    if (success) {
      // Haptic feedback on quest reward claim
      _triggerHaptic(VibrationIntensity.medium);

      widget.onClaimReward(quest.id, quest.goldReward, quest.xpReward);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Claimed! +${quest.goldReward} Gold, +${quest.xpReward} XP',
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

class _QuestCard extends StatelessWidget {
  final DailyQuest quest;
  final Color accentColor;
  final VoidCallback onClaimReward;

  const _QuestCard({
    required this.quest,
    required this.accentColor,
    required this.onClaimReward,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = quest.isCompleted;
    final isClaimed = quest.isClaimedReward;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isClaimed
          ? Colors.grey.shade800.withValues(alpha: 0.5)
          : const Color(0xFF2d2d44),
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
                    quest.title,
                    style: TextStyle(
                      fontSize: 18,
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
            const SizedBox(height: 8),

            // Description
            Text(
              quest.description,
              style: TextStyle(
                fontSize: 14,
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
                        '${quest.currentProgress} / ${quest.targetValue}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isClaimed ? Colors.white38 : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: quest.progressPercentage,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isClaimed ? Colors.grey : accentColor,
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
                    spacing: 12,
                    children: [
                      _RewardChip(
                        icon: Icons.monetization_on,
                        label: '+${quest.goldReward}',
                        color: Colors.amber,
                        isGrayed: isClaimed,
                      ),
                      _RewardChip(
                        icon: Icons.star,
                        label: '+${quest.xpReward} XP',
                        color: Colors.purple,
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
                        vertical: 12,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isGrayed
            ? Colors.grey.withValues(alpha: 0.3)
            : color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
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
            size: 16,
            color: isGrayed ? Colors.grey : color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isGrayed ? Colors.grey : color,
            ),
          ),
        ],
      ),
    );
  }
}
