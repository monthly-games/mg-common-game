/// Battle System for MG-Games
///
/// Provides common battle types, entities, and manager base class.
///
/// Usage:
/// ```dart
/// import 'package:mg_common_game/systems/battle/battle.dart';
///
/// class MyBattleManager extends BattleManagerBase {
///   final BattleEntity player;
///   final List<BattleEntity> enemies;
///
///   @override
///   List<BattleEntity> get playerEntities => [player];
///
///   @override
///   List<BattleEntity> get enemyEntities => enemies;
///
///   @override
///   Future<void> executeEnemyTurn() async {
///     for (final enemy in enemies.where((e) => e.isAlive)) {
///       await Future.delayed(Duration(milliseconds: 500));
///       executeAttack(source: enemy, target: player);
///     }
///     endEnemyTurn();
///   }
/// }
/// ```
library battle;

export 'battle_types.dart';
export 'battle_entity.dart';
export 'battle_manager_base.dart';
