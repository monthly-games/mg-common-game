import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TutorialPage {
  final String title;
  final String content;
  final String? imageAsset;

  const TutorialPage({
    required this.title,
    required this.content,
    this.imageAsset,
  });
}

class TutorialGameOverlay extends StatefulWidget {
  final FlameGame game;
  final List<TutorialPage> pages;
  final VoidCallback? onComplete;
  final Color? accentColor;

  const TutorialGameOverlay({
    super.key,
    required this.game,
    required this.pages,
    this.onComplete,
    this.accentColor,
  });

  @override
  State<TutorialGameOverlay> createState() => _TutorialGameOverlayState();
}

class _TutorialGameOverlayState extends State<TutorialGameOverlay> {
  int _currentPage = 0;

  void _nextPage() {
    if (_currentPage < widget.pages.length - 1) {
      setState(() {
        _currentPage++;
      });
    } else {
      _close();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _close() {
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      widget.game.overlays.remove('TutorialGame');
      widget.game.resumeEngine();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pages.isEmpty) return const SizedBox.shrink();

    final page = widget.pages[_currentPage];
    final color = widget.accentColor ?? AppColors.primary;

    return Center(
      child: Container(
        width: 400,
        height: 350,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Title
            Text(
              page.title,
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Divider(color: color.withOpacity(0.5)),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (page.imageAsset != null) ...[
                      Image.asset(
                        page.imageAsset!,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      page.content,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  TextButton(
                    onPressed: _prevPage,
                    child: Text(
                      'PREV',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  )
                else
                  const SizedBox(width: 64),

                // Dots
                Row(
                  children: List.generate(widget.pages.length, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? color
                            : Colors.grey.withOpacity(0.5),
                      ),
                    );
                  }),
                ),

                if (_currentPage < widget.pages.length - 1)
                  TextButton(
                    onPressed: _nextPage,
                    child: Text(
                      'NEXT',
                      style: TextStyle(color: color),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: _close,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('GOT IT'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
