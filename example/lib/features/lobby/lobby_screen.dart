import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:get_it/get_it.dart';
import 'package:mg_common_game/core/engine/game_manager.dart';
import 'package:mg_common_game/features/idle/logic/offline_calculator.dart';
import 'package:mg_common_game/core/ui/layouts/game_scaffold.dart';
import 'package:mg_common_game/core/ui/widgets/hud/resource_bar.dart';
import 'package:mg_common_game/core/ui/theme/app_text_styles.dart';
import 'package:mg_common_game/core/ui/widgets/buttons/game_button.dart';
import 'package:mg_common_game/core/ui/widgets/dialogs/game_dialog.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOfflineRewards());
  }

  Future<void> _checkOfflineRewards() async {
    final gameManager = GetIt.I<GameManager>();
    // Ensure game manager is initialized/loaded (it should be since main awaited it)

    final lastTime = gameManager.lastSaveTime;
    if (lastTime != null) {
      final calculator = OfflineCalculator(ratePerSecond: 1); // 1 Gold/sec
      final rewards = calculator.calculateRewards(
        lastSaveTime: lastTime,
        currentTime: DateTime.now(),
      );

      if (rewards > 0) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => GameDialog(
            title: 'Welcome Back!',
            content: 'You were offline for a while.\nGained: $rewards Gold',
            confirmText: 'Claim',
            onConfirm: () {}, // No-op for now, just close
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      // We could add an AppBar if needed, or just custom HUD
      body: Stack(
        children: [
          // HUD Top Layer
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ResourceBar(
                  icon: Icons.monetization_on,
                  value: '1,250',
                  label: 'GOLD',
                ),
                ResourceBar(
                  icon: Icons.diamond,
                  value: '50',
                  color: Colors.cyan,
                ),
              ],
            ),
          ),

          // Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('LOBBY', style: AppTextStyles.header1),
                const SizedBox(height: 32),

                GameButton(
                  text: 'Start Game',
                  onPressed: () {
                    context.push('/game');
                    // Or show a dialog for testing
                    // GameDialog.confirm(
                    //   context: context,
                    //   title: 'Ready?',
                    //   content: 'Enter the battlefield?',
                    //   onConfirm: () => context.push('/game'),
                    // );
                  },
                  width: 200,
                ),
                const SizedBox(height: 16),

                GameButton(
                  text: 'Show Alert',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => GameDialog.alert(
                        context: context,
                        title: 'Notice',
                        content: 'This is a standardized alert dialog.',
                      ),
                    );
                  },
                  variant: GameButtonVariant.secondary,
                  width: 200,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
