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
          AlbumItem(
            albumId: '$i',
            title: 'Album $i',
            tags: const [],
          ),
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
        AlbumItem(
          albumId: '54',
          title: 'Updated',
          tags: const [],
        ),
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
  });
}

ReadingProgress progress({
  required String albumId,
  required String photoId,
  required String lastReadAt,
}) {
  return ReadingProgress(
    albumId: albumId,
    photoId: photoId,
    title: 'Chapter $photoId',
    imageIndex: 1,
    isFinished: false,
    lastReadAt: lastReadAt,
  );
}
