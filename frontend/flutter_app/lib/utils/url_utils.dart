/// Adds a cache-busting timestamp parameter to a URL
String addCacheBusterToUrl(String url) {
  // Generate a timestamp for cache busting
  final timestamp = DateTime.now().millisecondsSinceEpoch;

  // Check if URL already has query parameters
  final separator = url.contains('?') ? '&' : '?';

  // Return URL with timestamp
  return '$url${separator}t=$timestamp';
}
