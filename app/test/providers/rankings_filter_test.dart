import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jm_manga/models/album.dart';
import 'package:jm_manga/providers/album_providers.dart';
import 'package:jm_manga/providers/repository_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fake_repository.dart';

class _RankingsRepo extends FakeApiRepository {
  @override
  Future<List<AlbumItem>> getRankings(
    String type, {
    String category = '0',
    int page = 1,
  }) async => [
    AlbumItem(albumId: '1', title: 'Keep Manga', tags: const []),
    AlbumItem(albumId: '2', title: '[Block] Manga', tags: const []),
  ];
}

void main() {
  test('rankingsProvider filters by excluded tags from config', () async {
    SharedPreferences.setMockInitialValues({
      'excludedTags': jsonEncode(['Block']),
    });

    final repo = _RankingsRepo();
    final container = ProviderContainer(
      overrides: [apiRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final listener = container.listen(
      rankingsProvider(const RankingsKey('day', '0')),
      (previous, next) {},
    );

    await container.pump();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await container.pump();

    final value = listener.read().valueOrNull;
    expect(value?.length, 1);
    expect(value?.first.albumId, '1');
  });
}
