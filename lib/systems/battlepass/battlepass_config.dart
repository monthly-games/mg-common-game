/// 배틀패스 설정 - MG Common Game
///
/// 시즌, 보상, 티어 정의
library;

/// 배틀패스 보상 타입
enum BPRewardType {
  currency,     // 재화
  item,         // 아이템
  character,    // 캐릭터/파편
  costume,      // 코스튬
  title,        // 칭호
  frame,        // 프레임
  emoji,        // 이모티콘
  summonTicket, // 소환권
}

/// 배틀패스 보상
class BPReward {
  final String id;
  final String nameKr;
  final BPRewardType type;
  final int amount;
  final String? imageAsset;
  final bool isPremiumOnly; // 프리미엄 전용

  const BPReward({
    required this.id,
    required this.nameKr,
    required this.type,
    this.amount = 1,
    this.imageAsset,
    this.isPremiumOnly = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nameKr': nameKr,
    'type': type.index,
    'amount': amount,
    'isPremiumOnly': isPremiumOnly,
  };

  factory BPReward.fromJson(Map<String, dynamic> json) => BPReward(
    id: json['id'] ?? '',
    nameKr: json['nameKr'] ?? '',
    type: BPRewardType.values[json['type'] ?? 0],
    amount: json['amount'] ?? 1,
    isPremiumOnly: json['isPremiumOnly'] ?? false,
  );
}

/// 배틀패스 티어
class BPTier {
  final int level;
  final int requiredExp;
  final List<BPReward> freeRewards;
  final List<BPReward> premiumRewards;

  const BPTier({
    required this.level,
    required this.requiredExp,
    this.freeRewards = const [],
    this.premiumRewards = const [],
  });

  /// 모든 보상
  List<BPReward> get allRewards => [...freeRewards, ...premiumRewards];
}

/// 배틀패스 시즌 설정
class BPSeasonConfig {
  final String id;
  final String nameKr;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final int maxLevel;
  final int expPerLevel;
  final List<BPTier> tiers;
  final double premiumPrice; // USD

  const BPSeasonConfig({
    required this.id,
    required this.nameKr,
    this.description,
    required this.startDate,
    required this.endDate,
    this.maxLevel = 50,
    this.expPerLevel = 1000,
    required this.tiers,
    this.premiumPrice = 9.99,
  });

  /// 시즌 진행 중 여부
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// 남은 일수
  int get remainingDays {
    final diff = endDate.difference(DateTime.now());
    return diff.isNegative ? 0 : diff.inDays;
  }

  /// 총 시즌 일수
  int get totalDays {
    return endDate.difference(startDate).inDays;
  }

  /// 특정 레벨의 티어 정보
  BPTier? getTier(int level) {
    try {
      return tiers.firstWhere((t) => t.level == level);
    } catch (_) {
      return null;
    }
  }

  /// 특정 레벨까지 필요한 총 경험치
  int getTotalExpForLevel(int level) {
    int total = 0;
    for (int i = 1; i <= level && i <= maxLevel; i++) {
      final tier = getTier(i);
      total += tier?.requiredExp ?? expPerLevel;
    }
    return total;
  }
}

/// 배틀패스 미션 타입
enum BPMissionType {
  daily,    // 일일 미션
  weekly,   // 주간 미션
  seasonal, // 시즌 미션
}

/// 배틀패스 미션
class BPMission {
  final String id;
  final String titleKr;
  final String descriptionKr;
  final BPMissionType type;
  final int targetValue;
  final int expReward;
  final String? trackingKey; // 통계 추적 키

  const BPMission({
    required this.id,
    required this.titleKr,
    required this.descriptionKr,
    required this.type,
    required this.targetValue,
    required this.expReward,
    this.trackingKey,
  });
}

/// 기본 28일 시즌 생성 헬퍼
class BPSeasonBuilder {
  static BPSeasonConfig create28DaySeason({
    required String id,
    required String nameKr,
    required DateTime startDate,
    int maxLevel = 50,
    int expPerLevel = 1000,
    double premiumPrice = 9.99,
  }) {
    final endDate = startDate.add(const Duration(days: 28));

    // 티어 자동 생성
    final tiers = <BPTier>[];
    for (int level = 1; level <= maxLevel; level++) {
      tiers.add(_generateTier(level, expPerLevel));
    }

    return BPSeasonConfig(
      id: id,
      nameKr: nameKr,
      startDate: startDate,
      endDate: endDate,
      maxLevel: maxLevel,
      expPerLevel: expPerLevel,
      tiers: tiers,
      premiumPrice: premiumPrice,
    );
  }

