import 'daily_quest_system.dart';

/// 예제 퀘스트 템플릿
///
/// 이 파일은 다양한 게임 타입에 맞는 퀘스트 템플릿 예제를 제공합니다.
/// 각 게임은 자신의 GameQuestData 구현에서 이 템플릿들을 참조하여 사용자화할 수 있습니다.

/// 퍼즐 게임용 퀘스트 템플릿
class PuzzleQuestTemplates {
  static List<DailyQuest> getTemplates() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return [
      DailyQuest(
        id: 'puzzle_daily_play',
        title: '일일 퍼즐 플레이',
        description: '퍼즐 게임을 3회 플레이하세요',
        difficulty: QuestDifficulty.easy,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 100),
        ],
        requirements: {'plays': 3},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
      DailyQuest(
        id: 'puzzle_clear_stages',
        title: '스테이지 클리어',
        description: '스테이지 5개를 클리어하세요',
        difficulty: QuestDifficulty.normal,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 200),
          QuestReward(type: QuestRewardType.gems, amount: 10),
        ],
        requirements: {'stages_cleared': 5},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
      DailyQuest(
        id: 'puzzle_no_hint',
        title: '힌트 없이 클리어',
        description: '힌트를 사용하지 않고 스테이지 3개 클리어',
        difficulty: QuestDifficulty.hard,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 500),
          QuestReward(type: QuestRewardType.gems, amount: 30),
        ],
        requirements: {'stages_no_hint': 3},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
    ];
  }
}

/// 리듬 게임용 퀘스트 템플릿
class RhythmQuestTemplates {
  static List<DailyQuest> getTemplates() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return [
      DailyQuest(
        id: 'rhythm_play_5_songs',
        title: '5곡 플레이',
        description: '어떤 난이도든 5곡을 플레이하세요',
        difficulty: QuestDifficulty.easy,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 150),
        ],
        requirements: {'songs_played': 5},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
      DailyQuest(
        id: 'rhythm_perfect_combo',
        title: '퍼펙트 콤보',
        description: '단일 곡에서 100 콤보 달성',
        difficulty: QuestDifficulty.hard,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 400),
          QuestReward(type: QuestRewardType.gems, amount: 25),
        ],
        requirements: {'max_combo': 100},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
      DailyQuest(
        id: 'rhythm_full_combo',
        title: '풀 콤보',
        description: '어떤 곡에서든 풀 콤보 달성',
        difficulty: QuestDifficulty.expert,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 1000),
          QuestReward(type: QuestRewardType.gems, amount: 50),
          QuestReward(
            type: QuestRewardType.items,
            amount: 1,
            itemId: 'exclusive_title',
          ),
        ],
        requirements: {'full_combo': 1},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
    ];
  }
}

/// 레이싱 게임용 퀘스트 템플릿
class RacingQuestTemplates {
  static List<DailyQuest> getTemplates() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return [
      DailyQuest(
        id: 'racing_complete_3_races',
        title: '3번의 레이스',
        description: '레이스를 3번 완주하세요',
        difficulty: QuestDifficulty.easy,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 200),
        ],
        requirements: {'races_completed': 3},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
      DailyQuest(
        id: 'racing_win_first_place',
        title: '1등 달성',
        description: '레이스에서 1등으로 완주하세요',
        difficulty: QuestDifficulty.normal,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 300),
          QuestReward(type: QuestRewardType.gems, amount: 20),
        ],
        requirements: {'first_place_finishes': 1},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
      DailyQuest(
        id: 'racing_drift_mastery',
        title: '드리프트 마스터',
        description: '단일 레이스에서 드리프트 50회 달성',
        difficulty: QuestDifficulty.hard,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 500),
          QuestReward(type: QuestRewardType.gems, amount: 35),
        ],
        requirements: {'drift_count': 50},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
    ];
  }
}

