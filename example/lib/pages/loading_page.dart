import 'package:flutter/material.dart';
import 'package:mg_common_game/core/ui/mg_ui.dart';

/// 로딩 쇼케이스 페이지
class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  bool _isOverlayLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로딩')),
      body: MGLoadingOverlay(
        isLoading: _isOverlayLoading,
        message: '처리 중...',
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection('스피너'),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                MGLoadingSpinner(size: 24),
                MGLoadingSpinner(size: 32),
                MGLoadingSpinner(size: 48),
                MGLoadingSpinner(size: 64, color: Colors.orange),
              ],
            ),
            MGSpacing.vLg,
            _buildSection('점 로딩'),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                MGDotsLoading(),
                MGDotsLoading(dotCount: 5, color: Colors.green),
                MGDotsLoading(dotSize: 12, color: Colors.purple),
              ],
            ),
            MGSpacing.vLg,
            _buildSection('로딩 오버레이'),
            MGButton.primary(
              label: '오버레이 테스트 (2초)',
              onPressed: () async {
                setState(() => _isOverlayLoading = true);
                await Future.delayed(const Duration(seconds: 2));
                setState(() => _isOverlayLoading = false);
              },
            ),
            MGSpacing.vMd,
            MGButton.secondary(
              label: '풀스크린 로딩 테스트',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const _FullScreenLoadingDemo(),
                  ),
                );
              },
            ),
            MGSpacing.vLg,
            _buildSection('스켈레톤'),
            const MGSkeleton(height: 20),
            MGSpacing.vSm,
            const MGSkeleton(width: 200, height: 16),
            MGSpacing.vSm,
            const Row(
              children: [
                MGSkeleton.avatar(),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MGSkeleton.text(width: 150),
                      SizedBox(height: 8),
                      MGSkeleton.text(width: 100),
                    ],
                  ),
                ),
              ],
            ),
            MGSpacing.vLg,
            _buildSection('스켈레톤 카드'),
            const MGSkeletonCard(),
            MGSpacing.vLg,
            _buildSection('스켈레톤 리스트'),
            const MGSkeletonListItem(),
            const MGSkeletonListItem(hasTrailing: true),
            const MGSkeletonListItem(hasLeading: false),
            const SizedBox(height: 100),
          ],
        ),
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
}

class _FullScreenLoadingDemo extends StatefulWidget {
  const _FullScreenLoadingDemo();

  @override
  State<_FullScreenLoadingDemo> createState() => _FullScreenLoadingDemoState();
}

class _FullScreenLoadingDemoState extends State<_FullScreenLoadingDemo> {
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  Future<void> _simulateLoading() async {
    for (var i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() => _progress = i / 100);
      }
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MGFullScreenLoading(
      logo: const FlutterLogo(size: 100),
      progress: _progress,
      message: '게임 로딩 중...',
    );
  }
}
