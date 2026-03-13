import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_common_game/core/economy/currency_manager.dart';

/// 퀘스트 보상 타입
enum QuestRewardType {
  coins,
  gems,
  experience,
  items,
  custom,
}

/// 퀘스트 난이도
enum QuestDifficulty {
  easy,
  normal,
  hard,
  expert,
}

/// 퀘스트 보상
class QuestReward {
  final QuestRewardType type;
  final int amount;
  final String? itemId; // items 타입일 때 특정 아이템 ID
  final Map<String, dynamic>? customData; // custom 타입일 때 추가 데이터

  const QuestReward({
    required this.type,
    required this.amount,
    this.itemId,
    this.customData,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'amount': amount,
        if (itemId != null) 'itemId': itemId,
        if (customData != null) 'customData': customData,
      };

  factory QuestReward.fromJson(Map<String, dynamic> json) => QuestReward(
        type: QuestRewardType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => QuestRewardType.coins,
        ),
        amount: json['amount'] as int,
        itemId: json['itemId'] as String?,
        customData: json['customData'] as Map<String, dynamic>?,
      );
}

/// 일일 퀘스트 정의
class DailyQuest {
  final String id;
  final String title;
  final String description;
  final QuestDifficulty difficulty;
  final List<QuestReward> rewards;
  final Map<String, dynamic> requirements; // 퀘스트별 요구사항
  final DateTime startTime;
  final DateTime endTime;
  final bool isActive;

  const DailyQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.rewards,
    required this.requirements,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
  });

  /// 진행률 계산 (0.0 ~ 1.0)
  double get progress => 1.0; // 서브클래스에서 구현

  /// 완료 여부
  bool get isCompleted => progress >= 1.0;

  /// 완료 가능 여부 (시간 내에 완료할 수 있는지)
  bool get canComplete {
    final now = DateTime.now();
    return now.isBefore(endTime) && isActive;
  }

  /// 남은 시간
  Duration get remainingTime {
    final now = DateTime.now();
    if (now.isAfter(endTime)) return Duration.zero;
    return endTime.difference(now);
  }

  DailyQuest copyWith({
    String? id,
    String? title,
    String? description,
    QuestDifficulty? difficulty,
    List<QuestReward>? rewards,
    Map<String, dynamic>? requirements,
    DateTime? startTime,
    DateTime? endTime,
    bool? isActive,
  }) {
    return DailyQuest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      rewards: rewards ?? this.rewards,
      requirements: requirements ?? this.requirements,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'difficulty': difficulty.name,
        'rewards': rewards.map((r) => r.toJson()).toList(),
        'requirements': requirements,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'isActive': isActive,
      };

  factory DailyQuest.fromJson(Map<String, dynamic> json) => DailyQuest(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        difficulty: QuestDifficulty.values.firstWhere(
          (e) => e.name == json['difficulty'],
          orElse: () => QuestDifficulty.normal,
        ),
        rewards: (json['rewards'] as List)
            .map((r) => QuestReward.fromJson(r as Map<String, dynamic>))
            .toList(),
        requirements: json['requirements'] as Map<String, dynamic>,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        isActive: json['isActive'] as bool,
      );
}

/// 게임별 퀘스트 데이터
abstract class GameQuestData {
  /// 게임 ID
  String get gameId;

  /// 퀘스트 템플릿 반환
  List<DailyQuest> getQuestTemplates();

  /// 플레이어 진행률 불러오기
  Future<Map<String, dynamic>> fetchPlayerProgress();

  /// 퀘스트 완료 처리
  Future<void> completeQuest(String questId);

  /// 보상 지급
  Future<void> grantReward(QuestReward reward);
}

/// 일일 퀘스트 시스템
class DailyQuestSystem extends ChangeNotifier {
  static final DailyQuestSystem _instance = DailyQuestSystem._();
  static DailyQuestSystem get instance => _instance;

  DailyQuestSystem._();

  // ============================================
  // 상태
  // ============================================
  SharedPreferences? _prefs;
  final Map<String, GameQuestData> _gameQuestData = {};
  final Map<String, List<DailyQuest>> _activeQuests = {};
  final Map<String, Map<String, dynamic>> _playerProgress = {};

  Timer? _refreshTimer;
  DateTime? _lastRefreshDate;

  // ============================================
  // Getters
  // ============================================
  bool get isInitialized => _prefs != null;

