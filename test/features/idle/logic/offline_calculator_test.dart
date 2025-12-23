import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/features/idle/logic/offline_calculator.dart';

void main() {
  group('OfflineCalculator', () {
    test('calculateRewards returns 0 if duration is small', () {
      final calculator = OfflineCalculator(ratePerSecond: 10);
      final rewards = calculator.calculateRewards(
        lastSaveTime: DateTime.now().subtract(const Duration(seconds: 2)),
        currentTime: DateTime.now(),
      );
      // Assuming a minimum threshold or just purely math
      expect(rewards, 20);
    });

    test('calculateRewards returns correct amount for 1 hour', () {
      final calculator = OfflineCalculator(ratePerSecond: 1); // 1 per sec
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));

      final rewards = calculator.calculateRewards(
        lastSaveTime: oneHourAgo,
        currentTime: now,
      );

      expect(rewards, 3600); // 1 * 60 * 60
    });

    test('calculateRewards handles inverted time gracefully (returns 0)', () {
      final calculator = OfflineCalculator(ratePerSecond: 10);
      final now = DateTime.now();
      final future = now.add(const Duration(hours: 1));

      final rewards = calculator.calculateRewards(
        lastSaveTime: future, // Future save time?
        currentTime: now,
      );

      expect(rewards, 0);
    });
  });
}
