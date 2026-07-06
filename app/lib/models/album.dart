class AlbumItem {
  final String albumId;
  final String title;
  final List<String> tags;
  final String? coverUrl;
  final String? syncStatus;

  AlbumItem({
    required this.albumId,
    required this.title,
    required this.tags,
    this.coverUrl,
    this.syncStatus,
  });

  AlbumItem copyWith({
    String? title,
    List<String>? tags,
    String? coverUrl,
    String? syncStatus,
    bool clearSyncStatus = false,
  }) {
    return AlbumItem(
      albumId: albumId,
      title: title ?? this.title,
      tags: tags ?? this.tags,
      coverUrl: coverUrl ?? this.coverUrl,
      syncStatus: clearSyncStatus ? null : (syncStatus ?? this.syncStatus),
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
}

class ChapterManifest {
  final String photoId;
  final String albumId;
  final String title;
  final List<String> imageNames;
  final int pageCount;

  ChapterManifest({
    required this.photoId,
    required this.albumId,
    required this.title,
    required this.imageNames,
    int? pageCount,
  }) : pageCount = pageCount ?? imageNames.length;
}
