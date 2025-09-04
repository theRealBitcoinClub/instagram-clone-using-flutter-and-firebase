import 'package:mahakka/memo/base/memo_verifier.dart';

/// A function signature for a validation check.
///
/// It takes a string of text and returns a MemoVerificationResponse.
typedef Validator = MemoVerificationResponse Function(String text);

/// A class to encapsulate text input validation logic using a decorator pattern.
///
/// It receives text and a list of validators, then executes them sequentially.
class MemoVerifierDecorator {
  final String _text;
  final List<Validator> _validators;

  MemoVerifierDecorator(this._text, [List<Validator>? validators]) : _validators = validators ?? [];

  /// Adds a new validator function to the list of checks.
  MemoVerifierDecorator addValidator(Validator validator) {
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

/// A centralized class to hold static validation methods.
///
/// This provides a clean interface for accessing specific verification rules
/// to be used with TextInputVerifier.
class InputValidators {
  static MemoVerificationResponse verifyPostLength(String text) {
    return MemoVerifier(text.trim()).verifyPostLength();
  }

  static MemoVerificationResponse verifyMinWordCount(String text) {
    return MemoVerifier(text.trim()).verifyMinWordCount();
  }

  static MemoVerificationResponse verifyUrl(String text) {
    return MemoVerifier(text.trim()).verifyUrls();
  }

  static MemoVerificationResponse verifyOffensiveWords(String text) {
    return MemoVerifier(text.trim()).verifyOffensiveWords();
  }

  static MemoVerificationResponse verifyHashtags(String text) {
    return MemoVerifier(text.trim()).verifyHashtagCount();
  }

  static MemoVerificationResponse verifyTopics(String text) {
    return MemoVerifier(text.trim()).verifyTopicCount();
  }
}
