# Quick Start Guide

mg_common_game 시스템별 빠른 시작 가이드입니다.

## 목차

1. [프로젝트 설정](#1-프로젝트-설정)
2. [코어 시스템](#2-코어-시스템)
3. [게임 시스템](#3-게임-시스템)
4. [수익화 시스템](#4-수익화-시스템)
5. [UI 컴포넌트](#5-ui-컴포넌트)
6. [장르별 가이드](#6-장르별-가이드)

---

## 1. 프로젝트 설정

### Submodule 추가

```bash
# 새 게임 프로젝트에서
cd your-game-project
git submodule add https://github.com/monthly-games/mg-common-game.git libs/mg_common_game
git submodule update --init --recursive
```

### pubspec.yaml

```yaml
name: your_game
description: Your awesome game

dependencies:
  flutter:
    sdk: flutter

  # MG Common Game
  mg_common_game:
    path: libs/mg_common_game

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

### main.dart 기본 구조

```dart
import 'package:flutter/material.dart';
import 'package:mg_common_game/mg_common_game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 필수 초기화
  await _initializeSystems();

  runApp(const MyGameApp());
}

Future<void> _initializeSystems() async {
  // 1. 저장 시스템 (필수)
  await SaveManager.instance.init();

  // 2. 오디오 시스템
  await AudioManager.instance.init();

  // 3. 분석 시스템
  await AnalyticsManager.instance.init();

  // 4. 현지화 (다국어 지원 시)
  await LocalizationManager.instance.init(
    supportedLocales: ['ko', 'en'],
    defaultLocale: 'ko',
  );

  // 5. 알림 시스템 (선택)
  await NotificationManager.instance.initialize();
  await NotificationManager.instance.requestPermission();

  // 6. 클라우드 저장 (선택)
  await CloudSaveManager.instance.initialize(
    gameId: 'your_game_id',
    userId: await _getUserId(),
  );
}

Future<String> _getUserId() async {
  // 사용자 ID 가져오기 로직
  return 'user_123';
}
```

---

## 2. 코어 시스템

### 2.1 저장 시스템

```dart
// === 기본 저장/로드 ===
await SaveManager.instance.init();

// 단순 값 저장
await SaveManager.instance.save('player_level', 10);
await SaveManager.instance.save('player_name', 'Hero');
await SaveManager.instance.save('settings', {'sound': true, 'music': true});

// 값 로드
final level = SaveManager.instance.load<int>('player_level') ?? 1;
final name = SaveManager.instance.load<String>('player_name') ?? 'Player';
final settings = SaveManager.instance.load<Map>('settings') ?? {};

// === 게임 데이터 일괄 저장 ===
class GameData {
  int level;
  int gold;
  List<String> inventory;

  Map<String, dynamic> toJson() => {
    'level': level,
    'gold': gold,
    'inventory': inventory,
  };

  factory GameData.fromJson(Map<String, dynamic> json) => GameData(
    level: json['level'] ?? 1,
    gold: json['gold'] ?? 0,
    inventory: List<String>.from(json['inventory'] ?? []),
  );
}

// 저장
await SaveManager.instance.save('game_data', gameData.toJson());

// 로드
final json = SaveManager.instance.load<Map>('game_data');
final data = json != null ? GameData.fromJson(json) : GameData();
```

### 2.2 오디오 시스템

```dart
// === 초기화 ===
await AudioManager.instance.init();

// === BGM ===
// 재생
AudioManager.instance.playBgm('assets/audio/bgm_main.mp3');

// 일시정지/재개
AudioManager.instance.pauseBgm();
AudioManager.instance.resumeBgm();

// 정지
AudioManager.instance.stopBgm();

// 페이드 효과
AudioManager.instance.playBgm('assets/audio/bgm_battle.mp3', fadeIn: true);
AudioManager.instance.stopBgm(fadeOut: true);

// === SFX ===
// 재생
AudioManager.instance.playSfx('assets/audio/sfx_click.mp3');
AudioManager.instance.playSfx('assets/audio/sfx_coin.mp3');

// 볼륨 (0.0 ~ 1.0)
AudioManager.instance.setBgmVolume(0.8);
AudioManager.instance.setSfxVolume(1.0);

// 음소거
AudioManager.instance.setMute(true);
```

### 2.3 분석 시스템

```dart
// === 초기화 ===
await AnalyticsManager.instance.init();

// === 이벤트 추적 ===
// 레벨 완료
AnalyticsManager.instance.logEvent('level_complete', {
  'level': 5,
  'score': 1000,
  'stars': 3,
  'time_seconds': 120,
});

// 아이템 구매
AnalyticsManager.instance.logEvent('item_purchase', {
  'item_id': 'sword_001',
  'item_name': 'Fire Sword',
  'price': 500,
  'currency': 'gold',
});

// 튜토리얼 진행
AnalyticsManager.instance.logEvent('tutorial_step', {
  'step': 3,
  'step_name': 'first_battle',
});

// === 화면 추적 ===
AnalyticsManager.instance.logScreenView('main_menu');
AnalyticsManager.instance.logScreenView('shop');
AnalyticsManager.instance.logScreenView('battle');

// === 사용자 속성 ===
AnalyticsManager.instance.setUserProperty('player_type', 'premium');
AnalyticsManager.instance.setUserProperty('level', '50');
AnalyticsManager.instance.setUserProperty('region', 'korea');
```

### 2.4 클라우드 저장

```dart
// === 초기화 ===
await CloudSaveManager.instance.initialize(
  gameId: 'my_game',
  userId: 'user_123',
  defaultResolution: ConflictResolution.useNewer,
  autoSyncInterval: Duration(minutes: 5),
);

// === 저장 ===
await CloudSaveManager.instance.save({
  'level': 10,
  'gold': 5000,
  'inventory': ['sword_001', 'shield_002'],
  'achievements': ['first_blood', 'level_10'],
});

// === 데이터 읽기 ===
final data = CloudSaveManager.instance.getData();
final level = CloudSaveManager.instance.getValue<int>('level');

// === 수동 동기화 ===
await CloudSaveManager.instance.sync();

// === 강제 업로드/다운로드 ===
await CloudSaveManager.instance.forceUpload();
await CloudSaveManager.instance.forceDownload();

// === 충돌 처리 ===
await CloudSaveManager.instance.initialize(
  gameId: 'my_game',
  userId: 'user_123',
  conflictResolver: (conflict) async {
    // 사용자에게 선택 요청
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Save Conflict'),
        content: Text('Choose which save to keep'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'local'),
            child: Text('Local'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cloud'),
            child: Text('Cloud'),
          ),
        ],
      ),
    );

    return choice == 'local' ? conflict.local : conflict.cloud;
  },
);
```

### 2.5 알림 시스템

```dart
// === 초기화 ===
await NotificationManager.instance.initialize(
  onReceived: (notification) {
    print('Received: ${notification.title}');
  },
  onTapped: (notification, actionId) {
    // 알림 탭 시 처리
    if (notification.type == NotificationType.dailyReward) {
      Navigator.pushNamed(context, '/daily_reward');
    }
  },
);

// === 권한 요청 ===
final granted = await NotificationManager.instance.requestPermission();

// === 즉시 알림 ===
await NotificationManager.instance.showNotification(
  GameNotification(
    id: 'reward_ready',
    type: NotificationType.dailyReward,
    title: 'Reward Ready!',
    body: 'Your daily reward is waiting!',
    priority: NotificationPriority.high,
  ),
);

// === 예약 알림 ===
// 일일 보상 알림
await NotificationManager.instance.scheduleDailyRewardNotification(
  time: NotificationScheduler.nextOccurrence(9, 0), // 오전 9시
  title: 'Daily Reward!',
  body: 'Claim your daily reward!',
);

// 에너지 충전 알림
await NotificationManager.instance.scheduleEnergyFullNotification(
  time: NotificationScheduler.energyRefillTime(
    currentEnergy: 5,
    maxEnergy: 10,
    regenInterval: Duration(minutes: 5),
  ),
);

// 컴백 알림
await NotificationManager.instance.scheduleComebackNotification(
  afterInactivity: Duration(days: 1),
  title: 'We miss you!',
  body: 'Come back for a special reward!',
);

// === 알림 취소 ===
await NotificationManager.instance.cancelNotification('daily_reward');
await NotificationManager.instance.cancelAllNotifications();
```

---

## 3. 게임 시스템

### 3.1 진행 시스템

```dart
// === 레벨 시스템 ===
final progression = ProgressionManager();

// 경험치 추가
progression.addExp(100);

// 현재 상태 확인
print('Level: ${progression.level}');
print('Current EXP: ${progression.currentExp}');
print('EXP to Next: ${progression.expToNextLevel}');
print('Progress: ${progression.levelProgress}'); // 0.0 ~ 1.0

// 레벨업 이벤트
progression.addListener(() {
  if (progression.justLeveledUp) {
    showLevelUpDialog(progression.level);
  }
});

// === 업그레이드 시스템 ===
final upgrades = UpgradeManager();

// 업그레이드 등록
upgrades.registerUpgrade(Upgrade(
  id: 'damage',
  name: 'Attack Power',
  baseCost: 100,
  costMultiplier: 1.5,
  maxLevel: 50,
  effect: (level) => 10 + level * 5, // 레벨당 +5 데미지
));

upgrades.registerUpgrade(Upgrade(
  id: 'health',
  name: 'Max Health',
  baseCost: 150,
  costMultiplier: 1.4,
  effect: (level) => 100 + level * 20,
));

// 업그레이드 구매
if (upgrades.canPurchase('damage', playerGold)) {
  final cost = upgrades.getCost('damage');
  playerGold -= cost;
  upgrades.purchase('damage');
}

// 효과 가져오기
final damage = upgrades.getEffect('damage'); // 현재 데미지
final health = upgrades.getEffect('health'); // 현재 체력

// === 업적 시스템 ===
final achievements = AchievementManager();

// 업적 등록
achievements.register(Achievement(
  id: 'first_blood',
  name: 'First Blood',
  description: 'Defeat your first enemy',
  reward: {'gems': 10},
));

achievements.register(Achievement(
  id: 'level_10',
  name: 'Rising Star',
  description: 'Reach level 10',
  reward: {'gems': 50},
));

// 업적 해금
achievements.unlock('first_blood');

// 조건 확인 후 해금
if (playerLevel >= 10 && !achievements.isUnlocked('level_10')) {
  achievements.unlock('level_10');
}

// === 프레스티지 시스템 ===
final prestige = PrestigeManager(
  formula: PrestigeFormula.logarithmic,
  baseRequirement: 1000000,
);

// 프레스티지 포인트 미리보기
final points = prestige.calculatePrestigePoints(totalEarnings);
print('Prestige points: $points');

// 프레스티지 가능 여부
if (prestige.canPrestige(totalEarnings)) {
  await prestige.prestige();
  // 게임 리셋 및 보너스 적용
}

// 프레스티지 보너스
final multiplier = prestige.getTotalMultiplier(); // 1.0 + (prestigePoints * 0.1)
```

### 3.2 인벤토리 시스템

```dart
final inventory = InventoryManager();

// 아이템 추가
inventory.addItem('sword_001', quantity: 1);
inventory.addItem('potion_hp', quantity: 10);

// 아이템 사용/제거
inventory.removeItem('potion_hp', quantity: 1);

// 아이템 확인
final hasSword = inventory.hasItem('sword_001');
final potionCount = inventory.getQuantity('potion_hp');

// 전체 인벤토리
final items = inventory.getAllItems();
```

### 3.3 퀘스트 시스템

```dart
// === 일일 퀘스트 ===
final dailyQuests = DailyQuestManager();

dailyQuests.addQuest(Quest(
  id: 'daily_login',
  name: 'Daily Login',
  description: 'Login today',
  target: 1,
  reward: {'gold': 100},
));

dailyQuests.addQuest(Quest(
  id: 'kill_10',
  name: 'Monster Hunter',
  description: 'Defeat 10 monsters',
  target: 10,
  reward: {'gold': 500, 'gems': 5},
));

// 진행도 업데이트
dailyQuests.updateProgress('kill_10', 1);

// 완료 확인 및 보상 수령
if (dailyQuests.isCompleted('kill_10')) {
  final reward = dailyQuests.claimReward('kill_10');
  applyReward(reward);
}

// === 주간 도전 ===
final weeklyChallenges = WeeklyChallengeManager();

weeklyChallenges.addChallenge(Challenge(
  id: 'weekly_boss',
  name: 'Boss Slayer',
  description: 'Defeat 5 bosses this week',
  target: 5,
  reward: {'gems': 100},
));
```

---

## 4. 수익화 시스템

### 4.1 가챠 시스템

```dart
// === 가챠 풀 설정 ===
final gachaManager = GachaManager();

// 배너 생성
final characterBanner = GachaPool(
  id: 'character_banner_001',
  name: 'New Hero Pickup',
  items: [
    GachaItem(
      id: 'hero_ssr_001',
      name: 'Legendary Knight',
      rarity: GachaRarity.legendary,
      weight: 1,
    ),
    GachaItem(
      id: 'hero_sr_001',
      name: 'Elite Warrior',
      rarity: GachaRarity.epic,
      weight: 5,
    ),
    GachaItem(
      id: 'hero_r_001',
      name: 'Skilled Fighter',
      rarity: GachaRarity.rare,
      weight: 20,
    ),
    GachaItem(
      id: 'hero_c_001',
      name: 'Soldier',
      rarity: GachaRarity.common,
      weight: 74,
    ),
  ],
  pickupItemIds: ['hero_ssr_001'], // 픽업 대상
  pityConfig: PityConfig(
    softPityStart: 70,  // 70회부터 확률 증가
    hardPity: 90,       // 90회 확정
  ),
);

gachaManager.addPool(characterBanner);

// === 뽑기 ===
// 단일 뽑기
if (playerGems >= 300) {
  playerGems -= 300;
  final result = gachaManager.pull('character_banner_001');
  showGachaResult(result);
}

// 10연차 (1회 SR 이상 보장)
if (playerGems >= 2700) {
  playerGems -= 2700;
  final results = gachaManager.pull10('character_banner_001');
  showGachaResults(results);
}

// === 천장 확인 ===
final pityCount = gachaManager.getPityCount('character_banner_001');
print('Current pity: $pityCount / 90');
```

### 4.2 배틀패스 시스템

```dart
// === 시즌 설정 ===
final battlePass = BattlePassManager();

final season = BattlePassSeason(
  id: 'season_001',
  name: 'Season 1: Dawn of Heroes',
  startDate: DateTime.now(),
  endDate: DateTime.now().add(Duration(days: 28)),
  maxLevel: 50,
  expPerLevel: 1000,
  tiers: [
    BattlePassTier(
      level: 1,
      freeReward: {'gold': 100},
      premiumReward: {'gems': 10},
    ),
    BattlePassTier(
      level: 5,
      freeReward: {'gold': 500},
      premiumReward: {'skin': 'rare_skin_001'},
    ),
    BattlePassTier(
      level: 10,
      freeReward: {'gold': 1000},
      premiumReward: {'character': 'hero_sr_001'},
    ),
    // ... 50레벨까지
  ],
);

await battlePass.startSeason(season);

// === 경험치 획득 ===
// 일일 미션 완료
battlePass.addExp(100);

// 주간 미션 완료
battlePass.addExp(500);

// 게임 플레이
battlePass.addExp(50);

// === 보상 수령 ===
// 무료 보상
if (battlePass.canClaimFreeReward(5)) {
  final reward = battlePass.claimReward(5, isPremium: false);
  applyReward(reward);
}

// 프리미엄 보상
if (battlePass.isPremium && battlePass.canClaimPremiumReward(5)) {
  final reward = battlePass.claimReward(5, isPremium: true);
  applyReward(reward);
}

// === 프리미엄 구매 ===
await battlePass.purchasePremium();

// === 상태 확인 ===
print('Level: ${battlePass.currentLevel}');
print('EXP: ${battlePass.currentExp} / ${battlePass.expToNextLevel}');
print('Days left: ${battlePass.remainingDays}');
```

### 4.3 상점 시스템

```dart
// === 상점 설정 ===
final shop = ShopManager();

// 기본 상품
shop.addProduct(ShopProduct(
  id: 'gem_pack_small',
  name: 'Small Gem Pack',
  description: '50 Gems',
  price: Price(amount: 0.99, currency: 'USD'),
  type: ProductType.consumable,
  rewards: {'gems': 50},
));

shop.addProduct(ShopProduct(
  id: 'gem_pack_large',
  name: 'Large Gem Pack',
  description: '500 Gems + Bonus 50',
  price: Price(amount: 9.99, currency: 'USD'),
  type: ProductType.consumable,
  rewards: {'gems': 550},
  badge: 'Best Value',
));

// 광고 제거 (비소모성)
shop.addProduct(ShopProduct(
  id: 'remove_ads',
  name: 'Remove Ads',
  description: 'Remove all ads forever',
  price: Price(amount: 2.99, currency: 'USD'),
  type: ProductType.nonConsumable,
));

// VIP 구독
shop.addProduct(ShopProduct(
  id: 'vip_monthly',
  name: 'VIP Pass',
  description: 'Daily gems, exclusive rewards',
  price: Price(amount: 4.99, currency: 'USD'),
  type: ProductType.subscription,
  subscriptionPeriod: Duration(days: 30),
));

// 번들 (한정 시간)
shop.addBundle(ShopBundle(
  id: 'starter_pack',
  name: 'Starter Pack',
  products: ['gem_pack_small', 'gold_pack_small'],
  discount: 0.3, // 30% 할인
  limitedTime: Duration(days: 7),
));

// === 구매 ===
await shop.purchase('gem_pack_small');
```

---

## 5. UI 컴포넌트

### 5.1 디자인 시스템

```dart
import 'package:mg_common_game/core/ui/mg_ui.dart';

// === 색상 ===
Container(
  color: MGColors.primary,        // 메인 브랜드 색상
  child: Text('Primary', style: TextStyle(color: MGColors.onPrimary)),
);

Container(color: MGColors.surface);      // 배경
Container(color: MGColors.gold);         // 골드/코인
Container(color: MGColors.error);        // 에러
Container(color: MGColors.success);      // 성공
Container(color: MGColors.warning);      // 경고

// 지역별 테마
MGColors.indiaPrimary    // #FF6B35 (Orange)
MGColors.africaPrimary   // #FFD700 (Gold)
MGColors.seaPrimary      // #20B2AA (Teal)
MGColors.latamPrimary    // #DC143C (Red)

// === 타이포그래피 ===
Text('Title', style: MGTextStyles.h1);
Text('Subtitle', style: MGTextStyles.h2);
Text('Body text', style: MGTextStyles.body);
Text('Small text', style: MGTextStyles.bodySmall);
Text('HUD Score: 1000', style: MGTextStyles.hud);
Text('Button', style: MGTextStyles.buttonMedium);

// === 간격 ===
Padding(padding: EdgeInsets.all(MGSpacing.md));  // 16px
SizedBox(height: MGSpacing.sm);                   // 8px
SizedBox(width: MGSpacing.lg);                    // 24px

// 간격 위젯
MGSpacing.hXs   // SizedBox(width: 4)
MGSpacing.hSm   // SizedBox(width: 8)
MGSpacing.hMd   // SizedBox(width: 16)
MGSpacing.vXs   // SizedBox(height: 4)
MGSpacing.vSm   // SizedBox(height: 8)
MGSpacing.vMd   // SizedBox(height: 16)
```

### 5.2 버튼

```dart
// Primary 버튼
MGButton.primary(
  label: 'PLAY',
  icon: Icons.play_arrow,
  onPressed: () => startGame(),
  size: MGButtonSize.large,
);

// Secondary 버튼
MGButton.secondary(
  label: 'SETTINGS',
  onPressed: () => openSettings(),
);

// Danger 버튼
MGButton.danger(
  label: 'DELETE',
  onPressed: () => confirmDelete(),
);

// 아이콘 버튼
MGIconButton(
  icon: Icons.settings,
  onPressed: () => openSettings(),
  buttonSize: MGIconButtonSize.medium,
);

MGIconButton(
  icon: Icons.pause,
  onPressed: () => pauseGame(),
  buttonSize: MGIconButtonSize.large,
);
```

### 5.3 HUD 컴포넌트

```dart
// 리소스 바
Row(
  children: [
    MGResourceBar(
      icon: Icons.monetization_on,
      value: '1,234',
      iconColor: MGColors.gold,
      onTap: () => openShop(),
    ),
    MGSpacing.hMd,
    MGResourceBar(
      icon: Icons.diamond,
      value: '50',
      iconColor: Colors.cyan,
      onTap: () => openShop(),
    ),
  ],
);

// 프로그레스 바
Column(
  children: [
    // HP 바
    MGLinearProgress(
      value: currentHp / maxHp,
      height: 16,
      valueColor: Colors.red,
      backgroundColor: Colors.red.withOpacity(0.3),
    ),
    MGSpacing.vSm,
    // 경험치 바
    MGLinearProgress(
      value: currentExp / expToNext,
      height: 8,
      valueColor: Colors.blue,
    ),
  ],
);

// 완성된 HUD 예시
class GameHud extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(MGSpacing.md),
        child: Column(
          children: [
            // 상단 바
            Row(
              children: [
                MGResourceBar(icon: Icons.star, value: '1000'),
                Spacer(),
                MGIconButton(icon: Icons.pause, onPressed: pauseGame),
              ],
            ),

            Spacer(),

            // 하단 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                MGButton.primary(label: 'ATTACK', onPressed: attack),
                MGButton.secondary(label: 'SKILL', onPressed: useSkill),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 6. 장르별 가이드

### 6.1 방치형 게임

```dart
class IdleGame {
  late OfflineProgressManager offlineManager;
  late AutoClickerManager autoClicker;
  late PrestigeManager prestige;

  Future<void> init() async {
    offlineManager = OfflineProgressManager(
      maxOfflineHours: 24,
      offlineEfficiency: 0.5,
    );

    autoClicker = AutoClickerManager();
    autoClicker.registerClicker(AutoClicker(
      id: 'basic', name: 'Basic', baseCps: 1.0, baseCost: 100,
    ));
    autoClicker.registerClicker(AutoClicker(
      id: 'advanced', name: 'Advanced', baseCps: 5.0, baseCost: 1000,
    ));

    prestige = PrestigeManager(formula: PrestigeFormula.logarithmic);
  }

  void onAppResume() {
    final rewards = offlineManager.calculateOfflineRewards(
      currentGoldPerSecond: autoClicker.totalCps,
    );
    showOfflineRewardDialog(rewards);
  }

  void onAppPause() {
    offlineManager.recordLogout();
  }
}
```

### 6.2 매치-3 게임

```dart
class Match3Game {
  late Match3Board board;

  void init() {
    board = Match3Board(
      rows: 8,
      columns: 8,
      gemTypes: GemType.values,
    );
  }

  void onSwap(int row1, int col1, int row2, int col2) {
    if (board.isValidSwap(row1, col1, row2, col2)) {
      board.swap(row1, col1, row2, col2);

      final matches = board.findMatches();
      if (matches.isNotEmpty) {
        processMatches(matches);
      } else {
        board.swap(row1, col1, row2, col2); // 되돌리기
      }
    }
  }

  void processMatches(List<Match> matches) {
    for (final match in matches) {
      addScore(match.length * 100);

      // 특수 젬 생성
      if (match.length >= 4) {
        createSpecialGem(match);
      }
    }

    board.removeMatches(matches);
    board.cascade();

    // 연쇄 매치 확인
    final newMatches = board.findMatches();
    if (newMatches.isNotEmpty) {
      processMatches(newMatches);
    }
  }
}
```

### 6.3 리듬 게임

```dart
class RhythmGame {
  late RhythmManager rhythm;
  late JudgmentSystem judgment;

  void init() {
    rhythm = RhythmManager();
    judgment = JudgmentSystem(
      perfectWindow: 50,  // ms
      greatWindow: 100,
      goodWindow: 150,
      badWindow: 200,
    );
  }

  void onNoteHit(RhythmNote note, int hitTime) {
    final result = judgment.judge(note.targetTime, hitTime);

    switch (result) {
      case Judgment.perfect:
        addScore(300);
        combo++;
        break;
      case Judgment.great:
        addScore(200);
        combo++;
        break;
      case Judgment.good:
        addScore(100);
        combo++;
        break;
      case Judgment.bad:
        addScore(50);
        combo = 0;
        break;
      case Judgment.miss:
        combo = 0;
        break;
    }
  }
}
```

### 6.4 카드 게임

```dart
class CardGame {
  late DeckManager deck;
  late CardBattleState battle;

  void init() {
    deck = DeckManager();

    // 시작 덱 구성
    deck.addCard(CardData(id: 'strike', name: 'Strike', cost: 1, damage: 6));
    deck.addCard(CardData(id: 'defend', name: 'Defend', cost: 1, block: 5));
    deck.addCard(CardData(id: 'bash', name: 'Bash', cost: 2, damage: 8, effect: 'vulnerable'));

    battle = CardBattleState(
      maxEnergy: 3,
      handSize: 5,
    );
  }

  void startTurn() {
    battle.resetEnergy();
    battle.drawCards(deck, 5);
  }

  void playCard(CardData card, BattleEntity target) {
    if (battle.canPlayCard(card)) {
      battle.spendEnergy(card.cost);

      if (card.damage > 0) {
        target.takeDamage(card.damage);
      }
      if (card.block > 0) {
        battle.addBlock(card.block);
      }

      deck.discardCard(card);
    }
  }

  void endTurn() {
    deck.discardHand();
    battle.clearBlock();
    enemyTurn();
  }
}
```

---

## 다음 단계

1. [API Reference](API_REFERENCE.md) - 전체 API 문서
2. [Coding Standards](CODING_STANDARDS.md) - 코딩 표준
3. [Example](../example/example.dart) - 전체 예제 코드

---

<p align="center">
  <b>Monthly Games</b> - mg_common_game Quick Start Guide
</p>
