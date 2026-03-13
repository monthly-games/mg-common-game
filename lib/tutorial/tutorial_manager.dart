import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_common_game/analytics/analytics_manager.dart';

/// 튜토리얼 단계 타입
enum TutorialStepType {
  highlight, // UI 요소 강조
  dialog, // 대화창
  action, // 사용자 행동 유도
  wait, // 특정 이벤트 대기
  complete, // 튜토리얼 완료
}

/// 튜토리얼 단계
class TutorialStep {
  final String id;
  final String title;
  final String description;
  final TutorialStepType type;
  final String? targetWidgetKey; // 강조할 위젯의 키
  final List<String>? allowedActions; // 허용된 행동들
  final Duration? timeout;
  final Map<String, dynamic>? metadata;

  const TutorialStep({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.targetWidgetKey,
    this.allowedActions,
    this.timeout,
    this.metadata,
  });

  /// 하이라이트 단계
  static TutorialStep highlight({
    required String id,
    required String title,
    required String description,
    required String targetKey,
  }) =>
      TutorialStep(
        id: id,
        title: title,
        description: description,
        type: TutorialStepType.highlight,
        targetWidgetKey: targetKey,
      );

  /// 대화 단계
  static TutorialStep dialog({
    required String id,
    required String title,
    required String description,
  }) =>
      TutorialStep(
        id: id,
        title: title,
        description: description,
        type: TutorialStepType.dialog,
      );

  /// 행동 유도 단계
  static TutorialStep action({
    required String id,
    required String title,
    required String description,
    required String targetKey,
    List<String>? allowedActions,
  }) =>
      TutorialStep(
        id: id,
        title: title,
        description: description,
        type: TutorialStepType.action,
        targetWidgetKey: targetKey,
        allowedActions: allowedActions,
      );
}

/// 튜토리얼 진행 상태
class TutorialProgress {
  final String tutorialId;
  final List<String> completedSteps;
  final String currentStepId;
  final DateTime lastAccessed;
  final bool isSkipped;
  final DateTime? completedAt;

  const TutorialProgress({
    required this.tutorialId,
    required this.completedSteps,
    required this.currentStepId,
    required this.lastAccessed,
    this.isSkipped = false,
    this.completedAt,
  });

  double get progress {
    if (isSkipped) return 1.0;
    if (completedSteps.isEmpty) return 0.0;
    return completedSteps.length / (completedSteps.length + 1);
  }

  Map<String, dynamic> toJson() => {
        'tutorialId': tutorialId,
        'completedSteps': completedSteps,
        'currentStepId': currentStepId,
        'lastAccessed': lastAccessed.toIso8601String(),
        'isSkipped': isSkipped,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory TutorialProgress.fromJson(Map<String, dynamic> json) =>
      TutorialProgress(
        tutorialId: json['tutorialId'] as String,
        completedSteps:
            (json['completedSteps'] as List<dynamic>).cast<String>(),
        currentStepId: json['currentStepId'] as String,
        lastAccessed: DateTime.parse(json['lastAccessed'] as String),
        isSkipped: json['isSkipped'] as bool? ?? false,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
      );
}

/// 튜토리얼 정의
class Tutorial {
  final String id;
  final String name;
  final String description;
  final List<TutorialStep> steps;
  final bool isSkippable;
  final bool forceOnFirstLaunch;
  final String? rewardId;
  final int? rewardAmount;

  const Tutorial({
    required this.id,
    required this.name,
    required this.description,
    required this.steps,
    this.isSkippable = true,
    this.forceOnFirstLaunch = false,
    this.rewardId,
    this.rewardAmount,
  });
}

/// 튜토리얼 매니저
class TutorialManager {
  static final TutorialManager _instance = TutorialManager._();
  static TutorialManager get instance => _instance;

  TutorialManager._();

  // ============================================
  // 상태
  // ============================================
  SharedPreferences? _prefs;
  final Map<String, Tutorial> _tutorials = {};
  final Map<String, TutorialProgress> _progress = {};

