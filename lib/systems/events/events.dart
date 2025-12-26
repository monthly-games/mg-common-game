/// Event System for MG-Games
///
/// Manages limited-time events, seasonal campaigns, and recurring events.
///
/// ## Basic Usage
/// ```dart
/// import 'package:mg_common_game/systems/events/events.dart';
///
/// final eventManager = EventManager();
///
/// // Register an event
/// eventManager.registerEvent(GameEvent(
///   id: 'summer_2024',
///   name: 'Summer Festival',
///   description: 'Collect summer coins!',
///   type: EventType.seasonal,
///   startDate: DateTime(2024, 7, 1),
///   endDate: DateTime(2024, 7, 31),
///   missions: [
///     EventMission(
///       id: 'collect_100',
///       title: 'Collect 100 Coins',
///       description: 'Gather 100 summer coins',
///       targetValue: 100,
///       rewardPoints: 50,
///       trackingKey: 'summer_coin',
///     ),
///   ],
///   rewards: [
///     EventReward(
///       id: 'reward_50',
///       name: 'Summer Avatar',
///       type: 'avatar',
///       amount: 1,
///       requiredPoints: 50,
///     ),
///   ],
/// ));
///
/// // Track progress
/// eventManager.incrementMissionProgress('summer_2024', 'summer_coin', amount: 10);
///
/// // Or track across all active events
/// eventManager.incrementAllMissions('summer_coin', amount: 10);
///
/// // Claim rewards
/// eventManager.claimReward('summer_2024', 'reward_50');
/// ```
library events;

export 'event_types.dart';
export 'event_manager.dart';
