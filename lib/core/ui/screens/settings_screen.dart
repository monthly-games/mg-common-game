import 'package:flutter/material.dart';
import 'package:mg_common_game/systems/settings/settings_manager.dart';

/// Common settings screen for all games
class SettingsScreen extends StatefulWidget {
  final SettingsManager settingsManager;
  final String title;
  final Color accentColor;
  final VoidCallback onClose;
  final String? version;

  const SettingsScreen({
    super.key,
    required this.settingsManager,
    required this.title,
    required this.accentColor,
    required this.onClose,
    this.version = '1.0.0',
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    widget.settingsManager.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    widget.settingsManager.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: widget.accentColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onClose,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Audio Settings Section
          const _SectionHeader(
            icon: Icons.volume_up,
            title: 'Audio Settings',
          ),
          const SizedBox(height: 8),

          _SettingTile(
            icon: Icons.music_note,
            title: 'Background Music',
            subtitle: 'Play background music',
            value: widget.settingsManager.musicEnabled,
            onChanged: (value) {
              widget.settingsManager.setMusicEnabled(value);
            },
            color: widget.accentColor,
          ),

          _SettingTile(
            icon: Icons.volume_up,
            title: 'Sound Effects',
            subtitle: 'Play sound effects in game',
            value: widget.settingsManager.soundEnabled,
            onChanged: (value) {
              widget.settingsManager.setSoundEnabled(value);
              // Give immediate feedback
              if (value) {
                widget.settingsManager.triggerVibration(
                  intensity: VibrationIntensity.light,
                );
              }
            },
            color: widget.accentColor,
          ),

          const SizedBox(height: 24),

          // Haptic Feedback Section
          const _SectionHeader(
            icon: Icons.vibration,
            title: 'Haptic Feedback',
          ),
          const SizedBox(height: 8),

          _SettingTile(
            icon: Icons.vibration,
            title: 'Vibration',
            subtitle: 'Haptic feedback on actions',
            value: widget.settingsManager.vibrationEnabled,
            onChanged: (value) {
              widget.settingsManager.setVibrationEnabled(value);
              // Test vibration when enabled
              if (value) {
                widget.settingsManager.triggerVibration(
                  intensity: VibrationIntensity.medium,
                );
              }
            },
            color: widget.accentColor,
          ),

          const SizedBox(height: 24),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),

          // About Section
          const _SectionHeader(
            icon: Icons.info_outline,
            title: 'About',
          ),
          const SizedBox(height: 8),

          _InfoTile(
            title: 'Version',
            subtitle: widget.version ?? '1.0.0',
          ),
          _InfoTile(
            title: 'Made with',
            subtitle: 'Flutter & Flame',
          ),
        ],
      ),
    );
  }
}

/// Section header widget
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.amber, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// Setting tile with toggle switch
class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color color;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFF2d2d44),
      child: SwitchListTile(
        secondary: Icon(icon, color: color),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white70,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: color,
      ),
    );
  }
}

/// Information display tile (non-interactive)
class _InfoTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFF2d2d44),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}
