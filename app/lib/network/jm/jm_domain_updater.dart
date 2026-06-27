import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/app_logger.dart';
import 'jm_constants.dart';
import 'jm_crypto.dart';
import 'jm_domain.dart';

/// JM 域名更新器。
///
/// 负责从域名服务器拉取当前可用的 API / 图片域名，并在本地缓存。
/// 逻辑对齐 jmcomic 库的 `auto_update_domain`：先读缓存，缓存为空时依次
/// 请求 [JmConstants.apiDomainUpdateUrls] 中的地址，解密后提取 `Server` 字段。
class JmDomainUpdater {
  static const _apiDomainsKey = 'jm_updated_api_domains';
  static const _imageDomainsKey = 'jm_updated_image_domains';
  static const _updatedAtKey = 'jm_domains_updated_at';

  /// 缓存有效期。域名变化较快，设短一点（6 小时）。
  static const _cacheTtl = Duration(hours: 6);

  final Dio _dio;

  JmDomainUpdater({Dio? dio}) : _dio = dio ?? Dio();

  /// 获取当前可用的 API 域名列表。
  ///
  /// 优先使用未过期的本地缓存；缓存不存在或已过期时，从域名服务器拉取。
  /// 拉取失败则回退到 [JmConstants.apiDomains]。
  Future<List<String>> fetchApiDomains() async {
    final cached = await _loadCachedDomains(_apiDomainsKey);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    try {
      final updated = await _fetchFromServer();
      if (updated.apiDomains.isNotEmpty) {
        await _saveCachedDomains(_apiDomainsKey, updated.apiDomains);
        return updated.apiDomains;
      }
    } catch (e, st) {
      globalLogger.w('Failed to update JM domains: $e', stackTrace: st);
    }

    return List.unmodifiable(JmConstants.apiDomains);
  }

  /// 获取当前可用的图片域名列表。
  ///
  /// 域名服务器目前只下发 API 域名，图片域名回退到常量配置。
  Future<List<String>> fetchImageDomains() async {
    final cached = await _loadCachedDomains(_imageDomainsKey);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    return List.unmodifiable(JmConstants.imageDomains);
  }

  /// 同时获取 API 与图片域名，组成 [JmDomainConfig]。
  Future<JmDomainConfig> fetchDomainConfig() async {
    final apiDomains = await fetchApiDomains();
    final imageDomains = await fetchImageDomains();
    return JmDomainConfig(apiDomains: apiDomains, imageDomains: imageDomains);
  }

  /// 强制从域名服务器刷新域名，忽略缓存。
  Future<JmDomainConfig> refresh() async {
    final updated = await _fetchFromServer();
    if (updated.apiDomains.isNotEmpty) {
      await _saveCachedDomains(_apiDomainsKey, updated.apiDomains);
    }
    return updated;
  }

  Future<JmDomainConfig> _fetchFromServer() async {
    for (final url in JmConstants.apiDomainUpdateUrls) {
      try {
        final response = await _dio.get<String>(
          url,
          options: Options(
            responseType: ResponseType.plain,
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );
        final text = _stripLeadingNonAscii(response.data ?? '');
        if (text.isEmpty) continue;

        final jsonText = JmCrypto.decodeDomainServerData(text);
        final data = jsonDecode(jsonText) as Map<String, dynamic>;
        final serverList = data['Server'];
        if (serverList is! List || serverList.isEmpty) continue;

        final apiDomains = serverList
            .whereType<String>()
            .map((d) => d.trim())
            .where((d) => d.isNotEmpty)
            .toList();

        globalLogger.i('Updated JM API domains from $url: $apiDomains');
        return JmDomainConfig(
          apiDomains: List.unmodifiable(apiDomains),
          imageDomains: List.unmodifiable(JmConstants.imageDomains),
        );
      } catch (e, st) {
        globalLogger.w('Failed to fetch JM domains from $url: $e', stackTrace: st);
      }
    }

    return const JmDomainConfig();
  }

  static String _stripLeadingNonAscii(String text) {
    var i = 0;
    while (i < text.length && !text[i].isAscii) {
      i++;
    }
    return text.substring(i);
  }

  Future<List<String>?> _loadCachedDomains(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatedAt = prefs.getInt(_updatedAtKey);
      if (updatedAt == null) return null;
      final cachedTime = DateTime.fromMillisecondsSinceEpoch(updatedAt);
      if (DateTime.now().difference(cachedTime) > _cacheTtl) {
        return null;
      }
      final list = prefs.getStringList(key);
      if (list == null || list.isEmpty) return null;
      return list;
    } catch (e, st) {
      globalLogger.w('Failed to load cached JM domains: $e', stackTrace: st);
      return null;
    }
  }

  Future<void> _saveCachedDomains(String key, List<String> domains) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(key, domains);
      await prefs.setInt(_updatedAtKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e, st) {
      globalLogger.w('Failed to cache JM domains: $e', stackTrace: st);
    }
  }
}

extension _StringAscii on String {
  bool get isAscii => codeUnitAt(0) <= 127;
}
