import 'package:flutter/material.dart';
import '../../ui/theme/app_colors.dart';
import '../../models/score_entry.dart';

class LeaderboardScreen extends StatelessWidget {
  final String title;
  final List<ScoreEntry> scores;
  final VoidCallback? onReset;
  final VoidCallback onClose;

  const LeaderboardScreen({
    super.key,
    required this.title,
    required this.scores,
    required this.onClose,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: onClose,
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textHighEmphasis,
                      shadows: [
                        Shadow(
                          offset: Offset(2, 2),
                          blurRadius: 4,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                  // Spacer to center title if onClose is left
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: scores.isEmpty
                    ? const Center(
                        child: Text(
                          'No Scores Yet!',
                          style: TextStyle(
                            color: AppColors.textMediumEmphasis,
                            fontSize: 20,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: scores.length,
                        separatorBuilder: (_, __) => const Divider(
                          color: AppColors.secondary,
                          thickness: 0.5,
                        ),
                        itemBuilder: (context, index) {
                          final entry = scores[index];
                          return ListTile(
                            leading: entry.iconAsset != null
                                ? Image.asset(entry.iconAsset!,
                                    width: 40, height: 40)
                                : const Icon(Icons.star,
                                    color: Colors.amber, size: 32),
                            title: Text(
                              entry.label,
                              style: const TextStyle(
                                color: AppColors.textHighEmphasis,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Text(
                              '${entry.score}',
                              style: TextStyle(
                                color: entry.isHighlight
                                    ? Colors.yellowAccent
                                    : AppColors.primary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),

            if (onReset != null)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: TextButton.icon(
                  onPressed: () => _confirmReset(context),
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  label: const Text(
                    'Reset High Scores',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Reset High Scores?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onReset?.call();
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
