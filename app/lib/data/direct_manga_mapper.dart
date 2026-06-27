import '../network/jm/jm_models.dart';
import '../models/album.dart';

AlbumItem albumItemFromJm(JmListItem item, {String? coverUrl}) {
  return AlbumItem(
    albumId: item.id,
    title: item.title,
    tags: item.tags,
    coverUrl: coverUrl,
  );
}

AlbumDetail albumDetailFromJm(
  JmAlbum album, {
  String? coverUrl,
  bool? isFavorite,
}) {
  final episodes = album.episodes.isEmpty
      ? [
          {'photo_id': album.id, 'index': 0, 'title': 'Episode 1'},
        ]
      : album.episodes
            .map(
              (episode) => {
                'photo_id': episode.id,
                'index': episode.index,
                'title': episode.title,
              },
            )
            .toList();

  return AlbumDetail(
    albumId: album.id,
    title: album.title,
    description: album.description,
    author: album.authors.join(', '),
    tags: album.tags,
    coverUrl: coverUrl,
    likes: album.likes,
    views: album.views,
    episodes: episodes,
    isFavorite: isFavorite ?? album.isFavorite,
  );
}

PhotoDetail photoDetailFromJm(JmChapter chapter, List<String> imageUrls) {
  return PhotoDetail(
    photoId: chapter.id,
    title: chapter.title,
    albumId: chapter.albumId,
    pageCount: imageUrls.length,
    imageUrls: imageUrls,
  );
}
