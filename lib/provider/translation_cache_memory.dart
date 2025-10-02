// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:mahakka/memo/model/memo_model_post.dart';
// import 'package:mahakka/provider/translation_sequencer.dart';
// import 'package:mahakka/provider/translation_service.dart';
//
// class TranslationCache {
//   static const int _maxSize = 1233;
//   static final Map<String, String> _cache123 = {};
//   static final List<String> _keys123 = [];
//
//   String _generateKey(String postId, String languageCode) {
//     return '__$postId|$languageCode';
//   }
//
//   String? get(String postId, String languageCode) {
//     final key = _generateKey(postId, languageCode);
//     return _cache123[key];
//   }
//
//   void put(String postId, String languageCode, String translatedText) {
//     final key = _generateKey(postId, languageCode);
//
//     // If key already exists, remove it to update its position
//     if (_cache123.containsKey(key)) {
//       _keys123.remove(key);
//     }
//
//     // Add to cache
//     _cache123[key] = translatedText;
//     _keys123.add(key);
//
//     // Enforce FIFO size limit
//     if (_keys123.length > _maxSize) {
//       final oldestKey = _keys123.removeAt(0);
//       _cache123.remove(oldestKey);
//     }
//   }
//
//   void clear() {
//     _cache123.clear();
//     _keys123.clear();
//   }
//
//   int get size => _cache123.length;
//
//   @override
//   String toString() {
//     return 'TranslationCache(size: $size, keys: $_keys123)';
//   }
// }
//
// // Provider for the cache
// final translationCacheProvider = Provider<TranslationCache>((ref) {
//   return TranslationCache();
// });
//
// class PostTranslationParams {
//   final MemoModelPost post;
//   final bool doTranslate;
//   final String text;
//   final BuildContext context;
//   final String languageCode; // Add this
//
//   const PostTranslationParams({
//     required this.post,
//     required this.doTranslate,
//     required this.text,
//     required this.context,
//     required this.languageCode,
//   });
//
//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is PostTranslationParams &&
//           runtimeType == other.runtimeType &&
//           post.id == other.post.id &&
//           doTranslate == other.doTranslate &&
//           text == other.text &&
//           languageCode == other.languageCode;
//
//   @override
//   int get hashCode => Object.hash(post.id, doTranslate, text, languageCode);
// }
//
// final postTranslationViewerProvider = FutureProvider.family<String, PostTranslationParams>((ref, params) async {
//   final translationService = ref.read(translationServiceProvider);
//   final sequencer = ref.read(translationSequencerProvider);
//
//   // Create a unique request ID to deduplicate simultaneous requests for same post
//   final requestId = '${params.post.id}|${params.doTranslate}|${params.text.hashCode}|${params.languageCode}';
//
//   return sequencer.enqueue(requestId, () async {
//     print("🎯 SEQUENCER: Processing translation for post: ${params.post.id}");
//
//     final result = await translationService.translatePostForViewer(
//       params.post,
//       params.doTranslate,
//       params.text,
//       params.context,
//       params.languageCode,
//     );
//
//     print("🎯 SEQUENCER: Completed translation for post: ${params.post.id}");
//     return result;
//   });
// });
//
// final translationSequencerProvider = Provider<TranslationSequencer>((ref) {
//   return TranslationSequencer();
// });
