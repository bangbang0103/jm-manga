/// Parses and validates user-provided custom API / image domain inputs.
///
/// Accepts host names, `host:port`, IP addresses, and full URLs. Missing schemes
/// are normalized to `https://`. Supported schemes are `http` and `https` only.
class CustomDomainUtils {
  static const _allowedSchemes = {'http', 'https'};

  const CustomDomainUtils._();

  /// Parses [input] into a normalized base [Uri].
  ///
  /// Returns `uri: null, error: null` for empty/whitespace input (i.e. clear).
  /// Returns `uri: null, error: non-null` when the input is invalid.
  static ParsedCustomDomain parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const ParsedCustomDomain();
    }

    String url = trimmed;
    if (!url.contains('://')) {
      url = 'https://$url';
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      return const ParsedCustomDomain(error: 'Invalid URL');
    }

    if (!_allowedSchemes.contains(uri.scheme)) {
      return const ParsedCustomDomain(
        error: 'Only http:// or https:// are supported',
      );
    }

    if (uri.host.isEmpty) {
      return const ParsedCustomDomain(error: 'Host is required');
    }

    if (uri.hasQuery) {
      return const ParsedCustomDomain(error: 'Query parameters are not allowed');
    }

    if (uri.hasFragment) {
      return const ParsedCustomDomain(error: 'Fragment is not allowed');
    }

    if (uri.path.isNotEmpty && uri.path != '/') {
      return const ParsedCustomDomain(error: 'Path is not allowed');
    }

    if (uri.hasPort && (uri.port <= 0 || uri.port > 65535)) {
      return const ParsedCustomDomain(error: 'Invalid port');
    }

    return ParsedCustomDomain(uri: uri.replace(path: ''));
  }
}

/// Result of parsing a custom domain input.
class ParsedCustomDomain {
  /// Normalized base URI, or `null` when the input was empty or invalid.
  final Uri? uri;

  /// Validation error message, or `null` when the input is valid/empty.
  final String? error;

  const ParsedCustomDomain({this.uri, this.error});

  /// Whether the input is a non-empty, valid domain.
  bool get isValid => uri != null;
}
