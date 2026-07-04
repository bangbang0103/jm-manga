import 'package:flutter/foundation.dart';

/// 描述一次搜索请求。
@immutable
class SearchRequest {
  final String keywords;

  const SearchRequest({this.keywords = ''});

  /// 直接把用户输入的内容作为 search_query 发给服务端。
  String get effectiveQuery => keywords.trim();

  bool get hasSearchTerms => keywords.trim().isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is SearchRequest && other.keywords == keywords;

  @override
  int get hashCode => keywords.hashCode;
}

/// 已废弃：JM 搜索 API 不返回 tags，黑名单与 +/- tag 语法无法可靠工作，
/// 因此直接把原始搜索框内容透传给服务端。
class TagQueryParser {
  TagQueryParser._();

  static SearchRequest parse(String raw) => SearchRequest(keywords: raw);
}
