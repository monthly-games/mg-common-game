import 'package:flutter/material.dart';
import 'package:mg_common_game/esports/tournament_manager.dart';

/// E-Sports 메인 화면
class EsportsHubScreen extends StatefulWidget {
  const EsportsHubScreen({super.key});

  @override
  State<EsportsHubScreen> createState() => _EsportsHubScreenState();
}

class _EsportsHubScreenState extends State<EsportsHubScreen> {
  final _esportsManager = EsportsManager.instance;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('E-Sports')),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          TournamentListScreen(),
          MyTournamentsScreen(),
          TournamentBracketScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: '토너먼트',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '내 토너먼트',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bracket),
            label: '브래킷',
          ),
        ],
      ),
    );
  }
}

/// 토너먼트 목록 화면
class TournamentListScreen extends StatefulWidget {
  const TournamentListScreen({super.key});

  @override
  State<TournamentListScreen> createState() => _TournamentListScreenState();
}

class _TournamentListScreenState extends State<TournamentListScreen> {
  final _esportsManager = EsportsManager.instance;
  List<Tournament> _tournaments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  Future<void> _loadTournaments() async {
    setState(() => _loading = true);

    // 전체 토너먼트 목록 로드
    _tournaments = _esportsManager.getAllTournaments();

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : _tournaments.isEmpty
            ? const Center(child: Text('진행 중인 토너먼트가 없습니다'))
            : RefreshIndicator(
                onRefresh: _loadTournaments,
                child: ListView.builder(
                  itemCount: _tournaments.length,
                  itemBuilder: (context, index) {
                    final tournament = _tournaments[index];
                    return TournamentCard(
                      tournament: tournament,
                      onTap: () => _showTournamentDetail(context, tournament),
                    );
                  },
                ),
              );
  }

  void _showTournamentDetail(BuildContext context, Tournament tournament) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentDetailScreen(tournament: tournament),
      ),
    );
  }
}

/// 토너먼트 카드
class TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback? onTap;

  const TournamentCard({
    super.key,
    required this.tournament,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tournament.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tournament.description,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(context),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.format_list_numbered,
                    _getFormatName(tournament.format),
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.people,
                    '${tournament.participants.length}/${tournament.maxParticipants}',
                  ),
                  const SizedBox(width: 8),
                  if (tournament.prizePool > 0)
                    _buildInfoChip(
                      Icons.monetization_on,
                      '${(tournament.prizePool / 10000).toStringAsFixed(1)}만',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: tournament.participants.length / tournament.maxParticipants,
                backgroundColor: Colors.grey[200],
              ),
              const SizedBox(height: 4),
              Text(
                '${tournament.participants.length}명 참가 중',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final statusInfo = _getStatusInfo(tournament.status);

    return Chip(
      label: Text(statusInfo['label'] as String),
      backgroundColor: statusInfo['color'] as Color,
      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Map<String, dynamic> _getStatusInfo(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.registration:
        return {'label': '접수중', 'color': Colors.blue};
      case TournamentStatus.scheduled:
        return {'label': '예정', 'color': Colors.purple};
      case TournamentStatus.inProgress:
        return {'label': '진행중', 'color': Colors.green};
      case TournamentStatus.completed:
        return {'label': '완료', 'color': Colors.grey};
      case TournamentStatus.cancelled:
        return {'label': '취소', 'color': Colors.red};
    }
  }

  String _getFormatName(TournamentFormat format) {
    switch (format) {
      case TournamentFormat.singleElimination:
        return '단판 토너먼트';
      case TournamentFormat.doubleElimination:
        return '더블 토너먼트';
      case TournamentFormat.roundRobin:
        return '리그전';
      case TournamentFormat.groupStage:
        return '조별 예선';
    }
  }
}

/// 토너먼트 상세 화면
class TournamentDetailScreen extends StatelessWidget {
  final Tournament tournament;

  const TournamentDetailScreen({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tournament.name)),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: TournamentInfoHeader(tournament: tournament),
          ),
          SliverFillRemaining(
            child: DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  const TabBar(
                    isScrollable: true,
                    tabs: [
                      Tab(text: '정보'),
                      Tab(text: '참가자'),
                      Tab(text: '매치'),
                      Tab(text: '순위'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        TournamentInfoTab(tournament: tournament),
                        ParticipantListTab(tournament: tournament),
                        MatchListTab(tournament: tournament),
                        StandingsTab(tournament: tournament),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _registerTournament(context),
        icon: const Icon(Icons.person_add),
        label: const Text('참가신청'),
      ),
    );
  }

  void _registerTournament(BuildContext context) {
    // 토너먼트 참가 로직
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('참가 신청이 완료되었습니다')),
    );
  }
}

