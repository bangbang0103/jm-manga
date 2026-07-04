import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/models/reading_progress.dart';
import 'package:jm_manga/providers/repository_provider.dart';
import 'package:jm_manga/screens/library_screen.dart';

import '../fake_repository.dart';
import '../testable_app.dart';

class _MutableRecentRepo extends FakeApiRepository {
  List<ReadingProgress> recent = [
    ReadingProgress(
      albumId: '1',
      photoId: 'p1',
      title: 'Reading One',
      imageIndex: 1,
      isFinished: false,
      lastReadAt: '2026-06-16',
    ),
  ];

  @override
  Future<List<ReadingProgress>> getRecentProgress() async =>
      List.unmodifiable(recent);

  @override
  Future<List<ReadingProgress>> searchRecentProgress(String query) async =>
      recent
          .where(
            (p) => (p.title ?? '').toLowerCase().contains(query.toLowerCase()),
          )
          .toList();

  @override
  Future<void> deleteRecentProgress(List<String> albumIds) async {
    recent.removeWhere((p) => albumIds.contains(p.albumId));
  }

  @override
  Future<List<ReadingProgress>> getAlbumProgress(String albumId) async => [
    recent.firstWhere((p) => p.albumId == albumId),
  ];

  @override
  Future<void> syncProgress(ReadingProgress progress) async {
    recent.add(progress);
  }
}

void main() {
  group('LibraryScreen recent read', () {
    testWidgets('enters edit mode and deletes an item with undo', (
      WidgetTester tester,
    ) async {
      final repo = _MutableRecentRepo();
      await tester.pumpWidget(
        testable(
          const LibraryScreen(initialTab: 1),
          overrides: [apiRepositoryProvider.overrideWithValue(repo)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reading One'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('0 selected'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.radio_button_unchecked));
      await tester.pumpAndSettle();

      expect(find.text('Delete (1)'), findsOneWidget);

      await tester.tap(find.text('Delete (1)'));
      await tester.pumpAndSettle();
      // TopToast 的 2 秒 timer 需要走完，避免测试结束时还有未完成的 timer。
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Reading One'), findsNothing);
      expect(find.text('Undo'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(find.text('Reading One'), findsOneWidget);
    });

    testWidgets('search filters recent reads', (WidgetTester tester) async {
      final repo = _MutableRecentRepo();
      repo.recent = [
        ReadingProgress(
          albumId: '1',
          photoId: 'p1',
          title: 'NTR Academy',
          imageIndex: 1,
          isFinished: false,
          lastReadAt: '2026-06-16',
        ),
        ReadingProgress(
          albumId: '2',
          photoId: 'p2',
          title: 'Safe Title',
          imageIndex: 1,
          isFinished: false,
          lastReadAt: '2026-06-17',
        ),
      ];

      await tester.pumpWidget(
        testable(
          const LibraryScreen(initialTab: 1),
          overrides: [apiRepositoryProvider.overrideWithValue(repo)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NTR Academy'), findsOneWidget);
      expect(find.text('Safe Title'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'ntr');
      await tester.pumpAndSettle(const Duration(milliseconds: 350));

      expect(find.text('NTR Academy'), findsOneWidget);
      expect(find.text('Safe Title'), findsNothing);
    });
  });
}
