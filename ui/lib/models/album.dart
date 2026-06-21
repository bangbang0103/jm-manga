String _asString(dynamic value) => value.toString();

String? _asStringNullable(dynamic value) => value?.toString();

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase();
    return lower == 'true' || lower == '1';
  }
  return false;
}

class AlbumItem {
  final String albumId;
  final String title;
  final List<String> tags;
  final String? coverUrl;

  AlbumItem({
    required this.albumId,
    required this.title,
    required this.tags,
    this.coverUrl,
  });

  factory AlbumItem.fromJson(Map<String, dynamic> json) {
    return AlbumItem(
      albumId: _asString(json['album_id']),
      title: _asString(json['title']),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      coverUrl: _asStringNullable(json['cover_url']),
    );
  }
}

class AlbumDetail {
  final String albumId;
  final String title;
  final String description;
  final String author;
  final List<String> tags;
  final String? coverUrl;
  final String? likes;
  final String? views;
  final List<Map<String, dynamic>> episodes;
  final bool isFavorite;

  AlbumDetail({
    required this.albumId,
    required this.title,
    required this.description,
    required this.author,
    required this.tags,
    this.coverUrl,
    this.likes,
    this.views,
    required this.episodes,
    this.isFavorite = false,
  });

  factory AlbumDetail.fromJson(Map<String, dynamic> json) {
    return AlbumDetail(
      albumId: _asString(json['album_id']),
      title: _asString(json['title']),
      description: _asString(json['description']),
      author: _asString(json['author']),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      coverUrl: _asStringNullable(json['cover_url']),
      likes: _asStringNullable(json['likes']),
      views: _asStringNullable(json['views']),
      episodes:
          (json['episodes'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      isFavorite: _asBool(json['is_favorite']),
    );
  }
}

class PhotoDetail {
  final String photoId;
  final String title;
  final String albumId;
  final int pageCount;
  final List<String> imageUrls;

  PhotoDetail({
    required this.photoId,
    required this.title,
    required this.albumId,
    required this.pageCount,
    required this.imageUrls,
  });

  factory PhotoDetail.fromJson(Map<String, dynamic> json) {
    return PhotoDetail(
      photoId: _asString(json['photo_id']),
      title: _asString(json['title']),
      albumId: _asString(json['album_id']),
      pageCount: _asInt(json['page_count']),
      imageUrls: (json['image_urls'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}
