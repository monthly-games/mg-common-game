import 'package:flutter/material.dart';
import 'package:mg_common_game/core/ui/mg_ui.dart';

/// 버튼 쇼케이스 페이지
class ButtonsPage extends StatefulWidget {
  const ButtonsPage({super.key});

  @override
  State<ButtonsPage> createState() => _ButtonsPageState();
}

class _ButtonsPageState extends State<ButtonsPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('버튼')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('버튼 스타일'),
          Row(
            children: [
              Expanded(
                child: MGButton.primary(
                  label: 'Primary',
                  onPressed: () => _showSnackBar('Primary 클릭'),
                ),
              ),
              MGSpacing.hSm,
              Expanded(
                child: MGButton.secondary(
                  label: 'Secondary',
                  onPressed: () => _showSnackBar('Secondary 클릭'),
                ),
              ),
              MGSpacing.hSm,
              Expanded(
                child: MGButton.text(
                  label: 'Text',
                  onPressed: () => _showSnackBar('Text 클릭'),
                ),
              ),
            ],
          ),
          MGSpacing.vLg,
          _buildSection('버튼 크기'),
          MGButton(
            label: 'Small',
            size: MGButtonSize.small,
            onPressed: () {},
          ),
          MGSpacing.vSm,
          MGButton(
            label: 'Medium (기본)',
            size: MGButtonSize.medium,
            onPressed: () {},
          ),
          MGSpacing.vSm,
          MGButton(
            label: 'Large',
            size: MGButtonSize.large,
            onPressed: () {},
          ),
          MGSpacing.vLg,
          _buildSection('아이콘 버튼'),
          Row(
            children: [
              MGButton.primary(
                label: '저장',
                icon: Icons.save,
                onPressed: () {},
              ),
              MGSpacing.hSm,
              MGButton.secondary(
                label: '공유',
                icon: Icons.share,
                onPressed: () {},
              ),
              MGSpacing.hSm,
              MGButton.text(
                label: '삭제',
                icon: Icons.delete,
                onPressed: () {},
              ),
            ],
          ),
          MGSpacing.vLg,
          _buildSection('로딩 상태'),
          MGButton.primary(
            label: _isLoading ? '로딩 중...' : '로딩 테스트',
            loading: _isLoading,
            onPressed: () async {
              setState(() => _isLoading = true);
              await Future.delayed(const Duration(seconds: 2));
              setState(() => _isLoading = false);
            },
          ),
          MGSpacing.vLg,
          _buildSection('비활성화 상태'),
          Row(
            children: [
              Expanded(
                child: MGButton.primary(
                  label: 'Disabled',
                  enabled: false,
                  onPressed: () {},
                ),
              ),
              MGSpacing.hSm,
              Expanded(
                child: MGButton.secondary(
                  label: 'Disabled',
                  enabled: false,
                  onPressed: () {},
                ),
              ),
            ],
          ),
          MGSpacing.vLg,
          _buildSection('아이콘 버튼'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MGIconButton(
                icon: Icons.settings,
                tooltip: '설정',
                onPressed: () {},
              ),
              MGIconButton(
                icon: Icons.favorite,
                color: Colors.red,
                tooltip: '좋아요',
                onPressed: () {},
              ),
              MGIconButton(
                icon: Icons.share,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                tooltip: '공유',
                onPressed: () {},
              ),
              MGIconButton(
                icon: Icons.more_vert,
                tooltip: '더보기',
                onPressed: () {},
              ),
            ],
          ),
          MGSpacing.vLg,
          _buildSection('플로팅 액션 버튼'),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              MGFloatingButton(
                icon: Icons.add,
                tooltip: '추가',
                onPressed: () {},
              ),
              MGFloatingButton(
                icon: Icons.edit,
                mini: true,
                tooltip: '수정',
                onPressed: () {},
              ),
              MGFloatingButton(
                icon: Icons.save,
                extended: true,
                label: '저장하기',
                onPressed: () {},
              ),
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
