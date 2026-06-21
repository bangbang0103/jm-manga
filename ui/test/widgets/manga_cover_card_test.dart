import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/widgets/manga_cover_card.dart';

void main() {
  group('MangaCoverCard', () {
    testWidgets('renders title and aspect ratio 2:3', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MangaCoverCard(title: 'Test Manga', imageUrl: ''),
          ),
        ),
      );

      expect(find.text('Test Manga'), findsOneWidget);

      final aspectRatio = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(aspectRatio.aspectRatio, closeTo(2 / 3, 0.01));
    });

    testWidgets('renders HOT badge when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MangaCoverCard(
              title: 'Hot Manga',
              imageUrl: '',
              badgeText: 'HOT',
            ),
          ),
        ),
      );

      expect(find.text('HOT'), findsOneWidget);
    });
  });
}
