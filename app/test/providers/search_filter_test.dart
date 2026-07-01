import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jm_manga/models/album.dart';
import 'package:jm_manga/providers/album_providers.dart';
import 'package:jm_manga/providers/repository_provider.dart';
import 'package:jm_manga/utils/tag_query_parser.dart';

import '../fake_repository.dart';

class _SearchRepo extends FakeApiRepository {
  final queries = <String>[];

  @override
  Future<List<AlbumItem>> search(String query, {int page = 1}) async {
    queries.add('$query:$page');
    return [
      AlbumItem(albumId: 'blocked', title: 'Block Safe', tags: const ['Safe']),
      AlbumItem(albumId: 'keep', title: 'Keep', tags: const []),
      AlbumItem(albumId: 'allowed', title: 'Allowed', tags: const []),
    ];
  }
}

void main() {
  test('searchProvider sends full filter query to the server', () async {
    final repo = _SearchRepo();
    final container = ProviderContainer(
      overrides: [apiRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    const request = SearchRequest(
      keywords: 'MANA',
      includes: ['Safe'],
      excludes: ['Block'],
      globalExcludes: ['Hidden'],
      allowedGlobal: ['Hidden'],
    );
    container.listen(searchProvider(request), (_, _) {});

    await container.pump();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await container.pump();

    final value = container.read(searchProvider(request)).valueOrNull;
    expect(repo.queries, ['MANA +Safe +Hidden -Block:1']);
    expect(value?.map((item) => item.albumId), ['blocked', 'keep', 'allowed']);
  });

  test(
    'searchProvider does not fetch when request has no recall terms',
    () async {
      final repo = _SearchRepo();
      final container = ProviderContainer(
        overrides: [apiRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      const request = SearchRequest(excludes: ['Block']);
      container.listen(searchProvider(request), (_, _) {});

      await container.pump();

      expect(repo.queries, isEmpty);
      expect(container.read(searchProvider(request)).valueOrNull, isEmpty);
      expect(container.read(searchProvider(request).notifier).hasMore, false);
    },
  );
}
