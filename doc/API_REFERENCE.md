# MG Common Game - API Reference

A comprehensive shared library for 52 mobile games built with Flutter and Flame.

---

## Table of Contents

1. [Core Systems](#core-systems)
   - [Audio](#audio-system)
   - [Analytics](#analytics-system)
   - [Localization](#localization-system)
   - [Performance](#performance-system)
   - [Save System](#save-system)
2. [Game Systems](#game-systems)
   - [Idle/Clicker](#idleclicker-system)
   - [Match-3](#match-3-system)
   - [Runner/Rhythm](#runnerrhythm-system)
   - [Card Game](#card-game-system)
   - [Battle](#battle-system)
3. [Progression Systems](#progression-systems)
   - [Achievements](#achievement-system)
   - [Prestige](#prestige-system)
   - [Quests](#quest-system)
4. [Monetization](#monetization-systems)
   - [Gacha](#gacha-system)
   - [BattlePass](#battlepass-system)
   - [Shop](#shop-system)
5. [Social Systems](#social-systems)
6. [UI Components](#ui-components)
   - [Animations](#animations)
   - [Widgets](#widgets)

---

## Core Systems

### Audio System

**Location:** `lib/core/audio/`

#### AudioManager

Singleton manager for game audio with BGM and SFX support.

```dart
import 'package:mg_common_game/mg_common_game.dart';

// Initialize
final audio = AudioManager.instance;
await audio.initialize();

// Play BGM
await audio.playBgm('assets/audio/bgm/main_theme.mp3');
audio.setBgmVolume(0.8);

// Play SFX
await audio.playSfx('assets/audio/sfx/button_click.mp3');
audio.setSfxVolume(1.0);

// Pause/Resume
audio.pauseBgm();
audio.resumeBgm();

// Cleanup
audio.stopAll();
audio.dispose();
```

#### AudioSettings

Persistent audio configuration.

```dart
final settings = AudioSettings(
  bgmVolume: 0.8,
  sfxVolume: 1.0,
  bgmEnabled: true,
  sfxEnabled: true,
);

await settings.save();
final loaded = await AudioSettings.load();
```

---

### Analytics System

**Location:** `lib/core/analytics/`

#### AnalyticsManager

Firebase Analytics integration with event batching.

```dart
final analytics = AnalyticsManager.getInstance('game_0037');
await analytics.initialize(AnalyticsConfig(
  gameId: 'game_0037',
  firebaseEnabled: true,
  debugMode: kDebugMode,
));

// Log events
analytics.logEvent('button_click', {'button_id': 'play'});
analytics.logLevelComplete(5, score: 1000, stars: 3);
analytics.logPurchase('coins_500', 0.99, 'USD');

// Screen tracking
analytics.logScreenView('main_menu');

// User properties
analytics.setUserProperty('player_level', '10');
```

#### RemoteConfigManager

Firebase Remote Config for A/B testing.

```dart
final config = RemoteConfigManager.getInstance('game_0037');
await config.initialize(CasualGameDefaults.all);

// Get values
final dailyCoins = config.getInt('daily_reward_coins');
final showAds = config.getBool('show_interstitial_ads');
final welcomeMsg = config.getString('welcome_message');

// Fetch updates
await config.fetchAndActivate();
```

#### AnalyticsEvent / AnalyticsParam

Standard event and parameter names.

```dart
// Use predefined event names
analytics.logEvent(AnalyticsEvent.levelComplete, {
  AnalyticsParam.levelId: 'level_5',
  AnalyticsParam.score: 1000,
  AnalyticsParam.stars: 3,
  AnalyticsParam.duration: 120,
});

// Use event data builders
final eventData = AnalyticsEventData.levelComplete(
  levelId: 'level_5',
  score: 1000,
  stars: 3,
  duration: 120,
);
analytics.logEvent(AnalyticsEvent.levelComplete, eventData);
```

---

### Localization System

**Location:** `lib/core/localization/`

#### LocalizationManager

Multi-language support with 15 languages.

```dart
final localization = LocalizationManager.instance;
await localization.initialize(
  supportedLanguages: [
    GameLanguage.en,
    GameLanguage.ko,
    GameLanguage.ja,
  ],
  fallbackLanguage: GameLanguage.en,
  assetsPath: 'assets/i18n',
);

// Translate
final text = localization.translate('common.play');

// With parameters
final greeting = localization.translate('welcome', {'name': 'Player'});
// "Welcome, Player!"

// Pluralization
final coins = localization.plural('coins', 5);
// "5 coins"

// Change language
await localization.setLanguage(GameLanguage.ko);

// Extension method
final playText = 'common.play'.tr;
```

#### Supported Languages

| Code | Language | Native Name |
|------|----------|-------------|
| en | English | English |
| ko | Korean | 한국어 |
| ja | Japanese | 日本語 |
| zhCN | Chinese (Simplified) | 简体中文 |
| zhTW | Chinese (Traditional) | 繁體中文 |
| es | Spanish | Español |
| pt | Portuguese | Português |
| fr | French | Français |
| de | German | Deutsch |
| ru | Russian | Русский |
| id | Indonesian | Bahasa Indonesia |
| th | Thai | ไทย |
| vi | Vietnamese | Tiếng Việt |
| ar | Arabic | العربية |
| tr | Turkish | Türkçe |

#### CommonStrings

Predefined translation keys.

```dart
// UI strings
CommonStrings.play        // 'common.play'
CommonStrings.settings    // 'common.settings'
CommonStrings.confirm     // 'common.confirm'

// Game strings
CommonStrings.levelComplete  // 'game.level_complete'
CommonStrings.gameOver       // 'game.game_over'

// Shop strings
CommonStrings.buyNow      // 'shop.buy_now'
CommonStrings.outOfStock  // 'shop.out_of_stock'
```

---

### Performance System

**Location:** `lib/core/performance/`

#### ObjectPool

Generic object pooling to reduce GC pressure.

```dart
// Create pool
final bulletPool = ObjectPool<Bullet>(
  factory: () => Bullet(),
  reset: (bullet) => bullet.reset(),
  maxSize: 100,
  initialSize: 20,
);

// Use objects
final bullet = bulletPool.acquire();
// ... use bullet ...
bulletPool.release(bullet);

// Stats
print(bulletPool.stats);
// {poolSize: 20, maxSize: 100, created: 20, reused: 15, reuseRatio: 0.75}
```

#### MemoryManager

Cache management with LRU eviction.

```dart
final memory = MemoryManager.instance;
memory.initialize(
  maxStrongCacheSize: 50,
  cacheExpiry: Duration(minutes: 5),
);

// Strong cache (kept in memory)
memory.cacheStrong('player_data', playerData);
final data = memory.getStrong<PlayerData>('player_data');

// Weak cache (can be GC'd)
memory.cacheWeak('texture_large', largeTexture);
final texture = memory.getWeak<Texture>('texture_large');

// Memory pressure handling
memory.addPressureListener((pressure) {
  if (pressure == MemoryPressure.high) {
    // Reduce memory usage
  }
});

// Clear caches
memory.clearAllCaches();
```

#### FrameRateMonitor

FPS tracking and jank detection.

```dart
final monitor = FrameRateMonitor.instance;
monitor.startMonitoring(
  historySize: 120,
  reportInterval: Duration(seconds: 1),
);

// Get current FPS
print(monitor.currentFps);  // 60.0
print(monitor.quality);     // FrameRateQuality.excellent

// Listen to FPS updates
monitor.addFpsListener((fps, quality) {
  if (quality == FrameRateQuality.poor) {
    // Reduce graphics quality
  }
});

// Detect jank frames
monitor.addJankListener((frame) {
  print('Jank detected: ${frame.frameDuration.inMilliseconds}ms');
});

// Stats
print(monitor.stats);
// {fps: 60.0, quality: excellent, jankCount: 2, jankRatio: 0.01}
```

#### AssetOptimizer

Priority-based asset loading and caching.

```dart
final assets = AssetOptimizer.instance;
assets.initialize(
  maxConcurrentLoads: 3,
  maxCacheSize: 100,
  maxCacheSizeMB: 50,
);

// Register assets
assets.registerAsset('player', 'assets/images/player.png',
    priority: AssetPriority.critical);
assets.registerAsset('enemy', 'assets/images/enemy.png',
    priority: AssetPriority.high);

// Preload by priority
await assets.preloadByPriority(AssetPriority.critical,
    onProgress: (loaded, total, current) {
  print('Loading: $loaded/$total - $current');
});

// Get asset
final playerBytes = assets.getAsset<ByteData>('player');

// Unload when done
assets.unloadByPriority(AssetPriority.low);
```

#### PerformanceProfiler

Code execution measurement.

```dart
// Measure sync code
PerformanceProfiler.start('physics_update');
updatePhysics();
final duration = PerformanceProfiler.end('physics_update');

// Measure with callback
final result = PerformanceProfiler.measure('ai_calculation', () {
  return calculateAI();
});

// Async measurement
final data = await PerformanceProfiler.measureAsync('load_data', () async {
  return await loadGameData();
});

// Get stats
print(PerformanceProfiler.getStats('physics_update'));
// {name: physics_update, callCount: 100, avgMs: 2.5, minMs: 1.2, maxMs: 5.8}
```

---

### Save System

**Location:** `lib/core/systems/`

#### SaveManager

Persistent game data storage.

```dart
final save = SaveManager.instance;
await save.initialize();

// Save data
await save.setInt('player_level', 10);
await save.setString('player_name', 'Hero');
await save.setDouble('play_time', 3600.5);
await save.setBool('tutorial_complete', true);
await save.setObject('inventory', inventoryData);

// Load data
final level = save.getInt('player_level', defaultValue: 1);
final name = save.getString('player_name', defaultValue: 'Player');

// Remove
await save.remove('temp_data');

// Clear all
await save.clear();
```

---

## Game Systems

### Idle/Clicker System

**Location:** `lib/systems/idle/`

#### OfflineProgressManager

Calculate offline rewards.

```dart
final offline = OfflineProgressManager.instance;
await offline.initialize(
  maxOfflineHours: 24,
  offlineEfficiency: 0.5,  // 50% efficiency when offline
);

// Record session end
await offline.recordSessionEnd();

// On app resume, calculate rewards
final progress = await offline.calculateOfflineProgress();
if (progress != null) {
  print('Offline for ${progress.offlineDuration.inHours} hours');
  print('Earned: ${progress.currencyEarned} coins');
}
```

#### PrestigeManager

Prestige/rebirth system.

```dart
final prestige = PrestigeManager.instance;
await prestige.initialize(
  config: PrestigeConfig(
    baseRequirement: 1000000,
    formula: PrestigeFormula.logarithmic,
    pointsPerPrestige: 1.0,
  ),
);

// Check prestige availability
if (prestige.canPrestige(currentCurrency)) {
  final points = prestige.calculatePrestigePoints(currentCurrency);
  print('Prestige for $points points?');

  // Perform prestige
  await prestige.performPrestige(currentCurrency);
}

// Get multiplier from prestige points
final multiplier = prestige.getTotalMultiplier();
```

#### AutoClickerManager

Auto-clicker upgrades.

```dart
final autoClicker = AutoClickerManager.instance;
await autoClicker.initialize();

// Add auto-clickers
autoClicker.addAutoClicker(AutoClicker(
  id: 'basic_clicker',
  name: 'Basic Clicker',
  baseCps: 1.0,
  baseCost: 100,
  costMultiplier: 1.15,
));

// Purchase upgrade
if (autoClicker.canPurchase('basic_clicker', playerCoins)) {
  final cost = autoClicker.purchase('basic_clicker');
  playerCoins -= cost;
}

// Get total CPS
final totalCps = autoClicker.totalCps;
```

---

### Match-3 System

**Location:** `lib/systems/match3/`

#### Match3Board

Complete match-3 game logic.

```dart
final board = Match3Board(width: 8, height: 8);
await board.initialize();

// Make a swap
final result = board.trySwap(Position(2, 3), Position(2, 4));
if (result.isValid) {
  for (final match in result.matches) {
    print('Matched ${match.gems.length} gems!');
    score += match.score;
  }

  // Handle cascades
  while (board.hasPendingCascades) {
    final cascadeResult = await board.processCascade();
    score += cascadeResult.score;
  }
}

// Power-ups
board.activatePowerUp(PowerUpType.shuffle);
board.activatePowerUp(PowerUpType.hammer, position: Position(3, 4));

// Hints
final hint = board.getHint();
if (hint != null) {
  highlightPositions(hint.from, hint.to);
}
```

---

### Runner/Rhythm System

**Location:** `lib/systems/runner/`

#### RunnerTypes

Lane-based runner game types.

```dart
// Define lanes
enum RunnerLane { left, center, right }

// Obstacles
final obstacle = Obstacle(
  type: ObstacleType.barrier,
  lane: RunnerLane.center,
  position: 100.0,
);

// Collectibles
final coin = Collectible(
  type: CollectibleType.coin,
  lane: RunnerLane.left,
  value: 10,
);

// Power-ups
final shield = RunnerPowerUp(
  type: PowerUpType.shield,
  duration: Duration(seconds: 5),
);
```

#### RhythmTypes

Rhythm game timing and judgment.

```dart
// Note types
final note = RhythmNote(
  type: RhythmNoteType.tap,
  targetTime: Duration(milliseconds: 1500),
  lane: 2,
);

// Judge timing
final judgment = RhythmJudgment.judge(
  targetTime: note.targetTime,
  hitTime: playerHitTime,
  windows: RhythmTimingWindow.standard,
);

print(judgment); // RhythmJudgment.perfect

// Session stats
final stats = RhythmSessionStats();
stats.recordJudgment(judgment);
print('Accuracy: ${stats.accuracy}%');
print('Max Combo: ${stats.maxCombo}');
print('Rank: ${stats.rank}'); // S, A, B, C, D
```

---

### Card Game System

**Location:** `lib/systems/card/`

#### CardTypes

Card game definitions.

```dart
// Define cards
final strike = CardDefinition(
  id: 'strike',
  name: 'Strike',
  type: CardType.attack,
  rarity: CardRarity.common,
  cost: 1,
  effects: [DamageEffect(6)],
);

// Create deck
final deck = Deck(cards: [strike, strike, defend, defend, bash]);
deck.shuffle();

// Draw cards
final hand = deck.draw(5);

// Battle state
final battle = CardBattleState(
  maxEnergy: 3,
  deckSize: 20,
);
battle.startTurn();
battle.playCard(strike, target: enemy);
battle.endTurn();
```

---

### Battle System

**Location:** `lib/systems/battle/`

#### BattleManager

Turn-based battle management.

```dart
final battle = BattleManager();
await battle.initialize(
  player: playerEntity,
  enemies: [enemy1, enemy2],
);

// Player turn
battle.selectAction(BattleAction.attack);
battle.selectTarget(enemy1);
await battle.executeAction();

// Check battle state
if (battle.isVictory) {
  final rewards = battle.calculateRewards();
}
```

---

## Progression Systems

### Achievement System

**Location:** `lib/systems/progression/`

```dart
final achievements = AchievementManager.instance;
await achievements.initialize();

// Define achievements
achievements.register(Achievement(
  id: 'first_win',
  name: 'First Victory',
  description: 'Win your first battle',
  icon: 'trophy',
  reward: CurrencyReward(coins: 100),
));

// Track progress
achievements.updateProgress('kill_enemies', 1);
achievements.updateProgress('collect_coins', 50);

// Check and claim
if (achievements.isUnlocked('first_win')) {
  final reward = achievements.claim('first_win');
}
```

### Prestige System

See [Idle/Clicker System](#idleclicker-system).

### Quest System

**Location:** `lib/systems/quests/`

```dart
// Daily quests
final daily = DailyQuestManager.instance;
await daily.initialize();
await daily.refreshIfNeeded();

final quests = daily.activeQuests;
for (final quest in quests) {
  print('${quest.name}: ${quest.progress}/${quest.target}');
}

// Weekly challenges
final weekly = WeeklyChallengeManager.instance;
await weekly.initialize();
```

---

## Monetization Systems

### Gacha System

**Location:** `lib/systems/gacha/`

```dart
final gacha = GachaManager.instance;
await gacha.initialize();

// Define banner
gacha.registerBanner(GachaBanner(
  id: 'standard',
  name: 'Standard Banner',
  pool: GachaPool(
    items: [
      GachaItem(id: 'common_sword', rarity: Rarity.common, weight: 70),
      GachaItem(id: 'rare_sword', rarity: Rarity.rare, weight: 25),
      GachaItem(id: 'legendary_sword', rarity: Rarity.legendary, weight: 5),
    ],
  ),
  pitySystem: PitySystem(softPity: 75, hardPity: 90),
));

// Single pull
final result = gacha.pull('standard');
print('Got: ${result.item.name}');

// Multi pull
final results = gacha.pullMulti('standard', count: 10);
```

### BattlePass System

**Location:** `lib/systems/battlepass/`

```dart
final battlepass = BattlePassManager.instance;
await battlepass.initialize(BattlePassConfig(
  seasonId: 'season_1',
  maxLevel: 100,
  expPerLevel: 1000,
  rewards: battlePassRewards,
));

// Add experience
battlepass.addExp(500);

// Claim rewards
if (battlepass.canClaimLevel(10)) {
  final reward = battlepass.claimLevel(10, isPremium: hasPremiumPass);
}

// Check premium
if (!battlepass.isPremium) {
  // Show upgrade prompt
}
```

### Shop System

**Location:** `lib/systems/shop/`

```dart
final shop = ShopManager.instance;
await shop.initialize();

// Get items
final dailyDeals = shop.getDailyDeals();
final bundles = shop.getBundles();

// Purchase
final result = await shop.purchase(itemId, currency: playerCoins);
if (result.success) {
  applyPurchase(result.item);
}
```

---

## Social Systems

**Location:** `lib/systems/social/`

```dart
// Friends
final friends = FriendsManager.instance;
await friends.sendFriendRequest(userId);
await friends.acceptFriendRequest(requestId);
final friendList = await friends.getFriends();

// Leaderboards
final leaderboard = LeaderboardManager.instance;
await leaderboard.submitScore('weekly_high_score', 10000);
final topPlayers = await leaderboard.getTopScores(limit: 100);
final myRank = await leaderboard.getMyRank();

// Guilds
final guild = GuildManager.instance;
await guild.createGuild('Awesome Guild');
await guild.joinGuild(guildId);
```

---

## UI Components

### Animations

**Location:** `lib/ui/animations/`

#### Button Animations

```dart
// Bounce button
BounceButton(
  onPressed: () => print('Pressed!'),
  child: Text('Play'),
)

// Pulse button (attention-grabbing)
PulseButton(
  onPressed: onClaimReward,
  child: Text('Claim!'),
)

// Shimmer button (premium feel)
ShimmerButton(
  onPressed: onPurchase,
  child: Text('Buy Now'),
)

// Glow button
GlowButton(
  glowColor: Colors.blue,
  onPressed: onSpecialAction,
  child: Icon(Icons.star),
)
```

#### Widget Animations

```dart
// Fade in
FadeIn(
  duration: Duration(milliseconds: 300),
  delay: Duration(milliseconds: 100),
  child: MyWidget(),
)

// Slide in (multiple directions)
SlideIn.fromBottom(
  duration: Duration(milliseconds: 400),
  child: BottomSheet(),
)

// Scale in with bounce
BounceIn(
  duration: Duration(milliseconds: 600),
  child: RewardPopup(),
)

// Staggered list
StaggeredList(
  staggerDelay: Duration(milliseconds: 100),
  children: menuItems,
)

// Typewriter text
TypewriterText(
  text: 'Welcome to the game!',
  charDuration: Duration(milliseconds: 50),
  onComplete: () => showNextButton(),
)

// Animated counter
AnimatedCounter(
  value: score,
  duration: Duration(milliseconds: 500),
  formatter: (value) => NumberFormat.compact().format(value),
)
```

#### Screen Transitions

```dart
// Fade transition
Navigator.push(context, FadePageRoute(
  page: GameScreen(),
  duration: Duration(milliseconds: 300),
));

// Slide transitions
Navigator.push(context, SlideRightPageRoute(page: SettingsScreen()));
Navigator.push(context, SlideUpPageRoute(page: ShopScreen()));

// Scale transition
Navigator.push(context, ScalePageRoute(page: LevelSelectScreen()));

// Using GameNavigator
GameNavigator.push(context, GameScreen(), transition: TransitionType.fade);
GameNavigator.pushReplacement(context, MainMenu());
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2024-01 | Initial release |
| 1.1.0 | 2024-02 | Added Idle, Match-3, Runner systems |
| 1.2.0 | 2024-03 | Added Analytics, Localization, Performance |
| 1.3.0 | 2024-04 | Added UI Animations, Documentation |

---

## License

Copyright (c) 2024 Monthly Games. All rights reserved.
