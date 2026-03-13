import 'package:flutter/material.dart';
import 'package:mg_common_game/competitive/leaderboard_manager.dart';

class LeaderboardWidget extends StatefulWidget {
  final String leaderboardId;

  const LeaderboardWidget({
    Key? key,
    required this.leaderboardId,
  }) : super(key: key);

  @override
  State<LeaderboardWidget> createState() => _LeaderboardWidgetState();
}

class _LeaderboardWidgetState extends State<LeaderboardWidget> {
  final LeaderboardManager _leaderboardManager = LeaderboardManager.instance;

  Leaderboard? _leaderboard;
  List<LeaderboardEntry> _entries = [];
  bool _isLoading = true;
  String _userId = 'current_user';

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    await _leaderboardManager.initialize();
    setState(() => _isLoading = true);

    _leaderboard = _leaderboardManager.getLeaderboard(widget.leaderboardId);
    if (_leaderboard != null) {
      _entries = _leaderboardManager.getEntries(widget.leaderboardId);
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_leaderboard?.name ?? 'Leaderboard'),
      ),
      body: Column(
        children: [
          _buildTopThree(),
          Expanded(
            child: _buildEntriesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopThree() {
    if (_entries.isEmpty) {
      return const SizedBox.shrink();
    }

    final topThree = _entries.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: topThree.asMap().entries.map((entry) {
          final index = entry.key;
          final player = entry.value;
          return _buildTopPlayerCard(player, index);
        }).toList(),
      ),
    );
  }

  Widget _buildTopPlayerCard(LeaderboardEntry player, int index) {
    final heights = [80.0, 100.0, 80.0];
    final colors = [Colors.brown, Colors.grey, Colors.orange];
    final icons = [Icons.emoji_events, Icons.military_tech, Icons.stars];

    return Column(
      children: [
        Container(
          width: 60,
          height: heights[index],
          decoration: BoxDecoration(
            color: colors[index],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${player.rank}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        CircleAvatar(
          radius: 24,
          child: Text(player.username[0].toUpperCase()),
        ),
        const SizedBox(height: 4),
        Text(
          player.username,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${player.score.toInt()} pts',
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildEntriesList() {
    if (_entries.isEmpty) {
      return const Center(child: Text('No entries yet'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        final isUser = entry.userId == _userId;
        return _buildEntryTile(entry, isUser);
      },
    );
  }

  Widget _buildEntryTile(LeaderboardEntry entry, bool isUser) {
    return Container(
      decoration: BoxDecoration(
        border: isUser
            ? Border.all(color: Theme.of(context).primaryColor, width: 2)
            : null,
        borderRadius: BorderRadius.circular(8),
        color: isUser ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRankColor(entry.rank),
          child: Text(
            '${entry.rank}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          entry.username,
          style: TextStyle(fontWeight: isUser ? FontWeight.bold : FontWeight.normal),
        ),
        subtitle: entry.streak > 0 ? Text('🔥 ${entry.streak} win streak') : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.score.toInt()}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'pts',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.grey;
    if (rank == 3) return Colors.orange;
    if (rank <= 10) return Colors.blue;
    return Colors.grey[300]!;
  }
}
