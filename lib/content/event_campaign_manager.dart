import 'dart:async';
import 'package:flutter/material.dart';

enum CampaignType {
  event,
  season,
  special,
  collaboration,
  holiday,
}

enum CampaignStatus {
  upcoming,
  active,
  completed,
  cancelled,
}

class CampaignMission {
  final String missionId;
  final String name;
  final String description;
  final int targetValue;
  final int currentValue;
  final String metric;
  final bool isCompleted;

  const CampaignMission({
    required this.missionId,
    required this.name,
    required this.description,
    required this.targetValue,
    required this.currentValue,
    required this.metric,
    required this.isCompleted,
  });

  double get progress => targetValue > 0 ? currentValue / targetValue : 0.0;
}

class CampaignReward {
  final String rewardId;
  final String type;
  final int amount;
  final String itemId;
  final String itemName;

  const CampaignReward({
    required this.rewardId,
    required this.type,
    required this.amount,
    required this.itemId,
    required this.itemName,
  });
}

class CampaignTier {
  final String tierId;
  final String name;
  final int requiredPoints;
  final List<CampaignReward> rewards;

  const CampaignTier({
    required this.tierId,
    required this.name,
    required this.requiredPoints,
    required this.rewards,
  });
}

class EventCampaign {
  final String campaignId;
  final String name;
  final String description;
  final CampaignType type;
  final CampaignStatus status;
  final List<CampaignMission> missions;
  final List<CampaignTier> tiers;
  final DateTime startDate;
  final DateTime endDate;
  final String? bannerUrl;
  final String? iconUrl;
  final int maxPoints;
  final bool isFeatured;
  final Map<String, dynamic> metadata;

  const EventCampaign({
    required this.campaignId,
    required this.name,
    required this.description,
    required this.type,
    required this.status,
    required this.missions,
    required this.tiers,
    required this.startDate,
    required this.endDate,
    this.bannerUrl,
    this.iconUrl,
    required this.maxPoints,
    required this.isFeatured,
    required this.metadata,
  });

  double get progress {
    if (missions.isEmpty) return 0.0;
    final totalProgress = missions.fold<double>(0, (sum, m) => sum + m.progress);
    return totalProgress / missions.length;
  }

  bool get isActive => status == CampaignStatus.active;
  bool get isUpcoming => status == CampaignStatus.upcoming;
  bool get isCompleted => status == CampaignStatus.completed;
  bool get hasStarted => DateTime.now().isAfter(startDate);
  bool get hasEnded => DateTime.now().isAfter(endDate);
  int get earnedPoints => missions.where((m) => m.isCompleted).fold<int>(0, (sum, m) => sum + m.targetValue);
}

class CampaignManager {
  static final CampaignManager _instance = CampaignManager._();
  static CampaignManager get instance => _instance;

  CampaignManager._();

  final Map<String, EventCampaign> _campaigns = {};
  final Map<String, List<String>> _userProgress = {};
  final StreamController<CampaignEvent> _eventController = StreamController.broadcast();
  Timer? _checkTimer;

  Stream<CampaignEvent> get onCampaignEvent => _eventController.stream;

  Future<void> initialize() async {
    await _loadDefaultCampaigns();
    _startCheckTimer();
  }

  Future<void> _loadDefaultCampaigns() async {
    final campaigns = [
      EventCampaign(
        campaignId: 'summer_event_2024',
        name: 'Summer Festival',
        description: 'Join the summer festival event!',
        type: CampaignType.event,
        status: CampaignStatus.active,
        missions: [
          CampaignMission(
            missionId: 'play_10_games',
            name: 'Play 10 Games',
            description: 'Complete 10 matches',
            targetValue: 10,
            currentValue: 0,
            metric: 'games_played',
            isCompleted: false,
          ),
          CampaignMission(
            missionId: 'win_5_games',
            name: 'Win 5 Games',
            description: 'Win 5 matches',
            targetValue: 5,
            currentValue: 0,
            metric: 'wins',
            isCompleted: false,
          ),
        ],
        tiers: [
          CampaignTier(
            tierId: 'tier_1',
            name: 'Bronze',
            requiredPoints: 50,
            rewards: const [
              CampaignReward(
                rewardId: 'coins',
                type: 'currency',
                amount: 500,
                itemId: 'coins',
                itemName: 'Coins',
              ),
            ],
          ),
          CampaignTier(
            tierId: 'tier_2',
            name: 'Silver',
            requiredPoints: 150,
            rewards: const [
              CampaignReward(
                rewardId: 'premium',
                type: 'premium_currency',
                amount: 100,
                itemId: 'gems',
                itemName: 'Gems',
              ),
            ],
          ),
        ],
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        maxPoints: 200,
        isFeatured: true,
        metadata: {},
      ),
    ];

    for (final campaign in campaigns) {
      _campaigns[campaign.campaignId] = campaign;
    }
  }

