import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../config.dart';

class PostScraperFirebaseService {
  static const String orderByField = "createdDateTime";
  static const bool descendingOrder = true;
  final FirebaseFirestore _firestore;
  final String _collectionName;
  static const String _metadataCollection = '${FirestoreCollections.posts}_metadata';
  static const int _maxIdsPerDocument = 10000;
  static final _metadataCache = <String, Set<String>>{}; // document_id -> post_ids

  static final _persistedPostIds = Queue<String>();
  static const int _maxCacheSize = 100000;

  // Batch processing variables
  static final _batchQueue = Queue<MemoModelPost>();
  static Timer? _batchTimer;
  static const int _maxBatchSize = 500;
  static const Duration _batchTimeout = Duration(minutes: 3);
  static Function(bool success, int processedCount, List<String>? failedPostIds)? _currentOnFinishCallback;

  PostScraperFirebaseService({FirebaseFirestore? firestore, String collectionName = FirestoreCollections.posts})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _collectionName = collectionName;

  Future<void> initializePostMetadata() async {
    try {
      _print("🔄 Checking if post metadata needs initialization...");
      final existingMetadata = await _firestore.collection(_metadataCollection).limit(1).get();

      if (existingMetadata.docs.isNotEmpty) {
        _print("📊 Metadata documents already exist, loading into cache...");
        await _loadAllMetadataIntoCache();
        return;
      }

      _print("🔄 No metadata documents found, initializing from existing posts...");
      _metadataCache.clear();
      final allPostIds = await _getAllExistingPostIds();

      if (allPostIds.isEmpty) {
        _print("No existing posts found for metadata initialization");
        return;
      }

      // Distribute post IDs across metadata documents
      await _distributePostIdsToMetadataDocs(allPostIds);
      _print("✅ Post metadata initialized with ${allPostIds.length} post IDs across ${_metadataCache.length} documents");
    } catch (e) {
      _print("❌ Error initializing post metadata: $e", e: e);
      rethrow;
    }
  }

  /// Loads all existing metadata documents into cache
  Future<void> _loadAllMetadataIntoCache() async {
    try {
      final metadataDocs = await _firestore.collection(_metadataCollection).get();

      for (final doc in metadataDocs.docs) {
        final data = doc.data();
        final postIds = Set<String>.from(data['post_ids'] ?? []);
        _metadataCache[doc.id] = postIds;
      }

      final totalIds = _metadataCache.values.fold<int>(0, (sum, ids) => sum + ids.length);
      _print("📊 Loaded ${_metadataCache.length} metadata documents with $totalIds post IDs into cache");
    } catch (e) {
      _print("❌ Error loading metadata into cache: $e", e: e);
      throw e;
    }
  }

  /// Fetches all existing post IDs from the posts collection
  Future<Set<String>> _getAllExistingPostIds() async {
    final postIds = <String>{};

    try {
      final querySnapshot = await _firestore.collection(_collectionName).get();

      for (final doc in querySnapshot.docs) {
        postIds.add(doc.id);
      }

      _print("📊 Found ${postIds.length} existing post IDs");
      return postIds;
    } catch (e) {
      _print("❌ Error fetching existing post IDs: $e", e: e);
      return postIds;
    }
  }

  /// Distributes post IDs across multiple metadata documents
  Future<void> _distributePostIdsToMetadataDocs(Set<String> postIds) async {
    final postIdList = postIds.toList();
    final totalDocuments = (postIdList.length / _maxIdsPerDocument).ceil();

    for (int i = 0; i < totalDocuments; i++) {
      final startIndex = i * _maxIdsPerDocument;
      final endIndex = (i + 1) * _maxIdsPerDocument;
      final chunkIds = postIdList.sublist(startIndex, endIndex < postIdList.length ? endIndex : postIdList.length);

      final docId = 'metadata_${i + 1}';
      await _updateMetadataDocument(docId, chunkIds.toSet(), []);

      // Cache the document
      _metadataCache[docId] = chunkIds.toSet();
    }
  }

  /// Enhanced duplicate check that uses metadata documents
  bool isPostAlreadyOnFirebase(String postId) {
    for (final ids in _metadataCache.values) {
      if (ids.contains(postId)) {
        return true;
      }
    }

    return false;
  }

