import 'package:flutter/material.dart';
import 'package:jm_manga/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/album.dart';
import '../providers/album_providers.dart';
import '../data/favorite_service.dart';
import 'error_mapper.dart';
import 'top_toast.dart';

Future<void> toggleFavoriteAction(
  BuildContext context,
  WidgetRef ref, {
  required String albumId,
  AlbumItem? item,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final service = ref.read(favoriteServiceProvider);
  try {
    final favorited = await service.toggle(
      item ?? AlbumItem(albumId: albumId, title: albumId, tags: const []),
    );
    if (!context.mounted) return;
    TopToast.show(
      context,
      favorited ? l10n.favoriteAdded : l10n.favoriteRemoved,
      type: TopToastType.success,
    );
    ref.invalidate(favoritesProvider);
  } catch (e) {
    if (!context.mounted) return;
    TopToast.show(
      context,
      mapErrorToUserMessage(e, l10n),
      type: TopToastType.error,
    );
  }
}
