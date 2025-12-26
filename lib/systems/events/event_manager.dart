import 'package:flutter/foundation.dart';
import 'event_types.dart';

/// Event/Campaign Manager
/// Manages limited-time events, seasonal campaigns, and recurring events
class EventManager extends ChangeNotifier {
  final Map<String, GameEvent> _events = {};
  final Set<String> _notifiedEvents = {};

  // Callbacks
  void Function(GameEvent event)? onEventStarted;
  void Function(GameEvent event)? onEventEnded;
  void Function(EventMission mission)? onMissionCompleted;
  void Function(EventReward reward)? onRewardClaimed;

  /// All registered events
  List<GameEvent> get allEvents => _events.values.toList();

  /// Active events only
  List<GameEvent> get activeEvents =>
      _events.values.where((e) => e.isActive).toList();

  /// Upcoming events
  List<GameEvent> get upcomingEvents =>
      _events.values.where((e) => e.status == EventStatus.upcoming).toList();

  /// Ended events
  List<GameEvent> get endedEvents =>
      _events.values.where((e) => e.hasEnded).toList();

  /// Get event by ID
  GameEvent? getEvent(String eventId) => _events[eventId];

  /// Register a new event
  void registerEvent(GameEvent event) {
    _events[event.id] = event;
    notifyListeners();
  }

  /// Register multiple events
  void registerEvents(List<GameEvent> events) {
    for (final event in events) {
      _events[event.id] = event;
    }
    notifyListeners();
  }

  /// Remove an event
  void removeEvent(String eventId) {
    _events.remove(eventId);
    notifyListeners();
  }

  /// Update event from server
  void updateEvent(GameEvent event) {
    _events[event.id] = event;
    notifyListeners();
  }

  /// Increment mission progress for an event
  void incrementMissionProgress(
    String eventId,
    String trackingKey, {
    int amount = 1,
  }) {
    final event = _events[eventId];
    if (event == null || !event.isActive) return;

    GameEvent updatedEvent = event;
    for (final mission in event.missions) {
      if (mission.trackingKey == trackingKey && !mission.isCompleted) {
        final wasCompleted = mission.isCompleted;
        updatedEvent = updatedEvent.updateMissionProgress(mission.id, amount);

        // Check if mission just completed
        final updatedMission = updatedEvent.missions.firstWhere((m) => m.id == mission.id);
        if (!wasCompleted && updatedMission.isCompleted) {
          onMissionCompleted?.call(updatedMission);
        }
      }
    }

    _events[eventId] = updatedEvent;
    notifyListeners();
  }

  /// Increment mission progress across all active events
  void incrementAllMissions(String trackingKey, {int amount = 1}) {
    for (final eventId in activeEvents.map((e) => e.id)) {
      incrementMissionProgress(eventId, trackingKey, amount: amount);
    }
  }

  /// Claim a reward from an event
  bool claimReward(String eventId, String rewardId) {
    final event = _events[eventId];
    if (event == null) return false;

    final reward = event.rewards.firstWhere(
      (r) => r.id == rewardId,
      orElse: () => const EventReward(
        id: '',
        name: '',
        type: '',
        amount: 0,
        requiredPoints: 0,
      ),
    );

    if (reward.id.isEmpty || reward.claimed) return false;
    if (event.currentPoints < reward.requiredPoints) return false;

    _events[eventId] = event.claimReward(rewardId);
    onRewardClaimed?.call(reward);
    notifyListeners();
    return true;
  }

  /// Claim all available rewards for an event
  List<EventReward> claimAllRewards(String eventId) {
    final event = _events[eventId];
    if (event == null) return [];

    final claimed = <EventReward>[];
    for (final reward in event.claimableRewards) {
      if (claimReward(eventId, reward.id)) {
        claimed.add(reward);
      }
    }
    return claimed;
  }

  /// Check and trigger event status notifications
  void checkEventStatus() {
    final now = DateTime.now();

    for (final event in _events.values) {
      final key = '${event.id}_${event.status.name}';

      if (!_notifiedEvents.contains(key)) {
        if (event.isActive && now.difference(event.startDate).inMinutes < 5) {
          onEventStarted?.call(event);
          _notifiedEvents.add(key);
        } else if (event.hasEnded && now.difference(event.endDate).inMinutes < 5) {
          onEventEnded?.call(event);
          _notifiedEvents.add(key);
        }
      }
    }
  }

  /// Clean up ended events older than specified duration
  void cleanupEndedEvents({Duration maxAge = const Duration(days: 7)}) {
    final cutoff = DateTime.now().subtract(maxAge);
    _events.removeWhere((_, event) => event.hasEnded && event.endDate.isBefore(cutoff));
    notifyListeners();
  }

  /// Get total unclaimed rewards across all active events
  int get totalUnclaimedRewards {
    return activeEvents.fold(0, (sum, e) => sum + e.claimableRewards.length);
  }

  /// Get events by type
  List<GameEvent> getEventsByType(EventType type) {
    return _events.values.where((e) => e.type == type).toList();
  }

  // === Persistence ===

  Map<String, dynamic> toJson() {
    return {
      'events': _events.map((k, v) => MapEntry(k, v.toJson())),
      'notifiedEvents': _notifiedEvents.toList(),
    };
  }

  void fromJson(Map<String, dynamic> json) {
    _events.clear();
    if (json['events'] != null) {
      final eventsMap = json['events'] as Map<String, dynamic>;
      for (final entry in eventsMap.entries) {
        _events[entry.key] = GameEvent.fromJson(entry.value as Map<String, dynamic>);
      }
    }

    _notifiedEvents.clear();
    if (json['notifiedEvents'] != null) {
      _notifiedEvents.addAll(List<String>.from(json['notifiedEvents'] as List));
    }

    notifyListeners();
  }

  /// Clear all data
  void clear() {
    _events.clear();
    _notifiedEvents.clear();
    notifyListeners();
  }
}