/// 토너먼트 정보 헤더
class TournamentInfoHeader extends StatelessWidget {
  final Tournament tournament;

  const TournamentInfoHeader({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tournament.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(tournament.description),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildInfo(
                Icons.calendar_today,
                '시작: ${tournament.startDate.toString().split('.')[0]}',
              ),
              _buildInfo(
                Icons.format_list_numbered,
                _getFormatName(tournament.format),
              ),
              _buildInfo(
                Icons.people,
                '${tournament.participants.length}/${tournament.maxParticipants}명',
              ),
              if (tournament.prizePool > 0)
                _buildInfo(
                  Icons.monetization_on,
                  '상금: ${tournament.prizePool}원',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: Colors.grey[700]),
        ),
      ],
    );
  }

  String _getFormatName(TournamentFormat format) {
    switch (format) {
      case TournamentFormat.singleElimination:
        return '단판 토너먼트';
      case TournamentFormat.doubleElimination:
        return '더블 토너먼트';
      case TournamentFormat.roundRobin:
        return '리그전';
      case TournamentFormat.groupStage:
        return '조별 예선';
    }
  }
}

/// 토너먼트 정보 탭
class TournamentInfoTab extends StatelessWidget {
  final Tournament tournament;

  const TournamentInfoTab({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          title: const Text('토너먼트 ID'),
          subtitle: Text(tournament.id),
        ),
        ListTile(
          title: const Text('접수 시작'),
          subtitle: Text(tournament.registrationStart.toString().split('.')[0]),
        ),
        ListTile(
          title: const Text('접수 종료'),
          subtitle: Text(tournament.registrationEnd.toString().split('.')[0]),
        ),
        if (tournament.endDate != null)
          ListTile(
            title: const Text('종료일'),
            subtitle: Text(tournament.endDate!.toString().split('.')[0]),
          ),
      ],
    );
  }
}

/// 참가자 목록 탭
class ParticipantListTab extends StatelessWidget {
  final Tournament tournament;

