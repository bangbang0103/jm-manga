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
      AlbumItem(albumId: '1', title: 'First', tags: const []),
      AlbumItem(albumId: '2', title: 'Second', tags: const []),
    ];
  }
}

void main() {
  test('searchProvider sends raw query to the server', () async {
    final repo = _SearchRepo();
    final container = ProviderContainer(
      overrides: [apiRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    const request = SearchRequest(keywords: 'overwatch -3D');
    container.listen(searchProvider(request), (_, _) {});

    await container.pump();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await container.pump();

    final value = container.read(searchProvider(request)).valueOrNull;
    expect(repo.queries, ['overwatch -3D:1']);
    expect(value?.map((item) => item.albumId), ['1', '2']);
  });

  test('searchProvider does not fetch when query is empty', () async {
    final repo = _SearchRepo();
    final container = ProviderContainer(
      overrides: [apiRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    const request = SearchRequest(keywords: '');
    container.listen(searchProvider(request), (_, _) {});

    await container.pump();

    expect(repo.queries, isEmpty);
    expect(container.read(searchProvider(request)).valueOrNull, isEmpty);
    expect(container.read(searchProvider(request).notifier).hasMore, false);
  });
}
