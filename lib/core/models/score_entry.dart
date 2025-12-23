class ScoreEntry {
  final String label;
  final int score;
  final String? iconAsset;
  final bool isHighlight; // e.g. New Record

  const ScoreEntry({
    required this.label,
    required this.score,
    this.iconAsset,
    this.isHighlight = false,
  });
}
