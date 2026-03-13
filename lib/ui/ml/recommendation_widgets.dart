import 'package:flutter/material.dart';
import 'package:mg_common_game/ml/recommendation_engine.dart';

/// 추천 아이템 카드 위젯
class RecommendationCard extends StatelessWidget {
  final RecommendableItem item;
  final double score;
  final VoidCallback? onTap;

  const RecommendationCard({
    super.key,
    required this.item,
    required this.score,
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
                    child: Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  _buildScoreChip(context),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: item.tags.map((tag) => Chip(label: Text(tag))).toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text('${item.averageRating} (${item.ratingCount}개 평가)'),
                  const SizedBox(width: 16),
                  Icon(Icons.people, size: 16),
                  const SizedBox(width: 4),
                  Text('${item.popularityScore} 인기도'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreChip(BuildContext context) {
    final color = score >= 0.8
        ? Colors.green
        : score >= 0.5
            ? Colors.orange
            : Colors.red;

    return Chip(
      label: Text('${(score * 100).toStringAsFixed(0)}%'),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }
}

/// 추천 화면 위젯
class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final _engine = RecommendationEngine.instance;
  List<RecommendationResult> _recommendations = [];
  bool _loading = true;
  String _selectedType = 'all';

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() => _loading = true);

    final recommendations = await _engine.recommendHybrid(
      userId: 'current_user',
      limit: 20,
      itemType: _selectedType == 'all' ? null : _selectedType,
    );

    setState(() {
      _recommendations = recommendations;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('맞춤 추천'),
        actions: [
          DropdownButton<String>(
            value: _selectedType,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('전체')),
              DropdownMenuItem(value: 'game', child: Text('게임')),
              DropdownMenuItem(value: 'item', child: Text('아이템')),
            ],
            onChanged: (value) {
              setState(() => _selectedType = value!);
              _loadRecommendations();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _recommendations.isEmpty
              ? const Center(child: Text('추천 항목이 없습니다'))
              : ListView.builder(
                  itemCount: _recommendations.length,
                  itemBuilder: (context, index) {
                    final result = _recommendations[index];
                    final item = _engine.getItem(result.itemId);

                    if (item == null) return const SizedBox();

                    return RecommendationCard(
                      item: item,
                      score: result.score,
                      onTap: () => _showItemDetail(context, item),
                    );
                  },
                ),
    );
  }

  void _showItemDetail(BuildContext context, RecommendableItem item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ItemDetailSheet(item: item),
    );
  }
}

/// 아이템 상세 시트
class ItemDetailSheet extends StatelessWidget {
  final RecommendableItem item;

  const ItemDetailSheet({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(item.description ?? '설명이 없습니다'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: item.tags.map((tag) => Chip(label: Text(tag))).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('시작하기'),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.favorite_border),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 추천 설정 위젯
class RecommendationSettings extends StatelessWidget {
  const RecommendationSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('추천 설정')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('개인화 추천 사용'),
            subtitle: const Text('사용 행동을 기반으로 추천'),
            value: true,
            onChanged: (value) {},
          ),
          SwitchListTile(
            title: const Text('실시간 업데이트'),
            subtitle: const Text('추천을 실시간으로 업데이트'),
            value: true,
            onChanged: (value) {},
          ),
          ListTile(
            title: const Text('추천 알고리즘'),
            subtitle: const Text('하이브리드'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

/// 피드백 위젯
class RecommendationFeedback extends StatelessWidget {
  final String itemId;
  final VoidCallback? onFeedback;

  const RecommendationFeedback({
    super.key,
    required this.itemId,
    this.onFeedback,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('이 추천이 도움이 되셨나요?'),
        const SizedBox(width: 16),
        IconButton(
          onPressed: () => _submitFeedback(true),
          icon: const Icon(Icons.thumb_up),
          color: Colors.green,
        ),
        IconButton(
          onPressed: () => _submitFeedback(false),
          icon: const Icon(Icons.thumb_down),
          color: Colors.red,
        ),
      ],
    );
  }

  void _submitFeedback(bool helpful) {
    // 피드백 전송
    onFeedback?.call();
  }
}
