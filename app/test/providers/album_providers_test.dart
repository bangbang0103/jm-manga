import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/models/album.dart';
import 'package:jm_manga/providers/album_providers.dart';
import 'package:jm_manga/providers/repository_provider.dart';
import 'package:jm_manga/utils/tag_query_parser.dart';

import '../fake_repository.dart';

class _AlbumFakeRepository extends FakeApiRepository {
  final List<AlbumItem> searchResults;
  final List<AlbumItem> rankingResults;
  final List<AlbumItem> categoryResults;
  final List<AlbumItem> favoriteResults;
  final AlbumDetail? albumDetail;
  final PhotoDetail? photoDetail;

  _AlbumFakeRepository({
    this.searchResults = const [],
    this.rankingResults = const [],
    this.categoryResults = const [],
    this.favoriteResults = const [],
    this.albumDetail,
    this.photoDetail,
  });

  @override
  Future<List<AlbumItem>> search(String query, {int page = 1}) async {
    return searchResults;
  }

  @override
  Future<List<AlbumItem>> getRankings(
    String type, {
    String category = '0',
    int page = 1,
  }) async {
    return rankingResults;
  }

  @override
  Future<List<AlbumItem>> getCategories({
    String category = '0',
    String orderBy = 'mr',
    int page = 1,
  }) async {
    return categoryResults;
  }

  @override
  Future<List<AlbumItem>> getFavorites({
    String folderId = '0',
    int page = 1,
  }) async {
    return favoriteResults;
  }

  @override
  Future<AlbumDetail> getAlbumDetail(String albumId) async {
    return albumDetail ??
        AlbumDetail(
          albumId: albumId,
          title: 'Album $albumId',
          description: 'Description',
          author: 'Author',
          tags: const [],
          episodes: const [],
        );
  }

  @override
  Future<PhotoDetail> getPhotoDetail(String photoId) async {
    return photoDetail ??
        PhotoDetail(
          photoId: photoId,
          title: 'Photo $photoId',
          albumId: '1',
          pageCount: 0,
          imageUrls: const [],
        );
  }
}

void main() {
  group('SearchNotifier', () {
    test('returns empty list when query is empty', () async {
      final container = ProviderContainer(
        overrides: [
          apiRepositoryProvider.overrideWithValue(_AlbumFakeRepository()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        searchProvider(const SearchRequest(keywords: '')).notifier,
      );
      await Future.delayed(Duration.zero);

      expect(notifier.state.valueOrNull, isEmpty);
      expect(notifier.hasMore, isFalse);
    });

    test('searches and returns results', () async {
      final repo = _AlbumFakeRepository(
        searchResults: [
          AlbumItem(albumId: '1', title: 'One', tags: const []),
        ],
      );
      final container = ProviderContainer(
        overrides: [apiRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        searchProvider(const SearchRequest(keywords: 'one')).notifier,
      );
      await Future.delayed(Duration.zero);

      expect(notifier.state.valueOrNull?.length, 1);
      expect(notifier.state.valueOrNull?.first.albumId, '1');
    });
  });

  group('RankingsNotifier', () {
    test('loads rankings', () async {
      final repo = _AlbumFakeRepository(
        rankingResults: [AlbumItem(albumId: '1', title: 'Ranked', tags: const [])],
      );
      final container = ProviderContainer(
        overrides: [apiRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        rankingsProvider(const RankingsKey('daily', '0')).notifier,
      );
      await Future.delayed(Duration.zero);

      expect(notifier.state.valueOrNull?.length, 1);
    });
  });

  group('CategoryNotifier', () {
    test('loads categories', () async {
      final repo = _AlbumFakeRepository(
        categoryResults: [AlbumItem(albumId: '1', title: 'Cat', tags: const [])],
      );
      final container = ProviderContainer(
        overrides: [apiRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        categoryProvider(const CategoryKey('doujin', 'mr')).notifier,
      );
      await Future.delayed(Duration.zero);

      expect(notifier.state.valueOrNull?.length, 1);
    });
  });

  group('FavoritesNotifier', () {
    test('loads favorites', () async {
      final repo = _AlbumFakeRepository(
        favoriteResults: [
          AlbumItem(albumId: '1', title: 'Favorite', tags: const []),
        ],
      );
      final container = ProviderContainer(
        overrides: [apiRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(favoritesProvider.notifier);
      await Future.delayed(Duration.zero);

      expect(notifier.state.valueOrNull?.length, 1);
    });

    test('search filters favorites', () async {
      final repo = _AlbumFakeRepository(
        favoriteResults: [
          AlbumItem(albumId: '1', title: 'Alpha', tags: const []),
          AlbumItem(albumId: '2', title: 'Beta', tags: const []),
        ],
      );
      final container = ProviderContainer(
        overrides: [apiRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(favoritesProvider.notifier);
      await Future.delayed(Duration.zero);

      notifier.search('alp');

      expect(notifier.state.valueOrNull?.length, 1);
      expect(notifier.state.valueOrNull?.first.albumId, '1');
    });
  });

  group('albumDetailProvider', () {
    test('returns album detail', () async {
      final repo = _AlbumFakeRepository(
        albumDetail: AlbumDetail(
          albumId: '1',
          title: 'Detailed',
          description: 'Desc',
          author: 'Author',
          tags: const [],
          episodes: const [],
        ),
      );
      final container = ProviderContainer(
        overrides: [apiRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final value = await container.read(albumDetailProvider('1').future);
      expect(value.title, 'Detailed');
    });
  });

  group('photoDetailProvider', () {
    test('returns photo detail', () async {
      final repo = _AlbumFakeRepository(
        photoDetail: PhotoDetail(
          photoId: 'p1',
          title: 'Photo',
          albumId: '1',
          pageCount: 5,
          imageUrls: const [],
        ),
      );
      final container = ProviderContainer(
        overrides: [apiRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final value = await container.read(photoDetailProvider('p1').future);
      expect(value.pageCount, 5);
    });
  });
}
