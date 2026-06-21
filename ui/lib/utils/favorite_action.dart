import 'package:flutter/material.dart';
import 'package:jm_manga/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/account_provider.dart';
import '../providers/album_providers.dart';
import '../providers/repository_provider.dart';
import 'top_toast.dart';

Future<void> toggleFavoriteAction(
  BuildContext context,
  WidgetRef ref, {
  required String albumId,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final account = ref.read(selectedAccountProvider);
  if (account == null || account.isAnonymous) {
    TopToast.show(context, l10n.favoriteNeedAccount);
    return;
  }

  final repo = ref.read(apiRepositoryProvider);
  try {
    final result = await repo.toggleFavorite(albumId);
    if (!context.mounted) return;
    final favorited = result['favorited'] == true;
    TopToast.show(
      context,
      favorited ? l10n.favoriteAdded : l10n.favoriteRemoved,
      type: TopToastType.success,
    );
    ref.invalidate(favoritesProvider);
    ref.invalidate(albumDetailProvider(albumId));
  } catch (e) {
    if (!context.mounted) return;
    TopToast.show(
      context,
      l10n.favoriteFailed(e.toString()),
      type: TopToastType.error,
    );
  }
}
