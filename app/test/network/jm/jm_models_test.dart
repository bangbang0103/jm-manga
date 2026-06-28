import 'package:jm_manga/network/jm/jm_models.dart';
import 'package:test/test.dart';

void main() {
  group('JmChapter.fromJson', () {
    test('maps series_id to albumId for multi-chapter album', () {
      final chapter = JmChapter.fromJson({
        'id': 123,
        'series_id': '456',
        'name': 'Chapter 1',
        'images': ['00001.webp', '00002.webp'],
      });

      expect(chapter.id, '123');
      expect(chapter.albumId, '456');
      expect(chapter.title, 'Chapter 1');
      expect(chapter.imageNames, ['00001.webp', '00002.webp']);
    });

    test('falls back to chapter id for single album (series_id = 0)', () {
      final chapter = JmChapter.fromJson({
        'id': 386957,
        'series_id': '0',
        'name': 'Single Album',
        'images': ['00001.webp'],
      });

      expect(chapter.id, '386957');
      expect(chapter.albumId, '386957');
    });

    test('falls back to chapter id when series_id is missing', () {
      final chapter = JmChapter.fromJson({
        'id': 789,
        'name': 'No Series',
        'images': [],
      });

      expect(chapter.id, '789');
      expect(chapter.albumId, '789');
    });
  });
}
