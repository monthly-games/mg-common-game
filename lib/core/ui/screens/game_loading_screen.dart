import 'package:flutter/material.dart';
import '../../loading/resource_loader.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../layouts/game_scaffold.dart';
import '../widgets/containers/game_panel.dart';

class GameLoadingScreen extends StatefulWidget {
  final List<String> images;
  final List<String> audio;
  final VoidCallback onFinished;
  final String? backgroundImage;
  final String loadingText;

  const GameLoadingScreen({
    super.key,
    required this.images,
    required this.audio,
    required this.onFinished,
    this.backgroundImage,
    this.loadingText = 'LOADING...',
  });

  @override
  State<GameLoadingScreen> createState() => _GameLoadingScreenState();
}

class _GameLoadingScreenState extends State<GameLoadingScreen> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  Future<void> _startLoading() async {
    final loader = ResourceLoader();
    loader.onProgress.listen((progress) {
      if (mounted) {
        setState(() {
          _progress = progress;
        });
      }
    });

    await loader.loadAssets(images: widget.images, audio: widget.audio);

    // Small delay to ensure 100% is seen
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      widget.onFinished();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      backgroundImage: widget.backgroundImage,
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Loading Text
            Text(
              widget.loadingText,
              style: AppTextStyles.header1.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 32),

            // Progress Bar Container
            SizedBox(
              width: 300,
              height: 24,
              child: GamePanel(
                padding: EdgeInsets.zero,
                child: Stack(
                  children: [
                    // Fill
                    FractionallySizedBox(
                      widthFactor: _progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withOpacity(0.5),
                              blurRadius: 10,
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              '${(_progress * 100).toInt()}%',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}
