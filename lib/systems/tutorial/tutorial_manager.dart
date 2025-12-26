import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tutorial_step.dart';

/// Tutorial state
enum TutorialState {
  idle,
  running,
  paused,
  completed,
  skipped,
}

/// Manages tutorial sequences and progress
class TutorialManager extends ChangeNotifier {
  static const String _prefKeyPrefix = 'tutorial_completed_';

  TutorialState _state = TutorialState.idle;
  TutorialSequence? _currentSequence;
  int _currentStepIndex = 0;
  final Set<String> _completedTutorials = {};
  SharedPreferences? _prefs;

  TutorialState get state => _state;
  TutorialSequence? get currentSequence => _currentSequence;
  int get currentStepIndex => _currentStepIndex;
  TutorialStep? get currentStep =>
      _currentSequence != null && _currentStepIndex < _currentSequence!.steps.length
          ? _currentSequence!.steps[_currentStepIndex]
          : null;

  bool get isRunning => _state == TutorialState.running;
  bool get hasMoreSteps =>
      _currentSequence != null && _currentStepIndex < _currentSequence!.steps.length - 1;

  double get progress => _currentSequence != null
      ? (_currentStepIndex + 1) / _currentSequence!.totalSteps
      : 0.0;

  /// Initialize the tutorial manager
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadCompletedTutorials();
  }

  void _loadCompletedTutorials() {
    final keys = _prefs?.getKeys() ?? {};
    for (final key in keys) {
      if (key.startsWith(_prefKeyPrefix)) {
        final tutorialId = key.substring(_prefKeyPrefix.length);
        if (_prefs?.getBool(key) == true) {
          _completedTutorials.add(tutorialId);
        }
      }
    }
  }

  /// Check if a tutorial has been completed
  bool isTutorialCompleted(String tutorialId) {
    return _completedTutorials.contains(tutorialId);
  }

  /// Check if this is the first run (no tutorials completed)
  bool get isFirstRun => _completedTutorials.isEmpty;

  /// Start a tutorial sequence
  Future<bool> startTutorial(TutorialSequence sequence, {bool force = false}) async {
    if (!force && isTutorialCompleted(sequence.id)) {
      return false;
    }

    _currentSequence = sequence;
    _currentStepIndex = 0;
    _state = TutorialState.running;

    _currentStep?.onShow?.call();
    notifyListeners();

    _handleAutoAdvance();
    return true;
  }

  /// Advance to the next step
  void nextStep() {
    if (_currentSequence == null || _state != TutorialState.running) return;

    _currentStep?.onComplete?.call();

    if (hasMoreSteps) {
      _currentStepIndex++;
      _currentStep?.onShow?.call();
      notifyListeners();
      _handleAutoAdvance();
    } else {
      _completeTutorial();
    }
  }

  /// Go back to the previous step
  void previousStep() {
    if (_currentSequence == null || _currentStepIndex <= 0) return;

    _currentStepIndex--;
    _currentStep?.onShow?.call();
    notifyListeners();
  }

  /// Skip the current tutorial
  void skipTutorial() {
    if (_currentSequence == null) return;

    _currentSequence!.onSkip?.call();
    _state = TutorialState.skipped;
    _markTutorialCompleted(_currentSequence!.id);
    _currentSequence = null;
    _currentStepIndex = 0;
    notifyListeners();
  }

  /// Pause the tutorial
  void pauseTutorial() {
    if (_state == TutorialState.running) {
      _state = TutorialState.paused;
      notifyListeners();
    }
  }

  /// Resume the tutorial
  void resumeTutorial() {
    if (_state == TutorialState.paused) {
      _state = TutorialState.running;
      notifyListeners();
    }
  }

  void _completeTutorial() {
    if (_currentSequence == null) return;

    _currentSequence!.onComplete?.call();
    _state = TutorialState.completed;
    _markTutorialCompleted(_currentSequence!.id);
    _currentSequence = null;
    _currentStepIndex = 0;
    notifyListeners();
  }

  Future<void> _markTutorialCompleted(String tutorialId) async {
    _completedTutorials.add(tutorialId);
    await _prefs?.setBool('$_prefKeyPrefix$tutorialId', true);
  }

  /// Reset a specific tutorial (for testing)
  Future<void> resetTutorial(String tutorialId) async {
    _completedTutorials.remove(tutorialId);
    await _prefs?.remove('$_prefKeyPrefix$tutorialId');
    notifyListeners();
  }

  /// Reset all tutorials (for testing)
  Future<void> resetAllTutorials() async {
    for (final id in _completedTutorials.toList()) {
      await _prefs?.remove('$_prefKeyPrefix$id');
    }
    _completedTutorials.clear();
    notifyListeners();
  }

  void _handleAutoAdvance() {
    final delay = _currentStep?.autoAdvanceDelay;
    if (delay != null && !(_currentStep?.requireTap ?? true)) {
      Future.delayed(delay, () {
        if (_state == TutorialState.running) {
          nextStep();
        }
      });
    }
  }

  @override
  void dispose() {
    _currentSequence = null;
    super.dispose();
  }
}
