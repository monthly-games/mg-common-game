/// MG Common Game - Usage Examples
///
/// This file demonstrates how to use the major systems in mg_common_game.
/// Each section is a standalone example that can be adapted for your game.

import 'package:flutter/material.dart';
import 'package:mg_common_game/mg_common_game.dart';

// ============================================================
// 1. Game Initialization Example
// ============================================================

/// Initialize all core systems at app startup
Future<void> initializeGame() async {
  // Audio
  await AudioManager.instance.initialize();

  // Analytics
  final analytics = AnalyticsManager.getInstance('my_game');
  await analytics.initialize(AnalyticsConfig(
    gameId: 'my_game',
    firebaseEnabled: true,
    debugMode: true,
  ));

  // Localization
  await LocalizationManager.instance.initialize(
    supportedLanguages: [GameLanguage.en, GameLanguage.ko, GameLanguage.ja],
    fallbackLanguage: GameLanguage.en,
  );

  // Performance monitoring (debug only)
  FrameRateMonitor.instance.startMonitoring();

  // Memory management
  MemoryManager.instance.initialize(
    maxStrongCacheSize: 50,
    cacheExpiry: const Duration(minutes: 5),
  );

  // Save system
  await SaveManager.instance.initialize();
}

// ============================================================
// 2. Audio System Example
// ============================================================

class AudioExample {
  final audio = AudioManager.instance;

  Future<void> playGameSounds() async {
    // Background music
    await audio.playBgm('assets/audio/bgm/gameplay.mp3');
    audio.setBgmVolume(0.7);

    // Sound effects
    await audio.playSfx('assets/audio/sfx/coin_collect.mp3');
    await audio.playSfx('assets/audio/sfx/level_up.mp3');
  }

  void toggleMute() {
    if (audio.isBgmPlaying) {
      audio.pauseBgm();
    } else {
      audio.resumeBgm();
    }
  }
}

// ============================================================
// 3. Analytics Tracking Example
// ============================================================

class AnalyticsExample {
  final analytics = AnalyticsManager.getInstance('my_game');

  void trackLevelComplete(int level, int score, int stars) {
    analytics.logEvent(
      AnalyticsEvent.levelComplete,
      AnalyticsEventData.levelComplete(
        levelId: 'level_$level',
        score: score,
        stars: stars,
        duration: 120,
      ),
    );
  }

  void trackPurchase(String productId, double price) {
    analytics.logEvent(
      AnalyticsEvent.purchaseComplete,
      AnalyticsEventData.purchase(
        productId: productId,
        price: price,
        currency: 'USD',
      ),
    );
  }

  void trackScreenView(String screenName) {
    analytics.logEvent(
      AnalyticsEvent.screenView,
      AnalyticsEventData.screenView(screenName: screenName),
    );
  }
}

// ============================================================
// 4. Localization Example
// ============================================================

class LocalizationExample extends StatelessWidget {
  const LocalizationExample({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationManager.instance;

    return Column(
      children: [
        // Basic translation
        Text(l10n.translate(CommonStrings.play)),

        // Using extension method
        Text('common.settings'.tr),

        // With parameters
        Text(l10n.translate('welcome_message', {'name': 'Player'})),

        // Pluralization
        Text(l10n.plural('coins', 100)),

        // Language selector
        DropdownButton<GameLanguage>(
          value: l10n.currentLanguage,
          items: l10n.supportedLanguages.map((lang) {
            final info = l10n.getLanguageInfo(lang);
            return DropdownMenuItem(
              value: lang,
              child: Text(info?.nativeName ?? lang.name),
            );
          }).toList(),
          onChanged: (lang) {
            if (lang != null) l10n.setLanguage(lang);
          },
        ),
      ],
    );
  }
}

// ============================================================
// 5. Object Pooling Example
// ============================================================

class ObjectPoolExample {
  // Pool for bullet objects
  late final ObjectPool<Bullet> bulletPool;

  void initialize() {
    bulletPool = ObjectPool<Bullet>(
      factory: () => Bullet(),
      reset: (bullet) => bullet.reset(),
      maxSize: 100,
      initialSize: 20,
    );
  }

  void spawnBullet(double x, double y, double angle) {
    final bullet = bulletPool.acquire();
    bullet.spawn(x, y, angle);
    // Add to game world...
  }

  void despawnBullet(Bullet bullet) {
    bulletPool.release(bullet);
    // Remove from game world...
  }

