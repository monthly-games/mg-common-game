import 'package:flame/game.dart';
import 'package:flame_spine/flame_spine.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mg_common_game/core/engine/core_game.dart';
import 'package:mg_common_game/features/battle/battle_scene.dart';
import 'package:mg_common_game/features/battle/logic/turn_manager.dart';
import 'package:mg_common_game/features/battle/ui/battle_hud.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('In-Game'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          GameWidget<ExampleGame>(game: ExampleGame()),
          const _HudOverlay(),
        ],
      ),
    );
  }
}

class _HudOverlay extends StatefulWidget {
  const _HudOverlay();

  @override
  State<_HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<_HudOverlay> {
  TurnManager? _turnManager;

  @override
  void initState() {
    super.initState();
    _checkTurnManager();
  }

  void _checkTurnManager() async {
    // Simple polling to wait for Game/Scene to register TurnManager
    // In production, use a better signal (GameReady event)
    for (int i = 0; i < 10; i++) {
      if (GetIt.I.isRegistered<TurnManager>()) {
        if (mounted) {
          setState(() {
            _turnManager = GetIt.I<TurnManager>();
          });
        }
        return;
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_turnManager == null) {
      return const SizedBox.shrink(); // Loading or Waiting
    }
    return BattleHUD(turnManager: _turnManager!);
  }
}

class ExampleGame extends CoreGame {
  @override
  Color backgroundColor() => const Color(0xFF222222);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    print('ExampleCoreGame loaded');
    add(BattleScene());

    // Test Spine
    try {
      final spineboy = await SpineComponent.fromAssets(
        atlasFile: 'spine/spineboy.atlas',
        skeletonFile: 'spine/spineboy-pro.json', // or .json
        scale: Vector2.all(0.4),
      );
      spineboy.position = Vector2(200, 300);
      spineboy.animationState.setAnimation(0, 'walk', true);
      add(spineboy);
    } catch (e) {
      print('Spine Error: $e');
    }
  }

  @override
  void onTapDown(TapDownEvent info) {
    super.onTapDown(info);
    print('Tap handled in ExampleGame: ${info.localPosition}');
  }
}
