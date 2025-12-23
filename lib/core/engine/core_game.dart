import 'package:flame/game.dart';
// TapDetector is here now
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/core/engine/game_manager.dart';
import 'package:mg_common_game/core/engine/input_manager.dart';

/// The base game class for all Monthly Games.
/// It wraps [FlameGame] and provides standard integrations for:
/// - State Management (via GameManager)
/// - Input Handling (Taps, Drags)
/// - Common Lifecycle hooks
abstract class CoreGame extends FlameGame
    with TapDetector, PanDetector, HasEngineInput {
  late final GameManager _gameManager;

  CoreGame() {
    _gameManager = GetIt.I<GameManager>();
    // Ideally InputManager is also injected or passed in.
    // Assuming GetIt has it (user responsibility to register)
    try {
      final inputManager = GetIt.I<InputManager>();
      setInputManager(inputManager);
    } catch (e) {
      // InputManager might not be registered in tests or early dev
      print('InputManager not registered: $e');
    }
  }

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Potential for global asset loading here
  }

  @override
  void onMount() {
    super.onMount();
    _gameManager.initialize();
  }

  @override
  void onRemove() {
    _gameManager.stop();
    super.onRemove();
  }
}
