import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jm_manga/l10n/app_localizations.dart';
import 'package:jm_manga/models/album.dart';
import 'package:jm_manga/providers/album_providers.dart';
import 'package:jm_manga/providers/repository_provider.dart';
import 'package:jm_manga/screens/album_detail_screen.dart';
import 'package:jm_manga/screens/library_screen.dart';
import 'package:jm_manga/screens/rankings_screen.dart';
import 'package:jm_manga/screens/reader_screen.dart';
import 'package:jm_manga/screens/search_screen.dart';
import 'package:jm_manga/screens/settings_screen.dart';

import '../fake_repository.dart';
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

    testWidgets('LibraryScreen renders favorites without account', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testable(const LibraryScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Favorite'), findsOneWidget);
      expect(find.text('Favorite One'), findsOneWidget);
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

    testWidgets('AlbumDetailScreen toggles chapter sort order', (
      WidgetTester tester,
    ) async {
      final album = AlbumDetail(
        albumId: '12345',
        title: 'Album Title 12345',
        description: 'Description',
        author: 'Author',
        tags: const [],
        episodes: [
          {'photo_id': 'ep1', 'title': 'Chapter 1', 'index': 1},
          {'photo_id': 'ep2', 'title': 'Chapter 2', 'index': 2},
          {'photo_id': 'ep3', 'title': 'Chapter 3', 'index': 3},
        ],
        isFavorite: false,
      );

      await tester.pumpWidget(
        testable(
          const AlbumDetailScreen(albumId: '12345'),
          locale: const Locale('zh'),
          overrides: [
            albumDetailProvider.overrideWith((ref, albumId) async => album),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // 默认正序：首个可见章节是 Chapter 1，按钮显示「正序」。
      expect(find.text('正序'), findsOneWidget);
      expect(find.text('Chapter 1'), findsOneWidget);
      expect(find.text('Chapter 3'), findsNothing);

      await tester.tap(find.text('正序'));
      await tester.pumpAndSettle();

      // 倒序并回到顶部：首个可见章节变为 Chapter 3，按钮显示「倒序」。
      expect(find.text('倒序'), findsOneWidget);
      expect(find.text('Chapter 3'), findsOneWidget);
      expect(find.text('Chapter 1'), findsNothing);
    });

    testWidgets('AlbumDetailScreen does not stack app bars during refresh', (
      WidgetTester tester,
    ) async {
      final completers = <Completer<AlbumDetail>>[];
      final container = ProviderContainer(
        overrides: [
          apiRepositoryProvider.overrideWithValue(FakeApiRepository()),
          albumDetailProvider.overrideWith((ref, albumId) {
            final completer = Completer<AlbumDetail>();
            completers.add(completer);
            return completer.future;
          }),
        ],
      );
      addTearDown(container.dispose);

      // 占位 AppBar 的特征：title 是 SizedBox.shrink()；
      // SliverAppBar 内部的 AppBar title 是 Row，不会被匹配。
      final placeholderAppBar = find.byWidgetPredicate(
        (widget) => widget is AppBar && widget.title is SizedBox,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AlbumDetailScreen(albumId: '12345'),
          ),
        ),
      );

      // 初始加载中：无数据，显示占位 AppBar。
      expect(placeholderAppBar, findsOneWidget);

      completers.single.complete(
        await FakeApiRepository().getAlbumDetail('12345'),
      );
      await tester.pumpAndSettle();
      expect(placeholderAppBar, findsNothing);
      expect(find.byType(SliverAppBar), findsOneWidget);

      // 模拟从阅读器返回触发的刷新：isLoading=true 但仍持有旧数据，
      // 此时不应再出现占位 AppBar（否则会出现双层 TopBar）。
      container.refresh(albumDetailProvider('12345'));
      await tester.pump();
      expect(completers.length, 2, reason: 'refresh 应触发 provider 重建');
      expect(placeholderAppBar, findsNothing);
      expect(find.byType(SliverAppBar), findsOneWidget);

      completers.last.complete(
        await FakeApiRepository().getAlbumDetail('12345'),
      );
      await tester.pumpAndSettle();
      expect(placeholderAppBar, findsNothing);
      expect(find.byType(SliverAppBar), findsOneWidget);
    });

    testWidgets('ReaderScreen renders page list', (WidgetTester tester) async {
      await tester.pumpWidget(testable(const ReaderScreen(photoId: '999')));
      await tester.pumpAndSettle();
      expect(find.text('Page 1 / 0'), findsOneWidget);
    });

    testWidgets('SettingsScreen renders accounts and cache', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testable(const SettingsScreen()));
      await tester.pumpAndSettle();
      expect(find.text('JM Comic Accounts'), findsOneWidget);
      expect(find.text('Cache'), findsOneWidget);
      expect(find.text('Anonymous / No account'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });
}