  final StreamController<TutorialProgress> _progressController =
      StreamController<TutorialProgress>.broadcast();
  final StreamController<String> _startController =
      StreamController<String>.broadcast();
  final StreamController<String> _completeController =
      StreamController<String>.broadcast();

  Tutorial? _activeTutorial;
  int _currentStepIndex = 0;

  // Getters
  Tutorial? get activeTutorial => _activeTutorial;
  TutorialStep? get currentStep =>
      _activeTutorial?.steps[_currentStepIndex];
  List<Tutorial> get tutorials => _tutorials.values.toList();
  Stream<TutorialProgress> get onProgressUpdate => _progressController.stream;
  Stream<String> get onTutorialStart => _startController.stream;
  Stream<String> get onTutorialComplete => _completeController.stream;

  // ============================================
  // 초기화
  // ============================================

  Future<void> initialize() async {
    if (_prefs != null) return;

    _prefs = await SharedPreferences.getInstance();

    // 진행 상태 로드
    await _loadProgress();

    // 기본 튜토리얼 등록
    _registerDefaultTutorials();

    debugPrint('[Tutorial] Initialized');
  }

  Future<void> _loadProgress() async {
    final progressJson = _prefs!.getString('tutorial_progress');
    if (progressJson != null) {
      final json = jsonDecode(progressJson) as Map<String, dynamic>;

      for (final entry in json.entries) {
        _progress[entry.key] =
            TutorialProgress.fromJson(entry.value as Map<String, dynamic>);
      }
    }
  }

  void _registerDefaultTutorials() {
    // 게임 기본 튜토리얼
    _tutorials['game_basics'] = Tutorial(
      id: 'game_basics',
      name: '게임 기본',
      description: '게임의 기본 조작법을 배웁니다',
      forceOnFirstLaunch: true,
      rewardId: 'coins',
      rewardAmount: 100,
      steps: [
        TutorialStep.dialog(
          id: 'welcome',
          title: '환영합니다!',
          description: 'MG Games에 오신 것을 환영합니다. 기본 조작법을 알아볼까요?',
        ),
        TutorialStep.highlight(
          id: 'play_button',
          title: '플레이 버튼',
          description: '게임을 시작하려면 이 버튼을 누르세요',
          targetKey: 'play_button',
        ),
        TutorialStep.action(
          id: 'tap_play',
          title: '게임 시작',
          description: '플레이 버튼을 탭하여 게임을 시작하세요',
          targetKey: 'play_button',
          allowedActions: ['tap_play_button'],
        ),
        TutorialStep.dialog(
          id: 'controls',
          title: '조작법',
          description: '화면을 터치하여 캐릭터를 이동할 수 있습니다',
        ),
        TutorialStep.highlight(
          id: 'score',
          title: '점수',
          description: '여기서 현재 점수를 확인할 수 있습니다',
          targetKey: 'score_display',
        ),
        TutorialStep.dialog(
          id: 'complete',
          title: '튜토리얼 완료!',
          description: '축하합니다! 100코인을 받았습니다.',
        ),
      ],
    );

    // 퀘스트 튜토리얼
    _tutorials['quest_tutorial'] = Tutorial(
      id: 'quest_tutorial',
      name: '퀘스트 안내',
      description: '퀘스트 시스템 사용법을 배웁니다',
      steps: [
        TutorialStep.dialog(
          id: 'quest_intro',
          title: '퀘스트',
          description: '일일 퀘스트를 완료하면 보상을 받을 수 있습니다',
        ),
        TutorialStep.highlight(
          id: 'quest_tab',
          title: '퀘스트 탭',
          description: '여기서 퀘스트를 확인할 수 있습니다',
          targetKey: 'quest_tab',
        ),
        TutorialStep.action(
          id: 'open_quest',
          title: '퀘스트 열기',
          description: '퀘스트 탭을 탭하세요',
          targetKey: 'quest_tab',
          allowedActions: ['open_quest_tab'],
        ),
        TutorialStep.highlight(
          id: 'daily_quest',
          title: '일일 퀘스트',
          description: '매일 새로운 퀘스트가 등장합니다',
          targetKey: 'daily_quest_list',
        ),
      ],
    );

    // 상점 튜토리얼
    _tutorials['shop_tutorial'] = Tutorial(
      id: 'shop_tutorial',
      name: '상점 이용법',
      description: '상점에서 아이템을 구매하는 방법을 배웁니다',
      steps: [
        TutorialStep.dialog(
          id: 'shop_intro',
          title: '상점',
          description: '코인으로 아이템을 구매할 수 있습니다',
        ),
        TutorialStep.highlight(
          id: 'shop_tab',
          title: '상점 탭',
          description: '상점 탭을 눌러보세요',
          targetKey: 'shop_tab',
        ),
        TutorialStep.action(
          id: 'open_shop',
          title: '상점 열기',
          description: '상점 탭을 탭하세요',
          targetKey: 'shop_tab',
          allowedActions: ['open_shop_tab'],
        ),
        TutorialStep.highlight(
          id: 'item_list',
          title: '아이템 목록',
          description: '다양한 아이템을 판매하고 있습니다',
          targetKey: 'shop_item_list',
        ),
      ],
    );
  }