/// RPG 게임용 퀘스트 템플릿
class RPGQuestTemplates {
  static List<DailyQuest> getTemplates() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return [
      DailyQuest(
        id: 'rpg_defeat_enemies',
        title: '몬스터 사냥',
        description: '적 50마리를 처치하세요',
        difficulty: QuestDifficulty.easy,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 200),
          QuestReward(type: QuestRewardType.experience, amount: 500),
        ],
        requirements: {'enemies_defeated': 50},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
      DailyQuest(
        id: 'rpg_complete_dungeon',
        title: '던전 클리어',
        description: '던전을 1회 클리어하세요',
        difficulty: QuestDifficulty.normal,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 400),
          QuestReward(type: QuestRewardType.experience, amount: 1000),
          QuestReward(type: QuestRewardType.gems, amount: 15),
        ],
        requirements: {'dungeons_completed': 1},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
      DailyQuest(
        id: 'rpg_boss_defeat',
        title: '보스 처치',
        description: '보스 몬스터를 처치하세요',
        difficulty: QuestDifficulty.hard,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 800),
          QuestReward(type: QuestRewardType.experience, amount: 2000),
          QuestReward(type: QuestRewardType.gems, amount: 40),
        ],
        requirements: {'bosses_defeated': 1},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
      DailyQuest(
        id: 'rpg_collect_items',
        title: '아이템 수집',
        description: '레어 아이템 3개를 획득하세요',
        difficulty: QuestDifficulty.expert,
        rewards: [
          QuestReward(
            type: QuestRewardType.items,
            amount: 1,
            itemId: 'legendary_chest',
          ),
          QuestReward(type: QuestRewardType.gems, amount: 100),
        ],
        requirements: {'rare_items_collected': 3},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
    ];
  }
}

/// 타워 디펜스 게임용 퀘스트 템플릿
class TowerDefenseQuestTemplates {
  static List<DailyQuest> getTemplates() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return [
      DailyQuest(
        id: 'td_build_towers',
        title: '탑 건설',
        description: '모든 유형의 탑을 최소 1개씩 건설',
        difficulty: QuestDifficulty.easy,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 150),
        ],
        requirements: {'unique_towers_built': 4},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
      DailyQuest(
        id: 'td_wave_clear',
        title: '웨이브 방어',
        description: '웨이브 20을 클리어하세요',
        difficulty: QuestDifficulty.normal,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 300),
          QuestReward(type: QuestRewardType.gems, amount: 20),
        ],
        requirements: {'wave_cleared': 20},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
      DailyQuest(
        id: 'td_perfect_defense',
        title: '완벽한 방어',
        description: '적이 기지에 도달하지 못하게 웨이브 클리어 (10회)',
        difficulty: QuestDifficulty.hard,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 600),
          QuestReward(type: QuestRewardType.gems, amount: 40),
        ],
        requirements: {'perfect_waves': 10},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
    ];
  }
}

/// 아이들 게임용 퀘스트 템플릿
class IdleGameQuestTemplates {
  static List<DailyQuest> getTemplates() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return [
      DailyQuest(
        id: 'idle_collect_coins',
        title: '코인 수집',
        description: '10,000코인을 획득하세요',
        difficulty: QuestDifficulty.easy,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 500),
        ],
        requirements: {'coins_collected': 10000},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
      DailyQuest(
        id: 'idle_upgrade_facility',
        title: '시설 업그레이드',
        description: '시설을 5회 업그레이드하세요',
        difficulty: QuestDifficulty.normal,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 1000),
          QuestReward(type: QuestRewardType.gems, amount: 25),
        ],
        requirements: {'upgrades_performed': 5},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
      DailyQuest(
        id: 'idle_unlock_manager',
        title: '매니저 고용',
        description: '새로운 매니저를 1명 고용하세요',
        difficulty: QuestDifficulty.hard,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 2000),
          QuestReward(type: QuestRewardType.gems, amount: 50),
        ],
        requirements: {'managers_hired': 1},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
    ];
  }
}

/// 카드 배틀 게임용 퀘스트 템플릿
class CardBattleQuestTemplates {
  static List<DailyQuest> getTemplates() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return [
      DailyQuest(
        id: 'card_play_battles',
        title: '배틀 참여',
        description: '카드 배틀을 5회 플레이하세요',
        difficulty: QuestDifficulty.easy,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 200),
        ],
        requirements: {'battles_played': 5},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
      DailyQuest(
        id: 'card_win_battles',
        title: '배틀 승리',
        description: '배틀에서 3회 승리하세요',
        difficulty: QuestDifficulty.normal,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 300),
          QuestReward(type: QuestRewardType.gems, amount: 20),
        ],
        requirements: {'battles_won': 3},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
      DailyQuest(
        id: 'card_use_special_cards',
        title: '특수 카드 사용',
        description: '특수 카드를 10회 사용하세요',
        difficulty: QuestDifficulty.hard,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 500),
          QuestReward(type: QuestRewardType.gems, amount: 35),
        ],
        requirements: {'special_cards_used': 10},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
      DailyQuest(
        id: 'card_collect_cards',
        title: '카드 수집',
        description: '새로운 카드 3장을 획득하세요',
        difficulty: QuestDifficulty.expert,
        rewards: [
          QuestReward(
            type: QuestRewardType.items,
            amount: 3,
            itemId: 'card_pack_legendary',
          ),
          QuestReward(type: QuestRewardType.gems, amount: 100),
        ],
        requirements: {'new_cards_collected': 3},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
    ];
  }
}

