/// Represents a single cell on the board.
/// [type] is used for matching logic (e.g. "red", "blue", "sword").
/// [data] is for extra game-specific properties (e.g. "frozen", "hp").
class GridCell {
  final int x;
  final int y;
  String type;
  bool isEmpty;
  Map<String, dynamic> data;

  GridCell({
    required this.x,
    required this.y,
    this.type = '',
    this.isEmpty = true,
    this.data = const {},
  });

  void clear() {
    type = '';
    isEmpty = true;
    data = {};
  }
}

/// Manages a 2D grid of [GridCell]s.
/// Generic enough for Match-3, Merge, or even Turn-based Tactics board.
class GridManager {
  final int width;
  final int height;
  late final List<List<GridCell>> _cells;

  GridManager({required this.width, required this.height}) {
    _cells = List.generate(
      height,
      (y) => List.generate(
        width,
        (x) => GridCell(x: x, y: y),
      ),
    );
  }

  /// Access a cell safely. Throws [RangeError] if out of bounds.
  GridCell getCell(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) {
      throw RangeError(
          'Grid coordinates ($x, $y) out of bounds ($width, $height)');
    }
    return _cells[y][x];
  }

  /// Swaps contents of two cells.
  /// Does validation of bounds (via getCell) but NOT adjacency rules.
  /// Adjacency checks should be done by the specifics Game Logic or Input Handler.
  void swap(int x1, int y1, int x2, int y2) {
    final cellA = getCell(x1, y1);
    final cellB = getCell(x2, y2);

    final tempType = cellA.type;
    final tempEmpty = cellA.isEmpty;
    final tempData = cellA.data;

    cellA.type = cellB.type;
    cellA.isEmpty = cellB.isEmpty;
    cellA.data = cellB.data;

    cellB.type = tempType;
    cellB.isEmpty = tempEmpty;
    cellB.data = tempData;
  }

  // Future extensibility:
  // - shiftDown() for gravity
  // - fillRandom()
}
