import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic_validator.dart';
import 'package:mahakka/memo/scraper/memo_scraper_utils.dart';

enum MemoVerificationResponse {
  valid,
  moreThanThreeTags,
  zeroTags,
  noTopicNorTag,
  moreThanOneTopic,
  tooLong,
  tooShort,
  minWordCountNotReached,
  offensiveWords,
  email,
  urlThatsNotTgNorImageNorVideo,
  noImageNorVideo,
}

class MemoVerifier {
  final String text; // Input text to verify
  final List<String> _hashTags = [];
  final List<String> _topics = [];
  final List<String> _urls = [];

  // --- Configuration Constants ---
  static const int maxHashtags = 3;
  static const int maxTopics = 1;
  static const int minPostLength = 5; // Example, adjust as needed
  static const int maxPostLength = 280; // Example, adjust as needed
  static const int minWordCount = 1; // Example for posts

  static const int maxProfileNameLength = 30;
  static const int minProfileNameLength = 3;
  static const int maxProfileTextLength = 160;
  static const int minProfileTextLength = 0; // Profile text can be empty

  MemoVerifier(this.text);

  MemoVerificationResponse checkIsValidText() {
    if (hashTags.length > 3) return MemoVerificationResponse.moreThanThreeTags;
    // if (urls.length > 1 && !_urlMatchesTg() && post.imgurUrl.is) return MemoVerificationResponse.urlThatsNotTgNorImageNorVideo;

    return MemoVerificationResponse.valid;
  }

  MemoVerificationResponse verifyUserName() {
    if (text.length > maxProfileNameLength) return MemoVerificationResponse.tooLong;

    if (text.isEmpty || text.length < minProfileNameLength) return MemoVerificationResponse.tooShort;

    return MemoVerificationResponse.valid;
  }

  MemoVerificationResponse verifyProfileText() {
    if (text.isEmpty || text.length < minProfileTextLength) return MemoVerificationResponse.tooShort;

    if (text.length > maxProfileTextLength) return MemoVerificationResponse.tooLong;

    return MemoVerificationResponse.valid;
  }

  MemoVerificationResponse verifyImgur() {
    if (!text.contains("i.imgur.com")) return MemoVerificationResponse.noImageNorVideo;

    return MemoVerificationResponse.valid;
  }

  // --- Lazy Initializers for Scraped Data ---
  List<String> get hashTags {
    if (_hashTags.isEmpty) _hashTags.addAll(MemoScraperUtil.extractHashtags(text));

    return _hashTags;
  }

  List<String> get topics {
    if (_topics.isEmpty) _topics.addAll(MemoScraperUtil.extractTopics(text));

    return _topics;
  }

  List<String> get urls {
    if (_urls.isEmpty) _urls.addAll(MemoScraperUtil.extractUrls(text));

    return _urls;
  }

  // --- Individual Verification Methods for Post Content ---

  MemoVerificationResponse verifyHashtagCount() {
    if (hashTags.length > maxHashtags) {
      return MemoVerificationResponse.moreThanThreeTags;
    }
    return MemoVerificationResponse.valid;
  }

  MemoVerificationResponse verifyTopicCount() {
    if (topics.length > maxTopics) {
      return MemoVerificationResponse.moreThanOneTopic;
    }
    return MemoVerificationResponse.valid;
  }

  MemoVerificationResponse verifyPostLength() {
    final trimmedText = text.trim();
    if (trimmedText.length > maxPostLength) {
      return MemoVerificationResponse.tooLong;
    }
    // Note: 'tooShort' might also be covered by minWordCount, decide which is primary
    if (trimmedText.length < minPostLength && hashTags.isEmpty && topics.isEmpty) {
      // Only consider it too short if there are no tags/topics to compensate for short text
      return MemoVerificationResponse.tooShort;
    }
    return MemoVerificationResponse.valid;
  }

  MemoVerificationResponse verifyMinWordCount() {
    // Basic word count, can be made more sophisticated
    final wordCount = text.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
    if (wordCount < minWordCount && hashTags.isEmpty && topics.isEmpty) {
      // Consider tags/topics as content
      return MemoVerificationResponse.minWordCountNotReached;
    }
    return MemoVerificationResponse.valid;
  }

  MemoVerificationResponse verifyNoEmail() {
    // Basic email regex, can be improved
    final emailRegex = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
    if (emailRegex.hasMatch(text)) {
      return MemoVerificationResponse.email;
    }
    return MemoVerificationResponse.valid;
  }

  MemoVerificationResponse verifyUrls() {
    if (urls.isEmpty) return MemoVerificationResponse.valid; // No URLs to check

    for (String url in urls) {
      // Example: Allow only specific domains or types. This is highly customizable.
      bool isAllowedImgur = url.contains("imgur.com");
      bool isAllowedTelegram = url.contains("t.me");
      // bool isAllowedVideoHost = url.contains("youtube.com") || url.contains("vimeo.com");

      // This logic is just an example, make it fit your exact needs
      if (!isAllowedImgur && !isAllowedTelegram /* && !isAllowedVideoHost */ ) {
        return MemoVerificationResponse.urlThatsNotTgNorImageNorVideo;
      }
    }
    return MemoVerificationResponse.valid;
  }

