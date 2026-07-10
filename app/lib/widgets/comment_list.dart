import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/comment.dart';
import '../providers/album_providers.dart';
import '../providers/repository_provider.dart';
import '../widgets/comment_item.dart';
import '../widgets/error_placeholder.dart';
import '../widgets/loading_indicator.dart';
import '../l10n/app_localizations.dart';

class CommentListWidget extends ConsumerStatefulWidget {
  final String albumId;

  const CommentListWidget({super.key, required this.albumId});

  @override
  ConsumerState<CommentListWidget> createState() => _CommentListWidgetState();
}

class _CommentListWidgetState extends ConsumerState<CommentListWidget> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 200) {
      final notifier = ref.read(albumCommentsProvider(widget.albumId).notifier);
      if (!notifier.isLoadingMore && notifier.hasMore) {
        notifier.loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final commentsAsync = ref.watch(albumCommentsProvider(widget.albumId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(albumCommentsProvider(widget.albumId));
      },
      child: commentsAsync.when(
        data: (page) => _buildList(context, page, l10n),
        loading: () => const Center(child: AppLoadingIndicator(size: 28)),
        error: (e, _) => ErrorPlaceholder(
          message: _mapError(e, l10n),
          onRetry: () => ref.invalidate(albumCommentsProvider(widget.albumId)),
          retryLabel: l10n.actionRetry,
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, CommentPage page, AppLocalizations l10n) {
    if (page.items.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.commentsEmpty,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final notifier = ref.read(albumCommentsProvider(widget.albumId).notifier);

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: page.items.length + 1,
      itemBuilder: (context, index) {
        if (index == page.items.length) {
          return _buildFooter(context, notifier, l10n);
        }
        return CommentItem(
          comment: page.items[index],
          imageProviderBuilder: _imageProvider,
        );
      },
    );
  }

  Widget _buildFooter(
    BuildContext context,
    AlbumCommentsNotifier notifier,
    AppLocalizations l10n,
  ) {
    if (notifier.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: AppLoadingIndicator(size: 20)),
      );
    }
    if (!notifier.hasMore) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            l10n.commentsNoMore,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  ImageProvider? _imageProvider(String? photo) {
    if (photo == null || photo.isEmpty) return null;
    final repo = ref.read(apiRepositoryProvider);
    return repo.imageProvider('/media/users/$photo');
  }

  String _mapError(Object error, AppLocalizations l10n) {
    return error.toString();
  }
}
