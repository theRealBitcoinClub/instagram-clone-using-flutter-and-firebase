// translation_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:translator/translator.dart';

import '../screens/add_post_controller.dart';

// Main Translation Service Provider
final translationServiceProvider = Provider<TranslationService>((ref) {
  return TranslationService(ref);
});

// State Providers
final textAnimationProvider = StateProvider<double>((ref) => 1.0);
final showOriginalTextProvider = StateProvider<bool>((ref) => true);
final isTranslatingProvider = StateProvider<bool>((ref) => false);
final translatedTextProvider = StateProvider<String?>((ref) => null);
final detectedLanguageProvider = StateProvider<Language?>((ref) => null);
final languageDetectionFailedProvider = StateProvider<bool>((ref) => false);
final isAutoDetectingProvider = StateProvider<bool>((ref) => false);

class TranslationService {
  final Ref _ref;
  final GoogleTranslator translator = GoogleTranslator();

  TranslationService(this._ref);

  // Core translation methods
  Future<String> translateText({required String text, String? from, required String to}) async {
    try {
      final translation = await translator.translate(text, from: from ?? 'auto', to: to);
      return translation.text;
    } catch (e) {
      throw Exception('Translation failed: $e');
    }
  }

  Future<String> detectLanguage(String text) async {
    try {
      // USING SOME UNSUPPORTED LANGUAGE TO BE ABLE TO DETECT ENGLISH
      final detection = await translator.translate(text, to: "bg");
      return detection.sourceLanguage.code;
    } catch (e) {
      return 'error';
    }
  }

  // Complete language detection flow
  Future<void> detectLanguageWithFlow(String originalText, BuildContext context) async {
    _ref.read(isAutoDetectingProvider.notifier).state = true;
    _ref.read(languageDetectionFailedProvider.notifier).state = false;

    try {
      final detectedLangCode = await detectLanguage(originalText);

      if (detectedLangCode == "error") {
        showSnackBar("Error on translation request", context, type: SnackbarType.error);
        _ref.read(languageDetectionFailedProvider.notifier).state = true;
        _ref.read(detectedLanguageProvider.notifier).state = null;
        return;
      }

      final detectedLanguage = availableLanguages.firstWhere((lang) => lang.code == detectedLangCode, orElse: () => availableLanguages[0]);

      final languageDetectionFailed = detectedLanguage == availableLanguages[0];

      _ref.read(detectedLanguageProvider.notifier).state = detectedLanguage;
      _ref.read(languageDetectionFailedProvider.notifier).state = languageDetectionFailed;

      if (!languageDetectionFailed) {
        showSnackBar("Detected language: ${detectedLanguage.name}", context, type: SnackbarType.success);
      }

      // Set initial target language to detected language
      if (detectedLanguage.code != 'auto') {
        _ref.read(targetLanguageProvider.notifier).state = detectedLanguage;
        _ref.read(postTranslationProvider.notifier).state = _ref
            .read(postTranslationProvider)
            .copyWith(originalLanguage: detectedLanguage, targetLanguage: detectedLanguage);
      } else {
        showSnackBar("Unsupported language detected", context, type: SnackbarType.info);
      }
    } catch (e) {
      _ref.read(languageDetectionFailedProvider.notifier).state = true;
      _ref.read(detectedLanguageProvider.notifier).state = null;
    } finally {
      // Future.microtask(() {
      _ref.read(isAutoDetectingProvider.notifier).state = false;
      // });
    }
  }

  // Complete translation flow
  Future<void> translateTextWithFlow({
    required String originalText,
    required MemoModelPost post,
    required BuildContext context,
    required Function(String) onTextChanged,
  }) async {
    final targetLang = _ref.read(targetLanguageProvider);
    final detectedLanguage = _ref.read(detectedLanguageProvider);

    _ref.read(isTranslatingProvider.notifier).state = true;

    try {
      String translated = await translateText(text: originalText, from: detectedLanguage?.code, to: targetLang.code);

      // Process the translated text
      translated = MemoModelPost.restoreTagsAndTopicCase(translated, originalText);
      translated = MemoModelPost.restoreMediaUrlsCase(post, translated);

      // Update providers
      _ref.read(translatedTextProvider.notifier).state = translated;
      _ref.read(postTranslationProvider.notifier).state = _ref
          .read(postTranslationProvider)
          .copyWith(translatedText: translated, targetLanguage: targetLang);

      onTextChanged(translated);
    } catch (e) {
      showSnackBar("Translation failed: ${e.toString()}", context, type: SnackbarType.error);
    } finally {
      _ref.read(isTranslatingProvider.notifier).state = false;
    }
  }

  // Reset translation state
  void resetTranslationToShowOriginalText({required String originalText, required Function(String) onTextChanged}) {
    _ref.read(translatedTextProvider.notifier).state = null;
    _ref.read(postTranslationProvider.notifier).reset();
    onTextChanged(originalText);
  }

