import 'package:flutter/material.dart';
import 'package:mg_common_game/systems/stats/statistics_manager.dart';
import 'package:mg_common_game/systems/progression/progression_manager.dart';
import 'package:mg_common_game/systems/progression/prestige_manager.dart';
import 'package:mg_common_game/systems/quests/daily_quest.dart';
import 'package:mg_common_game/systems/progression/achievement_manager.dart';

class StatisticsScreen extends StatefulWidget {
  final StatisticsManager statisticsManager;
  final ProgressionManager? progressionManager;
  final PrestigeManager? prestigeManager;
  final DailyQuestManager? questManager;
  final AchievementManager? achievementManager;
  final String title;
  final Color accentColor;
  final VoidCallback onClose;

  const StatisticsScreen({
    super.key,
    required this.statisticsManager,
    this.progressionManager,
    this.prestigeManager,
    this.questManager,
    this.achievementManager,
    required this.title,
    required this.accentColor,
    required this.onClose,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    widget.statisticsManager.addListener(_onStatsUpdate);
  }

  @override
  void dispose() {
    widget.statisticsManager.removeListener(_onStatsUpdate);
    super.dispose();
  }

  void _onStatsUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: widget.accentColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onClose,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              widget.statisticsManager.resetSessionStats();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Session stats reset'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Reset Session Stats',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Session
            _SectionHeader(
              title: 'Current Session',
              icon: Icons.access_time,
              color: widget.accentColor,
            ),
            const SizedBox(height: 12),
            _StatsCard(
              children: [
                _StatRow(
                  label: 'Session Time',
                  value: widget.statisticsManager.currentSessionTimeFormatted,
                  icon: Icons.timer,
                ),
                _StatRow(
                  label: 'Games Played',
                  value: '${widget.statisticsManager.sessionGamesPlayed}',
                  icon: Icons.gamepad,
                ),
                _StatRow(
                  label: 'Gold Earned',
                  value: '${widget.statisticsManager.sessionGoldEarned}',
                  icon: Icons.monetization_on,
                  valueColor: Colors.amber,
                ),
                _StatRow(
                  label: 'XP Earned',
                  value: '${widget.statisticsManager.sessionXpEarned}',
                  icon: Icons.star,
                  valueColor: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Lifetime Stats
            _SectionHeader(
              title: 'Lifetime Statistics',
              icon: Icons.history,
              color: widget.accentColor,
            ),
            const SizedBox(height: 12),
            _StatsCard(
              children: [
                _StatRow(
                  label: 'Total Play Time',
                  value: widget.statisticsManager.totalPlayTimeFormatted,
                  icon: Icons.schedule,
                ),
                _StatRow(
                  label: 'Total Games',
                  value: '${widget.statisticsManager.totalGamesPlayed}',
                  icon: Icons.games,
                ),
                _StatRow(
                  label: 'Total Gold',
                  value: '${widget.statisticsManager.totalGoldEarned}',
                  icon: Icons.monetization_on,
                  valueColor: Colors.amber,
                ),
                _StatRow(
                  label: 'Total XP',
                  value: '${widget.statisticsManager.totalXpEarned}',
                  icon: Icons.star,
                  valueColor: Colors.purple,
                ),
                _StatRow(
                  label: 'Avg Gold/Game',
                  value: widget.statisticsManager.averageGoldPerGame.toStringAsFixed(1),
                  icon: Icons.trending_up,
                ),
                _StatRow(
                  label: 'Avg XP/Game',
                  value: widget.statisticsManager.averageXpPerGame.toStringAsFixed(1),
                  icon: Icons.trending_up,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Records
            _SectionHeader(
              title: 'Records',
              icon: Icons.emoji_events,
              color: Colors.amber,
            ),
            const SizedBox(height: 12),
            _StatsCard(
              children: [
                _StatRow(
                  label: 'Highest Level',
                  value: '${widget.statisticsManager.highestLevel}',
                  icon: Icons.arrow_upward,
                  valueColor: Colors.green,
                ),
                _StatRow(
                  label: 'Most Gold (Single Game)',
                  value: '${widget.statisticsManager.mostGoldInSingleGame}',
                  icon: Icons.local_fire_department,
                  valueColor: Colors.amber,
                ),
                _StatRow(
                  label: 'Longest Session',
                  value: _formatDuration(widget.statisticsManager.longestSessionSeconds),
                  icon: Icons.timer,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Progression
            if (widget.progressionManager != null || widget.prestigeManager != null)
              _SectionHeader(
                title: 'Progression',
                icon: Icons.timeline,
                color: widget.accentColor,
              ),
            if (widget.progressionManager != null || widget.prestigeManager != null)
              const SizedBox(height: 12),
            if (widget.progressionManager != null || widget.prestigeManager != null)
              _StatsCard(
                children: [
                  if (widget.progressionManager != null) ...[
                    _StatRow(
                      label: 'Current Level',
                      value: '${widget.progressionManager!.currentLevel}',
                      icon: Icons.bar_chart,
                      valueColor: Colors.blue,
                    ),
                    _StatRow(
                      label: 'Current XP',
                      value: '${widget.progressionManager!.currentXp} / ${widget.progressionManager!.xpToNextLevel}',
                      icon: Icons.trending_up,
                    ),
                  ],
                  if (widget.prestigeManager != null) ...[
                    _StatRow(
                      label: 'Prestige Level',
                      value: '${widget.prestigeManager!.prestigeLevel}',
                      icon: Icons.auto_awesome,
                      valueColor: Colors.amber,
                    ),
                    _StatRow(
                      label: 'Prestige Points',
                      value: '${widget.prestigeManager!.prestigePoints}',
                      icon: Icons.star,
                      valueColor: Colors.amber,
                    ),
                    _StatRow(
                      label: 'Total Prestiges',
                      value: '${widget.statisticsManager.totalPrestigesPerformed}',
                      icon: Icons.refresh,
                    ),
                  ],
                ],
              ),
            if (widget.progressionManager != null || widget.prestigeManager != null)
              const SizedBox(height: 24),

            // Activities
            _SectionHeader(
              title: 'Activities',
              icon: Icons.checklist,
              color: widget.accentColor,
            ),
            const SizedBox(height: 12),
            _StatsCard(
              children: [
                _StatRow(
                  label: 'Daily Quests Completed',
                  value: '${widget.statisticsManager.totalDailyQuestsCompleted}',
                  icon: Icons.assignment_turned_in,
                  valueColor: Colors.purple,
                ),
                if (widget.questManager != null)
                  _StatRow(
                    label: 'Today\'s Progress',
                    value: '${widget.questManager!.completedQuestCount} / ${widget.questManager!.totalQuestCount}',
                    icon: Icons.today,
                  ),
                _StatRow(
                  label: 'Achievements Unlocked',
                  value: '${widget.statisticsManager.totalAchievementsUnlocked}',
                  icon: Icons.military_tech,
                  valueColor: Colors.orange,
                ),
                if (widget.achievementManager != null)
                  _StatRow(
                    label: 'Total Achievements',
                    value: '${widget.achievementManager!.unlockedCount} / ${widget.achievementManager!.totalCount}',
                    icon: Icons.stars,
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  final List<Widget> children;

  const _StatsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2d2d44),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
