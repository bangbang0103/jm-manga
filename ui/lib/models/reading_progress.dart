import 'package:jm_manga/l10n/app_localizations.dart';

String _asString(dynamic value) => value.toString();

String? _asStringNullable(dynamic value) => value?.toString();

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

int? _asIntNullable(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase();
    return lower == 'true' || lower == '1';
  }
  return false;
}

class ReadingProgress {
  final String albumId;
  final String photoId;
  final String? title;
  final int imageIndex;
  final bool isFinished;
  final String lastReadAt;
  final int? episodeIndex;
  final int? pageCount;

  ReadingProgress({
    required this.albumId,
    required this.photoId,
    this.title,
    required this.imageIndex,
    required this.isFinished,
    required this.lastReadAt,
    this.episodeIndex,
    this.pageCount,
  });

  factory ReadingProgress.fromJson(Map<String, dynamic> json) {
    return ReadingProgress(
      albumId: _asString(json['album_id']),
      photoId: _asString(json['photo_id']),
      title: _asStringNullable(json['title']),
      imageIndex: _asInt(json['image_index']),
      isFinished: _asBool(json['is_finished']),
      lastReadAt: _asString(json['last_read_at']),
      episodeIndex: _asIntNullable(json['episode_index']),
      pageCount: _asIntNullable(json['page_count']),
    );
  }

  String get badgeText {
    if (isFinished) return 'Finished';

    final percent = pageCount != null && pageCount! > 0
        ? ((imageIndex + 1) / pageCount! * 100).round()
        : null;
    final chapter = episodeIndex != null ? '${episodeIndex! + 1}' : null;

    if (chapter != null && percent != null) {
      return '$chapter·$percent%';
    }
    if (percent != null) {
      return '$percent%';
    }
    return 'P${imageIndex + 1}';
  }

  String localizedBadgeText(AppLocalizations l10n) {
    if (isFinished) return l10n.badgeFinished;

    final percent = pageCount != null && pageCount! > 0
        ? ((imageIndex + 1) / pageCount! * 100).round()
        : null;
    final chapter = episodeIndex != null ? '${episodeIndex! + 1}' : null;

    if (chapter != null && percent != null) {
      return l10n.badgeChapterPercent(chapter, percent);
    }
    if (percent != null) {
      return l10n.badgePercent(percent);
    }
    return l10n.badgePage(imageIndex + 1);
  }
}
