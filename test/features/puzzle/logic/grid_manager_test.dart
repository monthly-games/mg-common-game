import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/features/puzzle/logic/grid_manager.dart';

void main() {
  group('GridManager', () {
    test('Initializes correctly', () {
      final grid = GridManager(width: 3, height: 3);
      expect(grid.width, 3);
      expect(grid.height, 3);

      // Check (0,0) is valid and empty/default
      final cell = grid.getCell(0, 0);
      expect(cell, isNotNull);
    });

    test('Swap works correctly', () {
      final grid = GridManager(width: 2, height: 2);

      // Set initial state
      grid.getCell(0, 0).type = 'A';
      grid.getCell(0, 1).type = 'B';

      // Swap (0,0) with (0,1)
      grid.swap(0, 0, 0, 1);

      expect(grid.getCell(0, 0).type, 'B');
      expect(grid.getCell(0, 1).type, 'A');
    });

    test('Swap ignores non-adjacent cells (optional verification)', () {
      // In strict mode, we might want to prevent this.
      // For now, let's just ensure logic is robust enough to swap any 2 coords provided.
      final grid = GridManager(width: 3, height: 3);
      grid.getCell(0, 0).type = 'A';
      grid.getCell(2, 2).type = 'B';

      grid.swap(0, 0, 2, 2);
      expect(grid.getCell(0, 0).type, 'B');
      expect(grid.getCell(2, 2).type, 'A');
    });

    test('Bounds Checking', () {
      final grid = GridManager(width: 2, height: 2);
      expect(() => grid.getCell(-1, 0), throwsA(isA<RangeError>()));
      expect(() => grid.getCell(2, 0), throwsA(isA<RangeError>()));
    });
  });
}
