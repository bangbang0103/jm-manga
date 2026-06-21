import 'album.dart';
import 'reading_progress.dart';

class ReaderInitialData {
  final AlbumDetail album;
  final List<ReadingProgress> progressList;

  const ReaderInitialData({required this.album, required this.progressList});
}
