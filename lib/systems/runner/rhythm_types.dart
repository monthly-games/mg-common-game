import 'package:flutter/material.dart';

/// Note types for rhythm games
enum RhythmNoteType {
  tap,        // Single tap
  hold,       // Hold for duration
  swipeUp,    // Swipe up
  swipeDown,  // Swipe down
  swipeLeft,  // Swipe left
  swipeRight, // Swipe right
  multiTap,   // Multiple simultaneous taps
}

/// Judgment result
enum RhythmJudgment {
  perfect,    // Exact timing
  great,      // Slightly off
  good,       // Acceptable
  bad,        // Poor timing
  miss,       // Completely missed
}

/// Lane for notes (1-4 lanes typical)
typedef RhythmLane = int;

/// A rhythm note
class RhythmNote {
  final String id;
  final RhythmNoteType type;
  final RhythmLane lane;
  final double hitTime;       // Time in seconds when note should be hit
  final double? holdDuration; // For hold notes
  final double? endTime;      // For hold notes

  RhythmJudgment? judgment;
  bool isHit;
  bool isMissed;
  double? hitAt;

  RhythmNote({
    required this.id,
    required this.type,
    required this.lane,
    required this.hitTime,
    this.holdDuration,
    this.endTime,
    this.judgment,
    this.isHit = false,
    this.isMissed = false,
    this.hitAt,
  });

  bool get isHoldNote => type == RhythmNoteType.hold;
  bool get isSwipeNote => type == RhythmNoteType.swipeUp ||
      type == RhythmNoteType.swipeDown ||
      type == RhythmNoteType.swipeLeft ||
      type == RhythmNoteType.swipeRight;

  RhythmNote copyWith({
    RhythmJudgment? judgment,
    bool? isHit,
    bool? isMissed,
    double? hitAt,
  }) {
    return RhythmNote(
      id: id,
      type: type,
      lane: lane,
      hitTime: hitTime,
      holdDuration: holdDuration,
      endTime: endTime,
      judgment: judgment ?? this.judgment,
      isHit: isHit ?? this.isHit,
      isMissed: isMissed ?? this.isMissed,
      hitAt: hitAt ?? this.hitAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'lane': lane,
      'hitTime': hitTime,
      'holdDuration': holdDuration,
      'endTime': endTime,
    };
  }

  factory RhythmNote.fromJson(Map<String, dynamic> json, String id) {
    return RhythmNote(
      id: id,
      type: RhythmNoteType.values[json['type'] as int],
      lane: json['lane'] as int,
      hitTime: (json['hitTime'] as num).toDouble(),
      holdDuration: (json['holdDuration'] as num?)?.toDouble(),
      endTime: (json['endTime'] as num?)?.toDouble(),
    );
  }
}

/// Judgment timing windows (in seconds)
class RhythmTimingWindow {
  final double perfect;
  final double great;
  final double good;
  final double bad;

  const RhythmTimingWindow({
    this.perfect = 0.05,   // ±50ms
    this.great = 0.1,      // ±100ms
    this.good = 0.15,      // ±150ms
    this.bad = 0.2,        // ±200ms
  });

  RhythmJudgment getJudgment(double timeDiff) {
    final diff = timeDiff.abs();
    if (diff <= perfect) return RhythmJudgment.perfect;
    if (diff <= great) return RhythmJudgment.great;
    if (diff <= good) return RhythmJudgment.good;
    if (diff <= bad) return RhythmJudgment.bad;
    return RhythmJudgment.miss;
  }

  static const RhythmTimingWindow easy = RhythmTimingWindow(
    perfect: 0.08,
    great: 0.15,
    good: 0.25,
    bad: 0.35,
  );

  static const RhythmTimingWindow normal = RhythmTimingWindow();

  static const RhythmTimingWindow hard = RhythmTimingWindow(
    perfect: 0.03,
    great: 0.07,
    good: 0.12,
    bad: 0.18,
  );
}

/// Score multipliers for judgments
class RhythmScoreMultiplier {
  static const Map<RhythmJudgment, double> multipliers = {
    RhythmJudgment.perfect: 1.0,
    RhythmJudgment.great: 0.8,
    RhythmJudgment.good: 0.5,
    RhythmJudgment.bad: 0.25,
    RhythmJudgment.miss: 0.0,
  };

  static double get(RhythmJudgment judgment) {
    return multipliers[judgment] ?? 0.0;
  }
}

/// Session stats for rhythm game
class RhythmSessionStats {
  int perfectCount;
  int greatCount;
  int goodCount;
  int badCount;
  int missCount;
  int maxCombo;
  int currentCombo;
  int totalScore;
  int totalNotes;

  RhythmSessionStats({
    this.perfectCount = 0,
    this.greatCount = 0,
    this.goodCount = 0,
    this.badCount = 0,
    this.missCount = 0,
    this.maxCombo = 0,
    this.currentCombo = 0,
    this.totalScore = 0,
    this.totalNotes = 0,
  });

