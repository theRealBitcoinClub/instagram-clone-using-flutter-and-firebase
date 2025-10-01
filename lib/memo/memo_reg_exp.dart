import 'package:mahakka/config_whitelist.dart';
import 'package:mahakka/memo/top_level_domains_media_extensions.dart';

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
  bool hasTwitterUrl() => _hasUrlMatchingPattern(WhitelistMediaDomains.twitter);
  bool hasTelegramUrl() => _hasUrlMatchingPattern(WhitelistMediaDomains.telegram);
  bool hasTwitterImageUrl() => _hasUrlMatchingPattern(WhitelistMediaDomains.twitterImages);
  bool hasTwitterInternalUrl() => _hasUrlMatchingPattern(WhitelistMediaDomains.twitterInternal);
  bool hasRedditUrl() => _hasUrlMatchingPattern(WhitelistMediaDomains.reddit);
  bool hasRedditImageUrl() => _hasUrlMatchingPattern(WhitelistMediaDomains.redditImages);
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
        hasTelegramUrl() ||
        hasTwitterUrl() ||
        hasTwitterImageUrl() ||
        hasTwitterInternalUrl() ||
        hasRedditUrl() ||
        hasRedditImageUrl() ||
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
  // static List<String> extractUrlsNew(String? text) => _extractMatches(text, urlRegex);
  static List<String> extractUrlsNew(String text) {
    final regex = RegExp(r'(https?://(?:www\.)?|www\.).*?(?=(?:https?://(?:www\.)?|www\.)|$)', caseSensitive: false, dotAll: true);

    final matches = regex.allMatches(text);
    return matches.map((match) => match.group(0)!).toList();
  }

  static List<String> wrapWithHttpAlways(List<String> urls) {
    return urls.map((url) {
      if (url.startsWith('http')) {
        return url;
      } else
        return 'http://$url';
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

  static List<String> extractUrlsRefinedb4(String text) {
    // Extended list of TLDs including less common ones
    const tlds =
        r'com|org|net|edu|gov|mil|io|co|uk|de|fr|jp|it|es|ca|au|us|br|ru|ch|se|nl|no|eu|info|biz|me|tv|cc|ws|name|mobi|asia|aero|jobs|museum|travel|cat|pro|tel|xxx|post|geo|tech|online|site|website|space|digital|cloud|link|click|blog|shop|store|art|design|dev|app|game|news|media|live|life|world|club|group|team|center|company|solutions|services|agency|network|systems|tech|engineering|consulting|management|partners|capital|ventures|investments|fund|finance|bank|insurance|legal|law|medical|health|care|pharmacy|clinic|hospital|dental|vet|edu|academy|school|college|university|institute|training|courses|education|coop|inc|llc|ltd|corp|corporation|limited|gmbh|ag|plc|sarl|bv|ab|oy|as|sk|cz|hu|pl|ro|bg|gr|hr|si|mk|al|ba|rs|me|yu|su|by|ua|kz|uz|ge|am|az|il|sa|ae|qa|om|kw|bh|eg|ma|tn|dz|ly|sd|ye|sy|jo|lb|ps|iq|ir|af|pk|in|bd|lk|np|bt|mv|mm|th|vn|kh|la|my|sg|id|ph|kr|cn|tw|hk|mo|mn|jp';

    // Image extensions
    const imageTypes =
        r'jpg|jpeg|png|gif|bmp|webp|svg|ico|tiff|tif|heic|heif|raw|cr2|nef|arw|dng|eps|ai|psd|sketch|xd|fig|avi|mp4|mov|wmv|flv|webm|mkv|3gp|m4v|mpg|mpeg|vob|ogv|divx|m2ts|mts|ts|mxf|arf|m4a|wav|mp3|flac|aac|ogg|wma|aiff|ape|opus|pdf|doc|docx|xls|xlsx|ppt|pptx|txt|rtf|zip|rar|7z|tar|gz|iso|dmg|exe|msi|apk|deb|rpm|pkg';

    final regex = RegExp(
      r'(https?://(?:www\.)?|www\.)[a-zA-Z0-9-]+\.[a-zA-Z0-9-]+(?:\.[a-zA-Z]{2,})*(?:/[^\s#?]*(?:\.(?:$imageTypes)(?=[\s#?]|$))?)?[^\s#]*(?:\?[^\s#]*)?(?:#[^\s]*)?'
          .replaceFirst(r'$imageTypes', imageTypes),
      caseSensitive: false,
    );

    final matches = regex.allMatches(text);
    return matches.map((match) => match.group(0)!).toList();
  }

  static List<String> extractUrlsRefined(String text) {
    final tlds = (CommonTLDs.mostCommonTLDs.toList()..sort((a, b) => b.length.compareTo(a.length))).join('|');
    // r'com|org|net|edu|gov|mil|io|co|uk|de|fr|jp|it|es|ca|au|us|br|ru|ch|se|nl|no|eu|info|biz|me|tv|cc|ws|name|mobi|asia|aero|jobs|museum|travel|cat|pro|tel|xxx|post|geo|tech|online|site|website|space|digital|cloud|link|click|blog|shop|store|art|design|dev|app|game|news|media|live|life|world|club|group|team|center|company|solutions|services|agency|network|systems|tech|engineering|consulting|management|partners|capital|ventures|investments|fund|finance|bank|insurance|legal|law|medical|health|care|pharmacy|clinic|hospital|dental|vet|edu|academy|school|college|university|institute|training|courses|education|coop|inc|llc|ltd|corp|corporation|limited|gmbh|ag|plc|sarl|bv|ab|oy|as|sk|cz|hu|pl|ro|bg|gr|hr|si|mk|al|ba|rs|me|yu|su|by|ua|kz|uz|ge|am|az|il|sa|ae|qa|om|kw|bh|eg|ma|tn|dz|ly|sd|ye|sy|jo|lb|ps|iq|ir|af|pk|in|bd|lk|np|bt|mv|mm|th|vn|kh|la|my|sg|id|ph|kr|cn|tw|hk|mo|mn|jp';

    final regex = RegExp(
      r'(https?://(?:www\.)?|www\.)[a-zA-Z0-9-.]+\.(?:$tlds)(?:[/?][a-zA-Z0-9\-._~:/?@!$&'
              '()*+,;=%]*)?'
          .replaceFirst(r'$tlds', tlds),
      caseSensitive: false,
    );

    final matches = regex.allMatches(text);
    return matches.map((match) => match.group(0)!).toList();
  }

  static List<String> extractUrlsRefinedExtensions(List<String> urls) {
    final sortedExtensions = (CommonTLDs.mediaExtensions..sort((a, b) => b.length.compareTo(a.length)));

    return urls.map((url) {
      int? lastExtensionIndex;

      // Find the last occurrence of any extension in the URL
      for (final extension in sortedExtensions) {
        final index = url.toLowerCase().indexOf("." + extension);
        if (index != -1) {
          final endIndex = index + extension.length;
          if (lastExtensionIndex == null || endIndex > lastExtensionIndex) {
            lastExtensionIndex = endIndex;
          }
        }
      }

      // Cut off at the extension if found
      if (lastExtensionIndex != null) {
        return url.substring(0, lastExtensionIndex + ".".length);
      }

      return url;
    }).toList();
  }

  static List<String> extractUrlsGenerously(String? text) {
    if (text == null) return [];

    return extractUrlsRefinedExtensions(extractUrlsRefined(text));
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

class MemoStringUtils {
  static String ensureSpacesAroundMatches(String text, List<String> searchStrings) {
    if (text.isEmpty) return text;

    // Reduce multiple whitespaces to single spaces first
    String result = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Sort by length descending (longest first) to handle contained strings
    final sortedStrings = List<String>.from(searchStrings)
      ..removeWhere((s) => s.isEmpty)
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final searchString in sortedStrings) {
      int startIndex = 0;
      while (startIndex < result.length) {
        final index = result.indexOf(searchString, startIndex);
        if (index == -1) break;

        // Handle space before
        String newBefore = '';
        if (index > 0) {
          if (result[index - 1] != ' ') {
            newBefore = ' ';
          }
        }

        // Handle space after
        String newAfter = '';
        final endIndex = index + searchString.length;
        if (endIndex < result.length) {
          if (result[endIndex] != ' ') {
            newAfter = ' ';
          }
        }

        if (newBefore.isNotEmpty || newAfter.isNotEmpty) {
          final before = result.substring(0, index);
          final after = result.substring(endIndex);

          result = '$before$newBefore$searchString$newAfter$after';
          startIndex = index + searchString.length + newBefore.length + newAfter.length;
        } else {
          startIndex = endIndex;
        }
      }
    }
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    return result;
  }

  static String removeEmoticons(String text) {
    if (text.isEmpty) return text;

    // Unicode ranges for emoticons and emoji
    final emoticonRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}' // Emoticons
      r'\u{1F300}-\u{1F5FF}' // Misc Symbols and Pictographs
      r'\u{1F680}-\u{1F6FF}' // Transport & Map Symbols
      r'\u{1F1E0}-\u{1F1FF}' // Flags (iOS)
      r'\u{2600}-\u{26FF}' // Misc symbols
      r'\u{2700}-\u{27BF}' // Dingbats
      r'\u{FE00}-\u{FE0F}' // Variation Selectors
      r'\u{1F900}-\u{1F9FF}' // Supplemental Symbols and Pictographs
      r'\u{1F018}-\u{1F270}' // Various
      r'\u{238C}]', // Miscellaneous Technical
      unicode: true,
    );

    return text.replaceAll(emoticonRegex, '').trim();
  }
}
