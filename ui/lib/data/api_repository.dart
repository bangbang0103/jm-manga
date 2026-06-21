import '../models/album.dart';
import '../models/api_response.dart';
import '../models/reading_progress.dart';
import 'api_client.dart';

class ApiRepository {
  final ApiClient client;

  ApiRepository({required this.client});

  Future<List<AlbumItem>> search(String query, {int page = 1}) async {
    final response = await client.get<Map<String, dynamic>>(
      '/api/v1/search',
      queryParameters: {'q': query, 'page': page},
    );
    final apiResponse = ApiResponse.fromJson(
      response.data!,
      (data) => (data['items'] as List<dynamic>)
          .map((item) => AlbumItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
    return apiResponse.data ?? [];
  }

  Future<List<AlbumItem>> getRankings(
    String type, {
    String category = '0',
    int page = 1,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      '/api/v1/categories/rankings/$type',
      queryParameters: {'page': page, 'category': category},
    );
    final apiResponse = ApiResponse.fromJson(
      response.data!,
      (data) => (data['items'] as List<dynamic>)
          .map((item) => AlbumItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
    return apiResponse.data ?? [];
  }

  Future<List<AlbumItem>> getCategories({
    String category = '0',
    String orderBy = 'mr',
    int page = 1,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      '/api/v1/categories',
      queryParameters: {
        'page': page,
        'category': category,
        'order_by': orderBy,
      },
    );
    final apiResponse = ApiResponse.fromJson(
      response.data!,
      (data) => (data['items'] as List<dynamic>)
          .map((item) => AlbumItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
    return apiResponse.data ?? [];
  }

  Future<AlbumDetail> getAlbumDetail(String albumId) async {
    final response = await client.get<Map<String, dynamic>>(
      '/api/v1/albums/$albumId',
    );
    final apiResponse = ApiResponse.fromJson(
      response.data!,
      (data) => AlbumDetail.fromJson(data as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  Future<PhotoDetail> getPhotoDetail(String photoId) async {
    final response = await client.get<Map<String, dynamic>>(
      '/api/v1/albums/photos/$photoId',
    );
    final apiResponse = ApiResponse.fromJson(
      response.data!,
      (data) => PhotoDetail.fromJson(data as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  String coverUrl(String albumId, {String size = '_3x4'}) {
    return '${client.dio.options.baseUrl}/api/v1/covers/$albumId?size=$size';
  }

  /// 图片/封面请求需要携带的鉴权头。
  ///
  /// `CachedNetworkImage` 等 widget 直接走 HTTP，不会自动使用 Dio 的 header，
  /// 因此需要显式注入 Authorization 与 X-JM-Username。
  Map<String, String> get imageHeaders {
    final headers = <String, String>{};
    final token = client.apiToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final username = client.jmUsername;
    if (username != null && username.isNotEmpty) {
      headers['X-JM-Username'] = username;
    }
    return headers;
  }

  Future<List<AlbumItem>> getFavorites({
    String folderId = '0',
    int page = 1,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      '/api/v1/favorites',
      queryParameters: {'folder_id': folderId, 'page': page},
    );
    final apiResponse = ApiResponse.fromJson(
      response.data!,
      (data) => (data['items'] as List<dynamic>)
          .map((item) => AlbumItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
    return apiResponse.data ?? [];
  }

  Future<Map<String, dynamic>> syncFavorites({
    String folderId = '0',
    int page = 1,
    bool force = false,
    bool full = false,
  }) async {
    final response = await client.post<Map<String, dynamic>>(
      '/api/v1/favorites/sync',
      queryParameters: {
        'folder_id': folderId,
        'page': page,
        'force': force,
        'full': full,
      },
    );
    final apiResponse = ApiResponse.fromJson(
      response.data!,
      (data) => data as Map<String, dynamic>,
    );
    return apiResponse.data ?? {'synced': false};
  }

  Future<Map<String, int>> getServerCacheSizes() async {
    final response = await client.get<Map<String, dynamic>>(
      '/api/v1/server/cache',
    );
    final data = response.data!;
    return {
      'covers': (data['covers'] as num?)?.toInt() ?? 0,
      'images': (data['images'] as num?)?.toInt() ?? 0,
      'database': (data['database'] as num?)?.toInt() ?? 0,
    };
  }

  Future<Map<String, dynamic>> toggleFavorite(String albumId) async {
    final response = await client.post<Map<String, dynamic>>(
      '/api/v1/favorites/$albumId',
    );
    final apiResponse = ApiResponse.fromJson(
      response.data!,
      (data) => data as Map<String, dynamic>,
    );
    return apiResponse.data ?? {'favorited': true};
  }

  Future<List<ReadingProgress>> getRecentProgress() async {
    final response = await client.get<Map<String, dynamic>>(
      '/api/v1/progress/recent',
    );
    final apiResponse = ApiResponse.fromJson(
      response.data!,
      (data) => (data as List<dynamic>)
          .map((item) => ReadingProgress.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
    return apiResponse.data ?? [];
  }

  Future<List<ReadingProgress>> getAlbumProgress(String albumId) async {
    final response = await client.get<Map<String, dynamic>>(
      '/api/v1/progress/$albumId',
    );
    final apiResponse = ApiResponse.fromJson(
      response.data!,
      (data) => (data as List<dynamic>)
          .map((item) => ReadingProgress.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
    return apiResponse.data ?? [];
  }

  Future<void> syncProgress(ReadingProgress progress) async {
    await client.post<Map<String, dynamic>>(
      '/api/v1/progress',
      data: {
        'album_id': progress.albumId,
        'photo_id': progress.photoId,
        if (progress.title != null && progress.title!.isNotEmpty)
          'title': progress.title,
        'image_index': progress.imageIndex,
        'is_finished': progress.isFinished,
        if (progress.episodeIndex != null)
          'episode_index': progress.episodeIndex,
        if (progress.pageCount != null) 'page_count': progress.pageCount,
      },
    );
  }

  Future<Map<String, dynamic>> checkHealth() async {
    final response = await client.get<Map<String, dynamic>>('/health');
    return response.data ?? {'status': 'ok'};
  }

  Future<Map<String, dynamic>> validateConnection() async {
    final health = await checkHealth();
    await getServerCacheSizes();
    return health;
  }

  Future<Map<String, dynamic>> loginToJm(
    String username,
    String password,
  ) async {
    final response = await client.post<Map<String, dynamic>>(
      '/api/v1/auth/jm',
      data: {'username': username, 'password': password},
    );
    return response.data ?? {'status': 'ok'};
  }

  Future<Map<String, dynamic>> testJmLogin(
    String username,
    String password,
  ) async {
    final response = await client.post<Map<String, dynamic>>(
      '/api/v1/auth/test',
      data: {'username': username, 'password': password},
    );
    return response.data ?? {'status': 'ok'};
  }
}
