import 'package:flutter/material.dart';

/// Tutorial step configuration
class TutorialStep {
  final String id;
  final String title;
  final String description;
  final GlobalKey? targetKey;
  final Alignment? targetAlignment;
  final TutorialHighlightShape highlightShape;
  final double highlightPadding;
  final TutorialPosition tooltipPosition;
  final VoidCallback? onShow;
  final VoidCallback? onComplete;
  final bool requireTap;
  final Duration? autoAdvanceDelay;

  const TutorialStep({
    required this.id,
    required this.title,
    required this.description,
    this.targetKey,
    this.targetAlignment,
    this.highlightShape = TutorialHighlightShape.rectangle,
    this.highlightPadding = 8.0,
    this.tooltipPosition = TutorialPosition.bottom,
    this.onShow,
    this.onComplete,
    this.requireTap = true,
    this.autoAdvanceDelay,
  });

  TutorialStep copyWith({
    String? id,
    String? title,
    String? description,
    GlobalKey? targetKey,
    Alignment? targetAlignment,
    TutorialHighlightShape? highlightShape,
    double? highlightPadding,
    TutorialPosition? tooltipPosition,
    VoidCallback? onShow,
    VoidCallback? onComplete,
    bool? requireTap,
    Duration? autoAdvanceDelay,
  }) {
    return TutorialStep(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetKey: targetKey ?? this.targetKey,
      targetAlignment: targetAlignment ?? this.targetAlignment,
      highlightShape: highlightShape ?? this.highlightShape,
      highlightPadding: highlightPadding ?? this.highlightPadding,
      tooltipPosition: tooltipPosition ?? this.tooltipPosition,
      onShow: onShow ?? this.onShow,
      onComplete: onComplete ?? this.onComplete,
      requireTap: requireTap ?? this.requireTap,
      autoAdvanceDelay: autoAdvanceDelay ?? this.autoAdvanceDelay,
    );
  }
}

/// Highlight shape for tutorial target
enum TutorialHighlightShape {
  rectangle,
  circle,
  roundedRectangle,
}

/// Tooltip position relative to target
enum TutorialPosition {
  top,
  bottom,
  left,
  right,
  center,
}

/// Tutorial sequence configuration
class TutorialSequence {
  final String id;
  final String name;
  final List<TutorialStep> steps;
  final bool canSkip;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;

  const TutorialSequence({
    required this.id,
    required this.name,
    required this.steps,
    this.canSkip = true,
    this.onComplete,
    this.onSkip,
  });

  int get totalSteps => steps.length;
}
