import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/models/reading_progress.dart';
import 'package:jm_manga/providers/album_providers.dart';
import 'package:jm_manga/providers/repository_provider.dart';

import '../fake_repository.dart';

class _FakeRecentRepo extends FakeApiRepository {
  List<ReadingProgress> recent = [];
  String? lastSearchQuery;
  List<String>? lastDeletedIds;
  Map<String, List<ReadingProgress>> albumProgress = {};
  List<ReadingProgress> synced = [];
  Object? searchError;
  Object? deleteError;

  @override
  Future<List<ReadingProgress>> getRecentProgress() async =>
      List.unmodifiable(recent);

  @override
  Future<List<ReadingProgress>> searchRecentProgress(String query) async {
    if (searchError != null) throw searchError!;
    lastSearchQuery = query;
    final lower = query.toLowerCase();
    return recent
        .where((p) => (p.title ?? '').toLowerCase().contains(lower))
        .toList();
  }

  @override
  Future<void> deleteRecentProgress(List<String> albumIds) async {
    if (deleteError != null) throw deleteError!;
    lastDeletedIds = albumIds;
    recent.removeWhere((p) => albumIds.contains(p.albumId));
  }

  @override
  Future<List<ReadingProgress>> getAlbumProgress(String albumId) async =>
      albumProgress[albumId] ?? [];

  @override
  Future<void> syncProgress(ReadingProgress progress) async {
    synced.add(progress);
    final index = recent.indexWhere(
      (p) => p.albumId == progress.albumId && p.photoId == progress.photoId,
    );
    if (index >= 0) {
      recent[index] = progress;
    } else {
      recent.add(progress);
    }
  }
}

void main() {
  group('RecentReadNotifier', () {
    late _FakeRecentRepo repo;
    late ProviderContainer container;

    setUp(() {
      repo = _FakeRecentRepo();
      container = ProviderContainer(
        overrides: [apiRepositoryProvider.overrideWithValue(repo)],
      );
    });

    tearDown(() => container.dispose());

    test('loads recent progress on creation', () async {
      repo.recent = [
        _progress(albumId: '1', title: 'One'),
        _progress(albumId: '2', title: 'Two'),
      ];

      final notifier = container.read(readingProgressProvider.notifier);
      await Future.delayed(Duration.zero);

      expect(
        container.read(readingProgressProvider).valueOrNull?.length,
        2,
      );
      expect(notifier.query, '');
    });

    test('search filters with debounce', () async {
      repo.recent = [
        _progress(albumId: '1', title: 'NTR Academy'),
        _progress(albumId: '2', title: 'Safe Title'),
      ];

      final notifier = container.read(readingProgressProvider.notifier);
      await Future.delayed(Duration.zero);

      notifier.search('ntr');
      expect(notifier.query, 'ntr');
      expect(container.read(readingProgressProvider).valueOrNull?.length, 2);

      await Future.delayed(const Duration(milliseconds: 350));

      expect(repo.lastSearchQuery, 'ntr');
      final items = container.read(readingProgressProvider).valueOrNull;
      expect(items?.length, 1);
      expect(items?.first.albumId, '1');
    });

    test('empty search query reloads full list', () async {
      repo.recent = [
        _progress(albumId: '1', title: 'One'),
      ];

      final notifier = container.read(readingProgressProvider.notifier);
      await Future.delayed(Duration.zero);
      notifier.search('one');
      await Future.delayed(const Duration(milliseconds: 350));

      notifier.search('');
      await Future.delayed(Duration.zero);

      expect(notifier.query, '');
      expect(
        container.read(readingProgressProvider).valueOrNull?.length,
        1,
      );
    });

    test('delete removes albums and refreshes', () async {
      repo.recent = [
        _progress(albumId: '1', title: 'One'),
        _progress(albumId: '2', title: 'Two'),
      ];
      repo.albumProgress['1'] = [repo.recent.first];

      final notifier = container.read(readingProgressProvider.notifier);
      await Future.delayed(Duration.zero);

      await notifier.delete(['1']);

      expect(repo.lastDeletedIds, ['1']);
      final items = container.read(readingProgressProvider).valueOrNull;
      expect(items?.length, 1);
      expect(items?.first.albumId, '2');
    });

    test('emits error when search fails', () async {
      repo.searchError = Exception('db error');

      final notifier = container.read(readingProgressProvider.notifier);
      await Future.delayed(Duration.zero);
      notifier.search('fail');
      await Future.delayed(const Duration(milliseconds: 350));

      expect(
        container.read(readingProgressProvider).hasError,
        isTrue,
      );
    });
  });
}

ReadingProgress _progress({
  required String albumId,
  required String title,
}) {
  return ReadingProgress(
    albumId: albumId,
    photoId: 'p$albumId',
    title: title,
    imageIndex: 1,
    isFinished: false,
    lastReadAt: '2026-01-01T00:00:00Z',
  );
}
