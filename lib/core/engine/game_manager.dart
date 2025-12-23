import 'package:injectable/injectable.dart';
import 'package:mg_common_game/core/engine/event_bus.dart';
import 'package:mg_common_game/core/systems/save_system.dart';

enum GameState {
  initializing,
  running,
  paused,
  stopped,
}

class GameStateChangedEvent {
  final GameState previous;
  final GameState current;
  GameStateChangedEvent(this.previous, this.current);
}

@singleton
class GameManager {
  final EventBus _eventBus;
  final SaveSystem _saveSystem;

  GameState _state = GameState.initializing;
  GameState get state => _state;

  DateTime? _lastSaveTime;
  DateTime? get lastSaveTime => _lastSaveTime;

  GameManager(this._eventBus, this._saveSystem);

  Future<void> initialize() async {
    _transitionTo(GameState.running);
    await _loadGameState();
  }

  void pause() {
    if (_state == GameState.running) {
      _transitionTo(GameState.paused);
      _saveGameState();
    }
  }

  void resume() {
    if (_state == GameState.paused) {
      _transitionTo(GameState.running);
    }
  }

  void stop() {
    _saveGameState();
    _transitionTo(GameState.stopped);
  }

  void _transitionTo(GameState newState) {
    if (_state == newState) return;
    final oldState = _state;
    _state = newState;
    _eventBus.fire(GameStateChangedEvent(oldState, newState));
  }

  Future<void> _saveGameState() async {
    final now = DateTime.now().toIso8601String();
    await _saveSystem.save('common_game_state', {
      'last_save_time': now,
      'gold': 0, // Placeholder
    });
    print('Game Saved: $now');
  }

  Future<void> _loadGameState() async {
    final data = await _saveSystem.load('common_game_state');
    if (data != null) {
      print('Game Loaded: $data');
      if (data.containsKey('last_save_time')) {
        _lastSaveTime = DateTime.tryParse(data['last_save_time']);
      }
    }
  }
}
