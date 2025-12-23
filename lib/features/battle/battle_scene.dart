import 'package:flame/components.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/core/engine/event_bus.dart';
import 'package:mg_common_game/features/battle/components/battle_entity.dart';
import 'package:mg_common_game/features/battle/logic/turn_manager.dart';

class BattleScene extends Component {
  late final TurnManager _turnManager;
  late final EventBus _eventBus;

  BattleEntity? _hero;
  BattleEntity? _enemy;

  BattleScene() {
    _eventBus = GetIt.I<EventBus>();
    _turnManager = TurnManager(_eventBus);
    if (GetIt.I.isRegistered<TurnManager>()) {
      GetIt.I.unregister<TurnManager>();
    }
    GetIt.I.registerSingleton<TurnManager>(_turnManager);
  }

  @override
  Future<void> onLoad() async {
    // 1. Setup Entities
    _hero = BattleEntity(
      id: 'Hero',
      assetName: 'hero_mock', // Requires asset
      isPlayer: true,
      position: Vector2(100, 300),
    );

    _enemy = BattleEntity(
      id: 'Goblin',
      assetName: 'goblin_mock', // Requires asset
      isPlayer: false,
      position: Vector2(300, 300),
    );

    await add(_hero!);
    await add(_enemy!);

    // 2. Start Battle
    _turnManager.startBattle();

    // 3. Listen to Turn Changes (Mocking UI response)
    _eventBus.stream.listen((event) {
      if (event is BattlePhaseChangedEvent) {
        _onPhaseChanged(event.phase);
      }
    });

    print('BattleScene Loaded. Starting Battle...');
  }

  void _onPhaseChanged(BattlePhase phase) async {
    switch (phase) {
      case BattlePhase.playerTurn:
        print('UI: Player Turn - Tap to Attack!');
        // Auto-attack for prototype
        await Future.delayed(const Duration(seconds: 1));
        _hero?.playAttack();
        _enemy?.takeDamage(10);
        _turnManager.endPlayerTurn();
        break;
      case BattlePhase.enemyTurn:
        print('UI: Enemy Turn');
        await Future.delayed(const Duration(seconds: 1));
        _enemy?.playAttack();
        _hero?.takeDamage(5);
        _turnManager.endEnemyTurn();
        break;
      default:
        break;
    }
  }
}