/// 요리/시뮬레이션 게임용 퀘스트 템플릿
class CookingQuestTemplates {
  static List<DailyQuest> getTemplates() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return [
      DailyQuest(
        id: 'cooking_serve_dishes',
        title: '요리 서빙',
        description: '요리를 20개 서빙하세요',
        difficulty: QuestDifficulty.easy,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 150),
        ],
        requirements: {'dishes_served': 20},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
      DailyQuest(
        id: 'cooking_master_recipes',
        title: '레시피 마스터',
        description: '레시피를 3개 마스터하세요',
        difficulty: QuestDifficulty.normal,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 300),
          QuestReward(type: QuestRewardType.gems, amount: 25),
        ],
        requirements: {'recipes_mastered': 3},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
      DailyQuest(
        id: 'cooking_perfect_dishes',
        title: '완벽한 요리',
        description: '완벽한 등급의 요리 10개 완성',
        difficulty: QuestDifficulty.hard,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 600),
          QuestReward(type: QuestRewardType.gems, amount: 40),
        ],
        requirements: {'perfect_dishes': 10},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
    ];
  }
}

/// 스포츠 게임용 퀘스트 템플릿
class SportsQuestTemplates {
  static List<DailyQuest> getTemplates() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return [
      DailyQuest(
        id: 'sports_play_matches',
        title: '경기 참여',
        description: '경기를 3회 플레이하세요',
        difficulty: QuestDifficulty.easy,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 200),
        ],
        requirements: {'matches_played': 3},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
      DailyQuest(
        id: 'sports_score_goals',
        title: '골/점수 달성',
        description: '골 10개를 득점하세요',
        difficulty: QuestDifficulty.normal,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 350),
          QuestReward(type: QuestRewardType.gems, amount: 25),
        ],
        requirements: {'goals_scored': 10},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
      DailyQuest(
        id: 'sports_win_matches',
        title: '승리 기록',
        description: '경기에서 3회 승리하세요',
        difficulty: QuestDifficulty.hard,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 500),
          QuestReward(type: QuestRewardType.gems, amount: 40),
        ],
        requirements: {'matches_won': 3},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
    ];
  }
}

/// 유틸리티 함수: 게임 타입에 따른 퀘스트 템플릿 반환
class QuestTemplateFactory {
  static List<DailyQuest> getTemplatesForGameType(String gameType) {
    switch (gameType.toLowerCase()) {
      case 'puzzle':
        return PuzzleQuestTemplates.getTemplates();
      case 'rhythm':
        return RhythmQuestTemplates.getTemplates();
      case 'racing':
        return RacingQuestTemplates.getTemplates();
      case 'rpg':
        return RPGQuestTemplates.getTemplates();
      case 'tower_defense':
      case 'towerdefense':
        return TowerDefenseQuestTemplates.getTemplates();
      case 'idle':
      case 'idle_game':
        return IdleGameQuestTemplates.getTemplates();
      case 'card_battle':
      case 'cardbattle':
        return CardBattleQuestTemplates.getTemplates();
      case 'cooking':
        return CookingQuestTemplates.getTemplates();
      case 'sports':
        return SportsQuestTemplates.getTemplates();
      default:
        // 기본 템플릿 반환
        return _getDefaultTemplates();
    }
  }

  static List<DailyQuest> _getDefaultTemplates() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return [
      DailyQuest(
        id: 'default_daily_login',
        title: '일일 접속',
        description: '오늘 게임에 접속하세요',
        difficulty: QuestDifficulty.easy,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 100),
        ],
        requirements: {'login': 1},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
      DailyQuest(
        id: 'default_daily_play',
        title: '일일 플레이',
        description: '게임을 1회 플레이하세요',
        difficulty: QuestDifficulty.easy,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 150),
        ],
        requirements: {'plays': 1},
        startTime: today,
        endTime: tomorrow,
        isActive: true,
      ),
    ];
  }
}