  void printStats() {
    final stats = bulletPool.stats;
    print('Pool size: ${stats['poolSize']}');
    print('Reuse ratio: ${stats['reuseRatio']}');
  }
}

class Bullet {
  double x = 0, y = 0, angle = 0;
  bool active = false;

  void spawn(double x, double y, double angle) {
    this.x = x;
    this.y = y;
    this.angle = angle;
    active = true;
  }

  void reset() {
    x = 0;
    y = 0;
    angle = 0;
    active = false;
  }
}

// ============================================================
// 6. Performance Monitoring Example
// ============================================================

class PerformanceExample extends StatefulWidget {
  const PerformanceExample({super.key});

  @override
  State<PerformanceExample> createState() => _PerformanceExampleState();
}

class _PerformanceExampleState extends State<PerformanceExample> {
  final monitor = FrameRateMonitor.instance;

  @override
  void initState() {
    super.initState();
    monitor.startMonitoring();

    // Listen for FPS updates
    monitor.addFpsListener(_onFpsUpdate);

    // Listen for jank
    monitor.addJankListener(_onJank);
  }

  void _onFpsUpdate(double fps, FrameRateQuality quality) {
    // Adjust graphics quality based on performance
    if (quality == FrameRateQuality.poor) {
      // Reduce particle count, disable shadows, etc.
    }
  }

  void _onJank(FrameData frame) {
    print('Jank detected: ${frame.frameDuration.inMilliseconds}ms');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: monitor,
      builder: (context, _) {
        return Text(
          'FPS: ${monitor.currentFps.toStringAsFixed(1)} (${monitor.quality.name})',
        );
      },
    );
  }

  @override
  void dispose() {
    monitor.removeFpsListener(_onFpsUpdate);
    super.dispose();
  }
}

// ============================================================
// 7. Idle Game Example
// ============================================================

class IdleGameExample extends StatefulWidget {
  const IdleGameExample({super.key});

  @override
  State<IdleGameExample> createState() => _IdleGameExampleState();
}

class _IdleGameExampleState extends State<IdleGameExample> {
  final offline = OfflineProgressManager.instance;
  final prestige = PrestigeManager.instance;
  final autoClicker = AutoClickerManager.instance;

  int coins = 0;
  int prestigePoints = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize systems
    await offline.initialize(maxOfflineHours: 24, offlineEfficiency: 0.5);
    await prestige.initialize(
      config: PrestigeConfig(
        baseRequirement: 1000000,
        formula: PrestigeFormula.logarithmic,
      ),
    );
    await autoClicker.initialize();

    // Check for offline progress
    final progress = await offline.calculateOfflineProgress();
    if (progress != null) {
      _showOfflineRewardDialog(progress);
    }

