import 'package:mahakka/memo/base/memo_verifier.dart';

import '../scraper/memo_scraper_utils.dart';

/// A function signature for a validation check.
///
/// It takes a string of text and returns a MemoVerificationResponse.
typedef Validator = MemoVerificationResponse Function(String text);

/// A class to encapsulate text input validation logic using a decorator pattern.
///
/// It receives text and a list of validators, then executes them sequentially.
class TextInputVerifier {
  final String _text;
  final List<Validator> _validators;

  TextInputVerifier(this._text, [List<Validator>? validators]) : _validators = validators ?? [];

  /// Adds a new validator function to the list of checks.
  TextInputVerifier addValidator(Validator validator) {
    _validators.add(validator);
    return this;
  }

  /// Executes all validators on the text and returns the first error found.
  ///
  /// If all validators pass, it returns MemoVerificationResponse.valid.
  MemoVerificationResponse getResult() {
    for (final validator in _validators) {
      final result = validator(_text);
      if (result != MemoVerificationResponse.valid) {
        return result;
      }
    }
    return MemoVerificationResponse.valid;
  }
}

//TODO SOMETHING STRANGE HERE, MAKE SURE TO COMMUNICATE CLEARLY THE MAXIMUM LENGTH AND HOW TAGS AND TOPICS ARE COUNTED INTO THAT
//OFFER A DIRECT FEEDBACK SHOWING A REMAINING CHARACTERS NUMBER

/// A centralized class to hold static validation methods.
///
/// This provides a clean interface for accessing specific verification rules
/// to be used with TextInputVerifier.
class InputValidators {
  static MemoVerificationResponse verifyPostLength(String text) {
    final trimmedText = text.trim();
    if (trimmedText.length > MemoVerifier.maxPostLength) {
      return MemoVerificationResponse.tooLong;
    }
    if (trimmedText.length < MemoVerifier.minPostLength) {
      return MemoVerificationResponse.tooShort;
    }
    return MemoVerificationResponse.valid;
  }

  static MemoVerificationResponse verifyMinWordCount(String text) {
    final wordCount = text.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
    if (wordCount < MemoVerifier.minWordCount) {
      return MemoVerificationResponse.minWordCountNotReached;
    }
    return MemoVerificationResponse.valid;
  }

  static MemoVerificationResponse verifyUrl(String text) {
    if (text.isEmpty) return MemoVerificationResponse.valid;
    final urls = MemoScraperUtil.extractUrls(text);
    if (urls.isNotEmpty) {
      // You can add more detailed URL validation here.
      return MemoVerificationResponse.urlThatsNotTgNorImageNorVideo;
    }
    return MemoVerificationResponse.valid;
  }

  static MemoVerificationResponse verifyOffensiveWords(String text) {
    // Placeholder for offensive word check.
    return MemoVerificationResponse.valid;
  }

  static MemoVerificationResponse verifyHashtags(String text) {
    final hashtags = MemoScraperUtil.extractHashtags(text);
    if (hashtags.isEmpty) {
      return MemoVerificationResponse.zeroTags;
    }
    if (hashtags.length > MemoVerifier.maxHashtags) {
      return MemoVerificationResponse.moreThanThreeTags;
    }
    return MemoVerificationResponse.valid;
  }

  static MemoVerificationResponse verifyTopics(String text) {
    final topics = MemoScraperUtil.extractTopics(text);
    if (topics.length > MemoVerifier.maxTopics) {
      return MemoVerificationResponse.moreThanOneTopic;
    }
    return MemoVerificationResponse.valid;
  }
}
