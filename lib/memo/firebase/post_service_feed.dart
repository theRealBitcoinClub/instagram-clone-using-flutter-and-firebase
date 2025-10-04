import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';

import '../../config.dart';

class PostServiceFeed {
  static const String orderByField = "createdDateTime";
  static const bool descendingOrder = true;
  final FirebaseFirestore _firestore;
  final String _collectionName;
  final bool _isDebugMode = kDebugMode; // Add this flag

  PostServiceFeed({FirebaseFirestore? firestore, String collectionName = FirestoreCollections.posts})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _collectionName = collectionName;

  //TODO LIMIT THE TOTAL POSTS THAT CAN BE RETRIEVED IN FREE MODE TO 100
  // --- PAGINATION METHOD (Primary method for the feed) ---
  // Future<List<MemoModelPost>> getPostsPaginated({required int limit, String? postId, List<String> mutedCreators = const []}) async {
  //   if (_isDebugMode) {
  //     print('PSF: 🔄📮 PostServiceFeed.getPostsPaginated() called');
  //     print('PSF:    📊 Parameters:');
  //     print('PSF:    ├── limit: $limit');
  //     print('PSF:    ├── postId: $postId');
  //     print('PSF:    ├── mutedCreators: ${mutedCreators.length} creators');
  //     if (mutedCreators.isNotEmpty) {
  //       print('PSF:    └── muted IDs: ${mutedCreators.take(5).toList()}${mutedCreators.length > 5 ? '...' : ''}');
  //     }
  //   }
  //
  //   Query query = _firestore.collection(_collectionName).orderBy(orderByField, descending: descendingOrder);
  //
  //   if (_isDebugMode) {
  //     print('PSF:    📋 Base query: $_collectionName ordered by $orderByField (descending: $descendingOrder)');
  //   }
  //
  //   var startAfterDoc = postId == null ? null : await _getDocumentSnapshot(postId);
  //
  //   if (startAfterDoc != null) {
  //     if (_isDebugMode) {
  //       print('PSF:    🎯 Using pagination cursor for post: $postId');
  //       print('PSF:    📍 Cursor orderByField Value: ${startAfterDoc.data()}');
  //     }
  //     query = query.startAfterDocument(startAfterDoc);
  //   } else {
  //     if (_isDebugMode) print('PSF:    🏁 No cursor - starting from beginning');
  //   }
  //
  //   var take = mutedCreators.take(10).toList();
  //   if (take.isNotEmpty) {
  //     if (_isDebugMode) {
  //       print('PSF:    🔇 Applying muted creators filter: ${take.length} creators');
  //       print('PSF:    ├── Filtered IDs: $take');
  //     }
  //     query = query.where("creatorId", whereNotIn: take);
  //   } else {
  //     if (_isDebugMode) print('PSF:    🔊 No muted creators to filter');
  //   }
  //
  //   if (_isDebugMode) {
  //     print('PSF:    🎯 Final query parameters:');
  //     print('PSF:    ├── limit: $limit');
  //     print('PSF:    ├── hasCursor: ${startAfterDoc != null}');
  //     print('PSF:    ├── mutedFilter: ${take.isNotEmpty}');
  //     print('PSF:    └── executing Firestore query...');
  //   }
  //
  //   final stopwatch = Stopwatch()..start();
  //   final querySnapshot = await query.limit(limit).get();
  //   stopwatch.stop();
  //
  //   if (_isDebugMode) {
  //     print('PSF:    ✅ Firestore query completed in ${stopwatch.elapsedMilliseconds}ms');
  //     print('PSF:    📦 Query result: ${querySnapshot.docs.length} documents');
  //     print('PSF:    🏷️ Document IDs: ${querySnapshot.docs.map((doc) => doc.id).toList()}');
  //   }
  //
  //   final posts = querySnapshot.docs.map((doc) {
  //     return MemoModelPost.fromSnapshot(doc);
  //   }).toList();
  //
  //   if (_isDebugMode) {
  //     print('PSF:    🎉 Successfully parsed ${posts.length} posts');
  //     print('PSF:    📊 Post details:');
  //     for (var i = 0; i < posts.length; i++) {
  //       final post = posts[i];
  //       print('PSF:    ├── [$i] ${post.id} by ${post.creatorId}');
  //       print('PSF:    │   ├── imageUrl: ${post.imageUrl?.isNotEmpty ?? false}');
  //       print('PSF:    │   ├── imgurUrl: ${post.imgurUrl?.isNotEmpty ?? false}');
  //       print('PSF:    │   ├── ipfsCid: ${post.ipfsCid?.isNotEmpty ?? false}');
  //       print('PSF:    │   └── created: ${post.createdDateTime}');
  //     }
  //     print('PSF:    └── 📮 PostServiceFeed.getPostsPaginated() completed');
  //   }
  //
  //   return posts;
  // }
  Future<List<MemoModelPost>> getPostsPaginated({required int limit, String? postId, List<String> mutedCreators = const []}) async {
    if (_isDebugMode) {
      print('PSF: 🔄📮 PostServiceFeed.getPostsPaginated() called');
      print('PSF:    📊 Parameters:');
      print('PSF:    ├── limit: $limit');
      print('PSF:    ├── postId: $postId');
      print('PSF:    ├── mutedCreators: ${mutedCreators.length} creators');
      if (mutedCreators.isNotEmpty) {
        print('PSF:    └── muted IDs: ${mutedCreators.take(5).toList()}${mutedCreators.length > 5 ? '...' : ''}');
      }
    }

    Query query = _firestore.collection(_collectionName).orderBy(orderByField, descending: descendingOrder);

    if (_isDebugMode) {
      print('PSF:    📋 Base query: $_collectionName ordered by $orderByField (descending: $descendingOrder)');
    }

    // var startAfterDoc = postId == null ? null : await _getDocumentSnapshot(postId);
    //
    // if (startAfterDoc != null) {
    //   if (_isDebugMode) {
    //     print('PSF:    🎯 Using pagination cursor for post: $postId');
    //     print('PSF:    📍 Cursor orderByField Value: ${startAfterDoc.data()}');
    //   }
    //   query = query.startAfterDocument(startAfterDoc);
    // } else {
    //   if (_isDebugMode) print('PSF:    🏁 No cursor - starting from beginning');
    // }

    // FIX: Validate whereNotIn parameters
    var take = mutedCreators.take(10).toList();
    if (take.isNotEmpty) {
      // Additional validation for whereNotIn
      if (take.length > 10) {
        if (_isDebugMode) {
          print('PSF:    ⚠️⚠️⚠️ WARNING: whereNotIn clause has ${take.length} items, but Firestore limit is 10');
          print('PSF:    ⚠️ Truncating to first 10 items');
        }
        take = take.take(10).toList();
      }

      // Check for empty strings or invalid values
      final validMutedCreators = take.where((id) => id.isNotEmpty).toList();
      if (validMutedCreators.length != take.length) {
        if (_isDebugMode) {
          print('PSF:    ⚠️ Filtered out ${take.length - validMutedCreators.length} empty creator IDs');
        }
        take = validMutedCreators;
      }

      if (take.isNotEmpty) {
        if (_isDebugMode) {
          print('PSF:    🔇 Applying muted creators filter: ${take.length} creators');
          print('PSF:    ├── Filtered IDs: $take');
          print('PSF:    ├── All IDs are non-empty: ${take.every((id) => id.isNotEmpty)}');
        }
        query = query.where("creatorId", whereNotIn: take);
      } else {
        if (_isDebugMode) print('PSF:    🔊 No valid muted creators to filter after validation');
      }
    } else {
      if (_isDebugMode) print('PSF:    🔊 No muted creators to filter');
    }

    if (_isDebugMode) {
      print('PSF:    🎯 Final query parameters:');
      print('PSF:    ├── limit: $limit');
      // print('PSF:    ├── hasCursor: ${startAfterDoc != null}');
      print('PSF:    ├── mutedFilter: ${take.isNotEmpty}');
      print('PSF:    ├── mutedFilterCount: ${take.length}');
      print('PSF:    └── executing Firestore query...');
    }

    try {
      // final stopwatch = Stopwatch()..start();
      final querySnapshot = await query.limit(limit).get();
      // stopwatch.stop();

      if (_isDebugMode) {
        // print('PSF:    ✅ Firestore query completed in ${stopwatch.elapsedMilliseconds}ms');
        print('PSF:    📦 Query result: ${querySnapshot.docs.length} documents');
        print('PSF:    🏷️ Document IDs: ${querySnapshot.docs.map((doc) => doc.id).toList()}');
      }

      final posts = querySnapshot.docs.map((doc) {
        return MemoModelPost.fromSnapshot(doc);
      }).toList();

      if (_isDebugMode) {
        print('PSF:    🎉 Successfully parsed ${posts.length} posts');
        print('PSF:    📊 Post details:');
        for (var i = 0; i < posts.length; i++) {
          final post = posts[i];
          print('PSF:    ├── [$i] ${post.id} by ${post.creatorId}');
          print('PSF:    │   ├── imageUrl: ${post.imageUrl?.isNotEmpty ?? false}');
          print('PSF:    │   ├── imgurUrl: ${post.imgurUrl?.isNotEmpty ?? false}');
          print('PSF:    │   ├── ipfsCid: ${post.ipfsCid?.isNotEmpty ?? false}');
          print('PSF:    │   └── created: ${post.createdDateTime}');
        }
        print('PSF:    └── 📮 PostServiceFeed.getPostsPaginated() completed');
      }

      return posts;
    } catch (e) {
      if (_isDebugMode) {
        print('PSF:    ❌❌❌ FIRESTORE QUERY ERROR: $e');
        print('PSF:    🔍 Query details that failed:');
        print('PSF:    ├── collection: $_collectionName');
        print('PSF:    ├── orderBy: $orderByField');
        print('PSF:    ├── descending: $descendingOrder');
        print('PSF:    ├── limit: $limit');
        // print('PSF:    ├── hasCursor: ${startAfterDoc != null}');
        print('PSF:    ├── mutedFilterCount: ${take.length}');
        print('PSF:    └── mutedIDs: $take');
      }
      rethrow;
    }
  }

