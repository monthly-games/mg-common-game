import 'package:mg_common_game/features/puzzle/logic/grid_manager.dart';

class PuzzleMatch {
  final String type;
  final List<GridCell> cells;

  PuzzleMatch(this.type, this.cells);
}

class MatchSolver {
  final int minMatch;

  MatchSolver({this.minMatch = 3});

  List<PuzzleMatch> findMatches(GridManager grid) {
    // 1. Find all horizontal and vertical runs first
    final horizontalMatches = <PuzzleMatch>[];
    final verticalMatches = <PuzzleMatch>[];

    // Horizontal Checks
    for (int y = 0; y < grid.height; y++) {
      var currentRun = <GridCell>[];
      for (int x = 0; x < grid.width; x++) {
        final cell = grid.getCell(x, y);
        if (_shouldContinueRun(currentRun, cell)) {
          currentRun.add(cell);
        } else {
          if (currentRun.length >= minMatch) {
            horizontalMatches
                .add(PuzzleMatch(currentRun.first.type, List.from(currentRun)));
          }
          currentRun = [];
          if (!cell.isEmpty && cell.type.isNotEmpty) {
            currentRun.add(cell);
          }
        }
      }
      if (currentRun.length >= minMatch) {
        horizontalMatches
            .add(PuzzleMatch(currentRun.first.type, List.from(currentRun)));
      }
    }

    // Vertical Checks
    for (int x = 0; x < grid.width; x++) {
      var currentRun = <GridCell>[];
      for (int y = 0; y < grid.height; y++) {
        final cell = grid.getCell(x, y);
        if (_shouldContinueRun(currentRun, cell)) {
          currentRun.add(cell);
        } else {
          if (currentRun.length >= minMatch) {
            verticalMatches
                .add(PuzzleMatch(currentRun.first.type, List.from(currentRun)));
          }
          currentRun = [];
          if (!cell.isEmpty && cell.type.isNotEmpty) {
            currentRun.add(cell);
          }
        }
      }
      if (currentRun.length >= minMatch) {
        verticalMatches
            .add(PuzzleMatch(currentRun.first.type, List.from(currentRun)));
      }
    }

    // 2. Merge intersecting matches
    return _mergeMatches([...horizontalMatches, ...verticalMatches]);
  }

  List<PuzzleMatch> _mergeMatches(List<PuzzleMatch> rawMatches) {
    if (rawMatches.isEmpty) return [];

    // Simple clustering: if two matches share any specific cell *instance*, merge them.
    // Since GridCell is an object, equality check works by reference.

    // Convert to sets of cells for easier checking?
    // Actually, we can use a disjoint set (union-find) or simple iterative merging.
    // Iterative merging is easier to reason about for small N.

    final merged = <PuzzleMatch>[];

    // Copy list to avoid modifying original while iterating?
    // Let's use a "visited" set of rawMatches indices or just consume them.
    var pending = List<PuzzleMatch>.from(rawMatches);

    while (pending.isNotEmpty) {
      var current = pending.removeAt(0);
      var currentCells = current.cells.toSet();
      var changed = true;

      while (changed) {
        changed = false;
        // Check if any other pending match intersects with current
        // Intersection means sharing at least one cell AND having the same type
        // (Type should be same by definition if cells are shared, but good to be safe)

        for (int i = 0; i < pending.length; i++) {
          final candidate = pending[i];
          if (candidate.type != current.type) continue;

          final candidateCells = candidate.cells.toSet();
          if (currentCells.intersection(candidateCells).isNotEmpty) {
            // Merge
            currentCells.addAll(candidateCells);
            pending.removeAt(i);
            changed = true;
            break; // Restart loop since pending changed
          }
        }
      }
      merged.add(PuzzleMatch(current.type, currentCells.toList()));
    }

    return merged;
  }

  bool _shouldContinueRun(List<GridCell> run, GridCell current) {
    if (current.isEmpty || current.type.isEmpty) return false;
    if (run.isEmpty) return true; // Start new run
    return run.last.type == current.type;
  }
}
