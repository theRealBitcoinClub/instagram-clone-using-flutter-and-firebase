import 'package:mahakka/config_whitelist.dart';

class MemoRegExp {
  final String text;

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

  // Member method that utilizes the text property to extract whitelisted image URLs
  List<String> extractAllWhitelistedImageUrls() {
    final List<String> allUrls = extractAllWhitelistedMediaUrls();

    // Filter for URLs that are likely to be images (common image extensions)
    final imageUrls = allUrls.where((url) {
      // Check if URL ends with common image extensions
      final lowerUrl = url.toLowerCase();
      return lowerUrl.endsWith('.jpg') ||
          lowerUrl.endsWith('.jpeg') ||
          lowerUrl.endsWith('.png') ||
          lowerUrl.endsWith('.gif') ||
          lowerUrl.endsWith('.webp') ||
          lowerUrl.endsWith('.bmp') ||
          lowerUrl.endsWith('.svg') ||
          lowerUrl.endsWith('.avif');
    }).toList();

    return imageUrls;
  }

  // Member method that utilizes the text property to extract whitelisted video URLs
  List<String> extractAllWhitelistedVideoUrls() {
    final List<String> allUrls = extractAllWhitelistedMediaUrls();

    // Filter for URLs that are likely to be videos (common video formats and platforms)
    final videoUrls = allUrls.where((url) {
      final lowerUrl = url.toLowerCase();

      // Check for common video file extensions supported by video_player
      final hasVideoExtension =
          lowerUrl.endsWith('.mp4') ||
          lowerUrl.endsWith('.mov') ||
          lowerUrl.endsWith('.m4v') ||
          lowerUrl.endsWith('.avi') ||
          lowerUrl.endsWith('.wmv') ||
          lowerUrl.endsWith('.flv') ||
          lowerUrl.endsWith('.mkv') ||
          lowerUrl.endsWith('.webm') ||
          lowerUrl.endsWith('.3gp');

      return hasVideoExtension;
    }).toList();

    return videoUrls;
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
    final RegExp ipfsExp = RegExp(r'b[A-Za-z2-7]{58,}');
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

  static List<String> extractTopics(String? text) => _extractMatches(text, r'@[a-zA-Z0-9_\-\.]+');
  // static List<String> extractTopics(String? text) => _extractMatches(text, r'(?:^|\s)(@[a-zA-Z0-9_\-\.]+)(?=\s|$)');
  static List<String> extractUrls(String? text) =>
      _extractMatches(text, r'(?:http[s]?:\/\/.)?(?:www\.)?[-a-zA-Z0-9@%._\+~#=]{2,256}\.[a-z]{2,6}\b(?:[-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)');
  // static List<String> extractHashtags(String? text) => _extractMatches(text, r'(?:\s|^)(?:#(?!(?:\d+|\w+?_|_\w*?)(?:\s|$)))(\w+)(?=\s|$)');
  static List<String> extractUrlsWithHttpsAlways(String? text) {
    final matches = extractUrls(text);
    return matches.map((url) {
      if (url.startsWith('www.')) {
        return 'https://$url';
      }
      return url;
    }).toList();
  }

  static List<String> extractHashtags(String? text) => _extractMatches(text, r'#\w+');

  static List<String> _extractMatches(String? text, String pattern) {
    if (text == null || text.isEmpty) return [];

    return RegExp(
      pattern,
      caseSensitive: false,
    ).allMatches(text).map((match) => match.group(0)?.trim() ?? '').where((match) => match.isNotEmpty).toList();
  }
}

class TextFilter {
  static final _urlRegex = RegExp(
    r'https?:\/\/(?:www\.)?[-\w@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-\w()@:%_\+.~#?&\/=]*)(?=\s|$)',
    caseSensitive: false,
  );

  /// Replaces all non-whitelisted domains in the text with "[link removed]"
  static String replaceNonWhitelistedDomains(String text) {
    return text.replaceAllMapped(_urlRegex, (match) {
      final url = match.group(0)!;
      return _isUrlWhitelisted(url) ? url : '[link removed]';
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
