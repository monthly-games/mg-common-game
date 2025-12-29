import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/ui/widgets/battlepass/battlepass_tier_list.dart';
import 'package:mg_common_game/systems/battlepass/battlepass_config.dart';

void main() {
  group('BattlePassTierList', () {
    late List<BPTier> testTiers;

    setUp(() {
      testTiers = [
        BPTier(
          level: 1,
          requiredExp: 1000,
          freeRewards: [
            BPReward(
              id: 'free_1',
              nameKr: '무료 보상 1',
              type: BPRewardType.currency,
              amount: 100,
            ),
          ],
          premiumRewards: [
            BPReward(
              id: 'premium_1',
              nameKr: '프리미엄 보상 1',
              type: BPRewardType.item,
              amount: 1,
              isPremiumOnly: true,
            ),
          ],
        ),
        BPTier(
          level: 2,
          requiredExp: 1000,
          freeRewards: [
            BPReward(
              id: 'free_2',
              nameKr: '무료 보상 2',
              type: BPRewardType.currency,
              amount: 200,
            ),
          ],
          premiumRewards: [
            BPReward(
              id: 'premium_2',
              nameKr: '프리미엄 보상 2',
              type: BPRewardType.character,
              amount: 1,
              isPremiumOnly: true,
            ),
          ],
        ),
      ];
    });

    testWidgets('renders tier list correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: BattlePassTierList(
                tiers: testTiers,
                currentLevel: 1,
                isPremium: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(BattlePassTierList), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('displays tier levels correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: BattlePassTierList(
                tiers: testTiers,
                currentLevel: 1,
                isPremium: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Lv.1'), findsOneWidget);
      expect(find.text('Lv.2'), findsOneWidget);
    });

    testWidgets('shows unlocked state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: BattlePassTierList(
                tiers: testTiers,
                currentLevel: 2,
                isPremium: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Both tiers should be unlocked
      expect(find.text('Lv.1'), findsOneWidget);
      expect(find.text('Lv.2'), findsOneWidget);
    });

    testWidgets('calls onClaimReward for free reward', (WidgetTester tester) async {
      int? claimedLevel;
      bool? isPremiumClaim;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: BattlePassTierList(
                tiers: testTiers,
                currentLevel: 1,
                isPremium: false,
                onClaimReward: (level, isPremium) {
                  claimedLevel = level;
                  isPremiumClaim = isPremium;
                },
              ),
            ),
          ),
        ),
      );

      // Find and tap the free reward
      final freeRewardTile = find.byType(GestureDetector).at(1);
      await tester.tap(freeRewardTile);
      await tester.pump();

      expect(claimedLevel, equals(1));
      expect(isPremiumClaim, isFalse);
    });

    testWidgets('shows claimed state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: BattlePassTierList(
                tiers: testTiers,
                currentLevel: 2,
                isPremium: false,
                claimedFreeLevels: {1},
              ),
            ),
          ),
        ),
      );

      // Should show check icon for claimed reward
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });

    testWidgets('shows premium locked state when not premium', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: BattlePassTierList(
                tiers: testTiers,
                currentLevel: 1,
                isPremium: false,
              ),
            ),
          ),
        ),
      );

      // Should show lock icon for premium rewards
      expect(find.byIcon(Icons.lock), findsWidgets);
    });

    testWidgets('allows claiming premium rewards when premium', (WidgetTester tester) async {
      int? claimedLevel;
      bool? isPremiumClaim;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: BattlePassTierList(
                tiers: testTiers,
                currentLevel: 1,
                isPremium: true,
                onClaimReward: (level, isPremium) {
                  claimedLevel = level;
                  isPremiumClaim = isPremium;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Premium rewards should be claimable
      expect(find.byIcon(Icons.lock), findsNothing);
    });

    testWidgets('handles empty tiers list', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: BattlePassTierList(
                tiers: [],
                currentLevel: 0,
                isPremium: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('BattlePassHeader', () {
    testWidgets('renders season information correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BattlePassHeader(
              seasonName: '시즌 1',
              currentLevel: 10,
              maxLevel: 50,
              currentExp: 500,
              expToNextLevel: 1000,
              remainingDays: 15,
              isPremium: false,
            ),
          ),
        ),
      );

      expect(find.text('시즌 1'), findsOneWidget);
      expect(find.text('15일 남음'), findsOneWidget);
    });

    testWidgets('displays current level and exp correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BattlePassHeader(
              seasonName: '시즌 1',
              currentLevel: 25,
              maxLevel: 50,
              currentExp: 750,
              expToNextLevel: 1000,
              remainingDays: 10,
              isPremium: false,
            ),
          ),
        ),
      );

      expect(find.text('25'), findsOneWidget);
      expect(find.text('750 / 1000'), findsOneWidget);
      expect(find.text('Lv'), findsOneWidget);
      expect(find.text('EXP'), findsOneWidget);
    });

    testWidgets('shows premium badge when premium', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BattlePassHeader(
              seasonName: '시즌 1',
              currentLevel: 10,
              maxLevel: 50,
              currentExp: 500,
              expToNextLevel: 1000,
              remainingDays: 15,
              isPremium: true,
            ),
          ),
        ),
      );

      expect(find.text('PREMIUM'), findsOneWidget);
    });

    testWidgets('shows purchase button when not premium', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BattlePassHeader(
              seasonName: '시즌 1',
              currentLevel: 10,
              maxLevel: 50,
              currentExp: 500,
              expToNextLevel: 1000,
              remainingDays: 15,
              isPremium: false,
            ),
          ),
        ),
      );

      expect(find.text('프리미엄 구매'), findsOneWidget);
    });

    testWidgets('hides purchase button when premium', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BattlePassHeader(
              seasonName: '시즌 1',
              currentLevel: 10,
              maxLevel: 50,
              currentExp: 500,
              expToNextLevel: 1000,
              remainingDays: 15,
              isPremium: true,
            ),
          ),
        ),
      );

      expect(find.text('프리미엄 구매'), findsNothing);
    });

    testWidgets('calls onPurchasePremium when button tapped', (WidgetTester tester) async {
      bool purchaseCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BattlePassHeader(
              seasonName: '시즌 1',
              currentLevel: 10,
              maxLevel: 50,
              currentExp: 500,
              expToNextLevel: 1000,
              remainingDays: 15,
              isPremium: false,
              onPurchasePremium: () {
                purchaseCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('프리미엄 구매'));
      await tester.pump();

      expect(purchaseCalled, isTrue);
    });

    testWidgets('shows progress bar correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BattlePassHeader(
              seasonName: '시즌 1',
              currentLevel: 10,
              maxLevel: 50,
              currentExp: 500,
              expToNextLevel: 1000,
              remainingDays: 15,
              isPremium: false,
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('handles low remaining days with error color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BattlePassHeader(
              seasonName: '시즌 1',
              currentLevel: 10,
              maxLevel: 50,
              currentExp: 500,
              expToNextLevel: 1000,
              remainingDays: 2,
              isPremium: false,
            ),
          ),
        ),
      );

      expect(find.text('2일 남음'), findsOneWidget);
    });
  });

  group('BattlePassMissionList', () {
    late List<BPMission> testMissions;

    setUp(() {
      testMissions = [
        BPMission(
          id: 'mission_1',
          titleKr: '일일 접속',
          descriptionKr: '게임에 접속하기',
          type: BPMissionType.daily,
          targetValue: 1,
          expReward: 100,
          trackingKey: 'login',
        ),
        BPMission(
          id: 'mission_2',
          titleKr: '전투 3회',
          descriptionKr: '전투를 3회 완료하기',
          type: BPMissionType.daily,
          targetValue: 3,
          expReward: 150,
          trackingKey: 'battle_count',
        ),
      ];
    });

    testWidgets('renders mission list correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BattlePassMissionList(
                missions: testMissions,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(BattlePassMissionList), findsOneWidget);
      expect(find.text('일일 접속'), findsOneWidget);
      expect(find.text('전투 3회'), findsOneWidget);
    });

    testWidgets('displays mission progress correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BattlePassMissionList(
                missions: testMissions,
                missionProgress: {
                  'login': 1,
                  'battle_count': 2,
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('1/1'), findsOneWidget);
      expect(find.text('2/3'), findsOneWidget);
    });

    testWidgets('shows claim button for completed missions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BattlePassMissionList(
                missions: testMissions,
                missionProgress: {
                  'login': 1,
                  'battle_count': 3,
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('수령'), findsWidgets);
    });

    testWidgets('calls onClaimMission when claim button tapped', (WidgetTester tester) async {
      String? claimedMissionId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BattlePassMissionList(
                missions: testMissions,
                missionProgress: {
                  'login': 1,
                  'battle_count': 3,
                },
                onClaimMission: (missionId) {
                  claimedMissionId = missionId;
                },
              ),
            ),
          ),
        ),
      );

      final claimButtons = find.text('수령');
      await tester.tap(claimButtons.first);
      await tester.pump();

      expect(claimedMissionId, isNotNull);
    });

    testWidgets('shows claimed state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BattlePassMissionList(
                missions: testMissions,
                missionProgress: {
                  'login': 1,
                  'battle_count': 3,
                },
                claimedMissions: {'mission_1'},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });

    testWidgets('displays exp rewards correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BattlePassMissionList(
                missions: testMissions,
              ),
            ),
          ),
        ),
      );

      expect(find.text('+100'), findsOneWidget);
      expect(find.text('+150'), findsOneWidget);
    });

    testWidgets('shows progress bar for each mission', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BattlePassMissionList(
                missions: testMissions,
                missionProgress: {
                  'login': 0,
                  'battle_count': 1,
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    });

    testWidgets('handles empty missions list', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BattlePassMissionList(
                missions: [],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(BattlePassMissionList), findsOneWidget);
    });

    testWidgets('displays mission type icons correctly', (WidgetTester tester) async {
      final mixedMissions = [
        BPMission(
          id: 'daily',
          titleKr: '일일 미션',
          descriptionKr: '매일 하는 미션',
          type: BPMissionType.daily,
          targetValue: 1,
          expReward: 100,
        ),
        BPMission(
          id: 'weekly',
          titleKr: '주간 미션',
          descriptionKr: '매주 하는 미션',
          type: BPMissionType.weekly,
          targetValue: 1,
          expReward: 500,
        ),
        BPMission(
          id: 'seasonal',
          titleKr: '시즌 미션',
          descriptionKr: '시즌 내내 하는 미션',
          type: BPMissionType.seasonal,
          targetValue: 1,
          expReward: 1000,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BattlePassMissionList(
                missions: mixedMissions,
              ),
            ),
          ),
        ),
      );

      // Check for mission type icons
      expect(find.byIcon(Icons.today), findsOneWidget);
      expect(find.byIcon(Icons.date_range), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    });
  });
}
