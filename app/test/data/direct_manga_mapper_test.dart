import 'package:jm_manga/data/direct_manga_mapper.dart';
import 'package:jm_manga/network/jm/jm_models.dart';
import 'package:test/test.dart';

void main() {
  group('direct manga mapper', () {
    test('maps list items to album cards', () {
      final item = albumItemFromJm(
        const JmListItem(id: '123', title: 'Title', tags: ['tag']),
        coverUrl: 'https://img.example/123.jpg',
      );

      expect(item.albumId, '123');
      expect(item.title, 'Title');
      expect(item.tags, ['tag']);
      expect(item.coverUrl, 'https://img.example/123.jpg');
    });

    test('maps album detail with series episodes', () {
      final detail = albumDetailFromJm(
        const JmAlbum(
          id: '1',
          title: 'Album',
          description: 'Desc',
          authors: ['A', 'B'],
          tags: ['x'],
          likes: '10',
          views: '20',
          episodes: [
            JmEpisode(id: 'p1', index: 0, title: 'One'),
            JmEpisode(id: 'p2', index: 1, title: 'Two'),
          ],
          isFavorite: true,
        ),
      );

      expect(detail.albumId, '1');
      expect(detail.author, 'A, B');
      expect(detail.likes, '10');
      expect(detail.views, '20');
      expect(detail.episodes, [
        {'photo_id': 'p1', 'index': 0, 'title': 'One'},
        {'photo_id': 'p2', 'index': 1, 'title': 'Two'},
      ]);
      expect(detail.isFavorite, isTrue);
    });

    test('maps chapter image URLs to photo detail', () {
      final photo = photoDetailFromJm(
        const JmChapter(
          id: 'p1',
          albumId: 'a1',
          title: 'Chapter',
          imageNames: ['00001.jpg', '00002.jpg'],
        ),
        ['https://img.example/1.jpg', 'https://img.example/2.jpg'],
      );

      expect(photo.photoId, 'p1');
      expect(photo.albumId, 'a1');
      expect(photo.pageCount, 2);
      expect(photo.imageUrls.last, 'https://img.example/2.jpg');
    });
  });
}
