import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/widgets/ranking_badge.dart';

void main() {
  group('RankingBadge', () {
    testWidgets('renders rank number', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: RankingBadge(rank: 5))),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('top 3 use gold, silver, bronze colors', (
      WidgetTester tester,
    ) async {
      for (final entry in {
        1: const Color(0xFFFFD700),
        2: const Color(0xFFC0C0C0),
        3: const Color(0xFFCD7F32),
      }.entries) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: RankingBadge(rank: entry.key)),
          ),
        );

        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, entry.value);
      }
    });
  });
}
