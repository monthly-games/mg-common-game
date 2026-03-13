import 'package:flutter/material.dart';
import 'package:mg_common_game/content/achievement_manager.dart';

class AchievementWidget extends StatefulWidget {
  final String userId;

  const AchievementWidget({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<AchievementWidget> createState() => _AchievementWidgetState();
}

class _AchievementWidgetState extends State<AchievementWidget> {
  final AchievementManager _achievementManager = AchievementManager.instance;
  List<Achievement> _achievements = [];
  List<AchievementCategory> _categories = [];
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    await _achievementManager.initialize();
    setState(() => _achievements = _achievementManager.getVisibleAchievements());
    setState(() => _categories = _achievementManager.getAllCategories());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildCategoryChips(),
        ),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.75,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _filteredAchievements.length,
        itemBuilder: (context, index) {
          final achievement = _filteredAchievements[index];
          return _buildAchievementCard(achievement);
        },
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            _buildCategoryChip('all', 'All'),
            ..._categories.map((cat) =>
              _buildCategoryChip(cat.categoryId, cat.name),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String id, String label) {
    final isSelected = _selectedCategory == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedCategory = id);
        },
      ),
    );
  }

  List<Achievement> get _filteredAchievements {
    if (_selectedCategory == 'all') return _achievements;
    return _achievements.where((a) => a.category == _selectedCategory).toList();
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final isCompleted = achievement.isCompleted;
    final isClaimed = achievement.status == AchievementStatus.claimed;

    return Card(
      child: InkWell(
        onTap: () => _showAchievementDetails(achievement),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isCompleted ? Colors.green : Colors.grey[300]!,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getTierIcon(achievement.tier),
                  size: 48,
                  color: _getTierColor(achievement.tier),
                ),
                const SizedBox(height: 8),
                Text(
                  achievement.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${achievement.points} pts',
                  style: TextStyle(
                    fontSize: 10,
                    color: isCompleted ? Colors.green : Colors.grey,
                  ),
                ),
                if (isClaimed)
                  const Icon(Icons.check_circle, color: Colors.green, size: 16)
                else if (isCompleted)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Claim',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getTierIcon(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return Icons.emoji_events;
      case AchievementTier.silver:
        return Icons.military_tech;
      case AchievementTier.gold:
        return Icons.stars;
      case AchievementTier.platinum:
        return Icons.diamond;
      case AchievementTier.diamond:
        return Icons.workspace_premium;
    }
  }

  Color _getTierColor(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return Colors.brown;
      case AchievementTier.silver:
        return Colors.grey;
      case AchievementTier.gold:
        return Colors.amber;
      case AchievementTier.platinum:
        return Colors.lightBlue;
      case AchievementTier.diamond:
        return Colors.cyan;
    }
  }

  void _showAchievementDetails(Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getTierIcon(achievement.tier),
              color: _getTierColor(achievement.tier),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(achievement.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievement.description),
            const SizedBox(height: 12),
            if (achievement.objectives.isNotEmpty)
              const Text('Objectives:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...achievement.objectives.map((obj) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Row(
                children: [
                  Expanded(child: Text(obj.description)),
                  Text(' ${obj.currentValue}/${obj.targetValue}'),
                ],
              ),
            )),
            const SizedBox(height: 12),
            Text('Rewards: ${achievement.rewards.length}'),
            Text('Points: ${achievement.points}'),
          ],
        ),
        actions: [
          if (achievement.isClaimable)
            ElevatedButton(
              onPressed: () => _claimReward(achievement),
              child: const Text('Claim Reward'),
            )
          else
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
        ],
      ),
    );
  }

  Future<void> _claimReward(Achievement achievement) async {
    final success = await _achievementManager.claimReward(
      userId: widget.userId,
      achievementId: achievement.achievementId,
    );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${achievement.name} reward claimed!')),
      );
      _loadAchievements();
    }
  }
}
