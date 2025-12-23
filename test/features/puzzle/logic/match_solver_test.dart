import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/features/puzzle/logic/grid_manager.dart';
import 'package:mg_common_game/features/puzzle/logic/match_solver.dart';

void main() {
  late GridManager grid;
  late MatchSolver solver;

  setUp(() {
    solver = MatchSolver();
  });

  // Helper to fill grid row
  void fillRow(int y, List<String> types) {
    for (int x = 0; x < types.length; x++) {
      grid.getCell(x, y).type = types[x];
      grid.getCell(x, y).isEmpty = types[x].isEmpty;
    }
  }

  // Helper to fill grid col
  void fillCol(int x, List<String> types) {
    for (int y = 0; y < types.length; y++) {
      grid.getCell(x, y).type = types[y];
      grid.getCell(x, y).isEmpty = types[y].isEmpty;
    }
  }

  group('MatchSolver', () {
    test('Finds simple horizontal match-3', () {
      grid = GridManager(width: 5, height: 5);
      // R R R B G
      fillRow(0, ['R', 'R', 'R', 'B', 'G']);

      final matches = solver.findMatches(grid);
      expect(matches.length, 1);
      expect(matches[0].cells.length, 3);
      expect(matches[0].type, 'R');
    });

    test('Finds simple vertical match-3', () {
      grid = GridManager(width: 5, height: 5);
      // R
      // R
      // R
      // B
      // G
      fillCol(0, ['R', 'R', 'R', 'B', 'G']);

      final matches = solver.findMatches(grid);
      expect(matches.length, 1);
      expect(matches[0].cells.length, 3);
      expect(matches[0].type, 'R');
    });

    test('Finds no matches', () {
      grid = GridManager(width: 3, height: 3);
      fillRow(0, ['A', 'B', 'C']);
      fillRow(1, ['C', 'A', 'B']);
      fillRow(2, ['B', 'C', 'A']);

      final matches = solver.findMatches(grid);
      expect(matches, isEmpty);
    });

    test('Intersecting Match (L-Shape) - Should merge or identify both', () {
      // Current behavior might separate them, improved behavior should ideally merge or at least find both.
      grid = GridManager(width: 5, height: 5);
      // R R R
      // R
      // R
      grid.getCell(0, 0).type = 'R';
      grid.getCell(0, 0).isEmpty = false;
      grid.getCell(1, 0).type = 'R';
      grid.getCell(1, 0).isEmpty = false;
      grid.getCell(2, 0).type = 'R';
      grid.getCell(2, 0).isEmpty = false;

      grid.getCell(0, 1).type = 'R';
      grid.getCell(0, 1).isEmpty = false;
      grid.getCell(0, 2).type = 'R';
      grid.getCell(0, 2).isEmpty = false;

      final matches = solver.findMatches(grid);

      // With improved logic: Should be 1 combined match
      expect(matches.length, 1);

      final totalCells = matches.fold<int>(0, (sum, m) => sum + m.cells.length);
      // 3 horiz + 3 vert sharing 1 center = 5 unique cells
      expect(totalCells, 5);
    });

    test('Finds match-4', () {
      grid = GridManager(width: 5, height: 5);
      fillRow(0, ['B', 'B', 'B', 'B', 'G']);

      final matches = solver.findMatches(grid);
      expect(matches.length, 1);
      expect(matches[0].cells.length, 4);
    });
  });
}
