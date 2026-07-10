/// Strip HTML tags from [html] and return plain text.
///
/// This is intentionally minimal: it removes everything between `<` and `>`.
/// HTML entities such as `&quot;` are left untouched. Use this only when the
/// source is known to be simple inline HTML like JM comment content.
String stripHtmlTags(String html) {
  return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
}