  const ParticipantListTab({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    final standings = tournament.calculateStandings();

    return ListView.builder(
      itemCount: standings.length,
      itemBuilder: (context, index) {
        final participant = standings[index];
        return ListTile(
          leading: CircleAvatar(
            child: Text('${index + 1}'),
          ),
          title: Text(participant.name),
          subtitle: Text('시드: ${participant.seed}'),
          trailing: Text(
            '${participant.stats['wins'] ?? 0}승',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}

/// 매치 목록 탭
class MatchListTab extends StatelessWidget {
  final Tournament tournament;

  const MatchListTab({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    if (tournament.matches.isEmpty) {
      return const Center(child: Text('등록된 매치가 없습니다'));
    }

    return ListView.builder(
      itemCount: tournament.matches.length,
      itemBuilder: (context, index) {
        final match = tournament.matches[index];
        return MatchCard(match: match);
      },
    );
  }
}

/// 매치 카드
class MatchCard extends StatelessWidget {
  final TournamentMatch match;

  const MatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  if (match.team1 != null) Text(match.team1!.name) else const Text('TBD'),
                  if (match.team1Score != null)
                    Text(
                      '${match.team1Score}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Text(
                    _formatTime(match.scheduledTime),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(_getResultText(match.result)),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  if (match.team2 != null) Text(match.team2!.name) else const Text('TBD'),
                  if (match.team2Score != null)
                    Text(
                      '${match.team2Score}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _getResultText(MatchResult result) {
    switch (result) {
      case MatchResult.pending:
        return 'VS';
      case MatchResult.team1Win:
        return '팀1 승';
      case MatchResult.team2Win:
        return '팀2 승';
      case MatchResult.draw:
        return '무승부';
      case MatchResult.walkover:
        return '부전승';
    }
  }
}

/// 순위 탭
class StandingsTab extends StatelessWidget {
  final Tournament tournament;

  const StandingsTab({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    final standings = tournament.calculateStandings();

    return ListView.builder(
      itemCount: standings.length,
      itemBuilder: (context, index) {
        final participant = standings[index];
        final wins = participant.stats['wins'] ?? 0;
        final losses = participant.stats['losses'] ?? 0;

        return Container(
          decoration: BoxDecoration(
            color: index < 3
                ? [
                    Colors.amber.withOpacity(0.1),
                    Colors.grey.withOpacity(0.1),
                    Colors.brown.withOpacity(0.1),
                  ][index]
                : null,
            border: index < 3
                ? Border(
                    left: BorderSide(
                      color: [
                        Colors.amber,
                        Colors.grey,
                        Colors.brown,
                      ][index],
                      width: 4,
                    ),
                  )
                : null,
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: index < 3
                  ? [
                      Colors.amber,
                      Colors.grey,
                      Colors.brown,
                    ][index]
                  : Colors.grey[300],
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            title: Text(participant.name),
            trailing: Text(
              '$wins승 $losses패',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}

/// 내 토너먼트 화면
class MyTournamentsScreen extends StatefulWidget {
  const MyTournamentsScreen({super.key});

  @override
  State<MyTournamentsScreen> createState() => _MyTournamentsScreenState();
}

class _MyTournamentsScreenState extends State<MyTournamentsScreen> {
  final _esportsManager = EsportsManager.instance;
  List<Tournament> _myTournaments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMyTournaments();
  }

  Future<void> _loadMyTournaments() async {
    setState(() => _loading = true);

    // 현재 사용자가 참가한 토너먼트 로드
    _myTournaments = _esportsManager.getUserTournaments('current_user');

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : _myTournaments.isEmpty
            ? const Center(child: Text('참가한 토너먼트가 없습니다'))
            : ListView.builder(
                itemCount: _myTournaments.length,
                itemBuilder: (context, index) {
                  final tournament = _myTournaments[index];
                  return TournamentCard(
                    tournament: tournament,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TournamentDetailScreen(
                            tournament: tournament,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
  }
}

/// 브래킷 화면
class TournamentBracketScreen extends StatefulWidget {
  const TournamentBracketScreen({super.key});

  @override
  State<TournamentBracketScreen> createState() => _TournamentBracketScreenState();
}

class _TournamentBracketScreenState extends State<TournamentBracketScreen> {
  final _esportsManager = EsportsManager.instance;
  Tournament? _selectedTournament;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_selectedTournament == null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _showTournamentSelector,
              child: const Text('토너먼트 선택'),
            ),
          )
        else
          Expanded(
            child: BracketView(tournament: _selectedTournament!),
          ),
      ],
    );
  }

  void _showTournamentSelector() {
    final tournaments = _esportsManager.getAllTournaments();

    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        itemCount: tournaments.length,
        itemBuilder: (context, index) {
          final tournament = tournaments[index];
          return ListTile(
            title: Text(tournament.name),
            onTap: () {
              setState(() => _selectedTournament = tournament);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}

/// 브래킷 뷰
class BracketView extends StatelessWidget {
  final Tournament tournament;

  const BracketView({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    final bracket = tournament.generateBracket();

    if (bracket.isEmpty) {
      return const Center(child: Text('브래킷이 생성되지 않았습니다'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tournament.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ...bracket.map((match) => _buildMatchItem(match)),
        ],
      ),
    );
  }

  Widget _buildMatchItem(Map<String, dynamic> match) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Round ${match['round']} - Match ${match['match']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(match['team1']?.toString() ?? 'TBD'),
                ),
                const Text('VS'),
                Expanded(
                  child: Text(match['team2']?.toString() ?? 'TBD', textAlign: TextAlign.right),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
