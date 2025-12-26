/// Event System Types
library event_types;

/// Event status
enum EventStatus {
  upcoming,
  active,
  ended,
}

/// Event type
enum EventType {
  /// Limited time event with special rewards
  limited,
  /// Recurring daily/weekly event
  recurring,
  /// Seasonal event (holiday, anniversary)
  seasonal,
  /// Collaboration event with other IPs
  collaboration,
  /// Competitive ranking event
  ranking,
  /// Community goal event
  community,
}

/// Event reward
class EventReward {
  final String id;
  final String name;
  final String type;
  final int amount;
  final int requiredPoints;
  final bool claimed;

  const EventReward({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.requiredPoints,
    this.claimed = false,
  });

  EventReward copyWith({bool? claimed}) {
    return EventReward(
      id: id,
      name: name,
      type: type,
      amount: amount,
      requiredPoints: requiredPoints,
      claimed: claimed ?? this.claimed,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'amount': amount,
    'requiredPoints': requiredPoints,
    'claimed': claimed,
  };

  factory EventReward.fromJson(Map<String, dynamic> json) => EventReward(
    id: json['id'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
    amount: json['amount'] as int,
    requiredPoints: json['requiredPoints'] as int,
    claimed: json['claimed'] as bool? ?? false,
  );
}

/// Event mission/task
class EventMission {
  final String id;
  final String title;
  final String description;
  final int targetValue;
  final int currentValue;
  final int rewardPoints;
  final String trackingKey;

  const EventMission({
    required this.id,
    required this.title,
    required this.description,
    required this.targetValue,
    this.currentValue = 0,
    required this.rewardPoints,
    required this.trackingKey,
  });

  bool get isCompleted => currentValue >= targetValue;
  double get progress => targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0;

  EventMission incrementProgress(int amount) {
    return EventMission(
      id: id,
      title: title,
      description: description,
      targetValue: targetValue,
      currentValue: (currentValue + amount).clamp(0, targetValue),
      rewardPoints: rewardPoints,
      trackingKey: trackingKey,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'targetValue': targetValue,
    'currentValue': currentValue,
    'rewardPoints': rewardPoints,
    'trackingKey': trackingKey,
  };

  factory EventMission.fromJson(Map<String, dynamic> json) => EventMission(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    targetValue: json['targetValue'] as int,
    currentValue: json['currentValue'] as int? ?? 0,
    rewardPoints: json['rewardPoints'] as int,
    trackingKey: json['trackingKey'] as String,
  );
}

/// Event configuration
class GameEvent {
  final String id;
  final String name;
  final String description;
  final EventType type;
  final DateTime startDate;
  final DateTime endDate;
  final String? bannerUrl;
  final List<EventMission> missions;
  final List<EventReward> rewards;
  final int totalPoints;
  final Map<String, dynamic> metadata;

  const GameEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.startDate,
    required this.endDate,
    this.bannerUrl,
    this.missions = const [],
    this.rewards = const [],
    this.totalPoints = 0,
    this.metadata = const {},
  });

  EventStatus get status {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return EventStatus.upcoming;
    if (now.isAfter(endDate)) return EventStatus.ended;
    return EventStatus.active;
  }

  bool get isActive => status == EventStatus.active;
  bool get hasEnded => status == EventStatus.ended;

  Duration get remainingTime {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return Duration.zero;
    return endDate.difference(now);
  }

  Duration get timeUntilStart {
    final now = DateTime.now();
    if (now.isAfter(startDate)) return Duration.zero;
    return startDate.difference(now);
  }

  int get currentPoints {
    return missions
        .where((m) => m.isCompleted)
        .fold(0, (sum, m) => sum + m.rewardPoints);
  }

  List<EventReward> get claimableRewards {
    return rewards
        .where((r) => !r.claimed && currentPoints >= r.requiredPoints)
        .toList();
  }

  GameEvent updateMissionProgress(String missionId, int amount) {
    final updatedMissions = missions.map((m) {
      if (m.id == missionId) {
        return m.incrementProgress(amount);
      }
      return m;
    }).toList();

    return GameEvent(
      id: id,
      name: name,
      description: description,
      type: type,
      startDate: startDate,
      endDate: endDate,
      bannerUrl: bannerUrl,
      missions: updatedMissions,
      rewards: rewards,
      totalPoints: totalPoints,
      metadata: metadata,
    );
  }

  GameEvent claimReward(String rewardId) {
    final updatedRewards = rewards.map((r) {
      if (r.id == rewardId && !r.claimed && currentPoints >= r.requiredPoints) {
        return r.copyWith(claimed: true);
      }
      return r;
    }).toList();

    return GameEvent(
      id: id,
      name: name,
      description: description,
      type: type,
      startDate: startDate,
      endDate: endDate,
      bannerUrl: bannerUrl,
      missions: missions,
      rewards: updatedRewards,
      totalPoints: totalPoints,
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type.index,
    'startDate': startDate.millisecondsSinceEpoch,
    'endDate': endDate.millisecondsSinceEpoch,
    'bannerUrl': bannerUrl,
    'missions': missions.map((m) => m.toJson()).toList(),
    'rewards': rewards.map((r) => r.toJson()).toList(),
    'totalPoints': totalPoints,
    'metadata': metadata,
  };

  factory GameEvent.fromJson(Map<String, dynamic> json) => GameEvent(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    type: EventType.values[json['type'] as int],
    startDate: DateTime.fromMillisecondsSinceEpoch(json['startDate'] as int),
    endDate: DateTime.fromMillisecondsSinceEpoch(json['endDate'] as int),
    bannerUrl: json['bannerUrl'] as String?,
    missions: (json['missions'] as List<dynamic>?)
        ?.map((m) => EventMission.fromJson(m as Map<String, dynamic>))
        .toList() ?? [],
    rewards: (json['rewards'] as List<dynamic>?)
        ?.map((r) => EventReward.fromJson(r as Map<String, dynamic>))
        .toList() ?? [],
    totalPoints: json['totalPoints'] as int? ?? 0,
    metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
  );
}
