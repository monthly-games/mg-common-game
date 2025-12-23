import 'package:flutter/material.dart';
import 'package:mg_common_game/core/ui/mg_ui.dart';

/// 카드 쇼케이스 페이지
class CardsPage extends StatelessWidget {
  const CardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('카드')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(context, '기본 카드'),
          const MGCard(
            child: Text('기본 카드입니다. 패딩과 그림자가 적용됩니다.'),
          ),
          MGSpacing.vMd,
          MGCard(
            onTap: () => _showSnackBar(context, '카드 클릭됨'),
            child: const Text('탭 가능한 카드입니다.'),
          ),
          MGSpacing.vLg,
          _buildSection(context, '카드 변형'),
          const MGCard.outlined(
            child: Text('테두리 카드 (elevation 없음)'),
          ),
          MGSpacing.vMd,
          const MGCard.transparent(
            child: Text('투명 카드 (배경 없음)'),
          ),
          MGSpacing.vLg,
          _buildSection(context, '아이템 카드'),
          MGItemCard(
            icon: Icons.star,
            title: '아이템 제목',
            subtitle: '아이템 설명입니다.',
            onTap: () {},
          ),
          MGSpacing.vMd,
          MGItemCard(
            icon: Icons.settings,
            iconColor: Colors.orange,
            title: '설정',
            subtitle: '게임 설정을 변경합니다.',
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          MGSpacing.vMd,
          const MGItemCard(
            leading: CircleAvatar(child: Text('MG')),
            title: '커스텀 리딩',
            subtitle: '아이콘 대신 커스텀 위젯 사용',
          ),
          MGSpacing.vLg,
          _buildSection(context, '통계 카드'),
          Row(
            children: [
              Expanded(
                child: MGStatCard(
                  icon: Icons.monetization_on,
                  label: '골드',
                  value: '12,500',
                  color: MGColors.gold,
                ),
              ),
              MGSpacing.hSm,
              Expanded(
                child: MGStatCard(
                  icon: Icons.diamond,
                  label: '젬',
                  value: '350',
                  color: MGColors.gem,
                ),
              ),
            ],
          ),
          MGSpacing.vMd,
          Row(
            children: [
              Expanded(
                child: MGStatCard(
                  icon: Icons.trending_up,
                  label: '점수',
                  value: '1,250',
                  change: '+15%',
                  positive: true,
                ),
              ),
              MGSpacing.hSm,
              Expanded(
                child: MGStatCard(
                  icon: Icons.trending_down,
                  label: '랭킹',
                  value: '#42',
                  change: '-3',
                  positive: false,
                ),
              ),
            ],
          ),
          MGSpacing.vLg,
          _buildSection(context, '게임 카드'),
          SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                MGGameCard(
                  thumbnail: Container(
                    color: MGColors.year1Primary,
                    child: const Center(
                      child: Icon(Icons.castle, size: 48, color: Colors.white),
                    ),
                  ),
                  title: 'Tower Defense',
                  category: 'Strategy',
                  rating: 4.5,
                  onTap: () {},
                ),
                MGSpacing.hSm,
                MGGameCard(
                  thumbnail: Container(
                    color: MGColors.year2Primary,
                    child: const Center(
                      child: Icon(Icons.extension, size: 48, color: Colors.white),
                    ),
                  ),
                  title: 'Puzzle Master',
                  category: 'Puzzle',
                  rating: 4.8,
                  onTap: () {},
                ),
                MGSpacing.hSm,
                MGGameCard(
                  thumbnail: Container(
                    color: MGColors.levelAPrimary,
                    child: const Center(
                      child: Icon(Icons.rocket_launch, size: 48, color: Colors.white),
                    ),
                  ),
                  title: 'Space Clicker',
                  category: 'Idle',
                  rating: 4.2,
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
