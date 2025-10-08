import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config.dart';
import '../../repositories/profile_post_cache.dart';

class PostServiceProfile {
  static const String orderByField = "createdDateTime";
  static const bool descendingOrder = true;
  final FirebaseFirestore _firestore;
  final String _collectionName;
  final bool _debugMode = kDebugMode;

  PostServiceProfile({FirebaseFirestore? firestore, String collectionName = FirestoreCollections.posts})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _collectionName = collectionName;

  // --- SIMPLE LIST IMPLEMENTATION FOR PROFILE POSTS ---
  Future<List<MemoModelPost>> getPostsByCreatorIdList(String creatorId, Ref ref, int limit) async {
    _print("🔄 PSP: getPostsByCreatorIdList called for creator: $creatorId");

    try {
      final postCache = ref.read(profilePostCacheProvider);
      final sharedPrefs = await SharedPreferences.getInstance();
      final countKey = '${limit}_post_count_$creatorId';

      final currentCount = await _getPostCountByCreatorId(creatorId);
      _print("📊 PSP: Current post count for $creatorId: $currentCount");

      final storedCount = sharedPrefs.getInt(countKey) ?? 0;
      _print("💾 PSP: Stored post count for $creatorId: $storedCount");

      final shouldFetchFromFirebase = storedCount == 0 || currentCount != storedCount;

      if (shouldFetchFromFirebase) {
        return await fetchFromFirebaseThenSaveToCache(creatorId, limit, postCache, sharedPrefs, countKey, currentCount);
      } else {
        _print("💾 PSP: Count unchanged, loading from cache");
        final cachedPosts = await postCache.getCachedProfilePosts(creatorId, limit);
        _print("📚 PSP: Loaded ${cachedPosts.length} posts from cache");
        return cachedPosts;
      }
    } catch (e) {
      _print("❌ PSP: Error in getPostsByCreatorIdList: $e");

      // Fallback to cache on error
      final postCache = ref.read(profilePostCacheProvider);
      final cachedPosts = await postCache.getCachedProfilePosts(creatorId, limit);
      _print("🔄 PSP: Fallback to cache, loaded ${cachedPosts.length} posts");
      return cachedPosts;
    }
  }

  Future<List<MemoModelPost>> fetchFromFirebaseThenSaveToCache(
    String creatorId,
    int limit,
    ProfilePostCache postCache,
    SharedPreferences sharedPrefs,
    String countKey,
    int currentCount,
  ) async {
    _print("🔄 PSP: Count changed or first load, fetching from Firebase");

    // var limit = ref.read(profileLimitProvider);
    final firebasePosts = await _fetchPostsFromFirebase(creatorId, limit);
    _print("✅ PSP: Fetched ${firebasePosts.length} posts from Firebase");

    await postCache.saveProfilePosts(creatorId, firebasePosts);

    await sharedPrefs.setInt(countKey, currentCount);
    _print("💾 PSP: Updated stored count to: $currentCount");

    return firebasePosts;
  }

  Future<int> _getPostCountByCreatorId(String creatorId) async {
    try {
      _print("🔢 PSP: Getting post count for creator: $creatorId");
      final query = _firestore.collection(_collectionName).where('creatorId', isEqualTo: creatorId);

      final countSnapshot = await query.count().get();
      final count = countSnapshot.count ?? 0;
      _print("✅ PSP: Post count retrieved: $count");
      return count;
    } catch (e) {
      _print("❌ PSP: Error getting post count: $e");
      return -1; // Return -1 to indicate error
    }
  }

  Future<List<MemoModelPost>> _fetchPostsFromFirebase(String creatorId, int limit) async {
    _print("🔥 PSP: Fetching posts from Firebase for creator: $creatorId");

    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('creatorId', isEqualTo: creatorId)
          .orderBy(orderByField, descending: descendingOrder)
          .limit(limit)
          .get();

      final posts = querySnapshot.docs.map((doc) {
        return MemoModelPost.fromSnapshot(doc);
      }).toList();

      _print("✅ PSP: Successfully fetched ${posts.length} posts from Firebase");
      return posts;
    } catch (e) {
      _print("❌ PSP: Error fetching posts from Firebase: $e");
      return [];
    }
  }

  void _print(String s) {
    if (kDebugMode) print(s);
  }
}
