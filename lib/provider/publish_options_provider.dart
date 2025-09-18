// Add this to your provider file (or create a new one if needed)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/provider/translation_service.dart';

class PublishOptions {
  final bool hasTranslation;
  final bool publishInBothLanguages;
  final String? originalText;
  final Language? originalLanguage;
  final Language? targetLanguage;

  const PublishOptions({
    required this.publishInBothLanguages,
    this.originalText,
    this.originalLanguage,
    this.targetLanguage,
    required this.hasTranslation,
  });

  PublishOptions copyWith({
    bool? publishInBothLanguages,
    String? originalText,
    Language? originalLanguage,
    Language? targetLanguage,
    bool? hasTranslation,
  }) {
    return PublishOptions(
      hasTranslation: hasTranslation ?? this.hasTranslation,
      publishInBothLanguages: publishInBothLanguages ?? this.publishInBothLanguages,
      originalText: originalText ?? this.originalText,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
    );
  }
}

// Create a provider for publish options
final publishOptionsProvider = StateProvider<PublishOptions>((ref) {
  return const PublishOptions(hasTranslation: false, publishInBothLanguages: false);
});