  /// 특정 게임의 활성 퀘스트 목록
  List<DailyQuest> getQuestsForGame(String gameId) {
    return _activeQuests[gameId] ?? [];
  }

  /// 모든 활성 퀘스트
  Map<String, List<DailyQuest>> get allQuests => Map.unmodifiable(_activeQuests);

  /// 완료 가능한 퀘스트 수
  int get completableQuests {
    int count = 0;
    for (final quests in _activeQuests.values) {
      for (final quest in quests) {
        if (quest.canComplete && !quest.isCompleted) {
          count++;
        }
      }
    }
    return count;
  }

  /// 완료된 퀘스트 수
  int get completedQuests {
    int count = 0;
    for (final quests in _activeQuests.values) {
      for (final quest in quests) {
        if (quest.isCompleted) {
          count++;
        }
      }
    }
    return count;
  }

  // ============================================
  // 초기화
  // ============================================

  /// 시스템 초기화
  Future<void> initialize() async {
    if (_prefs != null) return;

    _prefs = await SharedPreferences.getInstance();

    // 저장된 데이터 로드
    await _loadSavedData();

    // 새로운 날짜인지 확인하고 퀘스트 갱신
    await _checkAndRefreshQuests();

    // 매일 자정 갱신 타이머
    _scheduleMidnightRefresh();

    notifyListeners();
  }

  /// 게임 퀘스트 데이터 등록
  void registerGameData(String gameId, GameQuestData questData) {
    _gameQuestData[gameId] = questData;
    notifyListeners();
  }

  // ============================================
  // 퀘스트 관리
  // ============================================

  /// 퀘스트 진행률 업데이트
  Future<void> updateQuestProgress(
    String gameId,
    String questId,
    Map<String, dynamic> progress,
  ) async {
    if (!_playerProgress.containsKey(gameId)) {
      _playerProgress[gameId] = {};
    }

    _playerProgress[gameId]![questId] = progress;
    await _saveProgressData();

    // 진행률 변경 알림
    notifyListeners();
  }

  /// 퀘스트 완료
  Future<bool> completeQuest(String gameId, String questId) async {
    final quests = _activeQuests[gameId];
    if (quests == null) return false;

    final questIndex = quests.indexWhere((q) => q.id == questId);
    if (questIndex == -1) return false;

    final quest = quests[questIndex];
    if (!quest.canComplete) return false;

    // 게임별 완료 처리
    final gameData = _gameQuestData[gameId];
    if (gameData != null) {
      await gameData.completeQuest(questId);
    }

    // 보상 지급
    for (final reward in quest.rewards) {
      await _grantReward(reward);
    }

    // 완료 상태로 변경
    _activeQuests[gameId]![questIndex] = quest.copyWith(isActive: false);
    await _saveQuestData();

    notifyListeners();
    return true;
  }

  /// 보상 지급
  Future<void> _grantReward(QuestReward reward) async {
    switch (reward.type) {
      case QuestRewardType.coins:
        await CurrencyManager.instance.addCurrency(
          CurrencyType.coin,
          reward.amount,
          source: 'daily_quest',
        );
        break;
      case QuestRewardType.gems:
        await CurrencyManager.instance.addCurrency(
          CurrencyType.gem,
          reward.amount,
          source: 'daily_quest',
        );
        break;
      case QuestRewardType.experience:
        // 경험치 지급 로직 (게임별 구현)
        break;
      case QuestRewardType.items:
        // 아이템 지급 로직 (게임별 구현)
        break;
      case QuestRewardType.custom:
        // 커스텀 보상 지급
        break;
    }
  }

  // ============================================
  // 퀘스트 새로고침
  // ============================================

  /// 퀘스트 새로고침 (일일 자정)
  Future<void> refreshDailyQuests() async {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';

    // 오늘 이미 새로고침했는지 확인
    final lastRefresh = _prefs!.getString('last_refresh_date');
    if (lastRefresh == todayKey) {
      debugPrint('Daily quests already refreshed today');
      return;
    }

    await _checkAndRefreshQuests(force: true);
  }

