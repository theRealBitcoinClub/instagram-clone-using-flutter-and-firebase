// translation_service.dart
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/main.dart';
import 'package:mahakka/memo/memo_reg_exp.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/provider/translation_cache.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:translator/translator.dart';

import '../screens/add_post_controller.dart';

// Main Translation Service Provider
final translationServiceProvider = Provider<TranslationService>((ref) {
  return TranslationService(ref);
});

// Helper function to generate a hash key for cache
String _generateCacheKey(String text, String targetLang) {
  final key = '$text|$targetLang';
  final bytes = utf8.encode(key);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

final autoTranslationTextProvider = FutureProvider.family<String, String>((ref, originalText) async {
  final translationService = ref.read(translationServiceProvider);
  final systemLangCode = ref.watch(languageCodeProvider);

  // If no language code or it's English, return original text
  if (systemLangCode.isEmpty || systemLangCode == 'en') {
    return originalText;
  }

  try {
    // Generate cache key
    final cacheKey = _generateCacheKey(originalText, systemLangCode);

    // Check cache first
    final cache = ref.read(translationCacheProvider);
    final cachedTranslation = await cache.get(cacheKey, systemLangCode);

    if (cachedTranslation != null) {
      // print('Cache hit for: ${originalText.substring(0, originalText.length > 30 ? 30 : originalText.length)}...');
      return cachedTranslation;
    }

    // print('Cache miss, translating: ${originalText.substring(0, originalText.length > 30 ? 30 : originalText.length)}...');

    // Use the translation service
    final translationResult = await translationService.translateAuto(text: originalText, to: systemLangCode);

    // Store in cache
    await cache.put(cacheKey, systemLangCode, translationResult.text);

    return translationResult.text;
  } catch (error) {
    // If translation fails, return original text
    print('Translation error: $error');
    return originalText;
  }
});

// State Providers
// final textAnimationProvider = StateProvider<double>((ref) => 1.0);
// final showOriginalTextProvider = StateProvider<bool>((ref) => true);
final isTranslatingProvider = StateProvider<bool>((ref) => false);
final translatedTextPostCreationProvider = StateProvider<String?>((ref) => null);
final detectedLanguageProvider = StateProvider<MahakkaLanguage?>((ref) => null);
final languageDetectionFailedProvider = StateProvider<bool>((ref) => false);
final isAutoDetectingProvider = StateProvider<bool>((ref) => false);

class TranslationService {
  final Ref _ref;
  final GoogleTranslator translator = GoogleTranslator();

  TranslationService(this._ref);

  Future<String> translatePostForViewer(MemoModelPost post, bool doTranslate, String langCode) async {
    if (post.text == null || post.text!.trim().isEmpty) return "";

    String text = post.text!;

    // final cache = _ref.read(translationCacheProvider);
    if (!doTranslate) {
      return text;
    }

    String systemLangCode = _ref.read(languageCodeProvider);
    if (systemLangCode.isEmpty) {
      systemLangCode = 'en';
    }

    // String? cachedTranslation = await cache.get(post.id!, systemLangCode);
    // if (cachedTranslation != null) {
    //   return cachedTranslation;
    // }

    try {
      String parseResult = post.parseUrlsTagsTopicClearText(modifyTextProperty: false, parseGenerously: true);
      parseResult = MemoStringUtils.removeEmoticons(parseResult);

      if (parseResult.trim().isEmpty) {
        return text;
      }

      Translation translation = await translateAuto(text: parseResult, to: systemLangCode);
      String? translatedWithMeta = post.appendUrlsTagsTopicToText(textParam: translation.text);

      if (translatedWithMeta != null) {
        // cache.put(post.id!, systemLangCode, translatedWithMeta);
        return translatedWithMeta;
      }
      return text;
    } catch (e) {
      print("error translation $e"); // showSnackBar("Translation failed: ${e.toString()}", type: SnackbarType.error);
      return text;
    }
  }

  // Core translation methods
  Future<Translation> translateAuto({required String text, required String to}) async {
    try {
      return await translator.translate(text, from: 'auto', to: to);
      // return translation.text;
    } catch (e) {
      throw Exception('Translation failed: $e');
    }
  }

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
        _ref.read(snackbarServiceProvider).showTranslatedSnackBar("Error on translation request", type: SnackbarType.error);
        _ref.read(languageDetectionFailedProvider.notifier).state = true;
        _ref.read(detectedLanguageProvider.notifier).state = null;
        return;
      }

      final detectedLanguage = availableLanguages.firstWhere((lang) => lang.code == detectedLangCode, orElse: () => availableLanguages[0]);

      final languageDetectionFailed = detectedLanguage == availableLanguages[0];

      _ref.read(detectedLanguageProvider.notifier).state = detectedLanguage;
      _ref.read(languageDetectionFailedProvider.notifier).state = languageDetectionFailed;

      if (!languageDetectionFailed) {
        _ref.read(snackbarServiceProvider).showTranslatedSnackBar("Detected language: ${detectedLanguage.name}", type: SnackbarType.success);
      }

      // Set initial target language to detected language
      if (detectedLanguage.code != 'auto') {
        _ref.read(targetLanguageProvider.notifier).state = detectedLanguage;
        _ref.read(postCreationTranslationProvider.notifier).state = _ref
            .read(postCreationTranslationProvider)
            .copyWith(originalLanguage: detectedLanguage, targetLanguage: detectedLanguage);
      } else {
        _ref.read(snackbarServiceProvider).showTranslatedSnackBar("Unsupported language detected", type: SnackbarType.info);
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
      _ref.read(translatedTextPostCreationProvider.notifier).state = translated;
      _ref.read(postCreationTranslationProvider.notifier).state = _ref
          .read(postCreationTranslationProvider)
          .copyWith(translatedText: translated, targetLanguage: targetLang);

      onTextChanged(translated);
    } catch (e) {
      showSnackBar("Translation failed: ${e.toString()}", type: SnackbarType.error);
    } finally {
      _ref.read(isTranslatingProvider.notifier).state = false;
    }
  }

  // Reset translation state
  void resetTranslationToShowOriginalText({required String originalText, required Function(String) onTextChanged}) {
    _ref.read(translatedTextPostCreationProvider.notifier).state = null;
    _ref.read(postCreationTranslationProvider.notifier).reset();
    onTextChanged(originalText);
  }

  // Add this method to your TranslationService class
  void resetTranslationStateAfterPublish() {
    // Reset all translation-related providers
    Future.microtask(() {
      _ref.read(translatedTextPostCreationProvider.notifier).state = null;
      _ref.read(postCreationTranslationProvider.notifier).reset();
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
    required ref,
  }) async {
    if (ref.read(isTranslatingProvider)) return;

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
  final MahakkaLanguage? detectedLanguage;
  final bool languageDetectionFailed;
  final bool isAutoDetecting;
  final bool isTranslating;
  final String? translatedText;
  final MahakkaLanguage targetLanguage;

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
class PostCreationTranslation {
  final bool publishInBothLanguages;
  final String translatedText;
  final MahakkaLanguage? originalLanguage;
  final MahakkaLanguage? targetLanguage;

  const PostCreationTranslation({
    required this.publishInBothLanguages,
    required this.translatedText,
    this.originalLanguage,
    this.targetLanguage,
  });

  PostCreationTranslation copyWith({
    bool? publishInBothLanguages,
    String? translatedText,
    MahakkaLanguage? originalLanguage,
    MahakkaLanguage? targetLanguage,
  }) {
    return PostCreationTranslation(
      publishInBothLanguages: publishInBothLanguages ?? this.publishInBothLanguages,
      translatedText: translatedText ?? this.translatedText,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
    );
  }

  // Apply translation and append media URL
  MemoModelPost applyTranslationAndAppendMediaUrl({required MemoModelPost post, required ref}) {
    final useTranslation = targetLanguage != null && targetLanguage != originalLanguage;
    MahakkaLanguage? lang = useTranslation ? targetLanguage! : originalLanguage ?? null;
    String languageFlag = lang != null ? lang.flag : "";
    final content = useTranslation ? translatedText : post.text;

    // TODO: You'll need to import and use the actual media URL getter
    String mediaUrl = ref.read(addPostControllerProvider.notifier).getMediaUrl();
    // String mediaUrl = ""; // Placeholder

    return post.copyWith(text: "$languageFlag $content$mediaUrl");
  }
}

final postCreationTranslationProvider = StateProvider<PostCreationTranslation>((ref) {
  return const PostCreationTranslation(publishInBothLanguages: false, translatedText: "");
});

extension PostTranslationReset on StateController<PostCreationTranslation> {
  void reset() {
    state = const PostCreationTranslation(publishInBothLanguages: false, translatedText: "", originalLanguage: null, targetLanguage: null);
  }
}

// Language model and providers
class MahakkaLanguage {
  final String code;
  final String name;
  final String flag;

  const MahakkaLanguage({required this.code, required this.name, required this.flag});

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MahakkaLanguage && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;

  static MahakkaLanguage? getLanguageByCode(String languageCode) {
    // Handle case-insensitive matching and variations
    final normalizedCode = languageCode.toLowerCase().trim();

    for (final language in availableLanguages) {
      if (language.code.toLowerCase() == normalizedCode) {
        return language;
      }
    }

    //TODO add snackbar to call users to ask for their language to be supported
    //TODO report this error with crashlytics
    // Return english if system language is not supported yet
    return MahakkaLanguage.getLanguageByCode("en");
  }
}

const availableLanguages = [
  MahakkaLanguage(code: 'auto', name: 'Auto', flag: ''),
  MahakkaLanguage(code: 'zh-cn', name: '中国人', flag: '🇨🇳'),
  MahakkaLanguage(code: 'de', name: 'Deutsch', flag: '🇩🇪'),
  MahakkaLanguage(code: 'en', name: 'English', flag: '🇬🇧'),
  MahakkaLanguage(code: 'es', name: 'Español', flag: '🇪🇸'),
  MahakkaLanguage(code: 'tl', name: 'Filipino', flag: '🇵🇭'),
  MahakkaLanguage(code: 'fr', name: 'Français', flag: '🇫🇷'),
  MahakkaLanguage(code: 'it', name: 'Italiano', flag: '🇮🇹'),
  MahakkaLanguage(code: 'ja', name: 'Japans', flag: '🇯🇵'),
  MahakkaLanguage(code: 'ru', name: 'Русский', flag: '🇷🇺'),
];

final targetLanguageProvider = StateProvider<MahakkaLanguage>((ref) {
  return availableLanguages.firstWhere((lang) => lang.code == 'auto');
});

extension TargetLanguageReset on StateController<MahakkaLanguage> {
  void reset() {
    state = availableLanguages.firstWhere((lang) => lang.code == 'auto');
  }
}
