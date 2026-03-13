import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/ui/dashboard/main_dashboard_widget.dart';

void main() {
  group('MainDashboardWidget Tests', () {
    testWidgets('should display dashboard', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainDashboardWidget(userId: 'test_user'),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should show bottom navigation bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainDashboardWidget(userId: 'test_user'),
        ),
      );

      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('should display all navigation tabs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainDashboardWidget(userId: 'test_user'),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Stats'), findsOneWidget);
      expect(find.text('Ranks'), findsOneWidget);
    });

    testWidgets('should show home screen initially', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainDashboardWidget(userId: 'test_user'),
        ),
      );

      expect(find.text('Game Dashboard'), findsOneWidget);
    });

    testWidgets('should display all dashboard cards', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainDashboardWidget(userId: 'test_user'),
        ),
      );

      expect(find.text('Inventory'), findsOneWidget);
      expect(find.text('Shop'), findsOneWidget);
      expect(find.text('Quests'), findsOneWidget);
      expect(find.text('Achievements'), findsOneWidget);
      expect(find.text('Friends'), findsOneWidget);
      expect(find.text('Mail'), findsOneWidget);
    });

    testWidgets('should handle tab navigation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainDashboardWidget(userId: 'test_user'),
        ),
      );

      final profileTab = find.text('Profile');
      await tester.tap(profileTab);
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('should navigate to inventory', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainDashboardWidget(userId: 'test_user'),
        ),
      );

      final inventoryCard = find.text('Inventory');
      await tester.tap(inventoryCard);
      await tester.pumpAndSettle();
    });

    testWidgets('should navigate to shop', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainDashboardWidget(userId: 'test_user'),
        ),
      );

      final shopCard = find.text('Shop');
      await tester.tap(shopCard);
      await tester.pumpAndSettle();
    });

    testWidgets('should navigate to quests', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainDashboardWidget(userId: 'test_user'),
        ),
      );

      final questCard = find.text('Quests');
      await tester.tap(questCard);
      await tester.pumpAndSettle();
    });

    testWidgets('should navigate to achievements', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainDashboardWidget(userId: 'test_user'),
        ),
      );

      final achievementCard = find.text('Achievements');
      await tester.tap(achievementCard);
      await tester.pumpAndSettle();
    });

    testWidgets('should navigate to friends', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainDashboardWidget(userId: 'test_user'),
        ),
      );

      final friendsCard = find.text('Friends');
      await tester.tap(friendsCard);
      await tester.pumpAndSettle();
    });

    testWidgets('should navigate to mail', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainDashboardWidget(userId: 'test_user'),
        ),
      );

      final mailCard = find.text('Mail');
      await tester.tap(mailCard);
      await tester.pumpAndSettle();
    });

    testWidgets('should show notification icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainDashboardWidget(userId: 'test_user'),
        ),
      );

      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });

    testWidgets('should display card icons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainDashboardWidget(userId: 'test_user'),
        ),
      );

      expect(find.byIcon(Icons.inventory_2), findsOneWidget);
      expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
      expect(find.byIcon(Icons.task_alt), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      expect(find.byIcon(Icons.people), findsOneWidget);
      expect(find.byIcon(Icons.mail), findsOneWidget);
    });
  });
}
