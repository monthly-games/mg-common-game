import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GameScaffold extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? appBar;
  final Color backgroundColor;
  final String? backgroundImage; // Asset path for background image
  final bool useSafeArea;

  const GameScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.appBar,
    this.backgroundColor = AppColors.background,
    this.backgroundImage,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = body;

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image Layer
          if (backgroundImage != null)
            Image.asset(
              backgroundImage!,
              fit: BoxFit.cover,
            ),

          // Main Body
          content,
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
