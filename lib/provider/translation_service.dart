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
      //TODO THE PATTERNS SHALL BE EXCLUDED FROM TRANSLATION, THEY SHALL BE CUT OUT FROM THE TEXT AND BE ATTACHED TO THE END IF THEY ARE HASHTAGS AND TO THE BEGINNING IF A TOPIC
      //TODO FOR NOW WE EXPECT GOOGLE TRANSLATE TO SOLVE THAT BY ITSELF
      //TODO IF ANY UNSUPPORTED LANGUAGE IS DETECTED LEAVE THE TEXT AS IS
      // Check if text contains any excluded patterns
      // for (final pattern in excludePatterns) {
      //   if (text.contains(pattern)) {
      //     return text; // Don't translate if it contains excluded pattern
      //   }
      // }

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
  final String flag;

  const Language({required this.code, required this.name, required this.flag});

  @override
  String toString() => name;
}

// Available languages
const availableLanguages = [
  const Language(code: 'auto', name: 'Auto', flag: ''),
  const Language(code: 'zh', name: 'Chinese', flag: '🇨🇳'),
  const Language(code: 'en', name: 'English', flag: '🇬🇧'),
  const Language(code: 'tl', name: 'Filipino', flag: '🇵🇭'),
  const Language(code: 'fr', name: 'French', flag: '🇫🇷'),
  const Language(code: 'hi', name: 'Hindi', flag: '🇮🇳'),
  const Language(code: 'ja', name: 'Japanese', flag: '🇯🇵'),
  const Language(code: 'ru', name: 'Russian', flag: '🇷🇺'),
  const Language(code: 'es', name: 'Spanish', flag: '🇪🇸'),
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
