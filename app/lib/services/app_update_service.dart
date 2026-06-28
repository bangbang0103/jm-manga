import 'package:dio/dio.dart';

import '../models/app_update_info.dart';
import '../utils/proxy_config.dart';

/// Fetches the latest release information from GitHub Releases API.
class AppUpdateService {
  final Dio _dio;
  final String repoOwner;
  final String repoName;
  final String? proxyUrl;

  AppUpdateService({
    Dio? dio,
    this.repoOwner = 'bangbang0103',
    this.repoName = 'jm-manga',
    this.proxyUrl,
  }) : _dio = dio ?? Dio() {
    _dio.options = _dio.options.copyWith(
      baseUrl: 'https://api.github.com',
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 15),
    );
    configureDioProxy(_dio, proxyUrl);
  }

  /// Returns the latest release from `releases/latest`.
  ///
  /// Throws if the response is invalid or the request fails.
  Future<AppUpdateInfo> fetchLatestRelease() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/repos/$repoOwner/$repoName/releases/latest',
    );

    if (response.statusCode != 200 || response.data == null) {
      throw Exception('Failed to fetch latest release: ${response.statusCode}');
    }

    final data = response.data!;
    final tagName = data['tag_name'] as String?;
    final htmlUrl = data['html_url'] as String?;

    if (tagName == null || tagName.isEmpty || htmlUrl == null || htmlUrl.isEmpty) {
      throw const FormatException(
        'Invalid release response: missing tag_name or html_url',
      );
    }

    return AppUpdateInfo(
      version: tagName,
      releaseNotes: (data['body'] as String?) ?? '',
      releaseUrl: htmlUrl,
      publishedAt:
          data['published_at'] != null
              ? DateTime.tryParse(data['published_at'] as String)
              : null,
    );
  }
}
