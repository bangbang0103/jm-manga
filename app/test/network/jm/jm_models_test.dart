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

  group('JmComment.fromJson', () {
    Map<String, dynamic> baseJson() => {
          'CID': '11005404',
          'UID': '708492',
          'username': 'tester',
          'content': '<div>content</div>',
          'likes': '0',
          'addtime': 'Sep 01, 2026',
          'photo': 'nopic-Male.gif',
        };

    test('marks comment as spoiler when spoiler is 2', () {
      final comment = JmComment.fromJson({...baseJson(), 'spoiler': '2'});
      expect(comment.isSpoiler, isTrue);
    });

    test('treats spoiler 1 or missing as non-spoiler', () {
      expect(
        JmComment.fromJson({...baseJson(), 'spoiler': '1'}).isSpoiler,
        isFalse,
      );
      expect(JmComment.fromJson(baseJson()).isSpoiler, isFalse);
    });

    test('parses nested replies with their own spoiler flags', () {
      final comment = JmComment.fromJson({
        ...baseJson(),
        'replys': [
          {'CID': '1', 'UID': '2', 'username': 'a', 'spoiler': '2'},
          {'CID': '3', 'UID': '4', 'username': 'b', 'spoiler': '1'},
        ],
      });

      expect(comment.replies, hasLength(2));
      expect(comment.replies.first.isSpoiler, isTrue);
      expect(comment.replies.last.isSpoiler, isFalse);
    });
  });
}
