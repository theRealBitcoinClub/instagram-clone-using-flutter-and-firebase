import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';

import '../../config.dart';

class PostScraperFirebaseService {
  static const String orderByField = "createdDateTime";
  static const bool descendingOrder = true;
  final FirebaseFirestore _firestore;
  final String _collectionName;

  // FIFO cache for tracking persisted post IDs (max 10,000 entries)
  static final _persistedPostIds = Queue<String>();
  static const int _maxCacheSize = 100000;

  // Batch processing variables
  static final _batchQueue = Queue<MemoModelPost>();
  static Timer? _batchTimer;
  static const int _maxBatchSize = 500;
  static const Duration _batchTimeout = Duration(minutes: 2);
  static Function(bool success, int processedCount, List<String>? failedPostIds)? _currentOnFinishCallback;

  PostScraperFirebaseService({FirebaseFirestore? firestore, String collectionName = FirestoreCollections.posts})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _collectionName = collectionName;

  // Check if post is already persisted and add to cache if saving
  static bool _isPostAlreadyPersisted(String postId) {
    return _persistedPostIds.contains(postId);
  }

  // Add post ID to cache with FIFO eviction
  static void _addToPersistedCache(String postId) {
    if (_persistedPostIds.length >= _maxCacheSize) {
      // Remove oldest item (FIFO)
      _persistedPostIds.removeFirst();
    }
    _persistedPostIds.add(postId);
  }

  // Remove post ID from cache (useful if post gets deleted)
  static void _removeFromPersistedCache(String postId) {
    _persistedPostIds.remove(postId);
  }

  // Clear entire cache (useful for testing or memory management)
  static void clearPersistedCache() {
    _persistedPostIds.clear();
  }

  // Get current cache size for monitoring
  static int getPersistedCacheSize() {
    return _persistedPostIds.length;
  }

  // Batch processing methods
  static int getBatchQueueSize() {
    return _batchQueue.length;
  }

  //TODO need method to manually finish when scraper is done
  void clearBatchQueue() {
    _batchQueue.clear();
    _cancelTimer();
    print("Batch queue cleared");
  }

  void forceProcessBatch() {
    if (_batchQueue.isEmpty) {
      print("Batch queue is empty, nothing to process");
      _executeCallbackIfNeeded(true, 0, null);
      return;
    }

    print("🔄 Manually forcing batch processing with ${_batchQueue.length} posts...");
    _processBatch();
  }

  /// Saves posts using batching with timeout and duplicate prevention
  /// [onFinish] callback receives (success, processedCount, failedPostIds)
  void savePostsBatch(List<MemoModelPost> posts, {Function(bool success, int processedCount, List<String>? failedPostIds)? onFinish}) {
    if (_currentOnFinishCallback == null && onFinish != null) {
      _currentOnFinishCallback = onFinish;
    }

    final newPosts = _filterDuplicates(posts);

    if (newPosts.isEmpty) {
      print("All posts in the batch are duplicates, skipping...");
      _executeCallbackIfNeeded(true, 0, null);
      return;
    }

    _addToBatchQueue(newPosts);
    _startOrResetTimer();

    if (_batchQueue.length >= _maxBatchSize) {
      _processBatch();
    }
  }

  /// Filters out duplicates from both memory cache and Firebase persistence
  List<MemoModelPost> _filterDuplicates(List<MemoModelPost> posts) {
    final uniquePosts = <MemoModelPost>[];
    final duplicateIds = <String>[];

    for (final post in posts) {
      if (post.id == null) {
        print("Post has null ID, skipping");
        continue;
      }

      // Check memory cache first
      if (_batchQueue.any((p) => p.id == post.id)) {
        duplicateIds.add(post.id!);
        continue;
      }

      // Check persisted cache
      if (_isPostAlreadyPersisted(post.id!)) {
        duplicateIds.add(post.id!);
        continue;
      }

      uniquePosts.add(post);
    }

    if (duplicateIds.isNotEmpty) {
      if (kDebugMode) print("Filtered out ${duplicateIds.length} duplicates: ${duplicateIds.join(', ')}");
    }

    return uniquePosts;
  }

  void _addToBatchQueue(List<MemoModelPost> posts) {
    for (final post in posts) {
      _batchQueue.add(post);
    }
    print("Added ${posts.length} posts to batch queue. Queue size: ${_batchQueue.length}");
  }

  void _startOrResetTimer() {
    _cancelTimer();

    _batchTimer = Timer(_batchTimeout, () {
      print("Batch timeout reached after ${_batchTimeout.inMinutes} minutes");
      if (_batchQueue.isNotEmpty) {
        _processBatch();
      } else {
        _executeCallbackIfNeeded(true, 0, null);
      }
    });

    // print("Batch timer started/reset (${_batchTimeout.inMinutes} minutes)");
  }

  void _cancelTimer() {
    _batchTimer?.cancel();
    _batchTimer = null;
  }

  Future<void> _processBatch() async {
    if (_batchQueue.isEmpty) {
      print("Batch queue is empty, nothing to process");
      _executeCallbackIfNeeded(true, 0, null);
      return;
    }

    _cancelTimer();

    final postsToProcess = _batchQueue.toList();
    _batchQueue.clear();

    print("Processing batch of ${postsToProcess.length} posts...");

    try {
      final batch = _firestore.batch();
      final failedPostIds = <String>[];
      int successfulSaves = 0;

      for (final post in postsToProcess) {
        if (post.id == null) {
          print("Skipping post with null ID");
          failedPostIds.add('null_id_${postsToProcess.indexOf(post)}');
          continue;
        }

        try {
          final docRef = _firestore.collection(_collectionName).doc(post.id);
          batch.set(docRef, post.toJson(), SetOptions(merge: true));
          successfulSaves++;
        } catch (e) {
          print("Error adding post ${post.id} to batch: $e");
          failedPostIds.add(post.id!);
        }
      }

      if (successfulSaves > 0) {
        await batch.commit();
        print("✅ Batch commit successful! Saved $successfulSaves posts in 1 write operation");

        // Add successful posts to persistence cache
        for (final post in postsToProcess) {
          if (post.id != null && !failedPostIds.contains(post.id)) {
            _addToPersistedCache(post.id!);
          }
        }
      } else {
        print("❌ No posts were successfully added to the batch");
      }

      _executeCallbackIfNeeded(true, successfulSaves, failedPostIds.isNotEmpty ? failedPostIds : null);
    } catch (e) {
      print("❌ Batch commit failed: $e");

      // Return failed posts to queue for retry?
      // _batchQueue.addAll(postsToProcess);

      _executeCallbackIfNeeded(false, 0, postsToProcess.where((p) => p.id != null).map((p) => p.id!).toList());
    }
  }

  void _executeCallbackIfNeeded(bool success, int processedCount, List<String>? failedPostIds) {
    if (_currentOnFinishCallback != null) {
      _currentOnFinishCallback!(success, processedCount, failedPostIds);
      _currentOnFinishCallback = null;
    }
  }

  // Original single save method (for backward compatibility)
  Future<void> savePost(MemoModelPost post) async {
    // Check if post is already persisted
    if (_isPostAlreadyPersisted(post.id!)) {
      print("Post ${post.id} already persisted, skipping save.");
      return;
    }

    try {
      await _firestore.collection(_collectionName).doc(post.id).set(post.toJson(), SetOptions(merge: true));

      // Add to cache only after successful save
      _addToPersistedCache(post.id!);
      print("${post.id} Post saved successfully. ${post.text}");
    } catch (e) {
      print("Error saving post ${post.id}: $e");
      // Don't add to cache if save failed
    }
  }
}
