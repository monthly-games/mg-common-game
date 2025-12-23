class OfflineCalculator {
  final double ratePerSecond;

  OfflineCalculator({required this.ratePerSecond});

  int calculateRewards(
      {required DateTime lastSaveTime, required DateTime currentTime}) {
    final difference = currentTime.difference(lastSaveTime);
    if (difference.isNegative) {
      return 0;
    }
    final seconds = difference.inSeconds;
    return (seconds * ratePerSecond).floor();
  }
}