  void _startCheckTimer() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _checkCampaignStatus(),
    );
  }

  void _checkCampaignStatus() {
    for (final campaign in _campaigns.values) {
      if (campaign.isUpcoming && campaign.hasStarted) {
        _activateCampaign(campaign.campaignId);
      } else if (campaign.isActive && campaign.hasEnded) {
        _completeCampaign(campaign.campaignId);
      }
    }
  }

  void _activateCampaign(String campaignId) {
    final campaign = _campaigns[campaignId];
    if (campaign == null) return;

    final updated = EventCampaign(
      campaignId: campaign.campaignId,
      name: campaign.name,
      description: campaign.description,
      type: campaign.type,
      status: CampaignStatus.active,
      missions: campaign.missions,
      tiers: campaign.tiers,
      startDate: campaign.startDate,
      endDate: campaign.endDate,
      bannerUrl: campaign.bannerUrl,
      iconUrl: campaign.iconUrl,
      maxPoints: campaign.maxPoints,
      isFeatured: campaign.isFeatured,
      metadata: campaign.metadata,
    );

    _campaigns[campaignId] = updated;

    _eventController.add(CampaignEvent(
      type: CampaignEventType.campaignStarted,
      campaignId: campaignId,
      timestamp: DateTime.now(),
    ));
  }

  void _completeCampaign(String campaignId) {
    final campaign = _campaigns[campaignId];
    if (campaign == null) return;

    final updated = EventCampaign(
      campaignId: campaign.campaignId,
      name: campaign.name,
      description: campaign.description,
      type: campaign.type,
      status: CampaignStatus.completed,
      missions: campaign.missions,
      tiers: campaign.tiers,
      startDate: campaign.startDate,
      endDate: campaign.endDate,
      bannerUrl: campaign.bannerUrl,
      iconUrl: campaign.iconUrl,
      maxPoints: campaign.maxPoints,
      isFeatured: campaign.isFeatured,
      metadata: campaign.metadata,
    );

    _campaigns[campaignId] = updated;

    _eventController.add(CampaignEvent(
      type: CampaignEventType.campaignEnded,
      campaignId: campaignId,
      timestamp: DateTime.now(),
    ));
  }

  List<EventCampaign> getAllCampaigns() {
    return _campaigns.values.toList();
  }

  List<EventCampaign> getActiveCampaigns() {
    return _campaigns.values
        .where((c) => c.isActive)
        .toList();
  }

  List<EventCampaign> getUpcomingCampaigns() {
    return _campaigns.values
        .where((c) => c.isUpcoming)
        .toList();
  }

  EventCampaign? getCampaign(String campaignId) {
    return _campaigns[campaignId];
  }

  Future<bool> updateMission({
    required String campaignId,
    required String missionId,
    required int increment,
  }) async {
    final campaign = _campaigns[campaignId];
    if (campaign == null) return false;
    if (!campaign.isActive) return false;

    final missionIndex = campaign.missions.indexWhere((m) => m.missionId == missionId);
    if (missionIndex < 0) return false;

    final mission = campaign.missions[missionIndex];
    final newValue = (mission.currentValue + increment).clamp(0, mission.targetValue);
    final isCompleted = newValue >= mission.targetValue;

    final updatedMission = CampaignMission(
      missionId: mission.missionId,
      name: mission.name,
      description: mission.description,
      targetValue: mission.targetValue,
      currentValue: newValue,
      metric: mission.metric,
      isCompleted: isCompleted,
    );

    final updatedMissions = [...campaign.missions];
    updatedMissions[missionIndex] = updatedMission;

    final updated = EventCampaign(
      campaignId: campaign.campaignId,
      name: campaign.name,
      description: campaign.description,
      type: campaign.type,
      status: campaign.status,
      missions: updatedMissions,
      tiers: campaign.tiers,
      startDate: campaign.startDate,
      endDate: campaign.endDate,
      bannerUrl: campaign.bannerUrl,
      iconUrl: campaign.iconUrl,
      maxPoints: campaign.maxPoints,
      isFeatured: campaign.isFeatured,
      metadata: campaign.metadata,
    );

    _campaigns[campaignId] = updated;

    _eventController.add(CampaignEvent(
      type: CampaignEventType.missionUpdated,
      campaignId: campaignId,
      timestamp: DateTime.now(),
      data: {'missionId': missionId, 'newValue': newValue},
    ));

    return true;
  }

  List<CampaignTier> getUnlockedTiers(String campaignId, int points) {
    final campaign = _campaigns[campaignId];
    if (campaign == null) return [];

    return campaign.tiers
        .where((tier) => points >= tier.requiredPoints)
        .toList();
  }

  bool claimTierReward({
    required String campaignId,
    required String tierId,
    required String userId,
  }) {
    final campaign = _campaigns[campaignId];
    if (campaign == null) return false;

    final tier = campaign.tiers.firstWhere((t) => t.tierId == tierId, orElse: () => campaign.tiers.first);

    _userProgress.putIfAbsent(userId, () => []);
    if (_userProgress[userId]!.contains(tierId)) return false;

    _userProgress[userId]!.add(tierId);

    _eventController.add(CampaignEvent(
      type: CampaignEventType.rewardClaimed,
      campaignId: campaignId,
      userId: userId,
      timestamp: DateTime.now(),
      data: {'tierId': tierId},
    ));

    return true;
  }

  Map<String, dynamic> getCampaignStats(String campaignId) {
    final campaign = _campaigns[campaignId];
    if (campaign == null) return {};

    return {
      'progress': campaign.progress,
      'earnedPoints': campaign.earnedPoints,
      'maxPoints': campaign.maxPoints,
      'completedMissions': campaign.missions.where((m) => m.isCompleted).length,
      'totalMissions': campaign.missions.length,
    };
  }

  void dispose() {
    _checkTimer?.cancel();
    _eventController.close();
  }
}

class CampaignEvent {
  final CampaignEventType type;
  final String? campaignId;
  final String? userId;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const CampaignEvent({
    required this.type,
    this.campaignId,
    this.userId,
    required this.timestamp,
    this.data,
  });
}

enum CampaignEventType {
  campaignStarted,
  campaignEnded,
  missionUpdated,
  missionCompleted,
  rewardClaimed,
  tierUnlocked,
}