  /// Checks if post ID exists in any metadata document (including uncached ones)
  // Future<bool> _checkPostIdInMetadataDocuments(String postId) async {
  //   try {
  //     final metadataDocs = await _firestore.collection(_metadataCollection).get();
  //
  //     for (final doc in metadataDocs.docs) {
  //       final data = doc.data();
  //       final postIds = List<String>.from(data['post_ids'] ?? []);
  //
  //       // Cache this document for future checks
  //       _metadataCache[doc.id] = postIds.toSet();
  //
  //       if (postIds.contains(postId)) {
  //         return true;
  //       }
  //     }
  //     return false;
  //   } catch (e) {
  //     _print("❌ Error checking post ID in metadata documents: $e");
  //     return false; // Assume not duplicate on error
  //   }
  // }

  /// Updates metadata documents with new post IDs
  Future<void> _updateMetadataWithNewPosts(List<String> newPostIds) async {
    if (newPostIds.isEmpty) return;

    try {
      // Get current metadata documents
      final metadataDocs = await _firestore.collection(_metadataCollection).orderBy('document_number').get();

      if (metadataDocs.docs.isEmpty) {
        // Create first metadata document
        await _createNewMetadataDocument(1, newPostIds.toSet());
        return;
      }

      // Try to add to existing documents first
      var remainingIds = newPostIds.toSet();

      for (final doc in metadataDocs.docs) {
        if (remainingIds.isEmpty) break;

        final data = doc.data();
        final existingIds = Set<String>.from(data['post_ids'] ?? []);
        final currentSize = existingIds.length;
        final availableSpace = _maxIdsPerDocument - currentSize;

        if (availableSpace > 0) {
          final idsToAdd = remainingIds.take(availableSpace).toSet();
          await _updateMetadataDocument(doc.id, idsToAdd, []);

          // Update cache
          _metadataCache[doc.id] = {...existingIds, ...idsToAdd};
          remainingIds.removeAll(idsToAdd);
        }
      }

      // Create new documents for remaining IDs
      if (remainingIds.isNotEmpty) {
        final lastDocNumber = metadataDocs.docs.isNotEmpty ? (metadataDocs.docs.last.data()['document_number'] as int? ?? 0) : 0;
        await _createNewMetadataDocument(lastDocNumber + 1, remainingIds);
      }
    } catch (e) {
      _print("❌ Error updating metadata with new posts: $e", e: e);
    }
  }

  /// Creates a new metadata document
  Future<void> _createNewMetadataDocument(int documentNumber, Set<String> postIds) async {
    final docId = 'metadata_$documentNumber';

    await _firestore.collection(_metadataCollection).doc(docId).set({
      'post_ids': postIds.toList(),
      'document_number': documentNumber,
      'count': postIds.length,
      'last_updated': FieldValue.serverTimestamp(),
    });

    // Cache the new document
    _metadataCache[docId] = postIds;
    _print("📄 Created new metadata document $docId with ${postIds.length} post IDs");
  }

  /// Updates a metadata document with new IDs and optionally removes IDs
  Future<void> _updateMetadataDocument(String docId, Set<String> idsToAdd, List<String> idsToRemove) async {
    final docRef = _firestore.collection(_metadataCollection).doc(docId);

    await _firestore.runTransaction((transaction) async {
      final docSnapshot = await transaction.get(docRef);

      if (!docSnapshot.exists) {
        // Create new document
        transaction.set(docRef, {
          'post_ids': idsToAdd.toList(),
          'document_number': _extractDocumentNumber(docId),
          'count': idsToAdd.length,
          'last_updated': FieldValue.serverTimestamp(),
        });
        return;
      }

      final data = docSnapshot.data()!;
      final existingIds = Set<String>.from(data['post_ids'] ?? []);

      // Apply changes
      existingIds.addAll(idsToAdd);
      existingIds.removeAll(idsToRemove);

      transaction.update(docRef, {'post_ids': existingIds.toList(), 'count': existingIds.length, 'last_updated': FieldValue.serverTimestamp()});
    });
  }

  int _extractDocumentNumber(String docId) {
    final match = RegExp(r'metadata_(\d+)').firstMatch(docId);
    return match != null ? int.parse(match.group(1)!) : 1;
  }

  /// Clears the metadata cache (call this in onDispose)
  static void clearMetadataCache() {
    _metadataCache.clear();
    print("🧹 Metadata cache cleared");
  }

  /// Gets metadata cache statisticsl
  static Map<String, dynamic> getMetadataCacheStats() {
    final totalIds = _metadataCache.values.fold<int>(0, (sum, ids) => sum + ids.length);
    return {'cached_documents': _metadataCache.length, 'total_cached_ids': totalIds};
  }

