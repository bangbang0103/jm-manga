import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/comment.dart';
import '../utils/html_stripper.dart';

class CommentItem extends StatefulWidget {
  final Comment comment;
  final ImageProvider? Function(String? photo)? imageProviderBuilder;

  const CommentItem({
    super.key,
    required this.comment,
    this.imageProviderBuilder,
  });

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  bool _repliesExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final comment = widget.comment;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(
            photo: comment.photo,
            uid: comment.uid,
            imageProviderBuilder: widget.imageProviderBuilder,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.username,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (comment.levelName.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          comment.levelName,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  stripHtmlTags(comment.content),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      comment.addTime,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.thumb_up_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      comment.likes,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (comment.replies.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _RepliesToggle(
                    count: comment.replies.length,
                    expanded: _repliesExpanded,
                    onTap: () => setState(() => _repliesExpanded = !_repliesExpanded),
                  ),
                  if (_repliesExpanded)
                    _RepliesList(
                      replies: comment.replies,
                      imageProviderBuilder: widget.imageProviderBuilder,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatefulWidget {
  final String? photo;
  final String uid;
  final ImageProvider? Function(String? photo)? imageProviderBuilder;

  const _Avatar({this.photo, required this.uid, this.imageProviderBuilder});

  @override
  State<_Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<_Avatar> {
  bool _remoteFailed = false;

  @override
  Widget build(BuildContext context) {
    final remoteProvider = widget.imageProviderBuilder?.call(widget.photo);
    final useLocal = remoteProvider == null || _remoteFailed;

    return ClipOval(
      child: SizedBox(
        width: 40,
        height: 40,
        child: useLocal
            ? Image.asset(
                _localAvatarPath(widget.uid),
                fit: BoxFit.cover,
              )
            : Image(
                image: remoteProvider,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _remoteFailed = true);
                  });
                  return Image.asset(
                    _localAvatarPath(widget.uid),
                    fit: BoxFit.cover,
                  );
                },
              ),
      ),
    );
  }
}

String _localAvatarPath(String uid) {
  const count = 10;
  final index = uid.hashCode.abs() % count + 1;
  final name = index.toString().padLeft(2, '0');
  return 'assets/images/avatar/avatar_$name.png';
}

class _RepliesToggle extends StatelessWidget {
  final int count;
  final bool expanded;
  final VoidCallback onTap;

  const _RepliesToggle({
    required this.count,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      child: Text(
        expanded ? l10n.commentHideReplies : l10n.commentReplies(count),
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _RepliesList extends StatelessWidget {
  final List<CommentReply> replies;
  final ImageProvider? Function(String? photo)? imageProviderBuilder;

  const _RepliesList({required this.replies, this.imageProviderBuilder});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: replies.map((reply) => _ReplyItem(
          reply: reply,
          imageProviderBuilder: imageProviderBuilder,
        )).toList(),
      ),
    );
  }
}

class _ReplyItem extends StatelessWidget {
  final CommentReply reply;
  final ImageProvider? Function(String? photo)? imageProviderBuilder;

  const _ReplyItem({required this.reply, this.imageProviderBuilder});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(
            photo: reply.photo,
            uid: reply.uid,
            imageProviderBuilder: imageProviderBuilder,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reply.username,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stripHtmlTags(reply.content),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      reply.addTime,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.thumb_up_outlined,
                      size: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      reply.likes,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
