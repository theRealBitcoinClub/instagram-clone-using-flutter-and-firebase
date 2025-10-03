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
  Future<List<MemoModelPost>> getPostsByCreatorIdList(String creatorId, Ref ref) async {
    if (_debugMode) print("🔄 PSP: getPostsByCreatorIdList called for creator: $creatorId");

    try {
      final postCache = ref.read(profilePostCacheProvider);
      final sharedPrefs = await SharedPreferences.getInstance();
      final countKey = 'post_count_$creatorId';

      // 1. Get current count from Firebase
      final currentCount = await _getPostCountByCreatorId(creatorId);
      if (_debugMode) print("📊 PSP: Current post count for $creatorId: $currentCount");

      // 2. Get stored count from SharedPreferences
      final storedCount = sharedPrefs.getInt(countKey) ?? 0;
      if (_debugMode) print("💾 PSP: Stored post count for $creatorId: $storedCount");

      // 3. Check if we need to fetch from Firebase
      final shouldFetchFromFirebase = storedCount == 0 || currentCount != storedCount;

      if (shouldFetchFromFirebase) {
        if (_debugMode) print("🔄 PSP: Count changed or first load, fetching from Firebase");

        // Fetch from Firebase with limit
        final firebasePosts = await _fetchPostsFromFirebase(creatorId);
        if (_debugMode) print("✅ PSP: Fetched ${firebasePosts.length} posts from Firebase");

        // Save to cache
        await postCache.saveProfilePosts(creatorId, firebasePosts);

        // Update stored count
        await sharedPrefs.setInt(countKey, currentCount);
        if (_debugMode) print("💾 PSP: Updated stored count to: $currentCount");

        return firebasePosts;
      } else {
        if (_debugMode) print("💾 PSP: Count unchanged, loading from cache");
        // Load from cache
        final cachedPosts = await postCache.getCachedProfilePosts(creatorId);
        if (_debugMode) print("📚 PSP: Loaded ${cachedPosts.length} posts from cache");
        return cachedPosts;
      }
    } catch (e) {
      if (_debugMode) print("❌ PSP: Error in getPostsByCreatorIdList: $e");

      // Fallback to cache on error
      final postCache = ref.read(profilePostCacheProvider);
      final cachedPosts = await postCache.getCachedProfilePosts(creatorId);
      if (_debugMode) print("🔄 PSP: Fallback to cache, loaded ${cachedPosts.length} posts");
      return cachedPosts;
    }
  }

  Future<int> _getPostCountByCreatorId(String creatorId) async {
    try {
      if (_debugMode) print("🔢 PSP: Getting post count for creator: $creatorId");
      final query = _firestore.collection(_collectionName).where('creatorId', isEqualTo: creatorId);

      final countSnapshot = await query.count().get();
      final count = countSnapshot.count ?? 0;
      if (_debugMode) print("✅ PSP: Post count retrieved: $count");
      return count;
    } catch (e) {
      if (_debugMode) print("❌ PSP: Error getting post count: $e");
      return -1; // Return -1 to indicate error
    }
  }

  Future<List<MemoModelPost>> _fetchPostsFromFirebase(String creatorId) async {
    if (_debugMode) print("🔥 PSP: Fetching posts from Firebase for creator: $creatorId");

    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('creatorId', isEqualTo: creatorId)
          .orderBy(orderByField, descending: descendingOrder)
          .limit(profileCacheAndFirebaseLimit)
          .get();

      final posts = querySnapshot.docs.map((doc) {
        return MemoModelPost.fromSnapshot(doc);
      }).toList();

      if (_debugMode) print("✅ PSP: Successfully fetched ${posts.length} posts from Firebase");
      return posts;
    } catch (e) {
      if (_debugMode) print("❌ PSP: Error fetching posts from Firebase: $e");
      return [];
    }
  }

  //
  // Stream<List<MemoModelPost>> getPostsByCreatorIdStream(String creatorId, ref) {
  //   final controller = StreamController<List<MemoModelPost>>();
  //   final postCache = ref.read(profilePostCacheProvider);
  //
  //   () async {
  //     try {
  //       //TODO THIS IS DUPLICATE AS IN PROFILE DATA PROVIDER THE CACHED POSTS ARE ALREADY LOADED BEFORE THIS METHOD
  //       // 1. Get cached posts first
  //       final cachedPosts = await _getCachedPostsFirst(creatorId, ref);
  //       if (cachedPosts.isNotEmpty) {
  //         print("📚 Using cached profile posts for creator: $creatorId");
  //         controller.add(cachedPosts); // Emit cached data immediately
  //       }
  //
  //       // 2. Subscribe to Firebase stream for live updates
  //       final firebaseSubscription = _getFirebasePostsStream(creatorId, ref).listen(
  //         (firebasePosts) async {
  //           // Emit Firebase data
  //           controller.add(firebasePosts);
  //
  //           // Update cache in background (don't await to avoid blocking)
  //           if (firebasePosts.isNotEmpty) {
  //             postCache.cacheProfilePosts(creatorId, firebasePosts);
  //           }
  //         },
  //         onError: (error) {
  //           print("❌ Error in Firebase stream for creator $creatorId: $error");
  //           controller.addError(error);
  //         },
  //         onDone: () {
  //           if (!controller.isClosed) {
  //             controller.close();
  //           }
  //         },
  //       );
  //
  //       // 3. Cancel Firebase subscription when controller closes
  //       controller.onCancel = () {
  //         firebaseSubscription.cancel();
  //       };
  //     } catch (e) {
  //       print("❌ Error in getPostsByCreatorIdStream: $e");
  //       if (!controller.isClosed) {
  //         controller.addError(e);
  //         controller.close();
  //       }
  //     }
  //   }();
  //
  //   return controller.stream;
  // }
  //
  // Future<List<MemoModelPost>> _getCachedPostsFirst(String creatorId, ref) async {
  //   try {
  //     final postCache = ref.read(profilePostCacheProvider);
  //     return await postCache.getCachedProfilePosts(creatorId);
  //   } catch (e) {
  //     print("❌ Error reading cached profile posts: $e");
  //     return [];
  //   }
  // }
  //
  // Stream<List<MemoModelPost>> _getFirebasePostsStream(String creatorId, ref) {
  //   return _firestore
  //       .collection(_collectionName)
  //       .where('creatorId', isEqualTo: creatorId)
  //       .orderBy(orderByField, descending: descendingOrder)
  //       .limit(profileCacheAndFirebaseLimit) // ← ADD THIS LIMIT to prevent huge downloads
  //       .snapshots()
  //       .map((snapshot) => snapshot.docs.map((doc) => MemoModelPost.fromSnapshot(doc)).toList())
  //       .handleError((error) {
  //         print("Error fetching posts for creator $creatorId: $error.");
  //         return <MemoModelPost>[];
  //       });
  // }
}
