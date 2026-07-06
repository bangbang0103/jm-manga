import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/data/favorite_service.dart';
import 'package:jm_manga/models/album.dart';
import 'package:jm_manga/providers/album_providers.dart';
import 'package:jm_manga/providers/repository_provider.dart';

import '../fake_repository.dart';

class _ToggleFakeRepository extends FakeApiRepository {
  final Map<String, bool> states = {};

  @override
  Future<Map<String, dynamic>> toggleFavorite(
    String albumId, {
    AlbumItem? item,
  }) async {
    final newState = !(states[albumId] ?? false);
    states[albumId] = newState;
    return {'favorited': newState};
  }
}

void main() {
  group('FavoriteService', () {
    test('toggle returns new favorited state', () async {
      final repo = _ToggleFakeRepository();
      final service = FavoriteService(repo);

      final added = await service.toggle(
        AlbumItem(albumId: '1', title: 'One', tags: const []),
      );
      expect(added, isTrue);

      final removed = await service.toggle(
        AlbumItem(albumId: '1', title: 'One', tags: const []),
      );
      expect(removed, isFalse);
    });
  });

  group('favoriteStatusProvider', () {
    test('returns true when album id is in favorites', () async {
      final repo = _ToggleFakeRepository();
      final container = ProviderContainer(
        overrides: [apiRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      container.read(favoritesProvider.notifier);
      await Future.delayed(Duration.zero);

      // FakeApiRepository 默认返回一个 favorite albumId='1'
      final status = container.read(favoriteStatusProvider('1'));
      expect(status.valueOrNull, isTrue);
    });

    test('returns false when album id is not in favorites', () async {
      final repo = _ToggleFakeRepository();
      final container = ProviderContainer(
        overrides: [apiRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      container.read(favoritesProvider.notifier);
      await Future.delayed(Duration.zero);

      final status = container.read(favoriteStatusProvider('999'));
      expect(status.valueOrNull, isFalse);
    });
  });
}
