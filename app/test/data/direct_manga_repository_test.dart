import 'package:jm_manga/data/direct_manga_repository.dart';
import 'package:jm_manga/network/jm/jm_client.dart';
import 'package:jm_manga/network/jm/jm_constants.dart';
import 'package:jm_manga/network/jm/jm_models.dart';
import 'package:jm_manga/network/jm/jm_session_store.dart';
import 'package:jm_manga/local/local_manga_records.dart';
import 'package:jm_manga/local/local_manga_store.dart';
import 'package:jm_manga/models/album.dart';
import 'package:test/test.dart';

import '../local/test_database_helper.dart';

LocalMangaStore _createLocalStore() {
  return LocalMangaStore(records: LocalMangaRecords(createTestDatabase()));
}

void main() {
  group('DirectMangaRepository', () {
    test(
      'toggleFavorite adds missing local favorite before removing it',
      () async {
        final localStore = _createLocalStore();
        final repo = DirectMangaRepository(
          client: FakeJmClient(),
          ownerKey: 'device:test',
          localStore: localStore,
          sessionStore: MemorySessionStore(),
        );
        final item = AlbumItem(
          albumId: '42',
          title: 'Forty Two',
          tags: const [],
        );

        final added = await repo.toggleFavorite(item.albumId, item: item);
        final afterAdd = await repo.getFavorites();

        expect(added['favorited'], isTrue);
        expect(afterAdd.map((item) => item.albumId), ['42']);

        final removed = await repo.toggleFavorite(item.albumId, item: item);
        final afterRemove = await repo.getFavorites();

        expect(removed['favorited'], isFalse);
        expect(afterRemove, isEmpty);
      },
    );

    test('syncFavorites fetches JM pages into local favorites', () async {
      final repo = DirectMangaRepository(
        client: FakeJmClient(),
        ownerKey: 'jm:alice',
        username: 'alice',
        localStore: _createLocalStore(),
        sessionStore: MemorySessionStore({
          'alice': {'AVS': 'saved-session'},
        }),
      );

      final result = await repo.syncFavorites(full: true);
      final favorites = await repo.getFavorites();

      expect(result['synced'], isTrue);
      expect(result['count'], 2);
      expect(result['failed'], isEmpty);
      expect(result['partial'], isFalse);
      // 与 JM 官方一致：后收藏的排在前面（page 1 先于 page 2）。
      expect(favorites.map((item) => item.albumId), ['1', '2']);
      expect(favorites.first.coverUrl, contains('/media/albums/1.jpg'));
    });

    test('syncFavorites merges pendingAdd not in remote', () async {
      final client = FakeJmClient();
      final localStore = _createLocalStore();
      final repo = DirectMangaRepository(
        client: client,
        ownerKey: 'jm:alice',
        username: 'alice',
        localStore: localStore,
        sessionStore: MemorySessionStore(),
      );

      await localStore.addFavorite(
        'jm:alice',
        AlbumItem(albumId: '3', title: 'Three', tags: const []),
      );

      final result = await repo.syncFavorites(full: true);
      final favorites = await repo.getFavorites();

      expect(result['synced'], isTrue);
      expect(result['failed'], isEmpty);
      expect(client.toggledIds, contains('3'));
      expect(favorites.map((item) => item.albumId), ['3', '1', '2']);
      expect(favorites.first.syncStatus, 'synced');
    });

    test(
      'syncFavorites does not toggle pendingAdd already in remote',
      () async {
        final client = FakeJmClient();
        final localStore = _createLocalStore();
        final repo = DirectMangaRepository(
          client: client,
          ownerKey: 'jm:alice',
          username: 'alice',
          localStore: localStore,
          sessionStore: MemorySessionStore(),
        );

        await localStore.addFavorite(
          'jm:alice',
          AlbumItem(albumId: '1', title: 'One Local', tags: const []),
        );

        final result = await repo.syncFavorites(full: true);

        expect(result['synced'], isTrue);
        expect(result['failed'], isEmpty);
        expect(client.toggledIds, isNot(contains('1')));
      },
    );

    test('syncFavorites removes pendingRemove in remote', () async {
      final client = FakeJmClient();
      final localStore = _createLocalStore();
      final repo = DirectMangaRepository(
        client: client,
        ownerKey: 'jm:alice',
        username: 'alice',
        localStore: localStore,
        sessionStore: MemorySessionStore(),
      );

      // 先写入一条 synced 记录，再标记为 pendingRemove。
      await localStore.addFavorite(
        'jm:alice',
        AlbumItem(albumId: '1', title: 'One', tags: const []),
        syncStatus: FavoriteSyncStatus.synced,
      );
      await localStore.removeFavorite('jm:alice', '1');

      final result = await repo.syncFavorites(full: true);
      final favorites = await repo.getFavorites();

      expect(result['synced'], isTrue);
      expect(result['failed'], isEmpty);
      expect(client.toggledIds, contains('1'));
      expect(favorites.map((item) => item.albumId), ['2']);
    });

    test('syncFavorites keeps failed pendingAdd as pending', () async {
      final client = FakeJmClient(failingToggleIds: {'3'});
      final localStore = _createLocalStore();
      final repo = DirectMangaRepository(
        client: client,
        ownerKey: 'jm:alice',
        username: 'alice',
        localStore: localStore,
        sessionStore: MemorySessionStore(),
      );

      await localStore.addFavorite(
        'jm:alice',
        AlbumItem(albumId: '3', title: 'Three', tags: const []),
      );

      final result = await repo.syncFavorites(full: true);
      final favorites = await repo.getFavorites();
      final pending = await localStore.pendingFavorites('jm:alice');

      expect(result['synced'], isTrue);
      expect(result['partial'], isTrue);
      expect(result['failed'], ['3']);
      expect(favorites.map((item) => item.albumId), ['3', '1', '2']);
      expect(pending.map((item) => item.albumId), ['3']);
      expect(pending.first.syncStatus, FavoriteSyncStatus.pendingAdd);
    });

    test(
      'syncFavorites does not clear pending on remote fetch failure',
      () async {
        final client = FakeJmClient(failFavoritePage: true);
        final localStore = _createLocalStore();
        final repo = DirectMangaRepository(
          client: client,
          ownerKey: 'jm:alice',
          username: 'alice',
          localStore: localStore,
          sessionStore: MemorySessionStore(),
        );

        await localStore.addFavorite(
          'jm:alice',
          AlbumItem(albumId: '3', title: 'Three', tags: const []),
        );

        await expectLater(
          repo.syncFavorites(full: true),
          throwsA(isA<Exception>()),
        );

        final pending = await localStore.pendingFavorites('jm:alice');
        expect(pending.map((item) => item.albumId), ['3']);
      },
    );

    test('loginToJm only logs in and does not sync favorites', () async {
      final client = FakeJmClient();
      final sessionStore = MemorySessionStore();
      final localStore = _createLocalStore();
      final repo = DirectMangaRepository(
        client: client,
        ownerKey: 'device:test',
        localStore: localStore,
        sessionStore: sessionStore,
      );

      final result = await repo.loginToJm('alice', 'secret');

      expect(result['status'], 'ok');
      expect(sessionStore.cookiesFor('alice'), {'AVS': 'new-session'});
      expect(client.favoritePageCalls, 0);
      expect(client.toggledIds, isEmpty);
    });

    test('getPhotoDetail uses persisted JM session cookies', () async {
      final client = FakeJmClient();
      final repo = DirectMangaRepository(
        client: client,
        ownerKey: 'jm:alice',
        username: 'alice',
        localStore: _createLocalStore(),
        sessionStore: MemorySessionStore({
          'alice': {'AVS': 'saved-session'},
        }),
      );

      final detail = await repo.getPhotoDetail('10');

      expect(detail.photoId, '10');
      expect(client.chapterCookies, {'AVS': 'saved-session'});
    });

    test(
      'getPhotoDetail saves chapter manifest for cache-first reads',
      () async {
        final localStore = _createLocalStore();
        final repo = DirectMangaRepository(
          client: FakeJmClient(),
          ownerKey: 'device:test',
          localStore: localStore,
          sessionStore: MemorySessionStore(),
        );

        final fresh = await repo.getPhotoDetail('10');
        final cached = await repo.getCachedPhotoDetail('10');

        expect(fresh.imageUrls.single, contains('scramble_id='));
        expect(cached, isNotNull);
        expect(cached!.photoId, '10');
        expect(cached.albumId, 'album-10');
        expect(cached.pageCount, 1);
        expect(cached.imageUrls.single, isNot(contains('scramble_id=')));
      },
    );
  });
}

