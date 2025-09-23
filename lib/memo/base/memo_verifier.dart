import 'dart:async';

import 'package:blockchain_utils/bip/bip/bip39/bip39_mnemonic_validator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/memo_reg_exp.dart';
import 'package:mahakka/memo_data_checker.dart';
import 'package:mahakka/screens/add_post_controller.dart';

enum MemoVerificationResponse {
  valid(""),
  moreThanThreeTags("Please remove one tag"),
  // zeroTags("Add at least one visible #tag."),
  noTopicNorTag("Must include @topic or #tag."),
  moreThanOneTopic("Only one @topic allowed"),
  tooLong("Text + media Url is too long."),
  tooLongMediaUrl("Media Url is too long."),
  tooShort("Too short. Tags count towards length."),
  minWordCountNotReached("Write more words."),
  offensiveWords("Offensive words detected."),
  email("Email not allowed."),
  urlThatsNotTgNorImageNorVideo("Invalid URL."),
  noImageNorVideo("No image or video found.");

  const MemoVerificationResponse(this.message);
  final String message;
}

class MemoVerifier {
  final String text; // Input text to verify
  final List<String> _hashTags = [];
  final List<String> _topics = [];
  final List<String> _urls = [];

  static const String super_tag = " #mahakka_com";
  //TODO if users dont add their own topic, you add this topic invisibly
  static const String super_topic = "@mahakka_com";
  // --- Configuration Constants ---
  static const int maxHashtags = 3;
  static const int maxTopics = 1;
  static const int minPostLength = 5; // Example, adjust as needed
  //TODO check if that max length works with attaching #mahakka to every post
  //TODO posts with topics will have shorter length for mentioning @topic and in addition the additional OP_CODE,
  //TODO but I could try to read the OP_CODE and build the visually appearing @topic on client side and give the user a character bonus for the textfield
  static int maxPostLength = 207 - super_tag.length - super_topic.length; // Example, adjust as needed
  static const int minWordCount = 1; // Example for posts

  static const int maxProfileNameLength = 30;
  static const int minProfileNameLength = 3;
  //memo has 217
  static const int maxProfileTextLength = 200;
  static const int minProfileTextLength = 0; // Profile text can be empty

  MemoVerifier(this.text);

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

  Future<String> verifyAndBuildImgurUrl() async {
    if (text.isEmpty || !text.contains("imgur") || MemoRegExp.extractUrls(text).isEmpty || text.length > 256) {
      return MemoVerificationResponse.noImageNorVideo.toString();
    }

    String newText = text.replaceFirst("/imgur.com", "/i.imgur.com");
    //TODO THESE DO NOT MATCH THE IMAGE URL MAYBE LATER FIND A WAY TO EXTRACT THE ACTUAL IMAGE URL FROM THAT LINK TOO
    // if (newText == text) newText = text.replaceFirst("imgur.com/a/", "imgur.com/");
    var checker = MemoDataChecker();
    if (await checker.checkUrlReturns404(newText)) {
      return MemoVerificationResponse.noImageNorVideo.toString();
    }
    if (!await checker.isImageValid(url: newText)) {
      var url = newText + ".jpeg";
      if (!await checker.isImageValid(url: url)) {
        url = newText + ".png";
        if (!await checker.isImageValid(url: url)) {
          url = newText + ".jpg";
          if (!await checker.isImageValid(url: url)) {
            return MemoVerificationResponse.noImageNorVideo.toString();
          } else
            return url;
        } else
          return url;
      } else
        return url;
    } else
      return newText;
  }

  // --- Lazy Initializers for Scraped Data ---
  List<String> get hashTags {
    if (_hashTags.isEmpty) _hashTags.addAll(MemoRegExp.extractHashtags(text));

    return _hashTags;
  }

  List<String> get topics {
    if (_topics.isEmpty) _topics.addAll(MemoRegExp.extractTopics(text));

    return _topics;
  }

  List<String> get urls {
    if (_urls.isEmpty) _urls.addAll(MemoRegExp.extractUrls(text));

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

  MemoVerificationResponse verifyNoTopicNorTag() {
    if (topics.isEmpty && hashTags.isEmpty) {
      return MemoVerificationResponse.noTopicNorTag;
    }
    return MemoVerificationResponse.valid;
  }

  MemoVerificationResponse verifyPostLength({int mediaUrlLength = 0}) {
    if (mediaUrlLength > maxPostLength) return MemoVerificationResponse.tooLongMediaUrl;

    final trimmedText = text.trim();
    if (trimmedText.length > (maxPostLength - mediaUrlLength)) {
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

  //TODO verify that giphy, imgur and youtube can be posted but no other urls
  //TODO verify that only one of these urls can be posted once per post
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
    //TODO This requires a dictionary of offensive words or an external service.
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
  MemoVerificationResponse checkAllPostValidations(Ref ref) {
    MemoVerificationResponse result;

    result = verifyPostLength(mediaUrlLength: ref.read(addPostControllerProvider.notifier).getMediaUrl().length);
    if (result != MemoVerificationResponse.valid) return result;

    result = verifyMinWordCount();
    if (result != MemoVerificationResponse.valid) return result;

    result = verifyNoEmail();
    if (result != MemoVerificationResponse.valid) return result;

    result = verifyUrls();
    if (result != MemoVerificationResponse.valid) return result;

    result = verifyOffensiveWords();
    if (result != MemoVerificationResponse.valid) return result;

    result = verifyHashtagCount();
    if (result != MemoVerificationResponse.valid) return result;

    result = verifyTopicCount();
    if (result != MemoVerificationResponse.valid) return result;

    result = verifyNoTopicNorTag();
    if (result != MemoVerificationResponse.valid) return result;

    return MemoVerificationResponse.valid;
  }

  // --- Verification Methods for User Profile Fields ---
  MemoVerificationResponse verifyProfileName() {
    final trimmedText = text.trim();
    if (trimmedText.length > maxProfileNameLength) return MemoVerificationResponse.tooLong;
    if (trimmedText.length < minProfileNameLength) return MemoVerificationResponse.tooShort;
    //TODO Add other checks for profile name if needed (e.g., allowed characters, urls, emails, offensive words)
    return MemoVerificationResponse.valid;
  }

  MemoVerificationResponse verifyProfileBio() {
    final trimmedText = text.trim(); // Bio can often be empty
    if (trimmedText.length > maxProfileTextLength) return MemoVerificationResponse.tooLong;
    //TODO No 'tooShort' for bio if it can be empty, unless you have a min if not empty.
    // if (trimmedText.isNotEmpty && trimmedText.length < minProfileTextLengthIfNotEmpty) return MemoVerificationResponse.tooShort;
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
