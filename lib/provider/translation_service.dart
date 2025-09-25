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
      //USING SOME UNSUPPORTED LANGUAGE TO BE ABLE TO DETECT ENGLISH
      final detection = await translator.translate(text, to: "bg");
      return detection.sourceLanguage?.code ?? 'auto';
    } catch (e) {
      return 'error';
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
  const Language(code: 'zh-cn', name: '中国人', flag: '🇨🇳'),
  const Language(code: 'de', name: 'Deutsch', flag: '🇩🇪'),
  const Language(code: 'en', name: 'English', flag: '🇬🇧'),
  const Language(code: 'es', name: 'Español', flag: '🇪🇸'),
  const Language(code: 'tl', name: 'Filipino', flag: '🇵🇭'),
  const Language(code: 'fr', name: 'Français', flag: '🇫🇷'),
  const Language(code: 'it', name: 'Italiano', flag: '🇮🇹'),
  const Language(code: 'ja', name: 'Japans', flag: '🇯🇵'),
  const Language(code: 'ru', name: 'Русский', flag: '🇷🇺'),
];

final targetLanguageProvider = StateProvider<Language>((ref) {
  return availableLanguages.firstWhere((lang) => lang.code == 'auto');
});

// Add this extension for targetLanguageProvider
extension TargetLanguageReset on StateController<Language> {
  void reset() {
    state = availableLanguages.firstWhere((lang) => lang.code == 'auto');
  }
}

final isTranslatingProvider = StateProvider<bool>((ref) => false);

final translatedTextProvider = StateProvider<String?>((ref) => null);
