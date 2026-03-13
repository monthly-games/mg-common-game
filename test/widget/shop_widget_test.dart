import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/ui/game/shop_widget.dart';

void main() {
  group('ShopWidget Tests', () {
    testWidgets('should display shop title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ShopWidget(userId: 'test_user'),
        ),
      );

      expect(find.text('Shop'), findsOneWidget);
    });

    testWidgets('should show items and bundles tabs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ShopWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Items'), findsOneWidget);
      expect(find.text('Bundles'), findsOneWidget);
    });

    testWidgets('should display loading indicator initially', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ShopWidget(userId: 'test_user'),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display shop items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ShopWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('should show item prices', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ShopWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('should handle purchase button tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ShopWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      final purchaseButton = find.byType(ElevatedButton).first;
      await tester.tap(purchaseButton);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('should display discount badges', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ShopWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('should show currency selector', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ShopWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(DropdownButton), findsOneWidget);
    });

    testWidgets('should display featured items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ShopWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Card), findsWidgets);
    });
  });
}
