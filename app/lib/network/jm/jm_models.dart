class JmListItem {
  final String id;
  final String title;
  final List<String> tags;

  const JmListItem({
    required this.id,
    required this.title,
    this.tags = const [],
  });

  factory JmListItem.fromJson(Map<String, dynamic> json) {
    return JmListItem(
      id: (json['id'] ?? json['album_id'] ?? '').toString(),
      title: (json['name'] ?? json['title'] ?? '').toString(),
      tags:
          (json['tags'] as List<dynamic>?)
              ?.map((tag) => tag.toString())
              .toList() ??
          const [],
    );
  }
}

class JmSearchPage {
  final int total;
  final List<JmListItem> items;

  const JmSearchPage({required this.total, required this.items});

  factory JmSearchPage.fromJson(Map<String, dynamic> json) {
    return JmSearchPage(
      total: _asInt(json['total']),
      items:
          (json['content'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((item) => JmListItem.fromJson(item.cast<String, dynamic>()))
              .toList() ??
          const [],
    );
  }
}

class JmLoginResult {
  final String uid;
  final String username;
  final String session;
  final int favorites;
  final int favoritesMax;

  const JmLoginResult({
    required this.uid,
    required this.username,
    required this.session,
    required this.favorites,
    required this.favoritesMax,
  });

  factory JmLoginResult.fromJson(Map<String, dynamic> json) {
    return JmLoginResult(
      uid: (json['uid'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      session: (json['s'] ?? '').toString(),
      favorites: _asInt(json['album_favorites']),
      favoritesMax: _asInt(json['album_favorites_max']),
    );
  }
}

class JmFavoritePage {
  final int total;
  final int count;
  final List<JmListItem> items;

  const JmFavoritePage({
    required this.total,
    required this.count,
    required this.items,
  });

  factory JmFavoritePage.fromJson(Map<String, dynamic> json) {
    return JmFavoritePage(
      total: _asInt(json['total']),
      count: _asInt(json['count']),
      items:
          (json['list'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((item) => JmListItem.fromJson(item.cast<String, dynamic>()))
              .toList() ??
          const [],
    );
  }
}

class JmAlbum {
  final String id;
  final String title;
  final String description;
  final List<String> authors;
  final List<String> tags;
  final String? likes;
  final String? views;
  final List<JmEpisode> episodes;
  final bool isFavorite;

  const JmAlbum({
    required this.id,
    required this.title,
    required this.description,
    this.authors = const [],
    this.tags = const [],
    this.likes,
    this.views,
    this.episodes = const [],
    this.isFavorite = false,
  });

  factory JmAlbum.fromJson(Map<String, dynamic> json) {
    return JmAlbum(
      id: json['id'].toString(),
      title: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      authors: _asStringList(json['author']),
      tags:
          (json['tags'] as List<dynamic>?)
              ?.map((tag) => tag.toString())
              .toList() ??
          const [],
      likes: json['likes']?.toString(),
      views: json['total_views']?.toString() ?? json['views']?.toString(),
      episodes:
          (json['series'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((item) => JmEpisode.fromJson(item.cast<String, dynamic>()))
              .toList() ??
          const [],
      isFavorite: _asBool(json['is_favorite']),
    );
  }
}

class JmEpisode {
  final String id;
  final int index;
  final String title;

  const JmEpisode({required this.id, required this.index, required this.title});

  factory JmEpisode.fromJson(Map<String, dynamic> json) {
    final index = _asInt(json['sort']) - 1;
    final rawName = (json['name'] ?? '').toString();
    final title = rawName.isEmpty ? 'Episode ${index + 1}' : rawName;
    return JmEpisode(
      id: (json['id'] ?? '').toString(),
      index: index < 0 ? 0 : index,
      title: title,
    );
  }
}

class JmChapter {
  final String id;
  final String albumId;
  final String title;
  final List<String> imageNames;

  const JmChapter({
    required this.id,
    required this.albumId,
    required this.title,
    this.imageNames = const [],
  });

  factory JmChapter.fromJson(Map<String, dynamic> json) {
    return JmChapter(
      id: json['id'].toString(),
      albumId: (json['series_id'] ?? '').toString(),
      title: (json['name'] ?? '').toString(),
      imageNames:
          (json['images'] as List<dynamic>?)
              ?.map((image) => image.toString())
              .toList() ??
          const [],
    );
  }
}

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

List<String> _asStringList(dynamic value) {
  if (value is List<dynamic>) {
    return value.map((item) => item.toString()).toList();
  }
  if (value == null) {
    return const [];
  }
  final text = value.toString();
  return text.isEmpty ? const [] : [text];
}