  MemoVerificationResponse verifyOffensiveWords() {
    // This requires a dictionary of offensive words or an external service.
    // Placeholder - implement your actual logic here.
    // List<String> offensiveDictionary = ["badword1", "badword2"];
    // for (String word in offensiveDictionary) {
    //   if (text.toLowerCase().contains(word)) {
    //     return MemoVerificationResponse.offensiveWords;
    //   }
    // }
    return MemoVerificationResponse.valid; // Assume valid if no check implemented
  }

  // --- Combined Check for Post Content (used before publishing) ---
  MemoVerificationResponse checkAllPostValidations() {
    MemoVerificationResponse result;

    result = verifyPostLength();
    if (result != MemoVerificationResponse.valid) return result;

    result = verifyMinWordCount();
    if (result != MemoVerificationResponse.valid) return result;

    result = verifyHashtagCount();
    if (result != MemoVerificationResponse.valid) return result;

    result = verifyTopicCount();
    if (result != MemoVerificationResponse.valid) return result;

    // Condition: Must have at least one topic OR at least one hashtag
    if (topics.isEmpty && hashTags.isEmpty) {
      // This condition can be tricky. Does "noTopicNorTag" mean if BOTH are empty?
      // Or should there be a minimum content if tags/topics are also absent?
      // For now, let's assume it means if both are empty after other checks pass.
      // It might conflict with zeroTags if zeroTags implies it's invalid on its own.
      // Let's refine based on your exact rule for noTopicNorTag and zeroTags.
      // If zeroTags means "invalid if hashtags are the only content type attempted and it's zero",
      // then the logic would be different.
      // Assuming for now: if a post is attempted, it should have a topic or a tag.
      // This check might be better placed depending on how you score content length.
    }

    result = verifyNoEmail();
    if (result != MemoVerificationResponse.valid) return result;

    result = verifyUrls();
    if (result != MemoVerificationResponse.valid) return result;

    result = verifyOffensiveWords();
    if (result != MemoVerificationResponse.valid) return result;

    // Check for noTopicNorTag - this depends on your business rule.
    // If a post MUST have either a topic or a tag:
    // if (topics.isEmpty && hashtags.isEmpty) {
    //   return MemoVerificationResponse.noTopicNorTag;
    // }

    // Check for zeroTags if it's a specific requirement for a tag-based post
    // This is tricky. If a user *intends* to post with tags, but provides zero, it's an error.
    // But if they post with a topic, zero tags is fine.
    // This check is probably better handled in the UI based on user intent or a specific post type.
    // For a general verifier, verifyHashtagCount() already handles > max.
    // Let's assume for now `zeroTags` is for a context where tags are mandatory.

    return MemoVerificationResponse.valid;
  }

  // --- Verification Methods for User Profile Fields ---
  MemoVerificationResponse verifyProfileName() {
    final trimmedText = text.trim();
    if (trimmedText.length > maxProfileNameLength) return MemoVerificationResponse.tooLong;
    if (trimmedText.length < minProfileNameLength) return MemoVerificationResponse.tooShort;
    // Add other checks for profile name if needed (e.g., allowed characters)
    return MemoVerificationResponse.valid;
  }

  MemoVerificationResponse verifyProfileBio() {
    final trimmedText = text.trim(); // Bio can often be empty
    if (trimmedText.length > maxProfileTextLength) return MemoVerificationResponse.tooLong;
    // No 'tooShort' for bio if it can be empty, unless you have a min if not empty.
    // if (trimmedText.isNotEmpty && trimmedText.length < minProfileTextLengthIfNotEmpty) return MemoVerificationResponse.tooShort;
    return MemoVerificationResponse.valid;
  }

  // --- Specific Context Verifications (like your original Imgur check) ---
  MemoVerificationResponse verifyIsImgurLink() {
    // Assuming 'text' is the URL here
    if (!text.contains("i.imgur.com") && !text.contains("imgur.com")) {
      // Broader Imgur check
      return MemoVerificationResponse.noImageNorVideo; // Or a more specific "notAnImgurUrl"
    }
    // You might also want to check if it's a direct image link (ends with .jpg, .png, etc.)
    final imgurImageRegex = RegExp(r'^https?://(i\.)?imgur\.com/.*\.(jpg|jpeg|png|gif|mp4|gifv)$');
    if (!imgurImageRegex.hasMatch(text)) {
      // return MemoVerificationResponse.notADirectImgurImageOrVideoLink;
    }
    return MemoVerificationResponse.valid;
  }

  String verifyMnemonic() {
    if (text.isEmpty) {
      return "Enter mnemonic of 12 words or generate a new one"; // Simplified message
    }
    if (!Bip39MnemonicValidator().isValid(text)) {
      return "Check failed, 12-words needed, verify every letter!";
    }

    return "success";
  }
}