  // Check if post is already persisted and add to cache if saving
  static bool _wasPostPersistedInThisScrapingRun(String postId) {
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

  void forceProcessBatch() {
    if (_batchQueue.isEmpty) {
      _print("Batch queue is empty, nothing to process");
      _executeCallbackIfNeeded(true, 0, null);
      return;
    }

    _print("🔄 Manually forcing batch processing with ${_batchQueue.length} posts...");
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
      _print("All posts in the batch are duplicates, skipping...");
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
        _print("Post has null ID, skipping");
        continue;
      }

      if (_batchQueue.any((p) => p.id == post.id)) {
        duplicateIds.add(post.id!);
        continue;
      }

      if (_wasPostPersistedInThisScrapingRun(post.id!)) {
        duplicateIds.add(post.id!);
        continue;
      }

      if (isPostAlreadyOnFirebase(post.id!)) {
        duplicateIds.add(post.id!);
        continue;
      }

      uniquePosts.add(post);
    }

    if (duplicateIds.isNotEmpty) {
      if (kDebugMode) _print("Filtered out ${duplicateIds.length} duplicates: ${duplicateIds.join(', ')}");
    }

    return uniquePosts;
  }

  void _addToBatchQueue(List<MemoModelPost> posts) {
    for (final post in posts) {
      _batchQueue.add(post);
    }
    _print("Added ${posts.length} posts to batch queue. Queue size: ${_batchQueue.length}");
  }

  void _startOrResetTimer() {
    _cancelTimer();

    _batchTimer = Timer(_batchTimeout, () {
      _print("Batch timeout reached after ${_batchTimeout.inMinutes} minutes");
      if (_batchQueue.isNotEmpty) {
        _processBatch();
      } else {
        _executeCallbackIfNeeded(true, 0, null);
      }
    });

    // _print("Batch timer started/reset (${_batchTimeout.inMinutes} minutes)");
  }

  void _cancelTimer() {
    _batchTimer?.cancel();
    _batchTimer = null;
  }

  Future<void> _processBatch() async {
    if (_batchQueue.isEmpty) {
      _print("Batch queue is empty, nothing to process");
      _executeCallbackIfNeeded(true, 0, null);
      return;
    }

    _cancelTimer();

    final postsToProcess = _batchQueue.toList();
    _batchQueue.clear();

    _print("Processing batch of ${postsToProcess.length} posts...");

    try {
      final batch = _firestore.batch();
      final failedPostIds = <String>[];
      int successfulSaves = 0;
      final successfulPostIds = <String>[];

      for (final post in postsToProcess) {
        if (post.id == null) {
          _print("Skipping post with null ID");
          failedPostIds.add('null_id_${postsToProcess.indexOf(post)}');
          continue;
        }

        try {
          final docRef = _firestore.collection(_collectionName).doc(post.id);
          batch.set(docRef, post.toJson(), SetOptions(merge: true));
          successfulSaves++;
          successfulPostIds.add(post.id!);
        } catch (e) {
          _print("Error adding post ${post.id} to batch: $e", e: e);
          failedPostIds.add(post.id!);
        }
      }

      if (successfulSaves > 0) {
        await batch.commit();
        _print("✅ Batch commit successful! Saved $successfulSaves posts in 1 write operation");

        // Add successful posts to persistence cache
        for (final post in postsToProcess) {
          if (post.id != null && !failedPostIds.contains(post.id)) {
            _addToPersistedCache(post.id!);
          }
        }
        // ✅ NEW: Update metadata documents with successful post IDs
        await _updateMetadataWithNewPosts(successfulPostIds);
      } else {
        _print("❌ No posts were successfully added to the batch");
      }

      _executeCallbackIfNeeded(true, successfulSaves, failedPostIds.isNotEmpty ? failedPostIds : null);
    } catch (e) {
      _print("❌ Batch commit failed: $e", e: e);

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
    if (_wasPostPersistedInThisScrapingRun(post.id!)) {
      _print("Post ${post.id} already persisted, skipping save.");
      return;
    }

    try {
      await _firestore.collection(_collectionName).doc(post.id).set(post.toJson(), SetOptions(merge: true));

      // Add to cache only after successful save
      _addToPersistedCache(post.id!);
      _print("${post.id} Post saved successfully. ${post.text}");
    } catch (e) {
      _print("Error saving post ${post.id}: $e", e: e);
      // Don't add to cache if save failed
    }
  }

  void _print(String s, {e}) {
    if (e != null) Sentry.captureException(e);
    if (kDebugMode) print("PSFS: " + s);
  }
}
