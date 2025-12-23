import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/core/engine/event_bus.dart';
import 'package:mg_common_game/features/battle/logic/turn_manager.dart';

class BattleHUD extends StatefulWidget {
  final TurnManager turnManager;

  const BattleHUD({super.key, required this.turnManager});

  @override
  State<BattleHUD> createState() => _BattleHUDState();
}

class _BattleHUDState extends State<BattleHUD> {
  BattlePhase _currentPhase = BattlePhase.start;

  @override
  void initState() {
    super.initState();
    // Listen to phase changes to update UI (enable/disable buttons)
    GetIt.I<EventBus>().stream.listen((event) {
      if (event is BattlePhaseChangedEvent) {
        if (mounted) {
          setState(() {
            _currentPhase = event.phase;
          });
        }
      }
    });
  }

  void _onAttackPressed() {
    if (_currentPhase == BattlePhase.playerTurn) {
      widget.turnManager.performPlayerAction('attack');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPlayerTurn = _currentPhase == BattlePhase.playerTurn;

    return Stack(
      children: [
        // Top: Enemy HP Bar (Mock)
        Positioned(
          top: 20,
          left: 50,
          right: 50,
          child: Container(
            height: 30,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 70, // Mock 70% HP
                  child: Container(color: Colors.red),
                ),
                const Spacer(flex: 30),
              ],
            ),
          ),
        ),

        // Bottom: Action Panel
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: isPlayerTurn ? _onAttackPressed : null,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text('ATTACK'),
              ),
              ElevatedButton(
                onPressed: isPlayerTurn ? () {} : null, // Skill mock
                child: const Text('SKILL'),
              ),
              ElevatedButton(
                onPressed: isPlayerTurn ? () {} : null, // Item mock
                child: const Text('ITEM'),
              ),
            ],
          ),
        ),

        // Turn Indicator
        Positioned(
          top: 60,
          right: 20,
          child: Text(
            isPlayerTurn ? 'YOUR TURN' : 'ENEMY TURN',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: 2, color: Colors.black)],
            ),
          ),
        ),
      ],
    );
  }
}
