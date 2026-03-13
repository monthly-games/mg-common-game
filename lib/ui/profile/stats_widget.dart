import 'package:flutter/material.dart';
import 'package:mg_common_game/player/progression_manager.dart';

class StatsWidget extends StatefulWidget {
  final String userId;

  const StatsWidget({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<StatsWidget> createState() => _StatsWidgetState();
}

class _StatsWidgetState extends State<StatsWidget> {
  final ProgressionManager _progressionManager = ProgressionManager.instance;

  Map<String, dynamic> _stats = {};
  List<Achievement> _completedAchievements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    await _progressionManager.initialize();
    setState(() => _isLoading = true);

    _stats = _progressionManager.getProgressionStats(widget.userId);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildOverviewCard(),
          const SizedBox(height: 16),
          _buildDetailedStats(),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    final level = _stats['level'] ?? 1;
    final totalPoints = _stats['totalPoints'] ?? 0;
    final completionRate = (_stats['completionRate'] ?? 0.0) * 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildOverviewItem('Level', '$level', Icons.looks_one),
                _buildOverviewItem('Points', '$totalPoints', Icons.stars),
                _buildOverviewItem('Completion', '${completionRate.toStringAsFixed(1)}%', Icons.pie_chart),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildDetailedStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Progression Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildStatRow('Current Level', '${_stats['level'] ?? 1}'),
        _buildStatRow('Total XP', '${_stats['totalXP'] ?? 0}'),
        _buildStatRow('Current XP', '${_stats['currentXP'] ?? 0}'),
        _buildStatRow('Stages Completed', '${_stats['stagesCompleted'] ?? 0}'),
        _buildStatRow('Daily XP', '${_stats['dailyXP'] ?? 0}'),
        _buildStatRow('Login Streak', '${_stats['loginStreak'] ?? 0} days'),
        const SizedBox(height: 24),
        const Text('Achievements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildStatRow('Total Achievements', '${_stats['totalAchievements'] ?? 0}'),
        _buildStatRow('Completed', '${_stats['completedAchievements'] ?? 0}'),
        _buildStatRow('In Progress', '${_stats['inProgressAchievements'] ?? 0}'),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
