/// 가챠 뽑기 연출 위젯
library;

import 'package:flutter/material.dart';
import '../../../../systems/gacha/gacha_pool.dart';
import '../../theme/mg_colors.dart';
import '../../layout/mg_spacing.dart';

/// 가챠 뽑기 연출 위젯
class GachaPullAnimation extends StatefulWidget {
  final List<GachaItem> results;
  final VoidCallback? onComplete;
  final Duration revealDuration;

  const GachaPullAnimation({
    super.key,
    required this.results,
    this.onComplete,
    this.revealDuration = const Duration(milliseconds: 500),
  });

  @override
  State<GachaPullAnimation> createState() => _GachaPullAnimationState();
}

class _GachaPullAnimationState extends State<GachaPullAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _opacityAnimations;
  int _currentIndex = 0;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startRevealSequence();
  }

  void _initAnimations() {
    _controllers = List.generate(
      widget.results.length,
      (index) => AnimationController(
        duration: widget.revealDuration,
        vsync: this,
      ),
    );

    _scaleAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut),
      );
    }).toList();

    _opacityAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeIn),
      );
    }).toList();
  }

  Future<void> _startRevealSequence() async {
    for (int i = 0; i < widget.results.length; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        setState(() => _currentIndex = i);
        _controllers[i].forward();
      }
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _showAll = true);
      widget.onComplete?.call();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showAll) {
      return _buildResultsGrid();
    }
    return _buildRevealAnimation();
  }

  Widget _buildRevealAnimation() {
    if (_currentIndex >= widget.results.length) {
      return const SizedBox.shrink();
    }

    final item = widget.results[_currentIndex];
    return Center(
      child: AnimatedBuilder(
        animation: _controllers[_currentIndex],
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimations[_currentIndex].value,
            child: Opacity(
              opacity: _opacityAnimations[_currentIndex].value,
              child: _GachaResultCard(item: item, isHighlight: true),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsGrid() {
    return Padding(
      padding: EdgeInsets.all(MGSpacing.md),
      child: GridView.builder(
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.results.length > 5 ? 5 : widget.results.length,
          crossAxisSpacing: MGSpacing.sm,
          mainAxisSpacing: MGSpacing.sm,
          childAspectRatio: 0.8,
        ),
        itemCount: widget.results.length,
        itemBuilder: (context, index) {
          return _GachaResultCard(
            item: widget.results[index],
            isHighlight: widget.results[index].rarity.index >= GachaRarity.superRare.index,
          );
        },
      ),
    );
  }
}

class _GachaResultCard extends StatelessWidget {
  final GachaItem item;
  final bool isHighlight;

  const _GachaResultCard({
    required this.item,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final rarityColor = _getRarityColor(item.rarity);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            rarityColor.withValues(alpha: 0.3),
            rarityColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rarityColor,
          width: isHighlight ? 3 : 1,
        ),
        boxShadow: isHighlight
            ? [
                BoxShadow(
                  color: rarityColor.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 아이템 아이콘 placeholder
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: rarityColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getRarityIcon(item.rarity),
              color: rarityColor,
              size: 32,
            ),
          ),
          SizedBox(height: MGSpacing.sm),
          // 아이템 이름
          Padding(
            padding: EdgeInsets.symmetric(horizontal: MGSpacing.xs),
            child: Text(
              item.nameKr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: MGSpacing.xs),
          // 등급 뱃지
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: MGSpacing.sm,
              vertical: MGSpacing.xs / 2,
            ),
            decoration: BoxDecoration(
              color: rarityColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              item.rarity.nameKr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRarityColor(GachaRarity rarity) {
    switch (rarity) {
      case GachaRarity.normal:
        return MGColors.common;
      case GachaRarity.rare:
        return MGColors.rare;
      case GachaRarity.superRare:
        return MGColors.epic;
      case GachaRarity.superSuperRare:
      case GachaRarity.ultraRare:
        return MGColors.legendary;
      case GachaRarity.legendary:
        return MGColors.mythic;
    }
  }

  IconData _getRarityIcon(GachaRarity rarity) {
    switch (rarity) {
      case GachaRarity.normal:
        return Icons.circle_outlined;
      case GachaRarity.rare:
        return Icons.star_border;
      case GachaRarity.superRare:
        return Icons.star;
      case GachaRarity.superSuperRare:
      case GachaRarity.ultraRare:
        return Icons.auto_awesome;
      case GachaRarity.legendary:
        return Icons.diamond;
    }
  }
}

/// 가챠 뽑기 버튼
class GachaPullButton extends StatelessWidget {
  final String label;
  final int cost;
  final String currencyIcon;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final bool isLoading;

  const GachaPullButton({
    super.key,
    required this.label,
    required this.cost,
    this.currencyIcon = '💎',
    this.onPressed,
    this.isEnabled = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isEnabled && !isLoading ? onPressed : null,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: MGSpacing.lg,
          vertical: MGSpacing.md,
        ),
        backgroundColor: MGColors.primaryAction,
        disabledBackgroundColor: Colors.grey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: MGSpacing.sm),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: MGSpacing.sm,
                    vertical: MGSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(currencyIcon),
                      SizedBox(width: MGSpacing.xs),
                      Text(
                        cost.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// 가챠 천장 표시 위젯
class GachaPityIndicator extends StatelessWidget {
  final int currentPulls;
  final int softPity;
  final int hardPity;

  const GachaPityIndicator({
    super.key,
    required this.currentPulls,
    required this.softPity,
    required this.hardPity,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentPulls / hardPity;
    final isSoftPityActive = currentPulls >= softPity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '천장까지',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            Text(
              '${hardPity - currentPulls}회',
              style: TextStyle(
                color: isSoftPityActive ? MGColors.warning : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: MGSpacing.xs),
        Stack(
          children: [
            // Background
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Progress
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSoftPityActive
                        ? [MGColors.warning, MGColors.error]
                        : [MGColors.primaryAction, MGColors.secondaryAction],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Soft pity marker
            Positioned(
              left: (softPity / hardPity) * MediaQuery.of(context).size.width * 0.8,
              child: Container(
                width: 2,
                height: 8,
                color: MGColors.warning,
              ),
            ),
          ],
        ),
        SizedBox(height: MGSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$currentPulls회',
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
            if (isSoftPityActive)
              Text(
                '확률 UP!',
                style: TextStyle(
                  color: MGColors.warning,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            Text(
              '$hardPity회',
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}
