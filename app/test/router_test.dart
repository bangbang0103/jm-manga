import 'package:flutter/material.dart';
import 'package:jm_manga/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/models/album.dart';
import 'package:jm_manga/models/reader_initial_data.dart';
import 'package:jm_manga/providers/repository_provider.dart';
import 'package:jm_manga/router.dart';
import 'package:jm_manga/screens/album_detail_screen.dart';
import 'package:jm_manga/screens/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_repository.dart';

void main() {
  group('Router', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      router.go('/');
    });

    Future<void> pumpRouter(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiRepositoryProvider.overrideWithValue(FakeApiRepository()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('initial route shows MainScreen', (WidgetTester tester) async {
      await pumpRouter(tester);
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(MainScreen), findsOneWidget);
    });

    testWidgets('reader chapter switch keeps previous route on back stack', (
      WidgetTester tester,
    ) async {
      await pumpRouter(tester);
      final album = AlbumDetail(
        albumId: '1',
        title: 'Album Title 1',
        description: 'Description',
        author: 'Author',
        tags: const [],
        episodes: const [
          {'photo_id': 'ep1', 'title': 'Chapter 1', 'index': 1},
          {'photo_id': 'ep2', 'title': 'Chapter 2', 'index': 2},
        ],
      );

      router.push('/album/1');
      await tester.pumpAndSettle();
      router.push(
        '/reader/ep1',
        extra: ReaderInitialData(album: album, progressList: const []),
      );
      await tester.pumpAndSettle();

      expect(router.canPop(), isTrue);

      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pumpAndSettle();

      expect(find.text('Chapter ep2'), findsWidgets);
      expect(router.canPop(), isTrue);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(AlbumDetailScreen), findsOneWidget);
    });
  });
}
