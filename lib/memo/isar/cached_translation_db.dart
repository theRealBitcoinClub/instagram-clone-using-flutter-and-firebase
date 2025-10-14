// models/cached_translation_db.dart
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:isar_community/isar.dart';

part 'cached_translation_db.g.dart';

// Helper function to generate a hash key for cache
String shaCacheKey(String text, String targetLang) {
  final key = '$text|$targetLang';
  final bytes = utf8.encode(key);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

@Collection()
class CachedTranslationDb {
  Id id = Isar.autoIncrement; // Fast FIFO with primary key sort

  @Index(unique: true) // Fast lookups by cacheKey
  late String cacheKey;

  late String postId;
  late String languageCode;
  late String translatedText;

  CachedTranslationDb();

  // Factory constructor that generates the cacheKey
  factory CachedTranslationDb.fromTranslation(String postId, String languageCode, String translatedText) {
    return CachedTranslationDb()
      ..cacheKey = CachedTranslationDb.generateCacheKey(postId, languageCode)
      ..postId = postId
      ..languageCode = languageCode
      ..translatedText = translatedText;
  }

  // Public static method to generate cache key
  static String generateCacheKey(String key, String languageCode) {
    return key.length > 60 ? shaCacheKey(key, languageCode) : '$key|$languageCode';
  }

  @override
  String toString() {
    return 'CachedTranslationDb(id: $id, postId: $postId, lang: $languageCode)';
  }
}
