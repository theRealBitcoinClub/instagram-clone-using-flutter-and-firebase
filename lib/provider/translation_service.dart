// translation_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:translator/translator.dart';

final translationServiceProvider = Provider<TranslationService>((ref) {
  return TranslationService();
}); // Add these providers to your translation_service.dart file
final textAnimationProvider = StateProvider<double>((ref) => 1.0);
final showOriginalTextProvider = StateProvider<bool>((ref) => true);

class TranslationService {
  final GoogleTranslator translator = GoogleTranslator();

  Future<String> translateText({required String text, String? from, required String to, List<String> excludePatterns = const []}) async {
    try {
      // Check if text contains any excluded patterns
      for (final pattern in excludePatterns) {
        if (text.contains(pattern)) {
          return text; // Don't translate if it contains excluded pattern
        }
      }

      final translation = await translator.translate(text, from: from ?? 'auto', to: to);
      return translation.text;
    } catch (e) {
      throw Exception('Translation failed: $e');
    }
  }

  Future<String> detectLanguage(String text) async {
    try {
      final detection = await translator.translate(text, to: 'en');
      return detection.sourceLanguage?.code ?? 'auto';
    } catch (e) {
      return 'auto';
    }
  }
}

// Language model
class Language {
  final String code;
  final String name;

  const Language({required this.code, required this.name});

  @override
  String toString() => name;
}

// Available languages
final availableLanguages = [
  const Language(code: 'auto', name: 'Auto'),
  const Language(code: 'en', name: 'English'),
  const Language(code: 'es', name: 'Spanish'),
  const Language(code: 'tl', name: 'Filipino'),
  const Language(code: 'zh', name: 'Chinese'),
  const Language(code: 'ja', name: 'Japanese'),
  const Language(code: 'hi', name: 'Hindi'),
  const Language(code: 'ru', name: 'Russian'),
];

// Riverpod providers for translation state
final sourceLanguageProvider = StateProvider<Language>((ref) {
  return availableLanguages.firstWhere((lang) => lang.code == 'auto');
});

final targetLanguageProvider = StateProvider<Language>((ref) {
  return availableLanguages.firstWhere((lang) => lang.code == 'es');
});

final isTranslatingProvider = StateProvider<bool>((ref) => false);

final translatedTextProvider = StateProvider<String?>((ref) => null);
