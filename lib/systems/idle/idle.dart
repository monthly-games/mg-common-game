/// Idle/Incremental Game System for MG-Games
///
/// Provides resource production over time with offline rewards.
///
/// ## Basic Usage
/// ```dart
/// import 'package:mg_common_game/systems/idle/idle.dart';
///
/// // Create and register resources
/// final goldMine = IdleResource(
///   id: 'gold_mine',
///   name: 'Gold Mine',
///   baseProductionRate: 100, // 100 gold per hour
///   maxStorage: 1000,
///   tier: 1,
/// );
///
/// final idleManager = IdleManager();
/// idleManager.registerResource(goldMine);
///
/// // Start production
/// idleManager.startProduction();
///
/// // Collect resources
/// final collected = idleManager.collectAll('gold_mine');
/// ```
///
/// ## Offline Rewards
/// ```dart
/// // On app resume, calculate offline rewards
/// final lastLogin = loadLastLoginTime();
/// final rewards = idleManager.processOfflineTime(lastLogin);
///
/// // Display rewards to player
/// for (final entry in rewards.entries) {
///   print('Earned ${entry.value} ${entry.key} while away!');
/// }
/// ```
///
/// ## Production Modifiers
/// ```dart
/// // Global modifier affects all resources
/// idleManager.setGlobalModifier(1.5); // +50% to all
///
/// // Per-resource modifier
/// idleManager.setProductionModifier('gold_mine', 2.0); // Double gold production
/// ```
///
/// ## Persistence
/// ```dart
/// // Save state
/// final saveData = idleManager.toJson();
/// saveToStorage(saveData);
///
/// // Load state
/// final loadedData = loadFromStorage();
/// idleManager.fromJson(loadedData);
/// ```
library idle;

export 'idle_resource.dart';
export 'idle_manager.dart';
