import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';

import '../../config.dart';

class PostService {
  static const String orderByField = "createdDateTime";
  static const bool descendingOrder = true;
  final FirebaseFirestore _firestore;
  final String _collectionName;

  // FIFO cache for tracking persisted post IDs (max 10,000 entries)
  static final _persistedPostIds = Queue<String>();
  static const int _maxCacheSize = 10000;

  PostService({FirebaseFirestore? firestore, String collectionName = FirestoreCollections.posts})
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

  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection(_collectionName).doc(postId).delete();
      // Remove from cache on successful deletion
      _removeFromPersistedCache(postId);
      print("Post $postId deleted successfully.");
    } catch (e) {
      print("Error deleting post $postId: $e");
      rethrow;
    }
  }

  // --- PAGINATION METHOD (Primary method for the feed) ---
  Future<List<MemoModelPost>> getPostsPaginated({required int limit, DocumentSnapshot? startAfterDoc}) async {
    Query query = _firestore.collection(_collectionName).orderBy(orderByField, descending: descendingOrder);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    final querySnapshot = await query.limit(limit).get();

    return querySnapshot.docs.map((doc) {
      return MemoModelPost.fromSnapshot(doc);
    }).toList();
  }

  Future<MemoModelPost?> getPostOnce(String postId) async {
    try {
      final DocumentSnapshot snapshot = await _firestore.collection(_collectionName).doc(postId).get();
      if (snapshot.exists) {
        return MemoModelPost.fromSnapshot(snapshot);
      } else {
        print("Post with ID $postId not found.");
        return null;
      }
    } catch (e) {
      print("Error fetching post $postId once: $e");
      return null;
    }
  }

  Future<int> getTotalPostCount() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection(_collectionName).count().get();
      return querySnapshot.count!;
    } catch (e) {
      print('Error getting post count: $e');
      return -1;
    }
  }

  Stream<List<MemoModelPost>> getPostsByCreatorIdStream(String creatorId) {
    return _firestore
        .collection(_collectionName)
        .where('creatorId', isEqualTo: creatorId)
        .orderBy(orderByField, descending: descendingOrder)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MemoModelPost.fromSnapshot(doc)).toList())
        .handleError((error) {
          print("Error fetching posts for creator $creatorId: $error.");
          return <MemoModelPost>[];
        });
  }
}
