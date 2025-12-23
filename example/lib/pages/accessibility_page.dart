import 'package:flutter/material.dart';
import 'package:mg_common_game/core/ui/mg_ui.dart';

/// 접근성 쇼케이스 페이지
class AccessibilityPage extends StatelessWidget {
  const AccessibilityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('접근성')),
      body: Builder(
        builder: (context) {
          final provider = MGAccessibilityProvider.of(context);
          if (provider == null) {
            return const Center(child: Text('AccessibilityProvider not found'));
          }

          return MGAccessibilitySettingsScreen(
            initialSettings: provider.settings,
            onSettingsChanged: provider.onSettingsChanged,
          );
        },
      ),
    );
  }
}
