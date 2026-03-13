import 'package:flutter/material.dart';
import 'package:mg_common_game/content/quest_manager.dart';

class QuestWidget extends StatefulWidget {
  final String userId;

  const QuestWidget({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<QuestWidget> createState() => _QuestWidgetState();
}

class _QuestWidgetState extends State<QuestWidget> {
  final QuestManager _questManager = QuestManager.instance;
  List<Quest> _quests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuests();
  }

  Future<void> _loadQuests() async {
    await _questManager.initialize();
    setState(() => _isLoading = true);
    _quests = _questManager.getActiveQuests(widget.userId);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quests'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Daily'),
              Tab(text: 'Weekly'),
              Tab(text: 'Story'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildQuestList(QuestType.daily),
                  _buildQuestList(QuestType.weekly),
                  _buildQuestList(QuestType.main),
                ],
              ),
      ),
    );
  }

  Widget _buildQuestList(QuestType type) {
    final filteredQuests = _quests.where((q) => q.type == type).toList();

    if (filteredQuests.isEmpty) {
      return const Center(
        child: Text('No quests available'),
      );
    }

    return ListView.builder(
      itemCount: filteredQuests.length,
      itemBuilder: (context, index) {
        final quest = filteredQuests[index];
        return _buildQuestCard(quest);
      },
    );
  }

  Widget _buildQuestCard(Quest quest) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    quest.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (quest.isCompleted)
                  const Icon(Icons.check_circle, color: Colors.green)
                else
                  Icon(Icons.radio_button_unchecked, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 8),
            Text(quest.description),
            const SizedBox(height: 12),
            if (!quest.isCompleted) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: quest.progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getProgressColor(quest.progress),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(quest.progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Rewards: ${quest.rewards.length}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ] else
              ElevatedButton(
                onPressed: () => _claimReward(quest),
                child: const Text('Claim Rewards'),
              ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.5) return Colors.blue;
    return Colors.orange;
  }

  Future<void> _claimReward(Quest quest) async {
    final success = await _questManager.claimReward(
      userId: widget.userId,
      questId: quest.questId,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quest completed! Rewards claimed.')),
      );
      _loadQuests();
    }
  }
}
