/// Information about the latest app release fetched from GitHub.
class AppUpdateInfo {
  /// The release tag, e.g. `v0.3.0`.
  final String version;

  /// Release notes in Markdown.
  final String releaseNotes;

  /// URL to the release page.
  final String releaseUrl;

  /// Optional publish timestamp.
  final DateTime? publishedAt;

  const AppUpdateInfo({
    required this.version,
    required this.releaseNotes,
    required this.releaseUrl,
    this.publishedAt,
  });

  @override
  String toString() {
    return 'AppUpdateInfo(version: $version, releaseUrl: $releaseUrl)';
  }
}