  Future<int> getTotalPostCount() async {
    if (_isDebugMode) {
      print('PSF: 🔢📊 PostServiceFeed.getTotalPostCount() called');
    }

    try {
      // final stopwatch = Stopwatch()..start();
      final querySnapshot = await FirebaseFirestore.instance.collection(_collectionName).count().get();
      // stopwatch.stop();

      if (_isDebugMode) {
        // print('PSF:    ✅ Total count query completed in ${stopwatch.elapsedMilliseconds}ms');
        print('PSF:    📈 Total posts in collection: ${querySnapshot.count}');
        print('PSF:    🔚 PostServiceFeed.getTotalPostCount() completed');
      }

      return querySnapshot.count!;
    } catch (e) {
      if (_isDebugMode) {
        print('PSF:    ❌📊 Error getting post count: $e');
        print('PSF:    🔚 PostServiceFeed.getTotalPostCount() failed');
      }
      return -1;
    }
  }

  Future<DocumentSnapshot?> _getDocumentSnapshot(String postId) async {
    if (_isDebugMode) {
      print('PSF:    🔍📄 _getDocumentSnapshot() called for post: $postId');
    }

    try {
      final stopwatch = Stopwatch()..start();
      final doc = await FirebaseFirestore.instance.collection(_collectionName).doc(postId).get();
      stopwatch.stop();

      if (_isDebugMode) {
        print('PSF:    ✅ Document fetch completed in ${stopwatch.elapsedMilliseconds}ms');
        print('PSF:    📄 Document exists: ${doc.exists}');
        if (doc.exists) {
          print('PSF:    📍 Document data keys: ${doc.data()?.keys.join(', ')}');
        }
        print('PSF:    🔚 _getDocumentSnapshot() completed');
      }

      return doc.exists ? doc : null;
    } catch (e) {
      if (_isDebugMode) {
        print('PSF:    ❌📄 Error getting document snapshot: $e');
        print('PSF:    🔚 _getDocumentSnapshot() failed');
      }
      return null;
    }
  }
}
