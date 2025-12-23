import 'package:mg_common_game/core/engine/event_bus.dart';

enum BattlePhase {
  start,
  playerTurn,
  enemyTurn,
  resolution,
}

class BattlePhaseChangedEvent {
  final BattlePhase phase;
  BattlePhaseChangedEvent(this.phase);
}

/// Manages the flow of a single battle.
/// Currently non-singleton (transient) as new battles will need new managers,
/// or we reset it. For now, we can make it injectable as a factory or singleton based on design.
/// Let's make it a standard class we instantiate in BattleScene for now to be safe.
class TurnManager {
  final EventBus _eventBus;

  BattlePhase _phase = BattlePhase.start;
  BattlePhase get phase => _phase;

  TurnManager(this._eventBus);

  void startBattle() {
    _transitionTo(BattlePhase.playerTurn);
  }

  // Player explicitly performs an action
  void performPlayerAction(String actionId) {
    if (_phase != BattlePhase.playerTurn) return;

    print('Player performed: $actionId');
    _eventBus.fire(BattlePhaseChangedEvent(
        BattlePhase.playerTurn)); // Notify action taken if needed

    // For prototype, any action ends turn after a small delay (handled by scene or here)
    // Let's assume Scene handles the animation, then calls endPlayerTurn
  }

  void endPlayerTurn() {
    if (_phase == BattlePhase.playerTurn) {
      _transitionTo(BattlePhase.enemyTurn);
    }
  }

  void endEnemyTurn() {
    if (_phase == BattlePhase.enemyTurn) {
      _transitionTo(BattlePhase.playerTurn);
    }
  }

  void endBattle() {
    _transitionTo(BattlePhase.resolution);
  }

  void _transitionTo(BattlePhase newPhase) {
    _phase = newPhase;
    print('Battle Phase: $newPhase');
    _eventBus.fire(BattlePhaseChangedEvent(newPhase));
  }
}
