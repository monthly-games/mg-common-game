import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class PauseGameOverlay extends StatelessWidget {
  final FlameGame game;
  final VoidCallback? onResume;
  final VoidCallback? onSettings;
  final VoidCallback? onQuit;

  const PauseGameOverlay({
    super.key,
    required this.game,
    this.onResume,
    this.onSettings,
    this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PAUSED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 30),
            _buildButton(
              context,
              'RESUME',
              () {
                if (onResume != null) {
                  onResume!();
                } else {
                  game.resumeEngine();
                  game.overlays.remove('pause');
                }
              },
            ),
            const SizedBox(height: 16),
            _buildButton(
              context,
              'SETTINGS',
              () {
                if (onSettings != null) {
                  onSettings!();
                } else {
                  game.overlays.add('settings');
                }
              },
            ),
            const SizedBox(height: 16),
            _buildButton(
              context,
              'QUIT',
              () {
                if (onQuit != null) {
                  onQuit!();
                } else {
                  // Default behavior: Resume engine (to avoid stuck state) and pop
                  game.resumeEngine();
                  Navigator.of(context).pop();
                }
              },
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String text,
    VoidCallback onPressed, {
    bool isDestructive = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isDestructive ? Colors.red.withOpacity(0.8) : Colors.grey[800],
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: isDestructive ? Colors.red : Colors.white),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
