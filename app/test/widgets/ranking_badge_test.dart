import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/core/theme/app_theme.dart';
import 'package:jm_manga/widgets/ranking_badge.dart';

void main() {
  group('RankingBadge', () {
    testWidgets('renders rank number', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: RankingBadge(rank: 5)),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('top 3 use theme accent colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: Column(
              children: [
                RankingBadge(rank: 1),
                RankingBadge(rank: 2),
                RankingBadge(rank: 3),
              ],
            ),
          ),
        ),
      );

      final scheme = Theme.of(tester.element(find.byType(RankingBadge).first)
              as BuildContext)
          .colorScheme;
      final containers = tester.widgetList<Container>(find.byType(Container));
      final colors = containers.map((c) => (c.decoration as BoxDecoration).color);

      expect(colors, [scheme.tertiary, scheme.surfaceContainerHighest, scheme.secondary]);
    });
  });
}
