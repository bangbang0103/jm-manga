import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/models/album.dart';
import 'package:jm_manga/models/reader_initial_data.dart';
import 'package:jm_manga/models/reading_progress.dart';
import 'package:jm_manga/providers/repository_provider.dart';
import 'package:jm_manga/screens/reader_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fake_repository.dart';
import '../pending_image_provider.dart';
import '../testable_app.dart';

class _ReaderFakeRepo extends FakeApiRepository {
  _ReaderFakeRepo(this.photo);

  final PhotoDetail photo;
  final List<ReadingProgress> synced = [];

  @override
  Future<PhotoDetail> getPhotoDetail(String photoId) async => photo;

  @override
  ImageProvider imageProvider(String url) => const PendingImageProvider();

  @override
  Future<void> syncProgress(ReadingProgress progress) async {
    synced.add(progress);
  }
}

PhotoDetail _photo({required int pageCount}) {
  return PhotoDetail(
    photoId: 'p1',
    title: 'Chapter 1',
    albumId: '1',
    pageCount: pageCount,
    imageUrls: [
      for (var i = 0; i < pageCount; i++) 'https://example.com/p1_$i.jpg',
    ],
  );
}

AlbumDetail _album() {
  return AlbumDetail(
    albumId: '1',
    title: 'Album One',
    description: '',
    author: '',
    tags: const [],
    episodes: const [
      {'photo_id': 'p1', 'title': 'Chapter 1', 'index': 1},
    ],
  );
}

ReadingProgress _progress(int imageIndex) {
  return ReadingProgress(
    albumId: '1',
    photoId: 'p1',
    title: 'Chapter 1',
    imageIndex: imageIndex,
    isFinished: false,
    lastReadAt: '2026-01-01T00:00:00Z',
  );
}

void main() {
  group('ReaderScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('starts at the first page without saved progress', (
      WidgetTester tester,
    ) async {
      final repo = _ReaderFakeRepo(_photo(pageCount: 20));
      await tester.pumpWidget(
        testable(
          ReaderScreen(
            photoId: 'p1',
            initialData: ReaderInitialData(
              album: _album(),
              progressList: const [],
            ),
          ),
          overrides: [apiRepositoryProvider.overrideWithValue(repo)],
        ),
      );
      await _pumpReader(tester);

      expect(find.text('Page 1 / 20'), findsOneWidget);
    });

    testWidgets('resumes to the saved page and syncs that position', (
      WidgetTester tester,
    ) async {
      final repo = _ReaderFakeRepo(_photo(pageCount: 20));
      await tester.pumpWidget(
        testable(
          ReaderScreen(
            photoId: 'p1',
            initialData: ReaderInitialData(
              album: _album(),
              progressList: [_progress(5)],
            ),
          ),
          overrides: [apiRepositoryProvider.overrideWithValue(repo)],
        ),
      );
      await _pumpReader(tester);

      expect(find.text('Page 6 / 20'), findsOneWidget);
      expect(repo.synced, isNotEmpty);
      expect(repo.synced.last.imageIndex, 5);
      expect(repo.synced.last.photoId, 'p1');
    });

    testWidgets('keeps the current page when toggling reader modes', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({'readerMode': 'paged'});
      final repo = _ReaderFakeRepo(_photo(pageCount: 20));
      await tester.pumpWidget(
        testable(
          ReaderScreen(
            photoId: 'p1',
            initialData: ReaderInitialData(
              album: _album(),
              progressList: const [],
            ),
          ),
          overrides: [apiRepositoryProvider.overrideWithValue(repo)],
        ),
      );
      await _pumpReader(tester);
      expect(find.text('Page 1 / 20'), findsOneWidget);

      // 点击右侧 30% 区域翻到第 2 页。
      await tester.tapAt(const Offset(760, 300));
      await _pumpReader(tester);
      expect(find.text('Page 2 / 20'), findsOneWidget);

      // paged → scroll：跳回当前页。
      await tester.tap(find.byIcon(Icons.view_agenda_outlined));
      await _pumpReader(tester);
      expect(find.text('Page 2 / 20'), findsOneWidget);

      // scroll → paged：仍以当前页起跳。
      await tester.tap(find.byIcon(Icons.auto_stories_outlined));
      await _pumpReader(tester);
      expect(find.text('Page 2 / 20'), findsOneWidget);
    });
  });
}

/// 图片在测试中永不加载，ImagePlaceholder 的呼吸动效会让 pumpAndSettle
/// 超时；这里用固定次数的 pump 推进 resume 跳帧与可见性上报直到收敛，
/// 同时覆盖进度同步的 1 秒防抖窗口，避免遗留未完成的 Timer。
Future<void> _pumpReader(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}
