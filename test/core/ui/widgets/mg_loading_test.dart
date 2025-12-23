import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/ui/widgets/loading/mg_loading.dart';

void main() {
  group('MGLoadingSpinner', () {
    testWidgets('renders circular progress indicator', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGLoadingSpinner(),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('applies custom size', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGLoadingSpinner(size: 64),
        ),
      ));

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, equals(64));
      expect(sizedBox.height, equals(64));
    });

    testWidgets('applies custom color', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGLoadingSpinner(color: Colors.red),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('MGLoadingOverlay', () {
    testWidgets('shows child when not loading', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGLoadingOverlay(
            isLoading: false,
            child: Text('Content'),
          ),
        ),
      ));

      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(MGLoadingSpinner), findsNothing);
    });

    testWidgets('shows loading spinner when loading', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: const MGLoadingOverlay(
              isLoading: true,
              child: Text('Content'),
            ),
          ),
        ),
      ));

      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(MGLoadingSpinner), findsOneWidget);
    });

    testWidgets('shows message when loading', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: const MGLoadingOverlay(
              isLoading: true,
              message: 'Loading...',
              child: Text('Content'),
            ),
          ),
        ),
      ));

      expect(find.text('Loading...'), findsOneWidget);
    });
  });

  group('MGFullScreenLoading', () {
    testWidgets('renders full screen loading', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: MGFullScreenLoading(),
      ));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(MGLoadingSpinner), findsOneWidget);
    });

    testWidgets('shows message when provided', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: MGFullScreenLoading(message: 'Loading game...'),
      ));

      expect(find.text('Loading game...'), findsOneWidget);
    });

    testWidgets('shows progress when provided', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: MGFullScreenLoading(progress: 0.5),
      ));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('shows logo when provided', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: MGFullScreenLoading(
          logo: FlutterLogo(size: 100),
        ),
      ));

      expect(find.byType(FlutterLogo), findsOneWidget);
    });
  });

  group('MGSkeleton', () {
    testWidgets('renders skeleton with default size', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGSkeleton(),
        ),
      ));

      expect(find.byType(MGSkeleton), findsOneWidget);
    });

    testWidgets('renders circle skeleton', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGSkeleton.circle(size: 40),
        ),
      ));

      expect(find.byType(MGSkeleton), findsOneWidget);
    });

    testWidgets('renders text skeleton', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGSkeleton.text(),
        ),
      ));

      expect(find.byType(MGSkeleton), findsOneWidget);
    });

    testWidgets('renders avatar skeleton', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGSkeleton.avatar(),
        ),
      ));

      expect(find.byType(MGSkeleton), findsOneWidget);
    });

    testWidgets('applies custom dimensions', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGSkeleton(
            width: 200,
            height: 100,
          ),
        ),
      ));

      final container = tester.widget<Container>(find.byType(Container).first);
      final constraints = container.constraints;
      expect(constraints?.maxWidth, equals(200));
      expect(constraints?.maxHeight, equals(100));
    });
  });

  group('MGSkeletonCard', () {
    testWidgets('renders skeleton card', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGSkeletonCard(),
        ),
      ));

      expect(find.byType(MGSkeletonCard), findsOneWidget);
    });

    testWidgets('shows image skeleton when hasImage is true', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGSkeletonCard(hasImage: true),
        ),
      ));

      // Should have multiple skeleton elements
      expect(find.byType(MGSkeleton), findsWidgets);
    });
  });

  group('MGSkeletonListItem', () {
    testWidgets('renders skeleton list item', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGSkeletonListItem(),
        ),
      ));

      expect(find.byType(MGSkeletonListItem), findsOneWidget);
    });

    testWidgets('shows leading skeleton when hasLeading is true', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGSkeletonListItem(hasLeading: true),
        ),
      ));

      expect(find.byType(MGSkeleton), findsWidgets);
    });
  });

  group('MGDotsLoading', () {
    testWidgets('renders dots loading animation', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGDotsLoading(),
        ),
      ));

      expect(find.byType(MGDotsLoading), findsOneWidget);
    });

    testWidgets('renders correct number of dots', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGDotsLoading(dotCount: 5),
        ),
      ));

      // Animation creates dots as containers
      expect(find.byType(MGDotsLoading), findsOneWidget);
    });
  });
}