  // Add this method to your TranslationService class
  void resetTranslationStateAfterPublish() {
    // Reset all translation-related providers
    Future.microtask(() {
      _ref.read(translatedTextProvider.notifier).state = null;
      _ref.read(postTranslationProvider.notifier).reset();
      _ref.read(targetLanguageProvider.notifier).reset();
      _ref.read(detectedLanguageProvider.notifier).state = null;
      _ref.read(languageDetectionFailedProvider.notifier).state = false;
      _ref.read(isAutoDetectingProvider.notifier).state = false;
      _ref.read(isTranslatingProvider.notifier).state = false;
    });
  }

  // Handle language selection
  Future<void> handleLanguageSelection({
    required String selectedLangCode,
    required String originalText,
    required BuildContext context,
    required Function(String) onTextChanged,
    required MemoModelPost post,
  }) async {
    final selectedLang = availableLanguages.firstWhere((lang) => lang.code == selectedLangCode, orElse: () => availableLanguages[1]);

    final detectedLanguage = _ref.read(detectedLanguageProvider);
    _ref.read(targetLanguageProvider.notifier).state = selectedLang;

    // Trigger translation if languages are different, otherwise reset
    if (detectedLanguage == null || selectedLang.code != detectedLanguage.code) {
      await translateTextWithFlow(originalText: originalText, post: post, context: context, onTextChanged: onTextChanged);
    } else {
      resetTranslationToShowOriginalText(originalText: originalText, onTextChanged: onTextChanged);
    }
  }
}

// State class to hold translation state
class TranslationState {
  final Language? detectedLanguage;
  final bool languageDetectionFailed;
  final bool isAutoDetecting;
  final bool isTranslating;
  final String? translatedText;
  final Language targetLanguage;

  TranslationState({
    required this.detectedLanguage,
    required this.languageDetectionFailed,
    required this.isAutoDetecting,
    required this.isTranslating,
    required this.translatedText,
    required this.targetLanguage,
  });
}

// Post Translation Model and Provider
class PostTranslation {
  final bool publishInBothLanguages;
  final String translatedText;
  final Language? originalLanguage;
  final Language? targetLanguage;

  const PostTranslation({required this.publishInBothLanguages, required this.translatedText, this.originalLanguage, this.targetLanguage});

  PostTranslation copyWith({bool? publishInBothLanguages, String? translatedText, Language? originalLanguage, Language? targetLanguage}) {
    return PostTranslation(
      publishInBothLanguages: publishInBothLanguages ?? this.publishInBothLanguages,
      translatedText: translatedText ?? this.translatedText,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
    );
  }

  // Apply translation and append media URL
  MemoModelPost applyTranslationAndAppendMediaUrl({required MemoModelPost post, required ref}) {
    final useTranslation = targetLanguage != null && targetLanguage != originalLanguage;
    Language? lang = useTranslation ? targetLanguage! : originalLanguage ?? null;
    String languageFlag = lang != null ? lang.flag : "";
    final content = useTranslation ? translatedText : post.text;

    // TODO: You'll need to import and use the actual media URL getter
    String mediaUrl = ref.read(addPostControllerProvider.notifier).getMediaUrl();
    // String mediaUrl = ""; // Placeholder

    return post.copyWith(text: "$languageFlag $content$mediaUrl");
  }
}

final postTranslationProvider = StateProvider<PostTranslation>((ref) {
  return const PostTranslation(publishInBothLanguages: false, translatedText: "");
});

extension PostTranslationReset on StateController<PostTranslation> {
  void reset() {
    state = const PostTranslation(publishInBothLanguages: false, translatedText: "", originalLanguage: null, targetLanguage: null);
  }
}

// Language model and providers
class Language {
  final String code;
  final String name;
  final String flag;

  const Language({required this.code, required this.name, required this.flag});

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Language && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;
}

const availableLanguages = [
  Language(code: 'auto', name: 'Auto', flag: ''),
  Language(code: 'zh-cn', name: '中国人', flag: '🇨🇳'),
  Language(code: 'de', name: 'Deutsch', flag: '🇩🇪'),
  Language(code: 'en', name: 'English', flag: '🇬🇧'),
  Language(code: 'es', name: 'Español', flag: '🇪🇸'),
  Language(code: 'tl', name: 'Filipino', flag: '🇵🇭'),
  Language(code: 'fr', name: 'Français', flag: '🇫🇷'),
  Language(code: 'it', name: 'Italiano', flag: '🇮🇹'),
  Language(code: 'ja', name: 'Japans', flag: '🇯🇵'),
  Language(code: 'ru', name: 'Русский', flag: '🇷🇺'),
];

final targetLanguageProvider = StateProvider<Language>((ref) {
  return availableLanguages.firstWhere((lang) => lang.code == 'auto');
});

extension TargetLanguageReset on StateController<Language> {
  void reset() {
    state = availableLanguages.firstWhere((lang) => lang.code == 'auto');
  }
}