  static BPTier _generateTier(int level, int baseExp) {
    // 레벨에 따른 경험치 증가 (1~20: 기본, 21~40: 1.5배, 41~50: 2배)
    int requiredExp = baseExp;
    if (level > 40) {
      requiredExp = (baseExp * 2).round();
    } else if (level > 20) {
      requiredExp = (baseExp * 1.5).round();
    }

    // 무료 보상 (5레벨마다)
    final freeRewards = <BPReward>[];
    if (level % 5 == 0) {
      freeRewards.add(BPReward(
        id: 'bp_gold_$level',
        nameKr: '골드',
        type: BPRewardType.currency,
        amount: level * 100,
      ));
    }

    // 프리미엄 보상 (매 레벨)
    final premiumRewards = <BPReward>[];

    // 10레벨마다 프리미엄 재화
    if (level % 10 == 0) {
      premiumRewards.add(BPReward(
        id: 'bp_gem_$level',
        nameKr: '프리미엄 화폐',
        type: BPRewardType.currency,
        amount: 100,
        isPremiumOnly: true,
      ));
    }

    // 25레벨 소환권
    if (level == 25) {
      premiumRewards.add(const BPReward(
        id: 'bp_ticket_25',
        nameKr: '소환권 x5',
        type: BPRewardType.summonTicket,
        amount: 5,
        isPremiumOnly: true,
      ));
    }

    // 50레벨 (최종) 한정 코스튬
    if (level == 50) {
      premiumRewards.add(const BPReward(
        id: 'bp_costume_50',
        nameKr: '시즌 한정 코스튬',
        type: BPRewardType.costume,
        amount: 1,
        isPremiumOnly: true,
      ));
    }

    return BPTier(
      level: level,
      requiredExp: requiredExp,
      freeRewards: freeRewards,
      premiumRewards: premiumRewards,
    );
  }

  /// 기본 일일 미션 생성
  static List<BPMission> createDefaultDailyMissions() => [
    const BPMission(
      id: 'daily_login',
      titleKr: '접속하기',
      descriptionKr: '게임에 접속',
      type: BPMissionType.daily,
      targetValue: 1,
      expReward: 100,
      trackingKey: 'login',
    ),
    const BPMission(
      id: 'daily_battle_3',
      titleKr: '전투 3회',
      descriptionKr: '전투 3회 완료',
      type: BPMissionType.daily,
      targetValue: 3,
      expReward: 150,
      trackingKey: 'battle_count',
    ),
    const BPMission(
      id: 'daily_stamina',
      titleKr: '스태미나 사용',
      descriptionKr: '스태미나 60 사용',
      type: BPMissionType.daily,
      targetValue: 60,
      expReward: 200,
      trackingKey: 'stamina_used',
    ),
  ];

  /// 기본 주간 미션 생성
  static List<BPMission> createDefaultWeeklyMissions() => [
    const BPMission(
      id: 'weekly_battle_20',
      titleKr: '전투 20회',
      descriptionKr: '전투 20회 완료',
      type: BPMissionType.weekly,
      targetValue: 20,
      expReward: 500,
      trackingKey: 'battle_count',
    ),
    const BPMission(
      id: 'weekly_enhance',
      titleKr: '캐릭터 강화',
      descriptionKr: '캐릭터 강화 10회',
      type: BPMissionType.weekly,
      targetValue: 10,
      expReward: 400,
      trackingKey: 'enhance_count',
    ),
    const BPMission(
      id: 'weekly_gacha',
      titleKr: '소환 10회',
      descriptionKr: '캐릭터 소환 10회',
      type: BPMissionType.weekly,
      targetValue: 10,
      expReward: 600,
      trackingKey: 'gacha_pull',
    ),
  ];
}
