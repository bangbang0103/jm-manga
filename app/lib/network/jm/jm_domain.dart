import 'jm_constants.dart';

class JmDomainConfig {
  final List<String> apiDomains;
  final List<String> imageDomains;
  final String scheme;

  const JmDomainConfig({
    this.apiDomains = JmConstants.apiDomains,
    this.imageDomains = JmConstants.imageDomains,
    this.scheme = 'https',
  });

  Uri apiUri(String path, {Map<String, Object?> queryParameters = const {}}) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri(
      scheme: scheme,
      host: apiDomains.first,
      path: normalizedPath,
      queryParameters: _cleanQuery(queryParameters),
    );
  }

  Uri imageUri(String path, {Map<String, Object?> queryParameters = const {}}) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri(
      scheme: scheme,
      host: imageDomains.first,
      path: normalizedPath,
      queryParameters: _cleanQuery(queryParameters),
    );
  }

  static Map<String, String>? _cleanQuery(Map<String, Object?> params) {
    final query = <String, String>{};
    for (final entry in params.entries) {
      final value = entry.value;
      if (value == null) continue;
      query[entry.key] = value.toString();
    }
    return query.isEmpty ? null : query;
  }
}
