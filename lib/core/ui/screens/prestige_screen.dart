import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/systems/progression/prestige_manager.dart';
import 'package:mg_common_game/systems/progression/progression_manager.dart';
import 'package:mg_common_game/systems/settings/settings_manager.dart';

/// Prestige screen showing prestige level, points, and available upgrades
class PrestigeScreen extends StatefulWidget {
  final PrestigeManager prestigeManager;
  final ProgressionManager progressionManager;
  final VoidCallback onClose;
  final VoidCallback onPrestige; // Callback when user confirms prestige
  final String title;
  final Color accentColor;

  const PrestigeScreen({
    super.key,
    required this.prestigeManager,
    required this.progressionManager,
    required this.onClose,
    required this.onPrestige,
    this.title = 'Prestige',
    this.accentColor = Colors.amber,
  });

  @override
  State<PrestigeScreen> createState() => _PrestigeScreenState();
}

class _PrestigeScreenState extends State<PrestigeScreen> {
  @override
  Widget build(BuildContext context) {
    final prestigePointsAvailable = widget.prestigeManager
        .calculatePrestigePoints(widget.progressionManager.currentLevel);
    final canPrestige = prestigePointsAvailable > 0;

    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: widget.accentColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onClose,
        ),
      ),
      body: AnimatedBuilder(
        animation: widget.prestigeManager,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prestige Info Card
                _buildPrestigeInfoCard(
                  prestigePointsAvailable,
                  canPrestige,
                ),
                const SizedBox(height: 24),

                // Prestige Upgrades Section
                const Text(
                  'Prestige Upgrades',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Prestige Points: ${widget.prestigeManager.prestigePoints}',
                  style: TextStyle(
                    fontSize: 18,
                    color: widget.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Prestige Upgrade List
                ...widget.prestigeManager.allPrestigeUpgrades
                    .map((upgrade) => _buildPrestigeUpgradeCard(upgrade))
                    .toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrestigeInfoCard(int pointsAvailable, bool canPrestige) {
    return Card(
      color: widget.accentColor.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.star,
              size: 64,
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            Text(
              'Prestige Level: ${widget.prestigeManager.prestigeLevel}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current Level: ${widget.progressionManager.currentLevel}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white30),
            const SizedBox(height: 16),
            Text(
              canPrestige
                  ? 'Reset to gain $pointsAvailable Prestige Points!'
                  : 'Reach Level 10+ to unlock Prestige',
              style: TextStyle(
                fontSize: 16,
                color: canPrestige ? Colors.greenAccent : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: canPrestige ? _showPrestigeConfirmation : null,
              icon: const Icon(Icons.refresh),
              label: const Text(
                'PRESTIGE NOW',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: canPrestige ? Colors.amber : Colors.grey,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            if (canPrestige)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Warning: This will reset your progress!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade300,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrestigeUpgradeCard(PrestigeUpgrade upgrade) {
    final cost = upgrade.costForNextLevel;
    final canAfford = widget.prestigeManager.canAffordPrestigeUpgrade(upgrade.id);
    final isMaxLevel = cost == -1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getUpgradeIcon(upgrade.id),
                color: widget.accentColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    upgrade.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    upgrade.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Level: ${upgrade.currentLevel}/${upgrade.maxLevel}',
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Bonus: ${(upgrade.totalMultiplier * 100 - 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Purchase Button
            if (!isMaxLevel)
              ElevatedButton(
                onPressed: canAfford
                    ? () {
                        final success = widget.prestigeManager
                            .purchasePrestigeUpgrade(upgrade.id);
                        if (success) {
                          // Haptic feedback on upgrade purchase
                          _triggerHaptic(VibrationIntensity.medium);
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${upgrade.name} upgraded to level ${upgrade.currentLevel}!',
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAfford ? widget.accentColor : Colors.grey,
                  foregroundColor: Colors.black,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_upward, size: 16),
                    Text('$cost PT', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'MAX',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getUpgradeIcon(String id) {
    if (id.contains('xp')) return Icons.trending_up;
    if (id.contains('gold') || id.contains('income')) return Icons.attach_money;
    if (id.contains('tower')) return Icons.security;
    if (id.contains('craft')) return Icons.build;
    if (id.contains('match')) return Icons.grid_on;
    return Icons.star;
  }

  void _showPrestigeConfirmation() {
    final pointsToGain = widget.prestigeManager
        .calculatePrestigePoints(widget.progressionManager.currentLevel);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.amber),
            SizedBox(width: 8),
            Text('Confirm Prestige'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to prestige?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('You will lose:'),
            const Text('• All progress and levels'),
            const Text('• All gold and resources'),
            const Text('• All regular upgrades'),
            const SizedBox(height: 16),
            Text(
              'You will gain:',
              style: TextStyle(color: widget.accentColor),
            ),
            Text(
              '• $pointsToGain Prestige Points',
              style: TextStyle(color: widget.accentColor),
            ),
            const Text('• Permanent prestige bonuses'),
            const Text('• Faster progression'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Heavy haptic feedback on prestige
              _triggerHaptic(VibrationIntensity.heavy);
              widget.onPrestige();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            child: const Text('PRESTIGE'),
          ),
        ],
      ),
    );
  }

  void _triggerHaptic(VibrationIntensity intensity) {
    if (GetIt.I.isRegistered<SettingsManager>()) {
      GetIt.I<SettingsManager>().triggerVibration(intensity: intensity);
    }
  }
}
