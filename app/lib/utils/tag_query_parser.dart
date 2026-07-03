import 'package:flutter/foundation.dart';

/// 描述一次搜索请求的所有显式与隐式过滤条件。
@immutable
class SearchRequest {
  final String keywords;
  final List<String> includes;
  final List<String> excludes;
  final List<String> globalExcludes;
  final List<String> allowedGlobal;

  const SearchRequest({
    this.keywords = '',
    this.includes = const <String>[],
    this.excludes = const <String>[],
    this.globalExcludes = const <String>[],
    this.allowedGlobal = const <String>[],
  });

  String get effectiveQuery => TagQueryParser.buildEffectiveQuery(this);

  String get historyQuery => TagQueryParser.buildHistoryQuery(this);

  bool get hasSearchTerms =>
      keywords.trim().isNotEmpty ||
      includes.any((tag) => tag.trim().isNotEmpty);

  @override
  bool operator ==(Object other) =>
      other is SearchRequest &&
      other.keywords == keywords &&
      _listEquals(other.includes, includes) &&
      _listEquals(other.excludes, excludes) &&
      _listEquals(other.globalExcludes, globalExcludes) &&
      _listEquals(other.allowedGlobal, allowedGlobal);

  @override
  int get hashCode => Object.hash(
    keywords,
    Object.hashAll(includes),
    Object.hashAll(excludes),
    Object.hashAll(globalExcludes),
    Object.hashAll(allowedGlobal),
  );

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// 解析并构造带 +/- 语法的 JM 站内搜索查询。
class TagQueryParser {
  TagQueryParser._();

  static SearchRequest parse(
    String raw, {
    List<String> globalExcludes = const <String>[],
    List<String> allowedGlobal = const <String>[],
  }) {
    final normalized = _normalize(raw);
    if (normalized.isEmpty) {
      return SearchRequest(
        globalExcludes: globalExcludes,
        allowedGlobal: allowedGlobal,
      );
    }

    final tokens = normalized.split(' ');
    final keywords = <String>[];
    // 使用 LinkedHashSet 保持出现顺序，同时去重。
    final includes = <String>{};
    final excludes = <String>{};
    final allowed = <String>{...allowedGlobal};
    final globalByKey = {
      for (final tag in globalExcludes) _compareTag(tag): _normalizeTag(tag),
    };

    for (final token in tokens) {
      if (token.isEmpty) continue;
      if (token.length > 1 && token.startsWith('+')) {
        final rest = token.substring(1);
        // 只支持单个 +/- 前缀；多个符号按普通关键词处理。
        if (rest.startsWith('+') || rest.startsWith('-')) {
          keywords.add(token);
          continue;
        }
        final tag = _normalizeTag(rest);
        if (tag.isNotEmpty) {
          final globalTag = globalByKey[_compareTag(tag)];
          if (globalTag != null) {
            allowed.add(globalTag);
          } else {
            includes.add(tag);
          }
          _removeTag(excludes, tag);
        } else {
          keywords.add(token);
        }
      } else if (token.length > 1 && token.startsWith('-')) {
        final rest = token.substring(1);
        if (rest.startsWith('+') || rest.startsWith('-')) {
          keywords.add(token);
          continue;
        }
        final tag = _normalizeTag(rest);
        if (tag.isNotEmpty) {
          excludes.add(tag);
          _removeTag(includes, tag);
          _removeTag(allowed, tag);
        } else {
          keywords.add(token);
        }
      } else {
        keywords.add(token);
      }
    }

    return SearchRequest(
      keywords: keywords.join(' '),
      includes: includes.toList(),
      excludes: excludes.toList(),
      globalExcludes: globalExcludes,
      allowedGlobal: allowed.toList(),
    );
  }

  /// 构造真正发给服务端的 search_query。
  static String buildEffectiveQuery(SearchRequest request) {
    final parts = <String>[];

    final keyword = request.keywords.trim();
    if (keyword.isNotEmpty) {
      parts.add(keyword);
    }

    final includeSet = <String>{...request.includes, ...request.allowedGlobal};
    final excludeSet = _buildEffectiveExcludedTags(request);

    for (final tag in includeSet) {
      parts.add('+$tag');
    }

    for (final tag in excludeSet) {
      parts.add('-$tag');
    }

    return parts.join(' ');
  }

  /// 构造保存到搜索历史的查询字符串，不包含自动追加的全局黑名单。
  static String buildHistoryQuery(SearchRequest request) {
    final parts = <String>[];

    final keyword = request.keywords.trim();
    if (keyword.isNotEmpty) {
      parts.add(keyword);
    }

    final includeSet = <String>{...request.includes, ...request.allowedGlobal};
    for (final tag in includeSet) {
      parts.add('+$tag');
    }

    for (final tag in request.excludes) {
      parts.add('-$tag');
    }

    return parts.join(' ');
  }

  static Set<String> _buildEffectiveExcludedTags(SearchRequest request) {
    final allowedKeys = {
      ...request.allowedGlobal.map(_compareTag),
      ...request.includes.map(_compareTag),
    };
    return {
      ...request.globalExcludes,
      ...request.excludes,
    }.where((tag) => !allowedKeys.contains(_compareTag(tag))).toSet();
  }

  static String _normalize(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _normalizeTag(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _compareTag(String input) {
    return _normalizeTag(input);
  }

  static void _removeTag(Set<String> tags, String tag) {
    final key = _compareTag(tag);
    tags.removeWhere((existing) => _compareTag(existing) == key);
  }
}
