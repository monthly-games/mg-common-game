import 'package:flutter/material.dart';
import 'package:mg_common_game/core/ui/mg_ui.dart';

/// 애니메이션 쇼케이스 페이지
class AnimationPage extends StatefulWidget {
  const AnimationPage({super.key});

  @override
  State<AnimationPage> createState() => _AnimationPageState();
}

class _AnimationPageState extends State<AnimationPage> {
  int _refreshKey = 0;
  bool _showStagger = false;
  bool _shake = false;

  void _refresh() {
    setState(() {
      _refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('애니메이션'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: ListView(
        key: ValueKey(_refreshKey),
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('페이드 인'),
          Row(
            children: [
              Expanded(
                child: MGFadeIn(
                  child: _buildAnimationBox('즉시'),
                ),
              ),
              MGSpacing.hSm,
              Expanded(
                child: MGFadeIn(
                  delay: const Duration(milliseconds: 200),
                  child: _buildAnimationBox('200ms 딜레이'),
                ),
              ),
              MGSpacing.hSm,
              Expanded(
                child: MGFadeIn(
                  delay: const Duration(milliseconds: 400),
                  child: _buildAnimationBox('400ms 딜레이'),
                ),
              ),
            ],
          ),
          MGSpacing.vLg,
          _buildSection('슬라이드 인'),
          Row(
            children: [
              Expanded(
                child: MGSlideIn.up(
                  child: _buildAnimationBox('위로'),
                ),
              ),
              MGSpacing.hSm,
              Expanded(
                child: MGSlideIn.down(
                  child: _buildAnimationBox('아래로'),
                ),
              ),
              MGSpacing.hSm,
              Expanded(
                child: MGSlideIn.left(
                  child: _buildAnimationBox('왼쪽'),
                ),
              ),
              MGSpacing.hSm,
              Expanded(
                child: MGSlideIn.right(
                  child: _buildAnimationBox('오른쪽'),
                ),
              ),
            ],
          ),
          MGSpacing.vLg,
          _buildSection('스케일 인'),
          Row(
            children: [
              Expanded(
                child: MGScaleIn(
                  child: _buildAnimationBox('기본'),
                ),
              ),
              MGSpacing.hSm,
              Expanded(
                child: MGScaleIn.pop(
                  child: _buildAnimationBox('팝!'),
                ),
              ),
              MGSpacing.hSm,
              Expanded(
                child: MGScaleIn(
                  delay: const Duration(milliseconds: 300),
                  child: _buildAnimationBox('딜레이'),
                ),
              ),
            ],
          ),
          MGSpacing.vLg,
          _buildSection('흔들기'),
          Center(
            child: MGShake(
              trigger: _shake,
              child: MGButton.primary(
                label: '흔들기 테스트',
                onPressed: () {
                  setState(() => _shake = true);
                  Future.delayed(const Duration(milliseconds: 600), () {
                    if (mounted) setState(() => _shake = false);
                  });
                },
              ),
            ),
          ),
          MGSpacing.vLg,
          _buildSection('펄스 (반복)'),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MGPulse(
                child: Icon(Icons.favorite, color: Colors.red, size: 48),
              ),
              MGPulse(
                minScale: 0.9,
                maxScale: 1.1,
                duration: Duration(milliseconds: 600),
                child: Icon(Icons.star, color: Colors.amber, size: 48),
              ),
              MGPulse(
                minScale: 0.85,
                maxScale: 1.15,
                child: Icon(Icons.notifications, color: Colors.blue, size: 48),
              ),
            ],
          ),
          MGSpacing.vLg,
          _buildSection('스태거 리스트'),
          MGButton.secondary(
            label: '스태거 애니메이션 표시',
            onPressed: () {
              setState(() => _showStagger = !_showStagger);
            },
          ),
          MGSpacing.vMd,
          if (_showStagger)
            MGStaggeredList(
              children: [
                _buildListItem('항목 1'),
                _buildListItem('항목 2'),
                _buildListItem('항목 3'),
                _buildListItem('항목 4'),
                _buildListItem('항목 5'),
              ],
            ),
          MGSpacing.vLg,
          _buildSection('애니메이션 듀레이션'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDurationChip('Micro', MGAnimationDurations.micro),
              _buildDurationChip('Short', MGAnimationDurations.short),
              _buildDurationChip('Medium', MGAnimationDurations.medium),
              _buildDurationChip('Long', MGAnimationDurations.long),
              _buildDurationChip('Extra Long', MGAnimationDurations.extraLong),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
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

  Widget _buildAnimationBox(String label) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildDurationChip(String label, Duration duration) {
    return Chip(
      label: Text('$label (${duration.inMilliseconds}ms)'),
    );
  }
}
