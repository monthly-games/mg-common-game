import 'package:flutter/material.dart';

/// Lane positions for runner games
enum RunnerLane {
  left,
  center,
  right,
}

/// Player actions
enum RunnerAction {
  run,
  jump,
  slide,
  dodge,
}

/// Obstacle types
enum ObstacleType {
  low,      // Need to jump
  high,     // Need to slide
  full,     // Need to dodge (change lane)
  pit,      // Gap in the ground
  moving,   // Moving obstacle
}

/// Collectible types
enum CollectibleType {
  coin,
  gem,
  powerUp,
  scoreBooster,
  magnet,
  shield,
}

/// Power-up types
enum RunnerPowerUp {
  magnet,       // Attract coins
  shield,       // Invincibility
  doubleScore,  // 2x score
  speedBoost,   // Faster (more points)
  fly,          // Fly over obstacles
  slowMotion,   // Slow down game
}

/// Game state
enum RunnerGameState {
  ready,
  playing,
  paused,
  gameOver,
}

/// Obstacle configuration
class ObstacleConfig {
  final ObstacleType type;
  final RunnerLane lane;
  final double speed;
  final double width;
  final double height;
  final int scoreValue;

  const ObstacleConfig({
    required this.type,
    required this.lane,
    this.speed = 1.0,
    this.width = 1.0,
    this.height = 1.0,
    this.scoreValue = 10,
  });

  /// Get required action to avoid this obstacle
  RunnerAction get requiredAction {
    switch (type) {
      case ObstacleType.low:
        return RunnerAction.jump;
      case ObstacleType.high:
        return RunnerAction.slide;
      case ObstacleType.full:
      case ObstacleType.pit:
      case ObstacleType.moving:
        return RunnerAction.dodge;
    }
  }
}

/// Collectible configuration
class CollectibleConfig {
  final CollectibleType type;
  final RunnerLane lane;
  final int value;
  final double duration;

  const CollectibleConfig({
    required this.type,
    required this.lane,
    this.value = 1,
    this.duration = 0,
  });
}

/// Player state
class RunnerPlayerState {
  RunnerLane currentLane;
  RunnerAction currentAction;
  bool isJumping;
  bool isSliding;
  bool isInvincible;
  double jumpProgress;
  double slideProgress;

  // Power-up states
  Map<RunnerPowerUp, double> activePowerUps;

  RunnerPlayerState({
    this.currentLane = RunnerLane.center,
    this.currentAction = RunnerAction.run,
    this.isJumping = false,
    this.isSliding = false,
    this.isInvincible = false,
    this.jumpProgress = 0.0,
    this.slideProgress = 0.0,
    Map<RunnerPowerUp, double>? activePowerUps,
  }) : activePowerUps = activePowerUps ?? {};

  bool get canJump => !isJumping && !isSliding;
  bool get canSlide => !isJumping && !isSliding;
  bool get canDodge => !isJumping;

  bool hasPowerUp(RunnerPowerUp powerUp) {
    return (activePowerUps[powerUp] ?? 0) > 0;
  }

  void addPowerUp(RunnerPowerUp powerUp, double duration) {
    activePowerUps[powerUp] = (activePowerUps[powerUp] ?? 0) + duration;
  }

  void updatePowerUps(double deltaTime) {
    final toRemove = <RunnerPowerUp>[];
    activePowerUps.forEach((powerUp, remaining) {
      activePowerUps[powerUp] = remaining - deltaTime;
      if (activePowerUps[powerUp]! <= 0) {
        toRemove.add(powerUp);
      }
    });
    for (final powerUp in toRemove) {
      activePowerUps.remove(powerUp);
    }
  }

  RunnerPlayerState copyWith({
    RunnerLane? currentLane,
    RunnerAction? currentAction,
    bool? isJumping,
    bool? isSliding,
    bool? isInvincible,
    double? jumpProgress,
    double? slideProgress,
  }) {
    return RunnerPlayerState(
      currentLane: currentLane ?? this.currentLane,
      currentAction: currentAction ?? this.currentAction,
      isJumping: isJumping ?? this.isJumping,
      isSliding: isSliding ?? this.isSliding,
      isInvincible: isInvincible ?? this.isInvincible,
      jumpProgress: jumpProgress ?? this.jumpProgress,
      slideProgress: slideProgress ?? this.slideProgress,
      activePowerUps: Map.from(activePowerUps),
    );
  }
}

/// Game session stats
class RunnerSessionStats {
  int distance;
  int coins;
  int gems;
  int obstaclesAvoided;
  int powerUpsCollected;
  int nearMisses;
  double playTime;
  int maxCombo;
  int currentCombo;

  RunnerSessionStats({
    this.distance = 0,
    this.coins = 0,
    this.gems = 0,
    this.obstaclesAvoided = 0,
    this.powerUpsCollected = 0,
    this.nearMisses = 0,
    this.playTime = 0,
    this.maxCombo = 0,
    this.currentCombo = 0,
  });

  int get score {
    return distance +
        (coins * 10) +
        (gems * 50) +
        (obstaclesAvoided * 5) +
        (nearMisses * 20) +
        (maxCombo * 100);
  }

  void reset() {
    distance = 0;
    coins = 0;
    gems = 0;
    obstaclesAvoided = 0;
    powerUpsCollected = 0;
    nearMisses = 0;
    playTime = 0;
    maxCombo = 0;
    currentCombo = 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'distance': distance,
      'coins': coins,
      'gems': gems,
      'obstaclesAvoided': obstaclesAvoided,
      'powerUpsCollected': powerUpsCollected,
      'nearMisses': nearMisses,
      'playTime': playTime,
      'maxCombo': maxCombo,
      'score': score,
    };
  }
}

/// Difficulty settings
class RunnerDifficulty {
  final String name;
  final double baseSpeed;
  final double speedIncrease;
  final double obstacleFrequency;
  final double collectibleFrequency;
  final double powerUpFrequency;
  final int maxSimultaneousObstacles;

  const RunnerDifficulty({
    required this.name,
    this.baseSpeed = 5.0,
    this.speedIncrease = 0.1,
    this.obstacleFrequency = 2.0,
    this.collectibleFrequency = 1.0,
    this.powerUpFrequency = 0.1,
    this.maxSimultaneousObstacles = 2,
  });

  static const RunnerDifficulty easy = RunnerDifficulty(
    name: 'Easy',
    baseSpeed: 4.0,
    speedIncrease: 0.05,
    obstacleFrequency: 3.0,
    collectibleFrequency: 1.5,
  );

  static const RunnerDifficulty normal = RunnerDifficulty(
    name: 'Normal',
    baseSpeed: 5.0,
    speedIncrease: 0.1,
    obstacleFrequency: 2.0,
    collectibleFrequency: 1.0,
  );

  static const RunnerDifficulty hard = RunnerDifficulty(
    name: 'Hard',
    baseSpeed: 6.0,
    speedIncrease: 0.15,
    obstacleFrequency: 1.5,
    collectibleFrequency: 0.8,
    maxSimultaneousObstacles: 3,
  );

  /// Get speed at given distance
  double getSpeedAtDistance(int distance) {
    return baseSpeed + (distance / 1000) * speedIncrease;
  }
}
