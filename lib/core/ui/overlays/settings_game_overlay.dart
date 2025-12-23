import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

class SettingsGameOverlay extends StatefulWidget {
  final FlameGame game;
  final VoidCallback? onBack;

  const SettingsGameOverlay({
    super.key,
    required this.game,
    this.onBack,
  });

  @override
  State<SettingsGameOverlay> createState() => _SettingsGameOverlayState();
}

class _SettingsGameOverlayState extends State<SettingsGameOverlay> {
  // TODO: Retrieve actual volume from AudioManager or generic prefs
  double _bgmVolume = 0.5;
  double _sfxVolume = 0.5;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blueAccent, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SETTINGS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 30),
            _buildSlider('BGM VOLUME', _bgmVolume, (val) {
              setState(() => _bgmVolume = val);
              FlameAudio.bgm.audioPlayer.setVolume(val);
            }),
            const SizedBox(height: 20),
            _buildSlider('SFX VOLUME', _sfxVolume, (val) {
              setState(() => _sfxVolume = val);
              // Store SFX volume preference if possible
            }),
            const SizedBox(height: 30),
            SizedBox(
              width: 150,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent.withOpacity(0.5),
                  side: const BorderSide(color: Colors.blueAccent),
                ),
                onPressed: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else {
                    widget.game.overlays.remove('settings');
                  }
                },
                child:
                    const Text('BACK', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
      String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                decoration: TextDecoration.none,
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
        Material(
          color: Colors.transparent,
          child: Slider(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blueAccent,
            inactiveColor: Colors.grey[800],
          ),
        ),
      ],
    );
  }
}
