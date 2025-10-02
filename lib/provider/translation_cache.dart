// translation_cache.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/provider/translation_sequencer.dart';
import 'package:mahakka/provider/translation_service.dart';

import '../memo/isar/cached_translation_db.dart';
import 'isar_provider.dart';

class TranslationCache {
  static const int _maxSize = 3333;
  static const int _cleanupThreshold = 4000; // ~20% tolerance

  TranslationCache(this.ref);
  final Ref ref;

  // Use the public method from the model class
  String _generateKey(String postId, String languageCode) {
    return CachedTranslationDb.generateCacheKey(postId, languageCode);
  }

  Future<String?> get(String postId, String languageCode) async {
    final isar = await ref.read(isarProvider.future);
    final cacheKey = _generateKey(postId, languageCode);

    final cached = await isar.cachedTranslationDbs.where().cacheKeyEqualTo(cacheKey).findFirst();

    return cached?.translatedText;
  }

  Future<void> put(String postId, String languageCode, String translatedText) async {
    final isar = await ref.read(isarProvider.future);

    await isar.writeTxn(() async {
      final cacheKey = _generateKey(postId, languageCode);

      // Check if exists using indexed cacheKey
      final existing = await isar.cachedTranslationDbs.where().cacheKeyEqualTo(cacheKey).findFirst();

      if (existing != null) {
        // Update existing
        existing.translatedText = translatedText;
        await isar.cachedTranslationDbs.put(existing);
      } else {
        // Create new entry
        final newEntry = CachedTranslationDb.fromTranslation(postId, languageCode, translatedText);
        await isar.cachedTranslationDbs.put(newEntry);

        // Only enforce size limit when we're over tolerance threshold
        await _enforceSizeLimitIfNeeded(isar);
      }
    });
  }

  Future<void> clear() async {
    final isar = await ref.read(isarProvider.future);
    await isar.writeTxn(() async {
      await isar.cachedTranslationDbs.clear();
    });
  }

  Future<int> get size async {
    final isar = await ref.read(isarProvider.future);
    return await isar.cachedTranslationDbs.count();
  }

  /// Enforce FIFO size limit only when significantly over limit
  Future<void> _enforceSizeLimitIfNeeded(Isar isar) async {
    final currentSize = await isar.cachedTranslationDbs.count();
    if (currentSize <= _cleanupThreshold) return;

    final entriesToRemove = currentSize - _maxSize;

    // Auto-increment IDs are naturally ordered by insertion order (FIFO)
    // Just get the first N entries - they're the oldest
    final oldEntries = await isar.cachedTranslationDbs
        .where()
        .limit(entriesToRemove) // No sort needed - natural order is FIFO!
        .findAll();

    await isar.cachedTranslationDbs.deleteAll(oldEntries.map((e) => e.id).toList());

    print('🧹 TranslationCache: Removed $entriesToRemove entries (was $currentSize)');
  }

  @override
  String toString() {
    return 'TranslationCache(maxSize: $_maxSize, cleanupThreshold: $_cleanupThreshold)';
  }
}

// Provider for the cache
final translationCacheProvider = Provider<TranslationCache>((ref) {
  return TranslationCache(ref);
});

// Update your Isar provider to include the new schema:
// isar_provider.dart - Add this to your existing provider
/*
final isarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();

  final isar = await Isar.open(
    directory: dir.path,
    [
      MemoModelPostDbSchema,
      MemoModelCreatorDbSchema,
      CachedTranslationDbSchema, // Add the new schema
    ],
    name: 'mahakka_db',
  );
  return isar;
});
*/

// The rest of your existing code remains the same:
class PostTranslationParams {
  final MemoModelPost post;
  final bool doTranslate;
  final String text;
  final BuildContext context;
  final String languageCode;

  const PostTranslationParams({
    required this.post,
    required this.doTranslate,
    required this.text,
    required this.context,
    required this.languageCode,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostTranslationParams &&
          runtimeType == other.runtimeType &&
          post.id == other.post.id &&
          doTranslate == other.doTranslate &&
          text == other.text &&
          languageCode == other.languageCode;

  @override
  int get hashCode => Object.hash(post.id, doTranslate, text, languageCode);
}

final postTranslationViewerProvider = FutureProvider.family<String, PostTranslationParams>((ref, params) async {
  final translationService = ref.read(translationServiceProvider);
  final translationCache = ref.read(translationCacheProvider);
  final sequencer = ref.read(translationSequencerProvider);

  // Check cache first
  final cachedTranslation = await translationCache.get(params.post.id!, params.languageCode);
  if (cachedTranslation != null) {
    print("📚 TranslationCache: Cache HIT for post: ${params.post.id}, lang: ${params.languageCode}");
    return cachedTranslation;
  }

  print("📚 TranslationCache: Cache MISS for post: ${params.post.id}, lang: ${params.languageCode}");

  final requestId = '${params.post.id}|${params.doTranslate}|${params.text.hashCode}|${params.languageCode}';

  return sequencer.enqueue(requestId, () async {
    print("🎯 SEQUENCER: Processing translation for post: ${params.post.id}");

    final result = await translationService.translatePostForViewer(
      params.post,
      params.doTranslate,
      params.text,
      params.context,
      params.languageCode,
    );

    // Store result in cache
    await translationCache.put(params.post.id!, params.languageCode, result);

    print("🎯 SEQUENCER: Completed translation for post: ${params.post.id}");
    return result;
  });
});

final translationSequencerProvider = Provider<TranslationSequencer>((ref) {
  return TranslationSequencer();
});
