import 'package:flutter/material.dart';
import '../../layout/mg_spacing.dart';

/// MG-Games 로딩 위젯
/// UI_UX_MASTER_GUIDE.md 기반

/// 로딩 스피너
class MGLoadingSpinner extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const MGLoadingSpinner({
    super.key,
    this.size = 32,
    this.color,
    this.strokeWidth = 3,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation(
          color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// 로딩 오버레이
class MGLoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final Color? overlayColor;
  final Widget? loadingWidget;
  final String? message;

  const MGLoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.overlayColor,
    this.loadingWidget,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: overlayColor ?? Colors.black54,
              child: Center(
                child: loadingWidget ??
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const MGLoadingSpinner(size: 48),
                        if (message != null) ...[
                          MGSpacing.vMd,
                          Text(
                            message!,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ],
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 풀스크린 로딩
class MGFullScreenLoading extends StatelessWidget {
  final String? message;
  final double? progress;
  final Color? backgroundColor;
  final Widget? logo;

  const MGFullScreenLoading({
    super.key,
    this.message,
    this.progress,
    this.backgroundColor,
    this.logo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (logo != null) ...[
              logo!,
              MGSpacing.vXl,
            ],
            if (progress != null)
              SizedBox(
                width: 200,
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[800],
                    ),
                    MGSpacing.vSm,
                    Text(
                      '${(progress! * 100).round()}%',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              )
            else
              const MGLoadingSpinner(size: 48),
            if (message != null) ...[
              MGSpacing.vMd,
              Text(
                message!,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 스켈레톤 로딩
class MGSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool circle;

  const MGSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 4,
    this.circle = false,
  });

  /// 원형 스켈레톤
  const MGSkeleton.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = 0,
        circle = true;

  /// 텍스트 스켈레톤
  const MGSkeleton.text({
    super.key,
    this.width = double.infinity,
    this.height = 14,
  })  : borderRadius = 4,
        circle = false;

  /// 아바타 스켈레톤
  const MGSkeleton.avatar({
    super.key,
    double size = 40,
  })  : width = size,
        height = size,
        borderRadius = 0,
        circle = true;

  @override
  State<MGSkeleton> createState() => _MGSkeletonState();
}

class _MGSkeletonState extends State<MGSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.circle
                ? null
                : BorderRadius.circular(widget.borderRadius),
            shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFF333333),
                Color(0xFF444444),
                Color(0xFF333333),
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 스켈레톤 카드
class MGSkeletonCard extends StatelessWidget {
  final bool hasImage;
  final bool hasTitle;
  final bool hasSubtitle;
  final int descriptionLines;

  const MGSkeletonCard({
    super.key,
    this.hasImage = true,
    this.hasTitle = true,
    this.hasSubtitle = true,
    this.descriptionLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage) ...[
            const MGSkeleton(height: 120, borderRadius: 8),
            const SizedBox(height: 12),
          ],
          if (hasTitle) ...[
            const MGSkeleton(width: 150, height: 20),
            const SizedBox(height: 8),
          ],
          if (hasSubtitle) ...[
            const MGSkeleton(width: 100, height: 14),
            const SizedBox(height: 12),
          ],
          ...List.generate(
            descriptionLines,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MGSkeleton(
                width: index == descriptionLines - 1 ? 200 : double.infinity,
                height: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 스켈레톤 리스트 아이템
class MGSkeletonListItem extends StatelessWidget {
  final bool hasLeading;
  final bool hasTrailing;

  const MGSkeletonListItem({
    super.key,
    this.hasLeading = true,
    this.hasTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          if (hasLeading) ...[
            const MGSkeleton.circle(size: 40),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                MGSkeleton(width: 120, height: 16),
                SizedBox(height: 6),
                MGSkeleton(width: 80, height: 12),
              ],
            ),
          ),
          if (hasTrailing) ...[
            const SizedBox(width: 12),
            const MGSkeleton(width: 60, height: 24, borderRadius: 12),
          ],
        ],
      ),
    );
  }
}

/// 점 로딩 애니메이션
class MGDotsLoading extends StatefulWidget {
  final double dotSize;
  final Color? color;
  final int dotCount;

  const MGDotsLoading({
    super.key,
    this.dotSize = 8,
    this.color,
    this.dotCount = 3,
  });

  @override
  State<MGDotsLoading> createState() => _MGDotsLoadingState();
}

class _MGDotsLoadingState extends State<MGDotsLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.dotCount, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index / widget.dotCount;
            final value = (_controller.value + delay) % 1.0;
            final scale = 0.5 + 0.5 * (1 - (value - 0.5).abs() * 2);

            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.dotSize * 0.25),
              width: widget.dotSize * scale,
              height: widget.dotSize * scale,
              decoration: BoxDecoration(
                color: color.withOpacity(0.5 + 0.5 * scale),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
