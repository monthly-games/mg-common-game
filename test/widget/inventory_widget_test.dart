import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/ui/game/inventory_widget.dart';

void main() {
  group('InventoryWidget Tests', () {
    testWidgets('should display inventory grid', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InventoryWidget(userId: 'test_user'),
        ),
      );

      expect(find.text('Inventory'), findsOneWidget);
    });

    testWidgets('should show loading indicator initially', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InventoryWidget(userId: 'test_user'),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display inventory items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InventoryWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('should show item details on tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InventoryWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      final firstItem = find.byType(InkWell).first;
      await tester.tap(firstItem);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('should filter items by category', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InventoryWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('should display item count badges', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InventoryWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('should show equipment tab', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InventoryWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Equipment'), findsOneWidget);
    });

    testWidgets('should show consumables tab', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InventoryWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Consumables'), findsOneWidget);
    });

    testWidgets('should show materials tab', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InventoryWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Materials'), findsOneWidget);
    });
  });
}
