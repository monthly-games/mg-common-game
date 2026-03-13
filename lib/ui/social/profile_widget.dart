import 'package:flutter/material.dart';
import 'package:mg_common_game/player/progression_manager.dart';
import 'package:mg_common_game/competitive/leaderboard_manager.dart';

class ProfileWidget extends StatefulWidget {
  final String userId;

  const ProfileWidget({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  final ProgressionManager _progressionManager = ProgressionManager.instance;
  final LeaderboardManager _leaderboardManager = LeaderboardManager.instance;

  PlayerProgress? _progress;
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    await _progressionManager.initialize();
    await _leaderboardManager.initialize();

    setState(() => _isLoading = true);
    _progress = _progressionManager.getPlayerProgress(widget.userId);
    if (_progress != null) {
      _stats = _progressionManager.getProgressionStats(widget.userId);
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _progress == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Level ${_progress!.level}'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.7),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.person, size: 80, color: Colors.white54),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildLevelProgress(),
                  const SizedBox(height: 16),
                  _buildStatsGrid(),
                  const SizedBox(height: 16),
                  _buildRankCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelProgress() {
    final progress = _progress!.levelProgress;
    final xpToNext = _progress!.xpToNextLevel;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Level Progress', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${_progress!.level} → ${_progress!.level + 1}'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              minHeight: 8,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${(progress * 100).toStringAsFixed(0)}%'),
                Text('$xpToNext XP to next level', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.5,
      children: [
        _buildStatCard('Rank', _progress!.rank.name, Icons.military_tech, Colors.amber),
        _buildStatCard('Current Stage', _progress!.stageId, Icons.map, Colors.blue),
        _buildStatCard('Completed Quests', '${_stats?['completedQuests'] ?? 0}', Icons.check_circle, Colors.green),
        _buildStatCard('Achievements', '${_stats?['totalAchievements'] ?? 0}', Icons.emoji_events, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12)),
                  Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankCard() {
    final rankName = _progress!.rank.name;
    final rankColor = _getRankColor(_progress!.rank);

    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [rankColor.withOpacity(0.2), rankColor.withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.workspace_premium, color: rankColor, size: 48),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Rank', style: TextStyle(fontSize: 12)),
                  Text(
                    rankName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: rankColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(Rank rank) {
    switch (rank) {
      case Rank.bronze:
        return Colors.brown;
      case Rank.silver:
        return Colors.grey;
      case Rank.gold:
        return Colors.amber;
      case Rank.platinum:
        return Colors.lightBlue;
      case Rank.diamond:
        return Colors.cyan;
      case Rank.master:
        return Colors.deepPurple;
      case Rank.grandmaster:
        return Colors.red;
      case Rank.challenger:
        return Colors.orange;
    }
  }
}
