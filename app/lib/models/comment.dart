/// Comment data model used by the UI layer.
class Comment {
  final String id;
  final String uid;
  final String username;
  final int level;
  final String levelName;
  final String content;
  final String likes;
  final String addTime;
  final String? photo;
  final bool isSpoiler;
  final List<CommentReply> replies;

  const Comment({
    required this.id,
    required this.uid,
    required this.username,
    required this.level,
    required this.levelName,
    required this.content,
    required this.likes,
    required this.addTime,
    this.photo,
    this.isSpoiler = false,
    this.replies = const [],
  });
}

/// A reply to a top-level [Comment].
class CommentReply {
  final String id;
  final String uid;
  final String username;
  final int level;
  final String levelName;
  final String content;
  final String likes;
  final String addTime;
  final String? photo;
  final bool isSpoiler;
  final String parentId;

  const CommentReply({
    required this.id,
    required this.uid,
    required this.username,
    required this.level,
    required this.levelName,
    required this.content,
    required this.likes,
    required this.addTime,
    this.photo,
    this.isSpoiler = false,
    required this.parentId,
  });
}

/// Paged result for album comments.
class CommentPage {
  final String total;
  final List<Comment> items;

  const CommentPage({
    required this.total,
    required this.items,
  });

  int get totalCount => int.tryParse(total) ?? 0;
}
