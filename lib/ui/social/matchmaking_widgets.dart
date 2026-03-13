import 'package:flutter/material.dart';
import 'package:mg_common_game/social/matchmaking_manager.dart';

/// 매칭 요청 카드
class MatchRequestCard extends StatelessWidget {
  final MatchRequest request;
  final VoidCallback? onCancel;
  final Duration? estimatedWaitTime;

  const MatchRequestCard({
    super.key,
    required this.request,
    this.onCancel,
    this.estimatedWaitTime,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.search, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '매칭 중',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        request.gameMode,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (estimatedWaitTime != null)
                  Column(
                    children: [
                      Text(
                        '${estimatedWaitTime!.inSeconds}초',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Text('예상 대기시간'),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: null, // Indeterminate
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onCancel,
                child: const Text('매칭 취소'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 매칭 화면
class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  final _matchmaker = MatchmakingManager.instance;
  MatchRequest? _currentRequest;
  bool _isMatching = false;

  @override
  void initState() {
    super.initState();
    _checkExistingRequest();
  }

  void _checkExistingRequest() {
    _currentRequest = _matchmaker.getActiveRequest('current_user');
    if (_currentRequest != null) {
      setState(() => _isMatching = true);
    }
  }

  Future<void> _startMatchmaking() async {
    final request = MatchRequest(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'current_user',
      username: '플레이어',
      gameMode: 'ranked',
      rating: _matchmaker.getPlayerRating('current_user', 'ranked'),
      requestedAt: DateTime.now(),
    );

    await _matchmaker.requestMatch(request);

    setState(() {
      _currentRequest = request;
      _isMatching = true;
    });

    _waitForMatch();
  }

  Future<void> _waitForMatch() async {
    final match = await _matchmaker.findMatch(
      userId: 'current_user',
      timeout: const Duration(minutes: 5),
    );

    if (match != null && mounted) {
      _showMatchFoundDialog(match);
    }
  }

  void _cancelMatchmaking() async {
    final cancelled = await _matchmaker.cancelMatch('current_user');

    if (cancelled && mounted) {
      setState(() {
        _currentRequest = null;
        _isMatching = false;
      });
    }
  }

  void _showMatchFoundDialog(Match match) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('매칭 완료!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text('매치 ID: ${match.id}'),
            const SizedBox(height: 8),
            Text('게임 모드: ${match.gameMode}'),
            const SizedBox(height: 16),
            ...match.players.map((player) => ListTile(
                  leading: CircleAvatar(child: Text(player[0])),
                  title: Text(player),
                )),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // 게임 시작
            },
            child: const Text('게임 시작'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerRating = _matchmaker.getPlayerRating('current_user', 'ranked');
    final tier = _matchmaker.getTierForRating(playerRating);

    return Scaffold(
      appBar: AppBar(title: const Text('매칭')),
      body: _isMatching && _currentRequest != null
          ? MatchRequestCard(
              request: _currentRequest!,
              onCancel: _cancelMatchmaking,
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TierDisplay(tier: tier, rating: playerRating),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _startMatchmaking,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('매칭 시작'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// 티어 표시 위젯
class TierDisplay extends StatelessWidget {
  final MatchTier tier;
  final int rating;

  const TierDisplay({
    super.key,
    required this.tier,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final tierInfo = _getTierInfo(tier);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tierInfo.color.withOpacity(0.3),
            tierInfo.color.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tierInfo.color, width: 2),
      ),
      child: Column(
        children: [
          Icon(tierInfo.icon, size: 64, color: tierInfo.color),
          const SizedBox(height: 16),
          Text(
            tierInfo.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: tierInfo.color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '$rating LP',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  TierInfo _getTierInfo(MatchTier tier) {
    switch (tier) {
      case MatchTier.bronze:
        return TierInfo(
          name: '브론즈',
          icon: Icons.military_tech,
          color: Colors.brown,
        );
      case MatchTier.silver:
        return TierInfo(
          name: '실버',
          icon: Icons.military_tech,
          color: Colors.grey,
        );
      case MatchTier.gold:
        return TierInfo(
          name: '골드',
          icon: Icons.emoji_events,
          color: Colors.amber,
        );
      case MatchTier.platinum:
        return TierInfo(
          name: '플래티넘',
          icon: Icons.emoji_events,
          color: Colors.blue,
        );
      case MatchTier.diamond:
        return TierInfo(
          name: '다이아몬드',
          icon: Icons.diamond,
          color: Colors.cyan,
        );
      case MatchTier.master:
        return TierInfo(
          name: '마스터',
          icon: Icons.star,
          color: Colors.purple,
        );
      case MatchTier.challenger:
        return TierInfo(
          name: '챌린저',
          icon: Icons.workspace_premium,
          color: Colors.red,
        );
    }
  }
}

class TierInfo {
  final String name;
  final IconData icon;
  final Color color;

  TierInfo({required this.name, required this.icon, required this.color});
}

/// 랭킹 화면
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final _matchmaker = MatchmakingManager.instance;
  List<RankingEntry> _rankings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRankings();
  }

  Future<void> _loadRankings() async {
    setState(() => _loading = true);

    final rankings = _matchmaker.getRankings(
      gameMode: 'ranked',
      limit: 100,
    );

    setState(() {
      _rankings = rankings;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('랭킹')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _rankings.length,
              itemBuilder: (context, index) {
                final entry = _rankings[index];
                return RankingTile(
                  rank: index + 1,
                  entry: entry,
                );
              },
            ),
    );
  }
}

/// 랭킹 타일
class RankingTile extends StatelessWidget {
  final int rank;
  final RankingEntry entry;

  const RankingTile({
    super.key,
    required this.rank,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = _getRankColor(rank);

    return Container(
      decoration: BoxDecoration(
        color: rankColor?.withOpacity(0.1),
        border: rank <= 3 ? Border.all(color: rankColor ?? Colors.grey) : null,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: rankColor,
          child: Text(
            '$rank',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        title: Text(entry.username),
        subtitle: Text('${entry.wins}승 ${entry.losses}패 (${entry.winRate.toStringAsFixed(1)}%)'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.rating} LP',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              _getTierName(entry.rating),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Color? _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return null;
    }
  }

  String _getTierName(int rating) {
    final tier = MatchmakingManager.instance.getTierForRating(rating);
    return tier.name.toUpperCase();
  }
}
