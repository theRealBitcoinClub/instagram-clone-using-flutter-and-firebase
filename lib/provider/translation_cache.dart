// translation_cache.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/provider/translation_service.dart';

class TranslationCache {
  static const int _maxSize = 1233;
  static final Map<String, String> _cache123 = {};
  static final List<String> _keys123 = [];

  String _generateKey(String postId, String languageCode) {
    return '__$postId|$languageCode';
  }

  String? get(String postId, String languageCode) {
    final key = _generateKey(postId, languageCode);
    return _cache123[key];
  }

  void put(String postId, String languageCode, String translatedText) {
    final key = _generateKey(postId, languageCode);

    // If key already exists, remove it to update its position
    if (_cache123.containsKey(key)) {
      _keys123.remove(key);
    }

    // Add to cache
    _cache123[key] = translatedText;
    _keys123.add(key);

    // Enforce FIFO size limit
    if (_keys123.length > _maxSize) {
      final oldestKey = _keys123.removeAt(0);
      _cache123.remove(oldestKey);
    }
  }

  void clear() {
    _cache123.clear();
    _keys123.clear();
  }

  int get size => _cache123.length;

  @override
  String toString() {
    return 'TranslationCache(size: $size, keys: $_keys123)';
  }
}

// Provider for the cache
final translationCacheProvider = Provider<TranslationCache>((ref) {
  return TranslationCache();
});

// // Add to your translation_service.dart
// final postTranslationViewerProvider = FutureProvider.family<String, PostTranslationParams>((ref, params) async {
//   final translationService = ref.read(translationServiceProvider);
//
//   return translationService.translatePostForViewerWithCache(params.postId, params.doTranslate, params.text, params.context);
// });

class PostTranslationParams {
  final MemoModelPost post;
  final bool doTranslate;
  final String text;
  final BuildContext context;
  final String languageCode; // Add this

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
  final sequencer = ref.read(translationSequencerProvider);

  // Create a unique request ID to deduplicate simultaneous requests for same post
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

    print("🎯 SEQUENCER: Completed translation for post: ${params.post.id}");
    return result;
  });
});

final translationSequencerProvider = Provider<TranslationSequencer>((ref) {
  return TranslationSequencer();
});

class SimpleMutex {
  Completer<void>? _lockCompleter;

  Future<T> protect<T>(Future<T> Function() operation) async {
    // Wait for existing lock to be released
    while (_lockCompleter != null) {
      await _lockCompleter!.future;
    }

    // Acquire lock
    _lockCompleter = Completer<void>();

    try {
      return await operation();
    } finally {
      // Release lock
      _lockCompleter?.complete();
      _lockCompleter = null;
    }
  }

  bool get isLocked => _lockCompleter != null;
}

class TranslationSequencer {
  final SimpleMutex _mutex = SimpleMutex();
  final Map<String, Completer<String>> _pendingRequests = {};

  Future<String> enqueue(String requestId, Future<String> Function() operation) async {
    // If there's already a pending request with the same ID, return its future
    if (_pendingRequests.containsKey(requestId)) {
      print("🎯 SEQUENCER: Returning existing future for: $requestId");
      return _pendingRequests[requestId]!.future;
    }

    // Create new completer for this request
    final requestCompleter = Completer<String>();
    _pendingRequests[requestId] = requestCompleter;

    try {
      // Use mutex to ensure only one operation runs at a time
      final result = await _mutex.protect(() async {
        print("🎯 SEQUENCER: Starting operation for: $requestId");

        final result = await operation();

        print("🎯 SEQUENCER: Completed operation for: $requestId");

        return result;
      });

      // Complete the request completer with the result
      requestCompleter.complete(result);
      return result;
    } catch (e, stack) {
      requestCompleter.completeError(e, stack);
      rethrow;
    } finally {
      _pendingRequests.remove(requestId);
    }
  }

  void clear() {
    _pendingRequests.clear();
  }

  int get pendingCount => _pendingRequests.length;
  bool get isLocked => _mutex.isLocked;
}
// You'll need to add the mutex package to your pubspec.yaml:
// dependencies:
//   async: ^2.11.0
// import 'package:async/async.dart';

// class TranslationSequencer {
//   Completer<void>? _currentCompleter;
//   final Map<String, Completer<String>> _pendingRequests = {};
//
//   Future<String> enqueue(String requestId, Future<String> Function() operation) async {
//     // If there's already a pending request with the same ID, return its future
//     if (_pendingRequests.containsKey(requestId)) {
//       print("🎯 SEQUENCER: Returning existing future for: $requestId");
//       return _pendingRequests[requestId]!.future;
//     }
//
//     // Create new completer for this request
//     final requestCompleter = Completer<String>();
//     _pendingRequests[requestId] = requestCompleter;
//
//     // Wait for current operation to complete (if any)
//     if (_currentCompleter != null) {
//       print("🎯 SEQUENCER: Waiting for previous operation to complete...");
//       await _currentCompleter!.future;
//     }
//
//     // Set up the current operation completer
//     _currentCompleter = Completer<void>();
//
//     print("🎯 SEQUENCER: Starting operation for: $requestId");
//
//     try {
//       // Execute the operation
//       final result = await operation();
//
//       // Complete the request completer
//       requestCompleter.complete(result);
//
//       print("🎯 SEQUENCER: Completed operation for: $requestId");
//       return result;
//     } catch (e) {
//       requestCompleter.completeError(e);
//       rethrow;
//     } finally {
//       // Clean up and complete the sequence
//       _pendingRequests.remove(requestId);
//       _currentCompleter?.complete();
//       _currentCompleter = null;
//       print("🎯 SEQUENCER: Sequence slot freed for next operation");
//     }
//   }
//
//   void clear() {
//     _currentCompleter?.complete();
//     _currentCompleter = null;
//     _pendingRequests.clear();
//   }
//
//   int get pendingCount => _pendingRequests.length;
//
//   bool get isProcessing => _currentCompleter != null;
// }

// class TranslationSequencer {
//   Completer<void> _currentCompleter = Completer<void>()..complete();
//   final Map<String, Completer<String>> _pendingRequests = {};
//
//   Future<String> enqueue(String requestId, Future<String> Function() operation) async {
//     // If there's already a pending request with the same ID, return its future
//     if (_pendingRequests.containsKey(requestId)) {
//       return _pendingRequests[requestId]!.future;
//     }
//
//     // Wait for current operation to complete
//     await _currentCompleter.future;
//
//     // Create new completer for this request
//     final completer = Completer<String>();
//     _pendingRequests[requestId] = completer;
//
//     // Set up the next operation
//     _currentCompleter = Completer<void>();
//
//     try {
//       // Execute the operation
//       final result = await operation();
//       completer.complete(result);
//       return result;
//     } catch (e) {
//       completer.completeError(e);
//       rethrow;
//     } finally {
//       // Clean up and complete the sequence
//       _pendingRequests.remove(requestId);
//       _currentCompleter.complete();
//     }
//   }
//
//   void clear() {
//     _currentCompleter = Completer<void>()..complete();
//     _pendingRequests.clear();
//   }
//
//   int get pendingCount => _pendingRequests.length;
// }
