// Add this to your provider file (or create a new one if needed)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/provider/translation_service.dart';

class PublishOptions {
  final bool publishInBothLanguages;
  final String translatedText;
  final Language? originalLanguage;
  final Language? targetLanguage;

  const PublishOptions({required this.publishInBothLanguages, required this.translatedText, this.originalLanguage, this.targetLanguage});

  PublishOptions copyWith({bool? publishInBothLanguages, String? translatedText, Language? originalLanguage, Language? targetLanguage}) {
    return PublishOptions(
      publishInBothLanguages: publishInBothLanguages ?? this.publishInBothLanguages,
      translatedText: translatedText ?? this.translatedText,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
    );
  }
}

// Create a provider for publish options
final publishOptionsProvider = StateProvider<PublishOptions>((ref) {
  return const PublishOptions(publishInBothLanguages: false, translatedText: "");
});
