import 'package:flutter/material.dart';
import 'package:mg_common_game/core/ui/mg_ui.dart';

import 'buttons_page.dart';
import 'cards_page.dart';
import 'progress_page.dart';
import 'loading_page.dart';
import 'dialogs_page.dart';
import 'accessibility_page.dart';
import 'theme_page.dart';
import 'animation_page.dart';
import 'game_canvas_page.dart';

/// MG UI 컴포넌트 쇼케이스 홈 페이지
class ShowcaseHomePage extends StatelessWidget {
  final VoidCallback? onToggleTheme;
  final bool isDarkMode;

  const ShowcaseHomePage({
    super.key,
    this.onToggleTheme,
    this.isDarkMode = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MG UI Components'),
        actions: [
          if (onToggleTheme != null)
            IconButton(
              icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: onToggleTheme,
              tooltip: isDarkMode ? '라이트 모드' : '다크 모드',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(context, 'UI 컴포넌트'),
          _buildMenuItem(
            context,
            icon: Icons.smart_button,
            title: '버튼',
            subtitle: 'MGButton, MGIconButton 등',
            page: const ButtonsPage(),
          ),
          _buildMenuItem(
            context,
            icon: Icons.credit_card,
            title: '카드',
            subtitle: 'MGCard, MGItemCard, MGStatCard 등',
            page: const CardsPage(),
          ),
          _buildMenuItem(
            context,
            icon: Icons.linear_scale,
            title: '프로그레스',
            subtitle: 'MGProgressBar, MGHPBar, MGExpBar 등',
            page: const ProgressPage(),
          ),
          _buildMenuItem(
            context,
            icon: Icons.hourglass_empty,
            title: '로딩',
            subtitle: 'MGLoadingSpinner, MGSkeleton 등',
            page: const LoadingPage(),
          ),
          _buildMenuItem(
            context,
            icon: Icons.chat_bubble_outline,
            title: '다이얼로그',
            subtitle: 'MGModal, MGBottomSheet, MGSnackBar 등',
            page: const DialogsPage(),
          ),
          MGSpacing.vLg,
          _buildSection(context, '테마 & 스타일'),
          _buildMenuItem(
            context,
            icon: Icons.palette,
            title: '테마 & 컬러',
            subtitle: '시맨틱, 레어리티, 카테고리 컬러',
            page: const ThemePage(),
          ),
          _buildMenuItem(
            context,
            icon: Icons.animation,
            title: '애니메이션',
            subtitle: 'MGFadeIn, MGSlideIn, MGPulse 등',
            page: const AnimationPage(),
          ),
          MGSpacing.vLg,
          _buildSection(context, '레이아웃'),
          _buildMenuItem(
            context,
            icon: Icons.gamepad,
            title: '게임 캔버스',
            subtitle: 'MGGameCanvas, MGTowerDefenseCanvas 등',
            page: const GameCanvasPage(),
          ),
          MGSpacing.vLg,
          _buildSection(context, '접근성'),
          _buildMenuItem(
            context,
            icon: Icons.accessibility_new,
            title: '접근성 설정',
            subtitle: '색맹, 고대비, 텍스트 크기 등',
            page: const AccessibilityPage(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget page,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
      ),
    );
  }
}