  // ============================================
  // 튜토리얼 관리
  // ============================================

  /// 튜토리얼 시작
  Future<void> startTutorial(String tutorialId) async {
    if (!_isInitialized) {
      await initialize();
    }

    final tutorial = _tutorials[tutorialId];
    if (tutorial == null) {
      debugPrint('[Tutorial] Tutorial not found: $tutorialId');
      return;
    }

    _activeTutorial = tutorial;
    _currentStepIndex = 0;

    final progress = TutorialProgress(
      tutorialId: tutorialId,
      completedSteps: [],
      currentStepId: tutorial.steps[0].id,
      lastAccessed: DateTime.now(),
    );

    _progress[tutorialId] = progress;
    await _saveProgress();

    _startController.add(tutorialId);
    _progressController.add(progress);

    // 애널리틱스
    await AnalyticsManager.instance.logEvent('tutorial_started', parameters: {
      'tutorial_id': tutorialId,
    });

    debugPrint('[Tutorial] Started: ${tutorial.name}');
  }

  /// 다음 단계로
  Future<void> nextStep() async {
    if (_activeTutorial == null) return;

    final currentStep = _activeTutorial!.steps[_currentStepIndex];
    _progress[_activeTutorial!.id]!.completedSteps.add(currentStep.id);

    _currentStepIndex++;

    if (_currentStepIndex >= _activeTutorial!.steps.length) {
      await completeTutorial();
      return;
    }

    final nextStep = _activeTutorial!.steps[_currentStepIndex];
    _progress[_activeTutorial!.id]!.currentStepId = nextStep.id;

    await _saveProgress();
    _progressController.add(_progress[_activeTutorial!.id]!);
  }

  /// 특정 단계로 점프
  Future<void> goToStep(String stepId) async {
    if (_activeTutorial == null) return;

    final stepIndex = _activeTutorial!.steps.indexWhere(
      (s) => s.id == stepId,
    );

    if (stepIndex == -1) return;

    _currentStepIndex = stepIndex;
    _progress[_activeTutorial!.id]!.currentStepId = stepId;

    await _saveProgress();
  }

