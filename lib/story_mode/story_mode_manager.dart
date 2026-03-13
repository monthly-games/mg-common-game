import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 스토리 타입
enum StoryType {
  main,       // 메인 스토리
  side,       // 사이드 퀘스트
  event,      // 이벤트 스토리
  character,  // 캐릭터 스토리
  tutorial,   // 튜토리얼
}

/// 챕터 상태
enum ChapterStatus {
  locked,     // 잠김
  available,  // 플레이 가능
  inProgress, // 진행 중
  completed,  // 완료
}

/// 선택지 타입
enum ChoiceType {
  standard,   // 일반 선택지
  battle,     // 전투 선택지
  skillCheck, // 스킬 체크
  item,       // 아이템 사용
}

/// 스토리 선택지
class StoryChoice {
  final String id;
  final String text;
  final ChoiceType type;
  final String? nextNodeId;
  final Map<String, dynamic>? requirements;
  final Map<String, dynamic>? consequences;
  final bool isDefault;

  const StoryChoice({
    required this.id,
    required this.text,
    required this.type,
    this.nextNodeId,
    this.requirements,
    this.consequences,
    this.isDefault = false,
  });

  /// 선택 가능 여부
  bool get isAvailable {
    if (requirements == null) return true;
    // 실제 구현에서는 조건 체크
    return true;
  }
}

/// 스토리 노드
class StoryNode {
  final String id;
  final String? speaker;
  final String dialogue;
  final String? backgroundUrl;
  final String? musicUrl;
  final List<StoryChoice> choices;
  final List<String>? characterSprites;
  final Map<String, dynamic>? metadata;
  final bool isEndNode;

  const StoryNode({
    required this.id,
    this.speaker,
    required this.dialogue,
    this.backgroundUrl,
    this.musicUrl,
    this.choices = const [],
    this.characterSprites,
    this.metadata,
    this.isEndNode = false,
  });
}

/// 챕터
class Chapter {
  final String id;
  final int chapterNumber;
  final String title;
  final String description;
  final List<Episode> episodes;
  final ChapterStatus status;
  final int? requiredLevel;
  final String? thumbnailUrl;

  const Chapter({
    required this.id,
    required this.chapterNumber,
    required this.title,
    required this.description,
    required this.episodes,
    required this.status,
    this.requiredLevel,
    this.thumbnailUrl,
  });

  /// 진행률
  double get progress {
    if (episodes.isEmpty) return 0.0;
    final completed = episodes.where((e) => e.isCompleted).length;
    return completed / episodes.length;
  }

  /// 플레이 가능 여부
  bool get isPlayable => status == ChapterStatus.available || status == ChapterStatus.inProgress;
}

/// 에피소드
class Episode {
  final String id;
  final int episodeNumber;
  final String title;
  final String description;
  final String startNodeId;
  final Map<String, StoryNode> nodes;
  final List<String> unlockedRewards;
  final bool isCompleted;

  const Episode({
    required this.id,
    required this.episodeNumber,
    required this.title,
    required this.description,
    required this.startNodeId,
    required this.nodes,
    this.unlockedRewards = const [],
    this.isCompleted = false,
  });

  /// 시작 노드
  StoryNode? get startNode => nodes[startNodeId];
}

/// 스토리 세이브 데이터
class StorySaveData {
  final String storyId;
  final String chapterId;
  final String episodeId;
  final String currentNodeId;
  final Map<String, dynamic> variables;
  final List<String> choices;
  final DateTime timestamp;

  const StorySaveData({
    required this.storyId,
    required this.chapterId,
    required this.episodeId,
    required this.currentNodeId,
    this.variables = const {},
    this.choices = const [],
    required this.timestamp,
  });
}

/// 엔딩 타입
enum EndingType {
  good,
  normal,
  bad,
  true,
  secret,
}

/// 엔딩
class StoryEnding {
  final String id;
  final String title;
  final String description;
  final EndingType type;
  final String? imageUrl;
  final String? unlockCondition;
  final bool isUnlocked;

  const StoryEnding({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.imageUrl,
    this.unlockCondition,
    this.isUnlocked = false,
  });
}

/// 스토리 모드 관리자
class StoryModeManager {
  static final StoryModeManager _instance = StoryModeManager._();
  static StoryModeManager get instance => _instance;

  StoryModeManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final Map<String, List<Chapter>> _stories = {};
  final Map<String, StorySaveData> _saveData = {};
  final Map<String, List<StoryEnding>> _endings = {};

  final StreamController<Chapter> _chapterController =
      StreamController<Chapter>.broadcast();
  final StreamController<StoryNode> _nodeController =
      StreamController<StoryNode>.broadcast();
  final StreamController<StoryEnding> _endingController =
      StreamController<StoryEnding>.broadcast();

  Stream<Chapter> get onChapterUpdate => _chapterController.stream;
  Stream<StoryNode> get onNodeChange => _nodeController.stream;
  Stream<StoryEnding> get onEndingUnlock => _endingController.stream;

  String? _currentStoryId;
  String? _currentChapterId;
  String? _currentEpisodeId;
  String? _currentNodeId;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 스토리 로드
    _loadStories();

    // 세이브 데이터 로드
    _loadSaveData();

    debugPrint('[StoryMode] Initialized');
  }

  void _loadStories() {
    // 메인 스토리
    _stories['main'] = _createMainStory();

    // 캐릭터 스토리
    _stories['character_1'] = _createCharacterStory();
  }

  List<Chapter> _createMainStory() {
    final chapters = <Chapter>[];

    // 챕터 1
    chapters.add(Chapter(
      id: 'chapter_1',
      chapterNumber: 1,
      title: '새로운 시작',
      description: '모험의 시작',
      status: ChapterStatus.available,
      requiredLevel: 1,
      episodes: [
        Episode(
          id: 'ep_1_1',
          episodeNumber: 1,
          title: '첫 만남',
          description: '운명의 만남',
          startNodeId: 'node_1_1_start',
          nodes: {
            'node_1_1_start': const StoryNode(
              id: 'node_1_1_start',
              speaker: '나레이터',
              dialogue: '어느 평화로운 마을, 당신은 눈을 떳습니다.',
              choices: [
                StoryChoice(
                  id: 'choice_1',
                  text: '주위를 둘러본다',
                  type: ChoiceType.standard,
                  nextNodeId: 'node_1_1_look_around',
                ),
                StoryChoice(
                  id: 'choice_2',
                  text: '밖으로 나간다',
                  type: ChoiceType.standard,
                  nextNodeId: 'node_1_1_go_outside',
                ),
              ],
            ),
            'node_1_1_look_around': const StoryNode(
              id: 'node_1_1_look_around',
              speaker: '나레이터',
              dialogue: '방 안에는 간단한 가구들만 있었습니다.',
              choices: [
                StoryChoice(
                  id: 'choice_3',
                  text: '밖으로 나간다',
                  type: ChoiceType.standard,
                  nextNodeId: 'node_1_1_go_outside',
                ),
              ],
            ),
            'node_1_1_go_outside': const StoryNode(
              id: 'node_1_1_go_outside',
              speaker: '나레이터',
              dialogue: '마을은 활기찼습니다. 이때, 수상한 사람이 다가왔습니다.',
              choices: [
                StoryChoice(
                  id: 'choice_4',
                  text: '말을 건다',
                  type: ChoiceType.standard,
                  nextNodeId: 'node_1_1_talk',
                ),
                StoryChoice(
                  id: 'choice_5',
                  text: '무시한다',
                  type: ChoiceType.standard,
                  nextNodeId: 'node_1_1_ignore',
                ),
              ],
            ),
            'node_1_1_talk': const StoryNode(
              id: 'node_1_1_talk',
              speaker: '수상한 사람',
              dialogue: '당신이 찾던 사람이죠? 따라오세요.',
              choices: [
                StoryChoice(
                  id: 'choice_6',
                  text: '따라간다',
                  type: ChoiceType.standard,
                  nextNodeId: 'node_1_1_end',
                  isDefault: true,
                ),
              ],
              isEndNode: true,
            ),
            'node_1_1_ignore': const StoryNode(
              id: 'node_1_1_ignore',
              speaker: '나레이터',
              dialogue: '그 사람은 실망한 듯 떠났습니다.',
              choices: [
                StoryChoice(
                  id: 'choice_7',
                  text: '계속한다',
                  type: ChoiceType.standard,
                  nextNodeId: 'node_1_1_end',
                  isDefault: true,
                ),
              ],
              isEndNode: true,
            ),
            'node_1_1_end': const StoryNode(
              id: 'node_1_1_end',
              speaker: '나레이터',
              dialogue: '이것이 당신 모험의 시작이었습니다.',
              choices: [],
              isEndNode: true,
            ),
          },
        ),
      ],
    ));

    // 챕터 2
    chapters.add(Chapter(
      id: 'chapter_2',
      chapterNumber: 2,
      title: '첫 번째 시련',
      description: '시험이 기다립니다',
      status: ChapterStatus.locked,
      requiredLevel: 5,
      episodes: [],
    ));

    return chapters;
  }

  List<Chapter> _createCharacterStory() {
    return [
      Chapter(
        id: 'char_1_chapter_1',
        chapterNumber: 1,
        title: '영웅의 과거',
        description: '그녀의 숨겨진 이야기',
        status: ChapterStatus.available,
        episodes: [],
      ),
    ];
  }

  Future<void> _loadSaveData() async {
    final saveJson = _prefs?.getString('story_save_data');
    if (saveJson != null) {
      // 실제로는 JSON 파싱
    }
  }

  /// 스토리 시작
  Future<void> startStory({
    required String storyId,
    required String chapterId,
    required String episodeId,
  }) async {
    _currentStoryId = storyId;
    _currentChapterId = chapterId;
    _currentEpisodeId = episodeId;

    final story = _stories[storyId];
    if (story == null) return;

    final chapter = story.firstWhere((c) => c.id == chapterId);
    final episode = chapter.episodes.firstWhere((e) => e.id == episodeId);

    _currentNodeId = episode.startNodeId;

    debugPrint('[StoryMode] Story started: $storyId/$chapterId/$episodeId');
  }

  /// 현재 노드 가져오기
  StoryNode? getCurrentNode() {
    if (_currentNodeId == null) return null;

    final story = _stories[_currentStoryId];
    if (story == null) return null;

    final chapter = story.firstWhere((c) => c.id == _currentChapterId);
    final episode = chapter.episodes.firstWhere((e) => e.id == _currentEpisodeId);

    return episode.nodes[_currentNodeId];
  }

  /// 선택지 선택
  Future<void> makeChoice(String choiceId) async {
    final currentNode = getCurrentNode();
    if (currentNode == null) return;

    final choice = currentNode.choices.firstWhere((c) => c.id == choiceId);
    if (choice.nextNodeId == null) return;

    _currentNodeId = choice.nextNodeId;

    final nextNode = getCurrentNode();
    if (nextNode != null) {
      _nodeController.add(nextNode);

      // 엔딩 체크
      if (nextNode.isEndNode) {
        await _completeEpisode();
      }
    }

    debugPrint('[StoryMode] Choice made: $choiceId -> $_currentNodeId');
  }

  /// 에피소드 완료
  Future<void> _completeEpisode() async {
    final story = _stories[_currentStoryId];
    if (story == null) return;

    final chapterIndex = story.indexWhere((c) => c.id == _currentChapterId);
    if (chapterIndex == -1) return;

    final chapter = story[chapterIndex];
    final episodeIndex = chapter.episodes.indexWhere((e) => e.id == _currentEpisodeId);
    if (episodeIndex == -1) return;

    final episode = chapter.episodes[episodeIndex];
    final updatedEpisode = Episode(
      id: episode.id,
      episodeNumber: episode.episodeNumber,
      title: episode.title,
      description: episode.description,
      startNodeId: episode.startNodeId,
      nodes: episode.nodes,
      unlockedRewards: episode.unlockedRewards,
      isCompleted: true,
    );

    final updatedEpisodes = List<Episode>.from(chapter.episodes);
    updatedEpisodes[episodeIndex] = updatedEpisode;

    final updatedChapter = Chapter(
      id: chapter.id,
      chapterNumber: chapter.chapterNumber,
      title: chapter.title,
      description: chapter.description,
      episodes: updatedEpisodes,
      status: chapter.episodes.every((e) => e.isCompleted)
          ? ChapterStatus.completed
          : ChapterStatus.inProgress,
      requiredLevel: chapter.requiredLevel,
      thumbnailUrl: chapter.thumbnailUrl,
    );

    final updatedChapters = List<Chapter>.from(story);
    updatedChapters[chapterIndex] = updatedChapter;

    _stories[_currentStoryId] = updatedChapters;
    _chapterController.add(updatedChapter);

    // 세이브
    await saveProgress();

    debugPrint('[StoryMode] Episode completed: $_currentEpisodeId');
  }

  /// 진행 저장
  Future<void> saveProgress() async {
    if (_currentStoryId == null ||
        _currentChapterId == null ||
        _currentEpisodeId == null ||
        _currentNodeId == null) return;

    final saveData = StorySaveData(
      storyId: _currentStoryId!,
      chapterId: _currentChapterId!,
      episodeId: _currentEpisodeId!,
      currentNodeId: _currentNodeId!,
      timestamp: DateTime.now(),
    );

    _saveData['$_currentUserId-$_currentStoryId'] = saveData;

    // 실제로는 SharedPreferences에 저장
    await _prefs?.setString(
      'story_save_$_currentUserId-$_currentStoryId',
      jsonEncode(saveData),
    );

    debugPrint('[StoryMode] Progress saved');
  }

  /// 진행 로드
  Future<void> loadProgress(String storyId) async {
    final saveKey = '$_currentUserId-$storyId';
    final saveJson = await _prefs?.getString('story_save_$saveKey');

    if (saveJson != null) {
      // 실제로는 JSON 파싱
      _currentStoryId = storyId;
      debugPrint('[StoryMode] Progress loaded');
    }
  }

  /// 챕터 잠금 해제
  Future<void> unlockChapter({
    required String storyId,
    required String chapterId,
  }) async {
    final story = _stories[storyId];
    if (story == null) return;

    final chapterIndex = story.indexWhere((c) => c.id == chapterId);
    if (chapterIndex == -1) return;

    final chapter = story[chapterIndex];
    if (chapter.status != ChapterStatus.locked) return;

    final updatedChapter = Chapter(
      id: chapter.id,
      chapterNumber: chapter.chapterNumber,
      title: chapter.title,
      description: chapter.description,
      episodes: chapter.episodes,
      status: ChapterStatus.available,
      requiredLevel: chapter.requiredLevel,
      thumbnailUrl: chapter.thumbnailUrl,
    );

    final updatedChapters = List<Chapter>.from(story);
    updatedChapters[chapterIndex] = updatedChapter;

    _stories[storyId] = updatedChapters;
    _chapterController.add(updatedChapter);

    debugPrint('[StoryMode] Chapter unlocked: $chapterId');
  }

  /// 엔딩 해제
  Future<void> unlockEnding({
    required String storyId,
    required String endingId,
  }) async {
    final endings = _endings[storyId] ?? [];

    final endingIndex = endings.indexWhere((e) => e.id == endingId);
    if (endingIndex == -1) return;

    final ending = endings[endingIndex];
    if (ending.isUnlocked) return;

    final updatedEnding = StoryEnding(
      id: ending.id,
      title: ending.title,
      description: ending.description,
      type: ending.type,
      imageUrl: ending.imageUrl,
      unlockCondition: ending.unlockCondition,
      isUnlocked: true,
    );

    final updatedEndings = List<StoryEnding>.from(endings);
    updatedEndings[endingIndex] = updatedEnding;

    _endings[storyId] = updatedEndings;
    _endingController.add(updatedEnding);

    debugPrint('[StoryMode] Ending unlocked: $endingId');
  }

  /// 스토리 데이터 조회
  List<Chapter>? getStory(String storyId) {
    return _stories[storyId];
  }

  List<Chapter>? getStories() {
    return _stories['main'];
  }

  /// 엔딩 조회
  List<StoryEnding> getEndings(String storyId) {
    return _endings[storyId] ?? [];
  }

  /// 해제된 엔딩 수
  int getUnlockedEndingCount(String storyId) {
    final endings = _endings[storyId] ?? [];
    return endings.where((e) => e.isUnlocked).length;
  }

  /// 총 엔딩 수
  int getTotalEndingCount(String storyId) {
    return _endings[storyId]?.length ?? 0;
  }

  void dispose() {
    _chapterController.close();
    _nodeController.close();
    _endingController.close();
  }
}
