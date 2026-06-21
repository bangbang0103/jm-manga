import 'package:jm_manga/data/api_repository.dart';
import 'package:jm_manga/models/album.dart';
import 'package:jm_manga/models/reading_progress.dart';

class FakeApiRepository implements ApiRepository {
  @override
  late final client = throw UnimplementedError();

  @override
  Future<AlbumDetail> getAlbumDetail(String albumId) async {
    return AlbumDetail(
      albumId: albumId,
      title: 'Album Title $albumId',
      description: 'Description',
      author: 'Author',
      tags: ['Action', 'Fantasy'],
      episodes: [
        {'photo_id': 'ep1', 'title': 'Chapter 1', 'index': 1},
      ],
      isFavorite: false,
    );
  }

  @override
  Future<List<AlbumItem>> getCategories({
    String category = '0',
    String orderBy = 'mr',
    int page = 1,
  }) async => [];

  @override
  Future<List<AlbumItem>> getFavorites({
    String folderId = '0',
    int page = 1,
  }) async => [AlbumItem(albumId: '1', title: 'Favorite One', tags: [])];

  @override
  Future<Map<String, dynamic>> syncFavorites({
    String folderId = '0',
    int page = 1,
    bool force = false,
    bool full = false,
  }) async => {'synced': true, 'count': 1, 'page': page, 'full': full};

  @override
  Future<Map<String, dynamic>> toggleFavorite(String albumId) async => {
    'favorited': true,
  };

  @override
  Future<Map<String, int>> getServerCacheSizes() async => {
    'covers': 0,
    'images': 0,
    'database': 0,
  };

  @override
  Future<List<AlbumItem>> getRankings(
    String type, {
    String category = '0',
    int page = 1,
  }) async => [
    AlbumItem(albumId: '1', title: 'Ranked Manga', tags: ['Action']),
  ];

  @override
  Future<List<ReadingProgress>> getRecentProgress() async => [
    ReadingProgress(
      albumId: '1',
      photoId: 'ep1',
      title: 'Reading One',
      imageIndex: 5,
      isFinished: false,
      lastReadAt: '2026-06-16',
    ),
  ];

  @override
  Future<List<ReadingProgress>> getAlbumProgress(String albumId) async => [
    ReadingProgress(
      albumId: albumId,
      photoId: 'ep1',
      title: 'Chapter 1',
      imageIndex: 3,
      isFinished: false,
      lastReadAt: '2026-06-16',
    ),
  ];

  @override
  String coverUrl(String albumId, {String size = '_3x4'}) => '';

  @override
  Map<String, String> get imageHeaders => {};

  @override
  Future<PhotoDetail> getPhotoDetail(String photoId) async => PhotoDetail(
    photoId: photoId,
    title: 'Chapter $photoId',
    albumId: '1',
    pageCount: 0,
    imageUrls: const [],
  );

  @override
  Future<List<AlbumItem>> search(String query, {int page = 1}) async => [
    AlbumItem(albumId: '1', title: 'Search Result', tags: []),
  ];

  @override
  Future<void> syncProgress(ReadingProgress progress) async {}

  @override
  Future<Map<String, dynamic>> checkHealth() async => {
    'status': 'ok',
    'version': '0.1.0-test',
    'uptime_seconds': 0,
  };

  @override
  Future<Map<String, dynamic>> validateConnection() async => checkHealth();

  @override
  Future<Map<String, dynamic>> loginToJm(
    String username,
    String password,
  ) async {
    return {'status': 'ok', 'username': username};
  }

  @override
  Future<Map<String, dynamic>> testJmLogin(
    String username,
    String password,
  ) async {
    return {'status': 'ok', 'username': username};
  }
}
