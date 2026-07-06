import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/l10n/app_localizations.dart';
import 'package:jm_manga/models/reading_progress.dart';

void main() {
  group('ReadingProgress', () {
    test('fromJson parses all fields', () {
      final progress = ReadingProgress.fromJson({
        'album_id': '1',
        'photo_id': 'p1',
        'title': 'Chapter 1',
        'image_index': 5,
        'is_finished': true,
        'last_read_at': '2026-01-01T00:00:00Z',
        'episode_index': 2,
        'page_count': 10,
      });

      expect(progress.albumId, '1');
      expect(progress.photoId, 'p1');
      expect(progress.title, 'Chapter 1');
      expect(progress.imageIndex, 5);
      expect(progress.isFinished, isTrue);
      expect(progress.lastReadAt, '2026-01-01T00:00:00Z');
      expect(progress.episodeIndex, 2);
      expect(progress.pageCount, 10);
    });

    test('fromJson coerces double image_index to int', () {
      final progress = ReadingProgress.fromJson({
        'album_id': '1',
        'photo_id': 'p1',
        'image_index': 5.0,
        'is_finished': 1,
        'last_read_at': '2026-01-01',
      });

      expect(progress.imageIndex, 5);
      expect(progress.isFinished, isTrue);
    });

    test('fromJson coerces string bool values', () {
      final progress = ReadingProgress.fromJson({
        'album_id': '1',
        'photo_id': 'p1',
        'image_index': '3',
        'is_finished': 'true',
        'last_read_at': '2026-01-01',
      });

      expect(progress.imageIndex, 3);
      expect(progress.isFinished, isTrue);
    });

    group('localizedBadgeText', () {
      late AppLocalizations l10n;

      setUpAll(() async {
        l10n = await AppLocalizations.delegate.load(const Locale('en'));
      });

      test('finished with episode', () {
        final progress = ReadingProgress(
          albumId: '1',
          photoId: 'p1',
          imageIndex: 9,
          isFinished: true,
          lastReadAt: '2026-01-01',
          episodeIndex: 2,
          pageCount: 10,
        );

        expect(progress.localizedBadgeText(l10n), '3-100%');
      });

      test('finished without episode', () {
        final progress = ReadingProgress(
          albumId: '1',
          photoId: 'p1',
          imageIndex: 9,
          isFinished: true,
          lastReadAt: '2026-01-01',
          pageCount: 10,
        );

        expect(progress.localizedBadgeText(l10n), 'Finished');
      });

      test('reading with chapter and percent', () {
        final progress = ReadingProgress(
          albumId: '1',
          photoId: 'p1',
          imageIndex: 4,
          isFinished: false,
          lastReadAt: '2026-01-01',
          episodeIndex: 1,
          pageCount: 10,
        );

        expect(progress.localizedBadgeText(l10n), '2·50%');
      });

      test('reading with percent only', () {
        final progress = ReadingProgress(
          albumId: '1',
          photoId: 'p1',
          imageIndex: 4,
          isFinished: false,
          lastReadAt: '2026-01-01',
          pageCount: 10,
        );

        expect(progress.localizedBadgeText(l10n), '50%');
      });

      test('reading with page only', () {
        final progress = ReadingProgress(
          albumId: '1',
          photoId: 'p1',
          imageIndex: 4,
          isFinished: false,
          lastReadAt: '2026-01-01',
        );

        expect(progress.localizedBadgeText(l10n), 'P5');
      });
    });
  });
}
