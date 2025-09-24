import 'package:mahakka/config_whitelist.dart';

class MemoRegExp {
  final String text;
  // static const topicRegex = r'\B@[a-zA-Z0-9_\-\.]+';
  // static const topicRegex = r'@[a-zA-Z0-9_\-\.]+';
  static const topicRegex = r'(?<!\w|https?://[^\s]*|www\.[^\s]*)@[a-zA-Z0-9_\-\.]+';
  static const hashtagRegex = r'#\w+';
  static const urlRegex = r'(?:http[s]?:\/\/.)?(?:www\.)?[-a-zA-Z0-9@%._\+~#=]{2,256}\.[a-z]{2,6}\b(?:[-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)';
  static const ipfsRegex = r'b[A-Za-z2-7]{58,}';

  static const imageExtensions = {".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp", ".svg", ".avif"};
  static const videoExtensions = {"mp4", "mov", "m4v", "avi", "wmv", "flv", "mkv", "webm", "3gp", "mpeg", "mpg", "m2v", "m4p", "m4b"};
  static const audioExtensions = {".mp3", ".wav", ".ogg", ".m4a", ".flac", ".aac", ".wma"};

  MemoRegExp(this.text);

  // Generic method to extract URLs matching a given pattern
  String _extractUrlByPattern(String pattern, {int group = 0}) {
    final imgurRegExp = RegExp(pattern, caseSensitive: false);
    final match = imgurRegExp.firstMatch(text.trim());
    return match?.group(group) ?? "";
  }

  // Generic method to check if any URL matches a pattern
  bool _hasUrlMatchingPattern(String pattern) {
    final RegExp exp = RegExp(pattern, caseSensitive: false);
    return exp.hasMatch(text.trim());
  }

  // Generic method to extract all URLs matching a pattern
  List<String> _extractAllUrlsByPattern(String pattern, {int group = 0}) {
    final RegExp exp = RegExp(pattern, caseSensitive: false);
    return exp.allMatches(text.trim()).map((match) => match.group(group) ?? "").toList();
  }

  // Static method to extract whitelisted image URLs from any text
  static List<String> extractWhitelistedImageUrls(String text) {
    final memoRegExp = MemoRegExp(text);
    return memoRegExp.extractAllWhitelistedImageUrls();
  }

  // Static method to extract whitelisted video URLs from any text
  static List<String> extractWhitelistedVideoUrls(String text) {
    final memoRegExp = MemoRegExp(text);
    return memoRegExp.extractAllWhitelistedVideoUrls();
  }

  // Generic method that can filter by any set of extensions
  List<String> _filterUrlsByExtensions(List<String> urls, Set<String> extensions) {
    return urls.where((url) {
      final lowerUrl = url.toLowerCase();
      return extensions.any((ext) => lowerUrl.endsWith(ext));
    }).toList();
  }

  // Specific methods that reuse the generic functionality
  List<String> extractAllWhitelistedImageUrls() {
    final allUrls = extractAllWhitelistedMediaUrls();
    return _filterUrlsByExtensions(allUrls, imageExtensions);
  }

  List<String> extractAllWhitelistedVideoUrls() {
    final allUrls = extractAllWhitelistedMediaUrls();
    return _filterUrlsByExtensions(allUrls, videoExtensions);
  }

  // Optional: Method to extract other media types
  List<String> extractAllWhitelistedAudioUrls() {
    final allUrls = extractAllWhitelistedMediaUrls();
    return _filterUrlsByExtensions(allUrls, audioExtensions);
  }

  // Extract first whitelisted image URL (useful for previews)
  String? extractFirstWhitelistedImageUrl() {
    final imageUrls = extractAllWhitelistedImageUrls();
    return imageUrls.isNotEmpty ? imageUrls.first : null;
  }

  // Extract first whitelisted video URL (useful for previews)
  String? extractFirstWhitelistedVideoUrl() {
    final videoUrls = extractAllWhitelistedVideoUrls();
    return videoUrls.isNotEmpty ? videoUrls.first : null;
  }

  // Specific domain methods
  String extractValidImgurOrGiphyUrl() {
    final imgurUrl = _extractUrlByPattern(WhitelistMediaDomains.imgur);
    if (imgurUrl.isNotEmpty) return imgurUrl;

    return _extractUrlByPattern(WhitelistMediaDomains.giphy);
  }

  String extractIpfsCid() {
    final RegExp ipfsExp = RegExp(ipfsRegex);
    final match = ipfsExp.firstMatch(text);
    return match?.group(0) ?? "";
  }

  String extractOdyseeUrl() {
    return _extractUrlByPattern(WhitelistMediaDomains.odysee);
  }

  String extractYoutubeUrl() {
    return _extractUrlByPattern(WhitelistMediaDomains.youtube);
  }

  String extractGithubImageUrl() {
    return _extractUrlByPattern(WhitelistMediaDomains.github);
  }

  String extractGitlabImageUrl() {
    return _extractUrlByPattern(WhitelistMediaDomains.gitlab);
  }

  String extractPsfIpfsUrl() {
    return _extractUrlByPattern(WhitelistMediaDomains.psfIpfs);
  }

  String extractWhitelistedDomainUrl() {
    return _extractUrlByPattern(WhitelistMediaDomains.domains);
  }

