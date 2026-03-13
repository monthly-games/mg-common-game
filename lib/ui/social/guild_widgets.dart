import 'package:flutter/material.dart';
import 'package:mg_common_game/social/guild_system.dart';

/// 길드 카드 위젯
class GuildCard extends StatelessWidget {
  final Guild guild;
  final VoidCallback? onTap;

  const GuildCard({
    super.key,
    required this.guild,
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
                  if (guild.emblemUrl != null && guild.emblemUrl!.isNotEmpty)
                    CircleAvatar(
                      backgroundImage: NetworkImage(guild.emblemUrl!),
                      radius: 24,
                    )
                  else
                    const CircleAvatar(
                      child: Icon(Icons.shield),
                      radius: 24,
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          guild.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          guild.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '${guild.members.length}/${guild.maxMembers}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Text('멤버'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.stars, size: 16),
                    label: Text('Lv.${guild.level}'),
                  ),
                  Chip(
                    avatar: const Icon(Icons.trophy, size: 16),
                    label: Text('점수: ${guild.score}'),
                  ),
                  if (guild.isAtWar)
                    const Chip(
                      avatar: Icon(Icons.gavel, size: 16),
                      label: Text('전쟁 중'),
                      backgroundColor: Colors.red,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 길드 목록 화면
class GuildListScreen extends StatefulWidget {
  const GuildListScreen({super.key});

  @override
  State<GuildListScreen> createState() => _GuildListScreenState();
}

class _GuildListScreenState extends State<GuildListScreen> {
  final _guildManager = GuildManager.instance;
  List<Guild> _guilds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGuilds();
  }

  Future<void> _loadGuilds() async {
    setState(() => _loading = true);

    final rankings = _guildManager.getGuildRankings(limit: 50);
    final guilds = rankings.map((r) => r.guild).toList();

    setState(() {
      _guilds = guilds;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('길드'),
        actions: [
          IconButton(
            onPressed: () => _showCreateGuildDialog(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _guilds.length,
              itemBuilder: (context, index) {
                final guild = _guilds[index];
                return GuildCard(
                  guild: guild,
                  onTap: () => _showGuildDetail(context, guild),
                );
              },
            ),
    );
  }

  void _showCreateGuildDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('길드 생성'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '길드 이름'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: '설명'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final guild = await _guildManager.createGuild(
                userId: 'current_user',
                name: nameController.text,
                description: descriptionController.text,
                emblemUrl: '',
              );

              if (guild != null && context.mounted) {
                Navigator.pop(context);
                _showGuildDetail(context, guild);
              }
            },
            child: const Text('생성'),
          ),
        ],
      ),
    );
  }

  void _showGuildDetail(BuildContext context, Guild guild) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuildDetailScreen(guild: guild),
      ),
    );
  }
}

/// 길드 상세 화면
class GuildDetailScreen extends StatelessWidget {
  final Guild guild;

  const GuildDetailScreen({super.key, required this.guild});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(guild.name)),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GuildInfoHeader(guild: guild),
          ),
          SliverFillRemaining(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: '멤버'),
                      Tab(text: '전쟁'),
                      Tab(text: '정보'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        GuildMemberList(guild: guild),
                        GuildWarList(guild: guild),
                        GuildInfoTab(guild: guild),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 길드 정보 헤더
class GuildInfoHeader extends StatelessWidget {
  final Guild guild;

  const GuildInfoHeader({super.key, required this.guild});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (guild.emblemUrl != null && guild.emblemUrl!.isNotEmpty)
            CircleAvatar(
              backgroundImage: NetworkImage(guild.emblemUrl!),
              radius: 48,
            )
          else
            const CircleAvatar(
              child: Icon(Icons.shield, size: 48),
              radius: 48,
            ),
          const SizedBox(height: 16),
          Text(
            guild.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(guild.description),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat('레벨', '${guild.level}'),
              _buildStat('멤버', '${guild.members.length}/${guild.maxMembers}'),
              _buildStat('점수', '${guild.score}'),
              _buildStat('전적', '${guild.wins}승 ${guild.losses}패'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label),
      ],
    );
  }
}

/// 길드 멤버 목록
class GuildMemberList extends StatelessWidget {
  final Guild guild;

  const GuildMemberList({super.key, required this.guild});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: guild.members.length,
      itemBuilder: (context, index) {
        final member = guild.members[index];
        return ListTile(
          leading: CircleAvatar(child: Text(member.username[0])),
          title: Text(member.username),
          subtitle: Text(_getRoleText(member.role)),
          trailing: member.role == GuildMemberRole.leader
              ? const Icon(Icons.stars, color: Colors.amber)
              : null,
        );
      },
    );
  }

  String _getRoleText(GuildMemberRole role) {
    switch (role) {
      case GuildMemberRole.leader:
        return '길드장';
      case GuildMemberRole.officer:
        return '간부';
      case GuildMemberRole.member:
        return '회원';
    }
  }
}

/// 길드 전쟁 목록
class GuildWarList extends StatelessWidget {
  final Guild guild;

  const GuildWarList({super.key, required this.guild});

  @override
  Widget build(BuildContext context) {
    final wars = GuildManager.instance.getActiveGuildWars(guild.id);

    if (wars.isEmpty) {
      return const Center(child: Text('진행 중인 전쟁이 없습니다'));
    }

    return ListView.builder(
      itemCount: wars.length,
      itemBuilder: (context, index) {
        final war = wars[index];
        final opponentId = war.guild1Id == guild.id ? war.guild2Id : war.guild1Id;
        final opponent = GuildManager.instance.getGuild(opponentId);

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${opponent?.name ?? "알 수 없는 길드"}와의 전쟁',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: war.guild1Score / (war.guild1Score + war.guild2Score + 1),
                ),
                const SizedBox(height: 8),
                Text(
                  '${war.guild1Score} : ${war.guild2Score}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 길드 정보 탭
class GuildInfoTab extends StatelessWidget {
  final Guild guild;

  const GuildInfoTab({super.key, required this.guild});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          title: const Text('길드 ID'),
          subtitle: Text(guild.id),
        ),
        ListTile(
          title: const Text('설립일'),
          subtitle: Text(guild.createdAt.toString().split('.')[0]),
        ),
        ListTile(
          title: const Text('길드장'),
          subtitle: Text(guild.leaderId),
        ),
      ],
    );
  }
}
