import 'dart:math';
import 'package:flutter/material.dart';
import 'match3_types.dart';

/// Callback types
typedef MatchCallback = void Function(MatchResult match);
typedef CascadeCallback = void Function(CascadeResult cascade);
typedef SwapCallback = void Function(Gem gem1, Gem gem2, bool isValid);

/// Match-3 game board manager
class Match3Board extends ChangeNotifier {
  final int rows;
  final int cols;
  final List<GemType> availableTypes;
  final Random _random = Random();

  late List<List<Gem?>> _board;
  int _gemIdCounter = 0;
  bool _isProcessing = false;
  int _currentCascade = 0;

  // Callbacks
  MatchCallback? onMatch;
  CascadeCallback? onCascade;
  SwapCallback? onSwap;
  VoidCallback? onBoardStable;

  // Stats
  int totalMatches = 0;
  int totalCascades = 0;
  int maxCascade = 0;
  int totalScore = 0;

  Match3Board({
    this.rows = 8,
    this.cols = 8,
    this.availableTypes = const [
      GemType.red,
      GemType.blue,
      GemType.green,
      GemType.yellow,
      GemType.purple,
    ],
  }) {
    _initializeBoard();
  }

  /// Get current board state
  List<List<Gem?>> get board => _board;

  /// Check if board is processing matches
  bool get isProcessing => _isProcessing;

  /// Get gem at position
  Gem? getGem(BoardPosition pos) {
    if (!isValidPosition(pos)) return null;
    return _board[pos.row][pos.col];
  }

  /// Check if position is valid
  bool isValidPosition(BoardPosition pos) {
    return pos.row >= 0 && pos.row < rows && pos.col >= 0 && pos.col < cols;
  }

  // ============================================================
  // Board Initialization
  // ============================================================

  void _initializeBoard() {
    _board = List.generate(
      rows,
      (row) => List.generate(
        cols,
        (col) => _createRandomGem(BoardPosition(row, col)),
      ),
    );

    // Ensure no initial matches
    _removeInitialMatches();
  }

  Gem _createRandomGem(BoardPosition position) {
    final type = availableTypes[_random.nextInt(availableTypes.length)];
    return Gem(
      id: 'gem_${_gemIdCounter++}',
      type: type,
      position: position,
    );
  }

  void _removeInitialMatches() {
    bool hasMatches = true;
    int iterations = 0;
    const maxIterations = 1000;

    while (hasMatches && iterations < maxIterations) {
      hasMatches = false;
      iterations++;

      for (int row = 0; row < rows; row++) {
        for (int col = 0; col < cols; col++) {
          final pos = BoardPosition(row, col);
          final gem = getGem(pos);
          if (gem == null) continue;

          // Check horizontal match
          if (col >= 2) {
            final gem1 = getGem(BoardPosition(row, col - 1));
            final gem2 = getGem(BoardPosition(row, col - 2));
            if (gem1 != null && gem2 != null &&
                gem.type == gem1.type && gem.type == gem2.type) {
              _board[row][col] = _createNonMatchingGem(pos);
              hasMatches = true;
            }
          }

          // Check vertical match
          if (row >= 2) {
            final gem1 = getGem(BoardPosition(row - 1, col));
            final gem2 = getGem(BoardPosition(row - 2, col));
            if (gem1 != null && gem2 != null &&
                gem.type == gem1.type && gem.type == gem2.type) {
              _board[row][col] = _createNonMatchingGem(pos);
              hasMatches = true;
            }
          }
        }
      }
    }
  }

  Gem _createNonMatchingGem(BoardPosition position) {
    final excludeTypes = <GemType>{};

    // Check left neighbors
    if (position.col >= 2) {
      final gem1 = getGem(BoardPosition(position.row, position.col - 1));
      final gem2 = getGem(BoardPosition(position.row, position.col - 2));
      if (gem1 != null && gem2 != null && gem1.type == gem2.type) {
        excludeTypes.add(gem1.type);
      }
    }

    // Check top neighbors
    if (position.row >= 2) {
      final gem1 = getGem(BoardPosition(position.row - 1, position.col));
      final gem2 = getGem(BoardPosition(position.row - 2, position.col));
      if (gem1 != null && gem2 != null && gem1.type == gem2.type) {
        excludeTypes.add(gem1.type);
      }
    }

    final validTypes = availableTypes.where((t) => !excludeTypes.contains(t)).toList();
    if (validTypes.isEmpty) {
      return _createRandomGem(position);
    }

    final type = validTypes[_random.nextInt(validTypes.length)];
    return Gem(
      id: 'gem_${_gemIdCounter++}',
      type: type,
      position: position,
    );
  }

