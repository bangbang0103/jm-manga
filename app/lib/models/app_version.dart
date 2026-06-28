/// A lightweight semver-like version with major/minor/patch.
///
/// Build numbers (e.g. `+1`) are parsed but ignored for comparison.
class AppVersion {
  final int major;
  final int minor;
  final int patch;

  const AppVersion({required this.major, required this.minor, required this.patch});

  /// Parses a version string such as `v0.2.1` or `0.2.1+5`.
  ///
  /// Throws [FormatException] if the input is not a valid version.
  factory AppVersion.parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw FormatException('Version string is empty');
    }

    // Strip an optional leading 'v' or 'V'.
    var versionPart = trimmed;
    if (versionPart.startsWith('v') || versionPart.startsWith('V')) {
      versionPart = versionPart.substring(1);
    }

    // Strip an optional build number (e.g. `+1`).
    final plusIndex = versionPart.indexOf('+');
    if (plusIndex != -1) {
      versionPart = versionPart.substring(0, plusIndex);
    }

    final parts = versionPart.split('.');
    if (parts.length != 3) {
      throw FormatException('Invalid version format: $input');
    }

    int parsePart(String part, String name) {
      final value = int.tryParse(part);
      if (value == null || value < 0) {
        throw FormatException('Invalid $name version component in: $input');
      }
      return value;
    }

    return AppVersion(
      major: parsePart(parts[0], 'major'),
      minor: parsePart(parts[1], 'minor'),
      patch: parsePart(parts[2], 'patch'),
    );
  }

  /// Returns `true` if this version is newer than [other].
  bool isNewerThan(AppVersion other) {
    if (major != other.major) return major > other.major;
    if (minor != other.minor) return minor > other.minor;
    return patch > other.patch;
  }

  @override
  String toString() => '$major.$minor.$patch';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppVersion &&
          runtimeType == other.runtimeType &&
          major == other.major &&
          minor == other.minor &&
          patch == other.patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);
}