  /// 튜토리얼 완료
  Future<void> completeTutorial() async {
    if (_activeTutorial == null) return;

    final tutorialId = _activeTutorial!.id;

    final progress = TutorialProgress(
      tutorialId: tutorialId,
      completedSteps: _activeTutorial!.steps.map((s) => s.id).toList(),
      currentStepId: '',
      lastAccessed: DateTime.now(),
      completedAt: DateTime.now(),
    );

    _progress[tutorialId] = progress;
    await _saveProgress();

    _completeController.add(tutorialId);
    _progressController.add(progress);

    // 보상 지급
    if (_activeTutorial!.rewardId != null) {
      await _grantReward(
        _activeTutorial!.rewardId!,
        _activeTutorial!.rewardAmount ?? 0,
      );
    }

    // 애널리틱스
    await AnalyticsManager.instance.logEvent('tutorial_completed', parameters: {
      'tutorial_id': tutorialId,
      'skipped': false,
    });

    debugPrint('[Tutorial] Completed: $_activeTutorial');

    _activeTutorial = null;
    _currentStepIndex = 0;
  }

  /// 튜토리얼 스킵
  Future<void> skipTutorial() async {
    if (_activeTutorial == null || !_activeTutorial!.isSkippable) return;

    final tutorialId = _activeTutorial!.id;

    final progress = TutorialProgress(
      tutorialId: tutorialId,
      completedSteps: [],
      currentStepId: '',
      lastAccessed: DateTime.now(),
      isSkipped: true,
      completedAt: DateTime.now(),
    );

    _progress[tutorialId] = progress;
    await _saveProgress();

    _completeController.add(tutorialId);

    // 애널리틱스
    await AnalyticsManager.instance.logEvent('tutorial_completed', parameters: {
      'tutorial_id': tutorialId,
      'skipped': true,
    });

    debugPrint('[Tutorial] Skipped: $_activeTutorial');

    _activeTutorial = null;
    _currentStepIndex = 0;
  }

  /// 튜토리얼 재시작
  Future<void> restartTutorial(String tutorialId) async {
    _progress.remove(tutorialId);
    await startTutorial(tutorialId);
  }

  /// 진행 상태 확인
  TutorialProgress? getProgress(String tutorialId) {
    return _progress[tutorialId];
  }

  /// 완료된 튜토리얼 확인
  bool isTutorialCompleted(String tutorialId) {
    final progress = _progress[tutorialId];
    return progress != null &&
        (progress.completedAt != null || progress.isSkipped);
  }

  /// 미완료 튜토리얼 목록
  List<Tutorial> getIncompleteTutorials() {
    return _tutorials.values.where((t) => !isTutorialCompleted(t.id)).toList();
  }

  /// 강제 튜토리얼 확인
  List<Tutorial> getForcedTutorials() {
    return _tutorials.values.where((t) => t.forceOnFirstLaunch).toList();
  }

  // ============================================
  // 리워드
  // ============================================

  Future<void> _grantReward(String rewardId, int amount) async {
    // 실제 리워드 지급 로직 (인벤토리 매니저 등)
    debugPrint('[Tutorial] Reward granted: $amount $rewardId');

    await AnalyticsManager.instance.logEvent('tutorial_reward_granted', parameters: {
      'reward_id': rewardId,
      'amount': amount,
    });
  }

  // ============================================
  // 저장/로드
  // ============================================

  Future<void> _saveProgress() async {
    final json = <String, dynamic>{};

    for (final entry in _progress.entries) {
      json[entry.key] = entry.value.toJson();
    }

    await _prefs!.setString('tutorial_progress', jsonEncode(json));
  }

  // ============================================
  // 리소스 정리
  // ============================================

  void dispose() {
    _progressController.close();
    _startController.close();
    _completeController.close();
  }

  bool get _isInitialized => _prefs != null;
}

/// 튜토리얼 오버레이 위젯
class TutorialOverlay extends StatelessWidget {
  final TutorialStep step;
  final VoidCallback? onNext;
  final VoidCallback? onSkip;
  final Widget child;

  const TutorialOverlay({
    super.key,
    required this.step,
    this.onNext,
    this.onSkip,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        _buildOverlay(context),
      ],
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    step.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (onSkip != null)
                        TextButton(
                          onPressed: onSkip,
                          child: const Text('건너뛰기'),
                        ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: onNext,
                        child: const Text('다음'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