  Future<void> _checkAndRefreshQuests({bool force = false}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = '${today.year}-${today.month}-${today.day}';

    // 마지막 갱신 날짜 확인
    final lastRefreshStr = _prefs!.getString('last_refresh_date');
    if (lastRefreshStr != null && !force) {
      final lastRefresh = DateTime.parse(lastRefreshStr);
      if (DateTime(lastRefresh.year, lastRefresh.month, lastRefresh.day)
              .isAtSameMomentAs(DateTime(today.year, today.month, today.day))) {
        return; // 이미 갱신됨
      }
    }

    // 모든 게임의 퀘스트 새로고침
    for (final entry in _gameQuestData.entries) {
      final gameId = entry.key;
      final questData = entry.value;

      // 새로운 퀘스트 생성
      final newQuests = <DailyQuest>[];
      final templates = questData.getQuestTemplates();

      for (final template in templates) {
        final questId = '${gameId}_${template.id}_${todayKey}';
        final quest = template.copyWith(
          id: questId,
          startTime: today,
          endTime: today.add(const Duration(days: 1, hours: -1)), // 자정까지
        );
        newQuests.add(quest);
      }

      _activeQuests[gameId] = newQuests;
    }

    // 갱신 날짜 저장
    await _prefs!.setString('last_refresh_date', todayKey);
    await _saveQuestData();

    notifyListeners();
  }

  /// 자정에 퀘스트 새로고침 스케줄
  void _scheduleMidnightRefresh() {
    _refreshTimer?.cancel();

    final now = DateTime.now();
    final nextMidnight = DateTime(
      now.year,
      now.month,
      now.day + 1,
    ); // 내일 자정

    final duration = nextMidnight.difference(now);

    _refreshTimer = Timer(duration, () {
      _checkAndRefreshQuests(force: true);
      _scheduleMidnightRefresh(); // 다음 날을 위해 재스케줄
    });
  }

  // ============================================
  // 데이터 저장/로드
  // ============================================

  Future<void> _saveQuestData() async {
    final questsJson = <String, dynamic>{};

    for (final entry in _activeQuests.entries) {
      questsJson[entry.key] = entry.value.map((q) => q.toJson()).toList();
    }

    await _prefs!.setString('daily_quests', jsonEncode(questsJson));
  }

  Future<void> _loadSavedData() async {
    // 퀘스트 데이터 로드
    final questsStr = _prefs!.getString('daily_quests');
    if (questsStr != null) {
      final questsJson = jsonDecode(questsStr) as Map<String, dynamic>;

      for (final entry in questsJson.entries) {
        final gameId = entry.key;
        final questsList = entry.value as List;

        _activeQuests[gameId] = questsList
            .map((q) => DailyQuest.fromJson(q as Map<String, dynamic>))
            .toList();
      }
    }

    // 진행률 데이터 로드
    final progressStr = _prefs!.getString('quest_progress');
    if (progressStr != null) {
      final progressJson = jsonDecode(progressStr) as Map<String, dynamic>;

      for (final entry in progressJson.entries) {
        final gameId = entry.key;
        _playerProgress[gameId] =
            (progressJson[gameId] as Map<String, dynamic>).cast<String, dynamic>();
      }
    }
  }

  Future<void> _saveProgressData() async {
    await _prefs!.setString('quest_progress', jsonEncode(_playerProgress));
  }

  /// 데이터 초기화
  Future<void> clearData() async {
    if (_prefs != null) {
      await _prefs!.remove('daily_quests');
      await _prefs!.remove('quest_progress');
      await _prefs!.remove('last_refresh_date');
    }

    _activeQuests.clear();
    _playerProgress.clear();

    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

/// 퀘스트 통계
class QuestStatistics {
  final int totalQuestsCompleted;
  final int totalQuestsAvailable;
  final int currentStreak; // 연속 완료 일수
  final int longestStreak;
  final DateTime lastCompletionDate;

  const QuestStatistics({
    required this.totalQuestsCompleted,
    required this.totalQuestsAvailable,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastCompletionDate,
  });

  /// 완료율
  double get completionRate {
    if (totalQuestsAvailable == 0) return 0.0;
    return totalQuestsCompleted / totalQuestsAvailable;
  }

  Map<String, dynamic> toJson() => {
        'totalQuestsCompleted': totalQuestsCompleted,
        'totalQuestsAvailable': totalQuestsAvailable,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastCompletionDate': lastCompletionDate.toIso8601String(),
      };

  factory QuestStatistics.fromJson(Map<String, dynamic> json) => QuestStatistics(
        totalQuestsCompleted: json['totalQuestsCompleted'] as int,
        totalQuestsAvailable: json['totalQuestsAvailable'] as int,
        currentStreak: json['currentStreak'] as int,
        longestStreak: json['longestStreak'] as int,
        lastCompletionDate: DateTime.parse(json['lastCompletionDate'] as String),
      );
}