  // ============================================================
  // Swap Logic
  // ============================================================

  /// Attempt to swap two gems
  Future<SwapResult> trySwap(BoardPosition pos1, BoardPosition pos2) async {
    if (_isProcessing) {
      return SwapResult.invalid('Board is processing');
    }

    if (!pos1.isAdjacentTo(pos2)) {
      return SwapResult.invalid('Gems are not adjacent');
    }

    final gem1 = getGem(pos1);
    final gem2 = getGem(pos2);

    if (gem1 == null || gem2 == null) {
      return SwapResult.invalid('Invalid gem position');
    }

    // Perform swap
    _performSwap(gem1, gem2);

    // Check for matches
    final matches = _findAllMatches();

    if (matches.isEmpty) {
      // Swap back
      _performSwap(gem2, gem1);
      onSwap?.call(gem1, gem2, false);
      return SwapResult.invalid('No matches found');
    }

    onSwap?.call(gem1, gem2, true);

    // Process matches
    await _processMatches(matches);

    return SwapResult.valid(matches);
  }

  void _performSwap(Gem gem1, Gem gem2) {
    final pos1 = gem1.position;
    final pos2 = gem2.position;

    gem1.isSwapping = true;
    gem2.isSwapping = true;

    _board[pos1.row][pos1.col] = gem2.copyWith(position: pos1);
    _board[pos2.row][pos2.col] = gem1.copyWith(position: pos2);

    notifyListeners();
  }

  // ============================================================
  // Match Detection
  // ============================================================

