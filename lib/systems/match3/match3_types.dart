import 'package:flutter/material.dart';

/// Types of gems/tiles in match-3 games
enum GemType {
  red,
  blue,
  green,
  yellow,
  purple,
  orange,
  pink,
  white,
}

/// Special gem types
enum SpecialGemType {
  normal,
  bomb,           // Clears 3x3 area
  lightning,      // Clears row or column
  rainbow,        // Matches any color
  crossBomb,      // Clears row and column
}

/// Match direction
enum MatchDirection {
  horizontal,
  vertical,
  both,
}

/// Board cell position
class BoardPosition {
  final int row;
  final int col;

  const BoardPosition(this.row, this.col);

  BoardPosition operator +(BoardPosition other) {
    return BoardPosition(row + other.row, col + other.col);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BoardPosition && other.row == row && other.col == col;
  }

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => 'BoardPosition($row, $col)';

  /// Manhattan distance to another position
  int distanceTo(BoardPosition other) {
    return (row - other.row).abs() + (col - other.col).abs();
  }

  /// Check if adjacent to another position
  bool isAdjacentTo(BoardPosition other) {
    return distanceTo(other) == 1;
  }
}

/// A gem/tile on the board
class Gem {
  final String id;
  GemType type;
  SpecialGemType specialType;
  BoardPosition position;
  bool isMatched;
  bool isFalling;
  bool isSwapping;
  bool isSelected;

  Gem({
    required this.id,
    required this.type,
    required this.position,
    this.specialType = SpecialGemType.normal,
    this.isMatched = false,
    this.isFalling = false,
    this.isSwapping = false,
    this.isSelected = false,
  });

  /// Get color for this gem type
  Color get color {
    switch (type) {
      case GemType.red:
        return Colors.red;
      case GemType.blue:
        return Colors.blue;
      case GemType.green:
        return Colors.green;
      case GemType.yellow:
        return Colors.yellow;
      case GemType.purple:
        return Colors.purple;
      case GemType.orange:
        return Colors.orange;
      case GemType.pink:
        return Colors.pink;
      case GemType.white:
        return Colors.white;
    }
  }

  /// Check if this gem can match with another
  bool canMatchWith(Gem other) {
    if (specialType == SpecialGemType.rainbow ||
        other.specialType == SpecialGemType.rainbow) {
      return true;
    }
    return type == other.type;
  }

  /// Create a copy with updated position
  Gem copyWith({
    GemType? type,
    SpecialGemType? specialType,
    BoardPosition? position,
    bool? isMatched,
    bool? isFalling,
    bool? isSwapping,
    bool? isSelected,
  }) {
    return Gem(
      id: id,
      type: type ?? this.type,
      specialType: specialType ?? this.specialType,
      position: position ?? this.position,
      isMatched: isMatched ?? this.isMatched,
      isFalling: isFalling ?? this.isFalling,
      isSwapping: isSwapping ?? this.isSwapping,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  String toString() => 'Gem($id, $type, $position)';
}

/// A match result
class MatchResult {
  final List<Gem> matchedGems;
  final MatchDirection direction;
  final BoardPosition center;
  final int matchLength;
  final SpecialGemType? createdSpecial;

  MatchResult({
    required this.matchedGems,
    required this.direction,
    required this.center,
    required this.matchLength,
    this.createdSpecial,
  });

  /// Score for this match
  int get score {
    int base = matchLength * 10;
    if (matchLength >= 5) base *= 3;
    else if (matchLength >= 4) base *= 2;
    return base;
  }

  @override
  String toString() => 'MatchResult($matchLength $direction at $center)';
}

/// A cascade/combo result
class CascadeResult {
  final List<MatchResult> matches;
  final int cascadeLevel;
  final int totalScore;
  final int totalGemsCleared;

  CascadeResult({
    required this.matches,
    required this.cascadeLevel,
  })  : totalScore = matches.fold(0, (sum, m) => sum + m.score) * cascadeLevel,
        totalGemsCleared = matches.fold(0, (sum, m) => sum + m.matchedGems.length);

  @override
  String toString() => 'CascadeResult(level: $cascadeLevel, score: $totalScore)';
}

/// Swap result
class SwapResult {
  final bool isValid;
  final List<MatchResult> matches;
  final String? invalidReason;

  SwapResult({
    required this.isValid,
    this.matches = const [],
    this.invalidReason,
  });

  static SwapResult invalid(String reason) =>
      SwapResult(isValid: false, invalidReason: reason);

  static SwapResult valid(List<MatchResult> matches) =>
      SwapResult(isValid: true, matches: matches);
}

/// Power-up types for match-3 games
enum Match3PowerUp {
  shuffle,        // Shuffle all gems
  hammer,         // Remove single gem
  rowClear,       // Clear entire row
  columnClear,    // Clear entire column
  colorBomb,      // Remove all gems of one color
  extraMoves,     // Add extra moves
  extraTime,      // Add extra time
}

/// Level objective types
enum Match3ObjectiveType {
  score,          // Reach target score
  collectGems,    // Collect specific gem types
  clearBlockers,  // Clear special blockers
  dropItems,      // Drop items to bottom
  spreadFill,     // Fill area with color
}

/// Level objective
class Match3Objective {
  final Match3ObjectiveType type;
  final int targetAmount;
  final GemType? targetGemType;
  int currentAmount;

  Match3Objective({
    required this.type,
    required this.targetAmount,
    this.targetGemType,
    this.currentAmount = 0,
  });

  bool get isCompleted => currentAmount >= targetAmount;

  double get progress => currentAmount / targetAmount;

  void addProgress(int amount) {
    currentAmount = (currentAmount + amount).clamp(0, targetAmount);
  }

  Match3Objective copyWith({int? currentAmount}) {
    return Match3Objective(
      type: type,
      targetAmount: targetAmount,
      targetGemType: targetGemType,
      currentAmount: currentAmount ?? this.currentAmount,
    );
  }
}
