import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/models/album.dart';
import 'package:jm_manga/utils/tag_filter.dart';

void main() {
  group('TagFilter.apply', () {
    final items = [
      AlbumItem(albumId: '1', title: 'Safe Title', tags: const ['Safe']),
      AlbumItem(albumId: '2', title: 'Block Title', tags: const ['Block']),
      AlbumItem(albumId: '3', title: 'Another', tags: const ['Safe', 'Block']),
    ];

    test('returns all items when excluded tags is empty', () {
      expect(TagFilter.apply(items, {}).length, 3);
    });

    test('removes items containing excluded tag', () {
      final result = TagFilter.apply(items, {'Block'});
      expect(result.length, 1);
      expect(result.first.albumId, '1');
    });

    test('falls back to title when tags are empty', () {
      final titleItems = [
        AlbumItem(albumId: '1', title: 'Keep This', tags: const []),
        AlbumItem(albumId: '2', title: '[Block] This', tags: const []),
      ];
      final result = TagFilter.apply(titleItems, {'block'});
      expect(result.length, 1);
      expect(result.first.albumId, '1');
    });

    test('matches case-insensitively and trims whitespace', () {
      final result = TagFilter.apply(items, {'  block ', 'BLOCK'});
      expect(result.length, 1);
      expect(result.first.albumId, '1');
    });
  });
}
