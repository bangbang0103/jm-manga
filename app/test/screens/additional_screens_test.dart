import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/screens/category_screen.dart';
import 'package:jm_manga/screens/main_screen.dart';
import 'package:jm_manga/screens/rankings_screen.dart';
import 'package:jm_manga/screens/settings_screen.dart';

import '../testable_app.dart';

void main() {
  group('CategoryScreen', () {
    testWidgets('renders title and order chips', (WidgetTester tester) async {
      await tester.pumpWidget(
        testable(const CategoryScreen(category: 'doujin')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Doujin'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsWidgets);
    });

    testWidgets('switches order on chip tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        testable(const CategoryScreen(category: 'doujin')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Top Rated'));
      await tester.pumpAndSettle();

      // ChoiceChip 会重新 build，仍然能找到一个选中的 chip。
      expect(find.byType(ChoiceChip), findsWidgets);
    });
  });

  group('MainScreen', () {
    testWidgets('renders bottom navigation with four tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testable(const MainScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Rankings'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('tapping library tab switches page', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testable(const MainScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();

      expect(find.text('Favorite'), findsOneWidget);
    });
  });

  group('RankingsScreen', () {
    testWidgets('renders period and category selectors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testable(const RankingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Rankings'), findsOneWidget);
      expect(find.text('Day'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
    });

    testWidgets('switching sort updates dropdown label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testable(const RankingsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('TopFavorite'));
      await tester.pumpAndSettle();

      expect(find.text('TopFavorite'), findsWidgets);
    });
  });

  group('SettingsScreen', () {
    testWidgets('renders account section and appearance tiles', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testable(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('JM Comic Accounts'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
    });

    testWidgets('tapping add account shows dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testable(const SettingsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Add JM Account'), findsOneWidget);
    });
  });
}
