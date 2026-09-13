import '../models/album.dart';
import '../models/comment.dart';
import '../network/jm/jm_models.dart';

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

CommentPage commentPageFromJm(JmCommentPage page, {required String Function(String) coverUrl}) {
  return CommentPage(
    total: page.total,
    items: page.items.map((item) => _commentFromJm(item, coverUrl: coverUrl)).toList(),
  );
}

Comment _commentFromJm(JmComment item, {required String Function(String) coverUrl}) {
  return Comment(
    id: item.id,
    uid: item.uid,
    username: item.username,
    level: item.level,
    levelName: item.levelName,
    content: item.content,
    likes: item.likes,
    addTime: item.addTime,
    photo: item.photo,
    isSpoiler: item.isSpoiler,
    replies:
        item.replies.map((reply) => _commentReplyFromJm(reply)).toList(),
  );
}

CommentReply _commentReplyFromJm(JmComment item) {
  return CommentReply(
    id: item.id,
    uid: item.uid,
    username: item.username,
    level: item.level,
    levelName: item.levelName,
    content: item.content,
    likes: item.likes,
    addTime: item.addTime,
    photo: item.photo,
    isSpoiler: item.isSpoiler,
    parentId: '',
  );
}

String userAvatarUrl(String photo) => '/media/users/$photo';