  List<MatchResult> _findAllMatches() {
    final matches = <MatchResult>[];
    final visited = <String>{};

    // Find horizontal matches
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols - 2; col++) {
        final match = _findHorizontalMatch(BoardPosition(row, col), visited);
        if (match != null) matches.add(match);
      }
    }

    // Find vertical matches
    for (int row = 0; row < rows - 2; row++) {
      for (int col = 0; col < cols; col++) {
        final match = _findVerticalMatch(BoardPosition(row, col), visited);
        if (match != null) matches.add(match);
      }
    }

    return matches;
  }

  MatchResult? _findHorizontalMatch(BoardPosition start, Set<String> visited) {
    final startGem = getGem(start);
    if (startGem == null) return null;

    final matchedGems = <Gem>[startGem];
    int col = start.col + 1;

    while (col < cols) {
      final gem = getGem(BoardPosition(start.row, col));
      if (gem == null || !startGem.canMatchWith(gem)) break;
      matchedGems.add(gem);
      col++;
    }

    if (matchedGems.length < 3) return null;

    // Check if already visited
    final key = matchedGems.map((g) => g.id).join(',');
    if (visited.contains(key)) return null;
    visited.add(key);

    // Determine special gem creation
    SpecialGemType? special;
    if (matchedGems.length >= 5) {
      special = SpecialGemType.rainbow;
    } else if (matchedGems.length >= 4) {
      special = SpecialGemType.lightning;
    }

    return MatchResult(
      matchedGems: matchedGems,
      direction: MatchDirection.horizontal,
      center: BoardPosition(start.row, start.col + matchedGems.length ~/ 2),
      matchLength: matchedGems.length,
      createdSpecial: special,
    );
  }

  MatchResult? _findVerticalMatch(BoardPosition start, Set<String> visited) {
    final startGem = getGem(start);
    if (startGem == null) return null;

    final matchedGems = <Gem>[startGem];
    int row = start.row + 1;

    while (row < rows) {
      final gem = getGem(BoardPosition(row, start.col));
      if (gem == null || !startGem.canMatchWith(gem)) break;
      matchedGems.add(gem);
      row++;
    }

    if (matchedGems.length < 3) return null;

    // Check if already visited
    final key = matchedGems.map((g) => g.id).join(',');
    if (visited.contains(key)) return null;
    visited.add(key);

    // Determine special gem creation
    SpecialGemType? special;
    if (matchedGems.length >= 5) {
      special = SpecialGemType.rainbow;
    } else if (matchedGems.length >= 4) {
      special = SpecialGemType.lightning;
    }

    return MatchResult(
      matchedGems: matchedGems,
      direction: MatchDirection.vertical,
      center: BoardPosition(start.row + matchedGems.length ~/ 2, start.col),
      matchLength: matchedGems.length,
      createdSpecial: special,
    );
  }

  // ============================================================
  // Match Processing
  // ============================================================

  Future<void> _processMatches(List<MatchResult> matches) async {
    _isProcessing = true;
    _currentCascade = 1;

    while (matches.isNotEmpty) {
      // Mark gems as matched
      for (final match in matches) {
        for (final gem in match.matchedGems) {
          final boardGem = getGem(gem.position);
          if (boardGem != null) {
            _board[gem.position.row][gem.position.col] =
                boardGem.copyWith(isMatched: true);
          }
        }
        totalMatches++;
        onMatch?.call(match);
      }

      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 200));

      // Remove matched gems
      _removeMatchedGems(matches);
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 100));

      // Create special gems if needed
      for (final match in matches) {
        if (match.createdSpecial != null) {
          _createSpecialGem(match.center, match.createdSpecial!,
              match.matchedGems.first.type);
        }
      }

      // Drop gems and fill
      await _dropAndFill();

      // Calculate cascade score
      final cascade = CascadeResult(
        matches: matches,
        cascadeLevel: _currentCascade,
      );
      totalScore += cascade.totalScore;
      onCascade?.call(cascade);

      // Check for new matches
      matches = _findAllMatches();
      if (matches.isNotEmpty) {
        _currentCascade++;
        totalCascades++;
        if (_currentCascade > maxCascade) {
          maxCascade = _currentCascade;
        }
      }
    }

    _isProcessing = false;
    onBoardStable?.call();
    notifyListeners();
  }

  void _removeMatchedGems(List<MatchResult> matches) {
    for (final match in matches) {
      for (final gem in match.matchedGems) {
        _board[gem.position.row][gem.position.col] = null;
      }
    }
  }

  void _createSpecialGem(BoardPosition pos, SpecialGemType special, GemType type) {
    _board[pos.row][pos.col] = Gem(
      id: 'gem_${_gemIdCounter++}',
      type: type,
      position: pos,
      specialType: special,
    );
  }

  Future<void> _dropAndFill() async {
    bool hasMoved = true;

    while (hasMoved) {
      hasMoved = false;

      // Drop existing gems
      for (int col = 0; col < cols; col++) {
        for (int row = rows - 1; row >= 0; row--) {
          if (_board[row][col] == null) {
            // Find gem to drop
            for (int aboveRow = row - 1; aboveRow >= 0; aboveRow--) {
              if (_board[aboveRow][col] != null) {
                _board[row][col] = _board[aboveRow][col]!.copyWith(
                  position: BoardPosition(row, col),
                  isFalling: true,
                );
                _board[aboveRow][col] = null;
                hasMoved = true;
                break;
              }
            }
          }
        }
      }

      // Fill from top
      for (int col = 0; col < cols; col++) {
        for (int row = 0; row < rows; row++) {
          if (_board[row][col] == null) {
            _board[row][col] = _createNonMatchingGem(BoardPosition(row, col));
            _board[row][col] = _board[row][col]!.copyWith(isFalling: true);
            hasMoved = true;
          }
        }
      }

      if (hasMoved) {
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    // Clear falling flags
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final gem = _board[row][col];
        if (gem != null && gem.isFalling) {
          _board[row][col] = gem.copyWith(isFalling: false);
        }
      }
    }
  }

  // ============================================================
  // Power-ups and Utilities
  // ============================================================

  /// Shuffle all gems
  void shuffle() {
    final gems = <Gem>[];

    // Collect all gems
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final gem = _board[row][col];
        if (gem != null) gems.add(gem);
      }
    }

    // Shuffle
    gems.shuffle(_random);

    // Redistribute
    int index = 0;
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        if (index < gems.length) {
          _board[row][col] = gems[index].copyWith(
            position: BoardPosition(row, col),
          );
          index++;
        }
      }
    }

    _removeInitialMatches();
    notifyListeners();
  }

  /// Remove a single gem (hammer power-up)
  void removeGem(BoardPosition pos) {
    if (!isValidPosition(pos)) return;

    _board[pos.row][pos.col] = null;
    notifyListeners();

    _dropAndFill().then((_) {
      final matches = _findAllMatches();
      if (matches.isNotEmpty) {
        _processMatches(matches);
      }
    });
  }

  /// Clear an entire row
  void clearRow(int row) {
    if (row < 0 || row >= rows) return;

    for (int col = 0; col < cols; col++) {
      _board[row][col] = null;
    }
    notifyListeners();

    _dropAndFill().then((_) {
      final matches = _findAllMatches();
      if (matches.isNotEmpty) {
        _processMatches(matches);
      }
    });
  }

  /// Clear an entire column
  void clearColumn(int col) {
    if (col < 0 || col >= cols) return;

    for (int row = 0; row < rows; row++) {
      _board[row][col] = null;
    }
    notifyListeners();

    _dropAndFill().then((_) {
      final matches = _findAllMatches();
      if (matches.isNotEmpty) {
        _processMatches(matches);
      }
    });
  }

  /// Clear all gems of a specific type
  void clearGemType(GemType type) {
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final gem = _board[row][col];
        if (gem != null && gem.type == type) {
          _board[row][col] = null;
        }
      }
    }
    notifyListeners();

    _dropAndFill().then((_) {
      final matches = _findAllMatches();
      if (matches.isNotEmpty) {
        _processMatches(matches);
      }
    });
  }

  /// Check if any moves are available
  bool hasAvailableMoves() {
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final pos = BoardPosition(row, col);

        // Check swap with right neighbor
        if (col < cols - 1) {
          if (_wouldCreateMatch(pos, BoardPosition(row, col + 1))) {
            return true;
          }
        }

        // Check swap with bottom neighbor
        if (row < rows - 1) {
          if (_wouldCreateMatch(pos, BoardPosition(row + 1, col))) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool _wouldCreateMatch(BoardPosition pos1, BoardPosition pos2) {
    final gem1 = getGem(pos1);
    final gem2 = getGem(pos2);
    if (gem1 == null || gem2 == null) return false;

    // Temporarily swap
    _board[pos1.row][pos1.col] = gem2.copyWith(position: pos1);
    _board[pos2.row][pos2.col] = gem1.copyWith(position: pos2);

    // Check for matches
    final hasMatch = _checkMatchAt(pos1) || _checkMatchAt(pos2);

    // Swap back
    _board[pos1.row][pos1.col] = gem1;
    _board[pos2.row][pos2.col] = gem2;

    return hasMatch;
  }

  bool _checkMatchAt(BoardPosition pos) {
    final gem = getGem(pos);
    if (gem == null) return false;

    // Check horizontal
    int count = 1;
    int col = pos.col - 1;
    while (col >= 0 && getGem(BoardPosition(pos.row, col))?.canMatchWith(gem) == true) {
      count++;
      col--;
    }
    col = pos.col + 1;
    while (col < cols && getGem(BoardPosition(pos.row, col))?.canMatchWith(gem) == true) {
      count++;
      col++;
    }
    if (count >= 3) return true;

    // Check vertical
    count = 1;
    int row = pos.row - 1;
    while (row >= 0 && getGem(BoardPosition(row, pos.col))?.canMatchWith(gem) == true) {
      count++;
      row--;
    }
    row = pos.row + 1;
    while (row < rows && getGem(BoardPosition(row, pos.col))?.canMatchWith(gem) == true) {
      count++;
      row++;
    }
    if (count >= 3) return true;

    return false;
  }

  /// Get hint (find a valid move)
  (BoardPosition, BoardPosition)? getHint() {
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final pos = BoardPosition(row, col);

        if (col < cols - 1) {
          final pos2 = BoardPosition(row, col + 1);
          if (_wouldCreateMatch(pos, pos2)) {
            return (pos, pos2);
          }
        }

        if (row < rows - 1) {
          final pos2 = BoardPosition(row + 1, col);
          if (_wouldCreateMatch(pos, pos2)) {
            return (pos, pos2);
          }
        }
      }
    }
    return null;
  }

  /// Reset board
  void reset() {
    totalMatches = 0;
    totalCascades = 0;
    maxCascade = 0;
    totalScore = 0;
    _currentCascade = 0;
    _isProcessing = false;
    _initializeBoard();
    notifyListeners();
  }

  /// Get gem count by type
  Map<GemType, int> getGemCounts() {
    final counts = <GemType, int>{};
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final gem = _board[row][col];
        if (gem != null) {
          counts[gem.type] = (counts[gem.type] ?? 0) + 1;
        }
      }
    }
    return counts;
  }
}