  // Check methods for each domain type
  bool hasImgurUrl() => _hasUrlMatchingPattern(WhitelistMediaDomains.imgur);
  bool hasGiphyUrl() => _hasUrlMatchingPattern(WhitelistMediaDomains.giphy);
  bool hasOdyseeUrl() => _hasUrlMatchingPattern(WhitelistMediaDomains.odysee);
  bool hasYoutubeUrl() => _hasUrlMatchingPattern(WhitelistMediaDomains.youtube);
  bool hasGithubImageUrl() => _hasUrlMatchingPattern(WhitelistMediaDomains.github);
  bool hasGitlabImageUrl() => _hasUrlMatchingPattern(WhitelistMediaDomains.gitlab);
  bool hasPsfIpfsUrl() => _hasUrlMatchingPattern(WhitelistMediaDomains.psfIpfs);
  bool hasWhitelistedDomainUrl() => _hasUrlMatchingPattern(WhitelistMediaDomains.domains);

  // Check if has any whitelisted media URL
  bool hasAnyWhitelistedMediaUrl() {
    return hasImgurUrl() ||
        hasGiphyUrl() ||
        hasOdyseeUrl() ||
        hasYoutubeUrl() ||
        hasGithubImageUrl() ||
        hasGitlabImageUrl() ||
        hasPsfIpfsUrl() ||
        hasWhitelistedDomainUrl();
  }

  // Check if has any whitelisted image URL
  bool hasAnyWhitelistedImageUrl() {
    return extractAllWhitelistedImageUrls().isNotEmpty;
  }

  // Check if has any whitelisted video URL
  bool hasAnyWhitelistedVideoUrl() {
    return extractAllWhitelistedVideoUrls().isNotEmpty;
  }

  // Extract all whitelisted media URLs
  List<String> extractAllWhitelistedMediaUrls() {
    final List<String> allUrls = [];
    for (final pattern in whitelistPatterns) {
      allUrls.addAll(_extractAllUrlsByPattern(pattern));
    }
    return allUrls.where((url) => url.isNotEmpty).toList();
  }

  // Check if has only whitelisted URLs (no non-whitelisted URLs)
  static bool hasOnlyWhitelistedUrls(List<String> urls) {
    if (urls.isEmpty) return true;

    final nonWhitelistedUrls = urls.where((url) => !isUrlWhitelisted(url)).toList();
    return nonWhitelistedUrls.isEmpty;
  }

  // Check if a specific URL is whitelisted
  static bool isUrlWhitelisted(String url) {
    return whitelistPatterns.any((pattern) => RegExp(pattern, caseSensitive: false).hasMatch(url.trim()));
  }

  static List<String> extractTopics(String? text) => _extractMatches(text, topicRegex);

  static List<String> extractUrls(String? text) => _extractMatches(text, urlRegex);

  static List<String> extractUrlsWithHttpsAlways(String? text) {
    final matches = extractUrls(text);
    return matches.map((url) {
      if (url.startsWith('www.')) {
        return 'https://$url';
      }
      return url;
    }).toList();
  }

  static List<String> extractHashtags(String? text) => _extractMatches(text, hashtagRegex);

  static List<String> _extractMatches(String? text, String pattern) {
    if (text == null || text.isEmpty) return [];

    return RegExp(
      pattern,
      caseSensitive: false,
    ).allMatches(text).map((match) => match.group(0)?.trim() ?? '').where((match) => match.isNotEmpty).toList();
  }
}

class TextFilter {
  static final _urlRegex = RegExp(MemoRegExp.urlRegex, caseSensitive: false);

  /// Replaces all non-whitelisted domains in the text with "[link removed]"
  static String replaceNonWhitelistedDomains(String text) {
    return text.replaceAllMapped(_urlRegex, (match) {
      final url = match.group(0)!;
      return _isUrlWhitelisted(url) ? url : '[link]';
    });
  }

  /// Replaces all non-whitelisted domains with a custom replacement string
  static String replaceNonWhitelistedDomainsWith(String text, String replacement) {
    return text.replaceAllMapped(_urlRegex, (match) {
      final url = match.group(0)!;
      return _isUrlWhitelisted(url) ? url : replacement;
    });
  }

  /// Removes all non-whitelisted domains completely from the text
  static String removeNonWhitelistedDomains(String text) {
    return text.replaceAllMapped(_urlRegex, (match) {
      final url = match.group(0)!;
      return _isUrlWhitelisted(url) ? url : '';
    });
  }

  /// Checks if a URL matches any of the whitelisted patterns
  static bool _isUrlWhitelisted(String url) {
    return whitelistPatterns.any((pattern) => RegExp(pattern, caseSensitive: false).hasMatch(url));
  }

  /// Returns a list of all non-whitelisted URLs found in the text
  static List<String> findNonWhitelistedUrls(String text) {
    final matches = _urlRegex.allMatches(text);
    return matches.map((match) => match.group(0)!).where((url) => !_isUrlWhitelisted(url)).toList();
  }

  /// Returns a list of all whitelisted URLs found in the text
  static List<String> findWhitelistedUrls(String text) {
    final matches = _urlRegex.allMatches(text);
    return matches.map((match) => match.group(0)!).where((url) => _isUrlWhitelisted(url)).toList();
  }

  /// Returns a list of all whitelisted image URLs found in the text
  static List<String> findWhitelistedImageUrls(String text) {
    return MemoRegExp.extractWhitelistedImageUrls(text);
  }

  /// Returns a list of all whitelisted video URLs found in the text
  static List<String> findWhitelistedVideoUrls(String text) {
    return MemoRegExp.extractWhitelistedVideoUrls(text);
  }

  /// Returns the first whitelisted image URL found in the text
  static String? findFirstWhitelistedImageUrl(String text) {
    final imageUrls = MemoRegExp.extractWhitelistedImageUrls(text);
    return imageUrls.isNotEmpty ? imageUrls.first : null;
  }

  /// Returns the first whitelisted video URL found in the text
  static String? findFirstWhitelistedVideoUrl(String text) {
    final videoUrls = MemoRegExp.extractWhitelistedVideoUrls(text);
    return videoUrls.isNotEmpty ? videoUrls.first : null;
  }
}
