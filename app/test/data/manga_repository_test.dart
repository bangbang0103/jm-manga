import 'package:jm_manga/data/direct_manga_repository.dart';
import 'package:jm_manga/data/manga_repository.dart';
import 'package:jm_manga/network/jm/jm_client.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('MangaRepository abstraction', () {
    test('direct repository implements browsing URL helpers', () {
      final repo = DirectMangaRepository(
        client: JmClient(),
        ownerKey: 'device:test',
      );

      expect(repo, isA<MangaRepository>());
      expect(repo.coverUrl('1'), contains('/media/albums/1.jpg'));
    });
  });
}
