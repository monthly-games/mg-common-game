import 'package:flutter/material.dart';
import 'tutorial_step.dart';
import 'tutorial_manager.dart';

/// Tutorial overlay widget that highlights targets and shows tooltips
class TutorialOverlay extends StatelessWidget {
  final TutorialManager manager;
  final Widget child;
  final Color overlayColor;
  final Color highlightColor;
  final TextStyle? titleStyle;
  final TextStyle? descriptionStyle;
  final Widget Function(BuildContext, TutorialStep, VoidCallback, VoidCallback?)? tooltipBuilder;

  const TutorialOverlay({
    super.key,
    required this.manager,
    required this.child,
    this.overlayColor = const Color(0xCC000000),
    this.highlightColor = Colors.white,
    this.titleStyle,
    this.descriptionStyle,
    this.tooltipBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: manager,
      builder: (context, _) {
        return Stack(
          children: [
            child,
            if (manager.isRunning && manager.currentStep != null)
              _buildOverlay(context),
          ],
        );
      },
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final step = manager.currentStep!;
    final targetKey = step.targetKey;

    Rect? targetRect;
    if (targetKey != null) {
      final renderBox = targetKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);
        targetRect = Rect.fromLTWH(
          position.dx - step.highlightPadding,
          position.dy - step.highlightPadding,
          renderBox.size.width + step.highlightPadding * 2,
          renderBox.size.height + step.highlightPadding * 2,
        );
      }
    }

    return GestureDetector(
      onTap: step.requireTap ? manager.nextStep : null,
      child: Stack(
        children: [
          // Dark overlay with hole
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _OverlayPainter(
              overlayColor: overlayColor,
              targetRect: targetRect,
              highlightShape: step.highlightShape,
              highlightColor: highlightColor,
            ),
          ),

          // Tooltip
          _buildTooltip(context, step, targetRect),

          // Skip button
          if (manager.currentSequence?.canSkip == true)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: _buildSkipButton(context),
            ),

          // Progress indicator
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 0,
            right: 0,
            child: _buildProgress(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTooltip(BuildContext context, TutorialStep step, Rect? targetRect) {
    if (tooltipBuilder != null) {
      return tooltipBuilder!(
        context,
        step,
        manager.nextStep,
        manager.hasMoreSteps ? null : manager.skipTutorial,
      );
    }

    final screenSize = MediaQuery.of(context).size;
    final tooltipWidth = screenSize.width * 0.85;

    double top = screenSize.height * 0.4;
    double left = (screenSize.width - tooltipWidth) / 2;

    if (targetRect != null) {
      switch (step.tooltipPosition) {
        case TutorialPosition.top:
          top = targetRect.top - 150;
          break;
        case TutorialPosition.bottom:
          top = targetRect.bottom + 20;
          break;
        case TutorialPosition.left:
          left = targetRect.left - tooltipWidth - 20;
          top = targetRect.center.dy - 60;
          break;
        case TutorialPosition.right:
          left = targetRect.right + 20;
          top = targetRect.center.dy - 60;
          break;
        case TutorialPosition.center:
          // Keep default centered position
          break;
      }

      // Clamp to screen bounds
      top = top.clamp(50, screenSize.height - 200);
      left = left.clamp(16, screenSize.width - tooltipWidth - 16);
    }

    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: tooltipWidth,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              step.title,
              style: titleStyle ??
                  const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              step.description,
              style: descriptionStyle ??
                  const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (step.requireTap)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      manager.hasMoreSteps ? 'Next' : 'Done',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkipButton(BuildContext context) {
    return GestureDetector(
      onTap: manager.skipTutorial,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
        ),
        child: const Text(
          'Skip',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(BuildContext context) {
    final sequence = manager.currentSequence;
    if (sequence == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${manager.currentStepIndex + 1} / ${sequence.totalSteps}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: manager.progress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// Painter for the overlay with a hole for the target
class _OverlayPainter extends CustomPainter {
  final Color overlayColor;
  final Rect? targetRect;
  final TutorialHighlightShape highlightShape;
  final Color highlightColor;

  _OverlayPainter({
    required this.overlayColor,
    required this.targetRect,
    required this.highlightShape,
    required this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = overlayColor;
    final highlightPaint = Paint()
      ..color = highlightColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    if (targetRect != null) {
      Path holePath;

      switch (highlightShape) {
        case TutorialHighlightShape.circle:
          final radius = targetRect!.longestSide / 2;
          holePath = Path()
            ..addOval(Rect.fromCircle(
              center: targetRect!.center,
              radius: radius,
            ));
          break;

        case TutorialHighlightShape.roundedRectangle:
          holePath = Path()
            ..addRRect(RRect.fromRectAndRadius(
              targetRect!,
              const Radius.circular(12),
            ));
          break;

        case TutorialHighlightShape.rectangle:
        default:
          holePath = Path()..addRect(targetRect!);
          break;
      }

      path.fillType = PathFillType.evenOdd;
      path.addPath(holePath, Offset.zero);

      // Draw highlight border
      canvas.drawPath(holePath, highlightPaint);
    }

    canvas.drawPath(path, overlayPaint);
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.overlayColor != overlayColor;
  }
}
