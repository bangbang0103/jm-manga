import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/screens/album_detail_screen.dart';
import 'package:jm_manga/screens/library_screen.dart';
import 'package:jm_manga/screens/rankings_screen.dart';
import 'package:jm_manga/screens/reader_screen.dart';
import 'package:jm_manga/screens/search_screen.dart';
import 'package:jm_manga/screens/settings_screen.dart';

import '../testable_app.dart';

void main() {
  group('Screens', () {
    testWidgets('SearchScreen renders search field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testable(const SearchScreen()));
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('RankingsScreen renders tabs', (WidgetTester tester) async {
      await tester.pumpWidget(testable(const RankingsScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Rankings'), findsOneWidget);
      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
    });

    testWidgets('LibraryScreen prompts to add account when none selected', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testable(const LibraryScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Please add a JM account in Settings'), findsOneWidget);
      expect(find.text('Go to Settings'), findsOneWidget);
    });

    testWidgets('AlbumDetailScreen renders title and read button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        testable(const AlbumDetailScreen(albumId: '12345')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Read Now'), findsOneWidget);
      expect(find.text('Album Title 12345'), findsWidgets);
    });

    testWidgets('ReaderScreen renders page list', (WidgetTester tester) async {
      await tester.pumpWidget(testable(const ReaderScreen(photoId: '999')));
      await tester.pumpAndSettle();
      expect(find.text('Page 1 / 0'), findsOneWidget);
    });

    testWidgets('SettingsScreen renders service, accounts and disconnect', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testable(const SettingsScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Service'), findsOneWidget);
      expect(find.text('JM Comic Accounts'), findsOneWidget);
      expect(find.text('Disconnect Service'), findsOneWidget);
      expect(find.text('Anonymous / No account'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });
}
