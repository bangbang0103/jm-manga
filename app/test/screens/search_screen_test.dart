import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/screens/search_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../testable_app.dart';

void main() {
  group('SearchScreen history', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'searchHistory': jsonEncode(['manga', 'comic']),
      });
    });

    testWidgets('renders history list when query is empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testable(const SearchScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Search history'), findsOneWidget);
      expect(find.text('manga'), findsOneWidget);
      expect(find.text('comic'), findsOneWidget);
    });

    testWidgets('tapping a history item executes search', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testable(const SearchScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('manga'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Search Result'), findsOneWidget);
    });

    testWidgets('deletes a single history item', (WidgetTester tester) async {
      await tester.pumpWidget(testable(const SearchScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('manga'), findsNothing);
      expect(find.text('comic'), findsOneWidget);
    });

    testWidgets('clears all history after confirmation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testable(const SearchScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clear all'));
      await tester.pumpAndSettle();

      expect(find.text('Clear search history?'), findsOneWidget);

      final dialogClear = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Clear all'),
      );
      await tester.tap(dialogClear);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('manga'), findsNothing);
      expect(find.text('comic'), findsNothing);
      expect(find.text('No search history yet'), findsOneWidget);
    });
  });
}