  int get hitCount => perfectCount + greatCount + goodCount + badCount;
  int get totalCount => hitCount + missCount;

  double get accuracy {
    if (totalCount == 0) return 0;
    return (perfectCount * 1.0 +
            greatCount * 0.8 +
            goodCount * 0.5 +
            badCount * 0.25) /
        totalCount;
  }

  String get rank {
    final acc = accuracy;
    if (acc >= 0.98) return 'SSS';
    if (acc >= 0.95) return 'SS';
    if (acc >= 0.90) return 'S';
    if (acc >= 0.85) return 'A';
    if (acc >= 0.75) return 'B';
    if (acc >= 0.60) return 'C';
    if (acc >= 0.40) return 'D';
    return 'F';
  }

  void recordJudgment(RhythmJudgment judgment) {
    switch (judgment) {
      case RhythmJudgment.perfect:
        perfectCount++;
        currentCombo++;
        break;
      case RhythmJudgment.great:
        greatCount++;
        currentCombo++;
        break;
      case RhythmJudgment.good:
        goodCount++;
        currentCombo++;
        break;
      case RhythmJudgment.bad:
        badCount++;
        currentCombo = 0;
        break;
      case RhythmJudgment.miss:
        missCount++;
        currentCombo = 0;
        break;
    }

    if (currentCombo > maxCombo) {
      maxCombo = currentCombo;
    }
  }

  void reset() {
    perfectCount = 0;
    greatCount = 0;
    goodCount = 0;
    badCount = 0;
    missCount = 0;
    maxCombo = 0;
    currentCombo = 0;
    totalScore = 0;
    totalNotes = 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'perfectCount': perfectCount,
      'greatCount': greatCount,
      'goodCount': goodCount,
      'badCount': badCount,
      'missCount': missCount,
      'maxCombo': maxCombo,
      'totalScore': totalScore,
      'totalNotes': totalNotes,
      'accuracy': accuracy,
      'rank': rank,
    };
  }
}

/// Song/chart metadata
class RhythmSongInfo {
  final String id;
  final String title;
  final String artist;
  final String? albumArt;
  final double duration;    // Song duration in seconds
  final double bpm;         // Beats per minute
  final int difficulty;     // 1-10 scale
  final String difficultyName;
  final int totalNotes;
  final int highScore;
  final String? rank;

  const RhythmSongInfo({
    required this.id,
    required this.title,
    required this.artist,
    this.albumArt,
    required this.duration,
    required this.bpm,
    this.difficulty = 1,
    this.difficultyName = 'Easy',
    this.totalNotes = 0,
    this.highScore = 0,
    this.rank,
  });

  String get durationFormatted {
    final minutes = (duration / 60).floor();
    final seconds = (duration % 60).floor();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  RhythmSongInfo copyWith({
    int? highScore,
    String? rank,
  }) {
    return RhythmSongInfo(
      id: id,
      title: title,
      artist: artist,
      albumArt: albumArt,
      duration: duration,
      bpm: bpm,
      difficulty: difficulty,
      difficultyName: difficultyName,
      totalNotes: totalNotes,
      highScore: highScore ?? this.highScore,
      rank: rank ?? this.rank,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'albumArt': albumArt,
      'duration': duration,
      'bpm': bpm,
      'difficulty': difficulty,
      'difficultyName': difficultyName,
      'totalNotes': totalNotes,
      'highScore': highScore,
      'rank': rank,
    };
  }
}

/// Chart data (list of notes for a song)
class RhythmChart {
  final String songId;
  final int difficulty;
  final List<RhythmNote> notes;
  final double offset;      // Audio offset in seconds

  const RhythmChart({
    required this.songId,
    required this.difficulty,
    required this.notes,
    this.offset = 0,
  });

  int get noteCount => notes.length;

  /// Get notes in time range
  List<RhythmNote> getNotesInRange(double startTime, double endTime) {
    return notes
        .where((note) => note.hitTime >= startTime && note.hitTime <= endTime)
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'songId': songId,
      'difficulty': difficulty,
      'offset': offset,
      'notes': notes.map((n) => n.toJson()).toList(),
    };
  }
}

/// Judgment display colors
class RhythmJudgmentColors {
  static Color getColor(RhythmJudgment judgment) {
    switch (judgment) {
      case RhythmJudgment.perfect:
        return Colors.yellow;
      case RhythmJudgment.great:
        return Colors.green;
      case RhythmJudgment.good:
        return Colors.blue;
      case RhythmJudgment.bad:
        return Colors.orange;
      case RhythmJudgment.miss:
        return Colors.red;
    }
  }

  static String getText(RhythmJudgment judgment) {
    switch (judgment) {
      case RhythmJudgment.perfect:
        return 'PERFECT';
      case RhythmJudgment.great:
        return 'GREAT';
      case RhythmJudgment.good:
        return 'GOOD';
      case RhythmJudgment.bad:
        return 'BAD';
      case RhythmJudgment.miss:
        return 'MISS';
    }
  }
}
