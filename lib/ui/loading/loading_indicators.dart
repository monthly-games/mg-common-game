import 'package:flutter/material.dart';
import 'package:mg_common_game/ui/theme/theme_manager.dart';

/// 스켈레톤 로딩 타입
enum SkeletonType {
  circle,
  rectangle,
  line,
  custom,
}

/// 스켈레톤 위젯
class Skeleton extends StatefulWidget {
  final SkeletonType type;
  final double? width;
  final double? height;
  final double borderRadius;
  final Widget? customWidget;
  final Color? baseColor;
  final Color? highlightColor;

  const Skeleton({
    super.key,
    this.type = SkeletonType.rectangle,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.customWidget,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colors = theme.colors;

    final baseColor = widget.baseColor ?? colors.onBackground.withOpacity(0.1);
    final highlightColor =
        widget.highlightColor ?? colors.onBackground.withOpacity(0.2);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return _buildSkeleton(baseColor, highlightColor);
      },
    );
  }

  Widget _buildSkeleton(Color baseColor, Color highlightColor) {
    final shimmer = Shader(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.centerRight,
        colors: [
          baseColor,
          highlightColor,
          baseColor,
        ],
        stops: [
          _animation.value - 1,
          _animation.value,
          _animation.value + 1,
        ],
      ).createShader(bounds),
    );

    switch (widget.type) {
      case SkeletonType.circle:
        return Container(
          width: widget.width ?? 40,
          height: widget.height ?? 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                _animation.value - 1,
                _animation.value,
                _animation.value + 1,
              ],
            ),
          ),
        );

      case SkeletonType.rectangle:
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                _animation.value - 1,
                _animation.value,
                _animation.value + 1,
              ],
            ),
          ),
        );

      case SkeletonType.line:
        return Container(
          width: widget.width ?? double.infinity,
          height: widget.height ?? 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                _animation.value - 1,
                _animation.value,
                _animation.value + 1,
              ],
            ),
          ),
        );

      case SkeletonType.custom:
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.centerRight,
            colors: [
              baseColor,
              highlightColor,
              baseColor,
            ],
            stops: [
              _animation.value - 1,
              _animation.value,
              _animation.value + 1,
            ],
          ).createShader(bounds),
          child: widget.customWidget ?? const SizedBox(),
        );
    }
  }
}

/// 스켈레톤 카드
class SkeletonCard extends StatelessWidget {
  final double? width;
  final double? height;
  final EdgeInsets padding;

  const SkeletonCard({
    super.key,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colors = theme.colors;

    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.onBackground.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Skeleton(type: SkeletonType.circle, width: 48, height: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(
                      type: SkeletonType.line,
                      width: double.infinity,
                      height: 16,
                    ),
                    const SizedBox(height: 8),
                    Skeleton(
                      type: SkeletonType.line,
                      width: 100,
                      height: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Skeleton(
            type: SkeletonType.line,
            width: double.infinity,
            height: 12,
          ),
          const SizedBox(height: 8),
          Skeleton(
            type: SkeletonType.line,
            width: double.infinity,
            height: 12,
          ),
          const SizedBox(height: 8),
          Skeleton(
            type: SkeletonType.line,
            width: 150,
            height: 12,
          ),
        ],
      ),
    );
  }
}

/// 스켈레톤 리스트
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  const SkeletonList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

/// 스켈레톤 그리드
class SkeletonGrid extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final Widget Function(BuildContext, int) itemBuilder;

  const SkeletonGrid({
    super.key,
    required this.itemCount,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 8,
    this.crossAxisSpacing = 8,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: itemCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
      ),
      itemBuilder: itemBuilder,
    );
  }
}

/// 프로그레스 인디케이터
class AppProgressIndicator extends StatelessWidget {
  final double value;
  final Color? color;
  final double strokeWidth;
  final String? label;

  const AppProgressIndicator({
    super.key,
    required this.value,
    this.color,
    this.strokeWidth = 4,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colors = theme.colors;

    final effectiveColor = color ?? colors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            value: value,
            color: effectiveColor,
            strokeWidth: strokeWidth,
            backgroundColor: colors.onBackground.withOpacity(0.1),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label!,
            style: theme.toMaterialTheme().textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

/// 선형 프로그레스 바
class LinearProgressBar extends StatelessWidget {
  final double value;
  final Color? color;
  final double height;
  final String? label;
  final bool showPercentage;

  const LinearProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 8,
    this.label,
    this.showPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colors = theme.colors;

    final effectiveColor = color ?? colors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label!,
                style: theme.toMaterialTheme().textTheme.bodyMedium,
              ),
              if (showPercentage)
                Text(
                  '${(value * 100).toInt()}%',
                  style: theme.toMaterialTheme().textTheme.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: height,
          decoration: BoxDecoration(
            color: colors.onBackground.withOpacity(0.1),
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: LinearProgressIndicator(
              value: value,
              color: effectiveColor,
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }
}

/// 풀스크린 로딩
class FullScreenLoading extends StatelessWidget {
  final String? message;
  final Widget? customWidget;

  const FullScreenLoading({
    super.key,
    this.message,
    this.customWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              customWidget ?? const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: theme.toMaterialTheme().textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
