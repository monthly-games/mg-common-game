import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:injectable/injectable.dart';
import 'package:mg_common_game/core/engine/event_bus.dart';

abstract class EngineInputEvent {}

class TapDownEventWrapper extends EngineInputEvent {
  final TapDownInfo info;
  TapDownEventWrapper(this.info);
}

class DragStartEventWrapper extends EngineInputEvent {
  final DragStartInfo info;
  DragStartEventWrapper(this.info);
}

@singleton
class InputManager {
  final EventBus _eventBus;

  InputManager(this._eventBus);

  void handleTapDown(TapDownInfo info) {
    _eventBus.fire(TapDownEventWrapper(info));
  }

  void handleDragStart(DragStartInfo info) {
    _eventBus.fire(DragStartEventWrapper(info));
  }
}

/// Mixin to be used on the Game class to route events to InputManager
mixin HasEngineInput on FlameGame {
  InputManager? _inputManager;

  void setInputManager(InputManager manager) {
    _inputManager = manager;
  }

  void onTapDown(TapDownInfo info) {
    _inputManager?.handleTapDown(info);
  }

  void onPanStart(DragStartInfo info) {
    _inputManager?.handleDragStart(info);
  }
}
