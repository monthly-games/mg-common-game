import 'package:flutter/material.dart';
import 'package:mg_common_game/core/ui/mg_ui.dart';

/// 테마 쇼케이스 페이지
class ThemePage extends StatelessWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('테마 & 컬러')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(context, '시맨틱 컬러'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildColorChip('Success', MGColors.success),
              _buildColorChip('Warning', MGColors.warning),
              _buildColorChip('Error', MGColors.error),
              _buildColorChip('Info', MGColors.info),
            ],
          ),
          MGSpacing.vLg,
          _buildSection(context, '자원 컬러'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildColorChip('Gold', MGColors.gold),
              _buildColorChip('Gem', MGColors.gem),
              _buildColorChip('Energy', MGColors.energy),
              _buildColorChip('EXP', MGColors.exp),
            ],
          ),
          MGSpacing.vLg,
          _buildSection(context, '레어리티 컬러'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildColorChip('Common', MGColors.common),
              _buildColorChip('Uncommon', MGColors.uncommon),
              _buildColorChip('Rare', MGColors.rare),
              _buildColorChip('Epic', MGColors.epic),
              _buildColorChip('Legendary', MGColors.legendary),
              _buildColorChip('Mythic', MGColors.mythic),
            ],
          ),
          MGSpacing.vLg,
          _buildSection(context, '카테고리 테마'),
          _buildThemeCard(
            context,
            'Year 1 (게임 0001-0012)',
            MGColors.getThemeByGameId('1'),
          ),
          MGSpacing.vSm,
          _buildThemeCard(
            context,
            'Year 2 (게임 0013-0024)',
            MGColors.getThemeByGameId('13'),
          ),
          MGSpacing.vSm,
          _buildThemeCard(
            context,
            'Level A (게임 0025-0036)',
            MGColors.getThemeByGameId('25'),
          ),
          MGSpacing.vSm,
          _buildThemeCard(
            context,
            'Emerging (게임 0037-0052)',
            MGColors.getThemeByGameId('37'),
          ),
          MGSpacing.vLg,
          _buildSection(context, '색맹 대응 팔레트'),
          _buildColorBlindSection(context, '적록 색맹', ColorBlindType.deuteranopia),
          MGSpacing.vSm,
          _buildColorBlindSection(context, '적색 색맹', ColorBlindType.protanopia),
          MGSpacing.vSm,
          _buildColorBlindSection(context, '청황 색맹', ColorBlindType.tritanopia),
          MGSpacing.vLg,
          _buildSection(context, '고대비 모드'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HighContrastColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: HighContrastColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '고대비 텍스트',
                  style: TextStyle(
                    color: HighContrastColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                MGSpacing.vSm,
                Text(
                  '가독성을 위한 고대비 배경과 텍스트',
                  style: TextStyle(color: HighContrastColors.textSecondary),
                ),
                MGSpacing.vMd,
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: const Text('Primary'),
                      backgroundColor: HighContrastColors.buttonPrimary,
                    ),
                    Chip(
                      label: const Text('Success'),
                      backgroundColor: HighContrastColors.success,
                    ),
                    Chip(
                      label: const Text('Error'),
                      backgroundColor: HighContrastColors.error,
                    ),
                  ],
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

  Widget _buildColorChip(String label, Color color) {
    return Chip(
      avatar: CircleAvatar(backgroundColor: color),
      label: Text(label),
    );
  }

  Widget _buildThemeCard(
    BuildContext context,
    String title,
    CategoryColors theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: theme.primary,
              ),
            ),
          ),
          _buildColorBox(theme.primary, 'Primary'),
          MGSpacing.hXs,
          _buildColorBox(theme.secondary, 'Secondary'),
          MGSpacing.hXs,
          _buildColorBox(theme.accent, 'Accent'),
        ],
      ),
    );
  }

  Widget _buildColorBox(Color color, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildColorBlindSection(
    BuildContext context,
    String title,
    ColorBlindType type,
  ) {
    final palette = ColorBlindColors.getPalette(type);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          _buildColorBox(palette.primary, 'Primary'),
          MGSpacing.hXs,
          _buildColorBox(palette.success, 'Success'),
          MGSpacing.hXs,
          _buildColorBox(palette.error, 'Error'),
          MGSpacing.hXs,
          _buildColorBox(palette.warning, 'Warning'),
        ],
      ),
    );
  }
}
