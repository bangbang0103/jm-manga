import 'package:jm_manga/local/local_manga_records.dart';
import 'package:jm_manga/models/album.dart';
import 'package:jm_manga/models/reading_progress.dart';
import 'package:sqflite/sqflite.dart';
import 'package:test/test.dart';

import 'test_database_helper.dart';

void main() {
  group('LocalMangaRecords', () {
    late Database db;
    late LocalMangaRecords records;

    setUp(() async {
      db = await createTestDatabase();
      records = LocalMangaRecords(Future.value(db));
    });

    tearDown(() async {
      await db.close();
    });

    test('keeps recent progress isolated by owner and album', () async {
      await records.saveProgress(
        'device:a',
        progress(
          albumId: '1',
          photoId: 'p1',
          lastReadAt: '2026-01-01T00:00:00Z',
        ),
      );
      await records.saveProgress(
        'device:a',
        progress(
          albumId: '1',
          photoId: 'p2',
          lastReadAt: '2026-01-02T00:00:00Z',
        ),
      );
      await records.saveProgress(
        'device:a',
        progress(
          albumId: '2',
          photoId: 'p3',
          lastReadAt: '2026-01-03T00:00:00Z',
        ),
      );
      await records.saveProgress(
        'device:b',
        progress(
          albumId: '9',
          photoId: 'p9',
          lastReadAt: '2026-01-04T00:00:00Z',
        ),
      );

      final recent = await records.recentProgress('device:a');
      expect(recent.map((item) => item.albumId), ['2', '1']);
      expect(recent[1].photoId, 'p2');

      final album = await records.albumProgress('device:a', '1');
      expect(album.map((item) => item.photoId), ['p2', 'p1']);

      final otherOwner = await records.recentProgress('device:b');
      expect(otherOwner.single.albumId, '9');
    });

    test('upserts, paginates, and removes favorites', () async {
      for (var i = 0; i < 55; i++) {
        await records.upsertFavorite(
          'jm:alice',
          AlbumItem(albumId: '$i', title: 'Album $i', tags: const []),
          syncStatus: 'synced',
        );
      }

      expect(await records.favoriteExists('jm:alice', '54'), isTrue);
      expect(await records.favoriteExists('jm:bob', '54'), isFalse);

      final firstPage = await records.favoriteRecords('jm:alice');
      final secondPage = await records.favoriteRecords('jm:alice', page: 2);
      expect(firstPage, hasLength(LocalMangaRecords.favoritePageSize));
      expect(secondPage, hasLength(5));
      expect(firstPage.first.albumId, '54');

      await records.upsertFavorite(
        'jm:alice',
        AlbumItem(albumId: '54', title: 'Updated', tags: const []),
        syncStatus: 'synced',
      );
      final updated = await records.favoriteRecords('jm:alice');
      expect(updated.first.title, 'Updated');

      expect(await records.removeFavorite('jm:alice', '54'), isTrue);
      expect(await records.favoriteExists('jm:alice', '54'), isFalse);
      expect(await records.removeFavorite('jm:alice', 'missing'), isFalse);
    });

    test('reports database size', () async {
      await records.saveProgress(
        'jm:alice',
        progress(
          albumId: '1',
          photoId: 'p1',
          lastReadAt: '2026-01-01T00:00:00Z',
        ),
      );

      final sizes = await records.sizes('jm:alice');
      expect(sizes['covers'], 0);
      expect(sizes['images'], 0);
      // 内存数据库没有文件路径，database 大小可能为 0；真实设备上为数据库文件大小。
      expect(sizes['database'], greaterThanOrEqualTo(0));
    });

    test('upserts and reads chapter manifest', () async {
      await records.upsertChapterManifest(
        ChapterManifest(
          photoId: 'p1',
          albumId: 'a1',
          title: 'Chapter 1',
          imageNames: const ['00001.webp', '00002.webp'],
        ),
      );

      final manifest = await records.chapterManifest('p1');

      expect(manifest, isNotNull);
      expect(manifest!.albumId, 'a1');
      expect(manifest.title, 'Chapter 1');
      expect(manifest.imageNames, ['00001.webp', '00002.webp']);
      expect(manifest.pageCount, 2);
    });

    test('deleteAlbumProgress removes only matching album and owner', () async {
      await records.saveProgress(
        'jm:alice',
        progress(
          albumId: '1',
          photoId: 'p1',
          lastReadAt: '2026-01-01T00:00:00Z',
        ),
      );
      await records.saveProgress(
        'jm:alice',
        progress(
          albumId: '1',
          photoId: 'p2',
          lastReadAt: '2026-01-02T00:00:00Z',
        ),
      );
      await records.saveProgress(
        'jm:alice',
        progress(
          albumId: '2',
          photoId: 'p3',
          lastReadAt: '2026-01-03T00:00:00Z',
        ),
      );
      await records.saveProgress(
        'jm:bob',
        progress(
          albumId: '1',
          photoId: 'p4',
          lastReadAt: '2026-01-04T00:00:00Z',
        ),
      );

      final deleted = await records.deleteAlbumProgress('jm:alice', '1');
      expect(deleted, 2);

      final recent = await records.recentProgress('jm:alice');
      expect(recent.map((r) => r.albumId), ['2']);

      final otherOwner = await records.recentProgress('jm:bob');
      expect(otherOwner.single.albumId, '1');
    });

    test('deleteAlbumProgressList removes multiple albums', () async {
      await records.saveProgress(
        'jm:alice',
        progress(
          albumId: '1',
          photoId: 'p1',
          lastReadAt: '2026-01-01T00:00:00Z',
        ),
      );
      await records.saveProgress(
        'jm:alice',
        progress(
          albumId: '2',
          photoId: 'p2',
          lastReadAt: '2026-01-02T00:00:00Z',
        ),
      );
      await records.saveProgress(
        'jm:alice',
        progress(
          albumId: '3',
          photoId: 'p3',
          lastReadAt: '2026-01-03T00:00:00Z',
        ),
      );

      final deleted = await records.deleteAlbumProgressList('jm:alice', [
        '1',
        '2',
      ]);
      expect(deleted, 2);

      final recent = await records.recentProgress('jm:alice');
      expect(recent.single.albumId, '3');
    });

    test('searchRecentProgress filters by title case-insensitively', () async {
      await records.saveProgress(
        'jm:alice',
        progress(
          albumId: '1',
          photoId: 'p1',
          title: 'NTR Academy',
          lastReadAt: '2026-01-01T00:00:00Z',
        ),
      );
      await records.saveProgress(
        'jm:alice',
        progress(
          albumId: '2',
          photoId: 'p2',
          title: 'Safe Title',
          lastReadAt: '2026-01-02T00:00:00Z',
        ),
      );
      await records.saveProgress(
        'jm:alice',
        progress(
          albumId: '1',
          photoId: 'p3',
          title: 'NTR Academy',
          lastReadAt: '2026-01-03T00:00:00Z',
        ),
      );

      final results = await records.searchRecentProgress('jm:alice', 'ntr');
      expect(results, hasLength(1));
      expect(results.single.albumId, '1');
      expect(results.single.photoId, 'p3');

      final empty = await records.searchRecentProgress('jm:alice', 'missing');
      expect(empty, isEmpty);
    });
  });
}

ReadingProgress progress({
  required String albumId,
  required String photoId,
  required String lastReadAt,
  String? title,
}) {
  return ReadingProgress(
    albumId: albumId,
    photoId: photoId,
    title: title ?? 'Chapter $photoId',
    imageIndex: 1,
    isFinished: false,
    lastReadAt: lastReadAt,
  );
}
