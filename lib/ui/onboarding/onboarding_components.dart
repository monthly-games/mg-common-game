import 'package:flutter/material.dart';
import 'package:mg_common_game/ui/theme/theme_manager.dart';
import 'package:mg_common_game/ui/animation/animation_components.dart';

/// 온보딩 페이지 데이터
class OnboardingPageData {
  final String title;
  final String description;
  final String? imagePath;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;

  const OnboardingPageData({
    required this.title,
    required this.description,
    this.imagePath,
    this.icon,
    this.backgroundColor,
    this.textColor,
  });
}

/// 온보딩 스크린
class OnboardingScreen extends StatefulWidget {
  final List<OnboardingPageData> pages;
  final VoidCallback? onCompleted;
  final VoidCallback? onSkipped;
  final String skipText;
  final String nextText;
  final String doneText;
  final bool showSkip;
  final bool showDots;
  final Duration autoScrollDuration;
  final bool autoScroll;

  const OnboardingScreen({
    super.key,
    required this.pages,
    this.onCompleted,
    this.onSkipped,
    this.skipText = '건너뛰기',
    this.nextText = '다음',
    this.doneText = '시작하기',
    this.showSkip = true,
    this.showDots = true,
    this.autoScrollDuration = const Duration(seconds: 5),
    this.autoScroll = false,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    if (widget.autoScroll) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    Future.delayed(widget.autoScrollDuration, () {
      if (mounted && _currentPage < widget.pages.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < widget.pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onCompleted?.call();
    }
  }

  void _skip() {
    widget.onSkipped?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colors = theme.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            if (widget.showSkip && _currentPage < widget.pages.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _skip,
                    child: Text(widget.skipText),
                  ),
                ),
              ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: widget.pages.length,
                itemBuilder: (context, index) {
                  return _OnboardingPage(
                    data: widget.pages[index],
                  );
                },
              ),
            ),

            // Dots Indicator
            if (widget.showDots)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: _PageIndicator(
                  currentPage: _currentPage,
                  pageCount: widget.pages.length,
                ),
              ),

            // Next/Done Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  child: Text(
                    _currentPage == widget.pages.length - 1
                        ? widget.doneText
                        : widget.nextText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 온보딩 페이지
class _OnboardingPage extends StatelessWidget {
  final OnboardingPageData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colors = theme.colors;

    final effectiveBackgroundColor = data.backgroundColor ?? colors.background;
    final effectiveTextColor = data.textColor ?? colors.onBackground;

    return Container(
      color: effectiveBackgroundColor,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image or Icon
          if (data.imagePath != null)
            Expanded(
              flex: 2,
              child: AnimatedWidgetWrapper(
                type: AnimationType.scaleIn,
                options: const AnimationOptions(
                  duration: Duration(milliseconds: 500),
                ),
                child: Image.asset(data.imagePath!),
              ),
            )
          else if (data.icon != null)
            Expanded(
              flex: 2,
              child: AnimatedWidgetWrapper(
                type: AnimationType.scaleIn,
                options: const AnimationOptions(
                  duration: Duration(milliseconds: 500),
                ),
                child: Icon(
                  data.icon,
                  size: 120,
                  color: colors.primary,
                ),
              ),
            ),

          const SizedBox(height: 32),

          // Title
          AnimatedWidgetWrapper(
            type: AnimationType.slideIn,
            direction: AnimationDirection.bottom,
            options: const AnimationOptions(
              duration: Duration(milliseconds: 400),
              delay: Duration(milliseconds: 200),
            ),
            child: Text(
              data.title,
              style: theme.toMaterialTheme().textTheme.displaySmall?.copyWith(
                color: effectiveTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 16),

          // Description
          AnimatedWidgetWrapper(
            type: AnimationType.slideIn,
            direction: AnimationDirection.bottom,
            options: const AnimationOptions(
              duration: Duration(milliseconds: 400),
              delay: Duration(milliseconds: 300),
            ),
            child: Text(
              data.description,
              style: theme.toMaterialTheme().textTheme.bodyLarge?.copyWith(
                color: effectiveTextColor.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// 페이지 인디케이터
class _PageIndicator extends StatelessWidget {
  final int currentPage;
  final int pageCount;

  const _PageIndicator({
    required this.currentPage,
    required this.pageCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
        (index) => _IndicatorDot(
          isActive: index == currentPage,
        ),
      ),
    );
  }
}

/// 인디케이터 도트
class _IndicatorDot extends StatelessWidget {
  final bool isActive;

  const _IndicatorDot({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? colors.primary : colors.onBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// 튜토리얼 하이라이트 (특정 위젯 강조)
class TutorialHighlight extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? description;
  final bool showHighlight;
  final VoidCallback? onDismiss;

  const TutorialHighlight({
    super.key,
    required this.child,
    this.title,
    this.description,
    this.showHighlight = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (showHighlight)
          Positioned.fill(
            child: _HighlightOverlay(
              title: title,
              description: description,
              onDismiss: onDismiss,
            ),
          ),
      ],
    );
  }
}

/// 하이라이트 오버레이
class _HighlightOverlay extends StatelessWidget {
  final String? title;
  final String? description;
  final VoidCallback? onDismiss;

  const _HighlightOverlay({
    this.title,
    this.description,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colors = theme.colors;

    return Container(
      color: colors.onBackground.withOpacity(0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null) ...[
                Text(
                  title!,
                  style: theme.toMaterialTheme().textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],
              if (description != null) ...[
                Text(
                  description!,
                  style: theme.toMaterialTheme().textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: onDismiss,
                child: const Text('확인'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 툴팁 위젯
class TooltipWidget extends StatelessWidget {
  final String message;
  final Widget child;
  final bool show;
  final Duration showDuration;
  final TooltipDirection direction;

  const TooltipWidget({
    super.key,
    required this.message,
    required this.child,
    this.show = false,
    this.showDuration = const Duration(seconds: 3),
    this.direction = TooltipDirection.top,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (show)
          Positioned(
            top: direction == TooltipDirection.bottom ? null : -50,
            bottom: direction == TooltipDirection.bottom ? -50 : null,
            left: 0,
            right: 0,
            child: _TooltipContent(
              message: message,
              direction: direction,
            ),
          ),
      ],
    );
  }
}

/// 툴팁 컨텐츠
class _TooltipContent extends StatelessWidget {
  final String message;
  final TooltipDirection direction;

  const _TooltipContent({
    required this.message,
    required this.direction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colors = theme.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.onBackground,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        message,
        style: TextStyle(
          color: colors.background,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// 툴팁 방향
enum TooltipDirection {
  top,
  bottom,
  left,
  right,
}