    // Start auto-click timer
    _startAutoClickTimer();
  }

  void _showOfflineRewardDialog(OfflineProgressData progress) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Welcome Back!'),
        content: Text(
          'You were away for ${progress.offlineDuration.inHours} hours.\n'
          'Earned: ${progress.currencyEarned} coins',
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => coins += progress.currencyEarned.toInt());
              Navigator.pop(ctx);
            },
            child: const Text('Collect'),
          ),
          TextButton(
            onPressed: () {
              // Watch ad for 2x
              setState(
                  () => coins += (progress.currencyEarned * 2).toInt());
              Navigator.pop(ctx);
            },
            child: const Text('Watch Ad for 2x'),
          ),
        ],
      ),
    );
  }

  void _startAutoClickTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      final cps = autoClicker.totalCps;
      setState(() => coins += cps.toInt());
      return true;
    });
  }

  void _tap() {
    setState(() => coins += 1 * prestige.getTotalMultiplier().toInt());
  }

  void _tryPrestige() {
    if (prestige.canPrestige(coins.toDouble())) {
      final points = prestige.calculatePrestigePoints(coins.toDouble());
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Prestige?'),
          content: Text('Reset progress for $points prestige points?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                prestige.performPrestige(coins.toDouble());
                setState(() {
                  coins = 0;
                  prestigePoints += points.toInt();
                });
                Navigator.pop(ctx);
              },
              child: const Text('Prestige'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Coins: $coins', style: const TextStyle(fontSize: 32)),
            Text('Prestige Points: $prestigePoints'),
            Text('CPS: ${autoClicker.totalCps}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _tap,
              child: const Text('TAP!'),
            ),
            ElevatedButton(
              onPressed: _tryPrestige,
              child: const Text('Prestige'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 8. UI Animations Example
// ============================================================

class AnimationsExample extends StatelessWidget {
  const AnimationsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Fade in animation
          FadeIn(
            duration: const Duration(milliseconds: 500),
            child: const Text('Fade In Text'),
          ),

          // Slide in from bottom
          SlideIn.fromBottom(
            delay: const Duration(milliseconds: 200),
            child: const Card(child: Text('Sliding Card')),
          ),

          // Bounce in
          BounceIn(
            delay: const Duration(milliseconds: 400),
            child: const Icon(Icons.star, size: 64),
          ),

          // Animated button
          BounceButton(
            onPressed: () => print('Pressed!'),
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue,
              child: const Text('Bounce Button'),
            ),
          ),

          // Shimmer button for premium feel
          ShimmerButton(
            onPressed: () => print('Premium!'),
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.amber,
              child: const Text('Buy Premium'),
            ),
          ),

          // Animated counter
          AnimatedCounter(
            value: 12345,
            duration: const Duration(milliseconds: 800),
            style: const TextStyle(fontSize: 48),
          ),

          // Staggered list
          StaggeredList(
            staggerDelay: const Duration(milliseconds: 100),
            children: [
              ListTile(title: Text('Item 1')),
              ListTile(title: Text('Item 2')),
              ListTile(title: Text('Item 3')),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 9. Screen Transitions Example
// ============================================================

class TransitionsExample {
  void navigateWithFade(BuildContext context) {
    Navigator.push(
      context,
      FadePageRoute(
        page: const DestinationScreen(),
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  void navigateWithSlide(BuildContext context) {
    Navigator.push(
      context,
      SlideUpPageRoute(page: const BottomSheetScreen()),
    );
  }

  void navigateWithScale(BuildContext context) {
    Navigator.push(
      context,
      ScalePageRoute(page: const PopupScreen()),
    );
  }

  void useGameNavigator(BuildContext context) {
    // Using the convenience class
    GameNavigator.push(
      context,
      const GameScreen(),
      transition: TransitionType.fade,
    );

    GameNavigator.pushReplacement(
      context,
      const MainMenuScreen(),
      transition: TransitionType.slideRight,
    );
  }
}

class DestinationScreen extends StatelessWidget {
  const DestinationScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Destination')));
}

class BottomSheetScreen extends StatelessWidget {
  const BottomSheetScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Bottom Sheet')));
}

class PopupScreen extends StatelessWidget {
  const PopupScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Popup')));
}

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Game')));
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Main Menu')));
}

// ============================================================
// 10. Gacha System Example
// ============================================================

class GachaExample {
  final gacha = GachaManager.instance;

  Future<void> initialize() async {
    await gacha.initialize();

    // Register a gacha banner
    gacha.registerBanner(GachaBanner(
      id: 'standard_banner',
      name: 'Standard Banner',
      pool: GachaPool(items: [
        GachaItem(id: 'sword_common', rarity: Rarity.common, weight: 70),
        GachaItem(id: 'sword_rare', rarity: Rarity.rare, weight: 25),
        GachaItem(id: 'sword_epic', rarity: Rarity.epic, weight: 4.5),
        GachaItem(id: 'sword_legendary', rarity: Rarity.legendary, weight: 0.5),
      ]),
      pitySystem: PitySystem(softPity: 75, hardPity: 90),
    ));
  }

  GachaResult singlePull() {
    return gacha.pull('standard_banner');
  }

  List<GachaResult> multiPull() {
    return gacha.pullMulti('standard_banner', count: 10);
  }

  int getPityCount() {
    return gacha.getPityCount('standard_banner');
  }
}

// ============================================================
// Main - Run Examples
// ============================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize game systems
  await initializeGame();

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MG Common Game Examples',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ExampleHome(),
    );
  }
}

class ExampleHome extends StatelessWidget {
  const ExampleHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MG Common Game Examples')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Idle Game Example'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const IdleGameExample()),
            ),
          ),
          ListTile(
            title: const Text('Animations Example'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AnimationsExample()),
            ),
          ),
          ListTile(
            title: const Text('Localization Example'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LocalizationExample()),
            ),
          ),
          ListTile(
            title: const Text('Performance Monitor'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PerformanceExample()),
            ),
          ),
        ],
      ),
    );
  }
}
