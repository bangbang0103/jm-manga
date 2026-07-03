import '../models/album.dart';
import 'app_logger.dart';

/// 按排除 tag 列表过滤漫画条目。
///
/// 由于列表接口（搜索 / 分类 / 排行）通常不返回 `tags`，匹配会同时检查标题；
/// 当条目本身带有 tag 时也会一并检查。比较时保留大小写，仅去除首尾空格。
class TagFilter {
  TagFilter._();

  static String _normalize(String text) => text.trim();

  static List<AlbumItem> apply(
    List<AlbumItem> items,
    Set<String> excludedTags,
  ) {
    if (excludedTags.isEmpty) return items;

    final normalizedExcluded = excludedTags.map(_normalize).toSet();
    final removed = <String>[];

    final visible = items.where((item) {
      final normalizedTags = item.tags.map(_normalize).toSet();
      final tagHit = normalizedExcluded.intersection(normalizedTags);

      final normalizedTitle = _normalize(item.title);
      final textHit = normalizedExcluded.where(
        (tag) => normalizedTitle.contains(tag),
      );

      final hit = {...tagHit, ...textHit};
      if (hit.isNotEmpty) {
        removed.add('${item.title}[${hit.join(',')}]');
      }
      return hit.isEmpty;
    }).toList();

    globalLogger.d(
      'TagFilter: ${removed.length}/${items.length} excluded by $excludedTags. '
      'Removed: $removed',
    );
    return visible;
  }
}