class FakeJmClient extends JmClient {
  int favoritePageCalls = 0;
  Map<String, String>? chapterCookies;
  final Set<String> toggledIds = {};
  final Set<String> failingToggleIds;
  final bool failFavoritePage;

  FakeJmClient({
    this.failingToggleIds = const {},
    this.failFavoritePage = false,
  });

  @override
  Future<JmLoginResult> login(String username, String password) async {
    setCookies({'AVS': 'new-session'});
    return JmLoginResult(
      uid: '1',
      username: username,
      session: 'new-session',
      favorites: 2,
      favoritesMax: 100,
    );
  }

  @override
  Future<JmFavoritePage> getFavoritePage({
    int page = 1,
    String folderId = '0',
    String orderBy = 'mr',
  }) async {
    if (failFavoritePage) {
      throw Exception('favorite page failure');
    }
    favoritePageCalls += 1;
    if (page == 1) {
      return const JmFavoritePage(
        total: 2,
        count: 1,
        items: [JmListItem(id: '1', title: 'One')],
      );
    }
    return const JmFavoritePage(
      total: 2,
      count: 1,
      items: [JmListItem(id: '2', title: 'Two')],
    );
  }

  @override
  Future<Map<String, dynamic>> toggleFavorite(String albumId) async {
    if (failingToggleIds.contains(albumId)) {
      throw Exception('toggle failure');
    }
    toggledIds.add(albumId);
    return {'favorited': true};
  }

  @override
  Future<JmChapter> getChapter(String chapterId) async {
    chapterCookies = cookies;
    return JmChapter(
      id: chapterId,
      albumId: 'album-$chapterId',
      title: 'Chapter $chapterId',
      imageNames: const ['00001.webp'],
    );
  }

  @override
  Future<int> getScrambleId(String chapterId) async {
    return JmConstants.scramble220980;
  }
}

class MemorySessionStore extends JmSessionStore {
  final Map<String, Map<String, String>> values;

  MemorySessionStore([Map<String, Map<String, String>>? initial])
    : values = {
        for (final entry in (initial ?? const {}).entries)
          entry.key: Map<String, String>.from(entry.value),
      };

  @override
  Future<Map<String, String>> readCookies(String username) async {
    return Map<String, String>.from(values[username] ?? const {});
  }

  @override
  Future<void> writeCookies(
    String username,
    Map<String, String> cookies,
  ) async {
    values[username] = Map<String, String>.from(cookies);
  }

  Map<String, String> cookiesFor(String username) {
    return Map<String, String>.from(values[username] ?? const {});
  }
}
