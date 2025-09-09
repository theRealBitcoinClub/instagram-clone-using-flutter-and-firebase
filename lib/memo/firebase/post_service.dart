import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';

import '../../config.dart';

// Assuming PostFilterType is defined elsewhere and accessible if needed here
// import 'package:mahakka/screens/feed_screen.dart'; // For PostFilterType

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _postsCollection = '_posts';
  static const String orderByField = "createdDateTime"; // Consistent field name
  static const bool descendingOrder = true;

  // --- PAGINATION METHOD (Primary method for the feed) ---
  Future<List<MemoModelPost>> getPostsPaginated({
    required int limit,
    DocumentSnapshot? startAfterDoc,
    // activeFilters are not used for Firestore query here, filtering is client-side
  }) async {
    Query query = _firestore.collection(_postsCollection).orderBy(orderByField, descending: descendingOrder);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    final querySnapshot = await query.limit(limit).get();

    return querySnapshot.docs.map((doc) {
      // Use the new factory constructor that includes the snapshot
      return MemoModelPost.fromSnapshot(doc);
    }).toList();
  }
  //
  // Future<MemoModelPost?> getPostOnce(String postId) async {
  //   try {
  //     final DocumentSnapshot snapshot = await _firestore.collection(_postsCollection).doc(postId).get();
  //     if (snapshot.exists) {
  //       // Use fromSnapshot here as well if you might need the docSnapshot later
  //       return MemoModelPost.fromSnapshot(snapshot);
  //     } else {
  //       print("Post with ID $postId not found.");
  //       return null;
  //     }
  //   } catch (e) {
  //     print("Error fetching post $postId once: $e");
  //     return null;
  //   }
  // }

  Future<void> savePost(MemoModelPost post) async {
    try {
      final batch = _firestore.batch();
      final postRef = _firestore.collection(FirestoreCollections.posts).doc(post.id);
      final counterRef = _firestore.collection(FirestoreCollections.metadata).doc(FirestoreCollections.posts);

      // First, set the post
      batch.set(postRef, post.toJson());

      // Check if counter exists and get current count if needed
      final counterDoc = await counterRef.get();

      if (!counterDoc.exists) {
        // Counter doesn't exist yet - initialize it with count 1
        batch.set(counterRef, {
          'count': await getTotalPostCount(),
          'lastUpdated': FieldValue.serverTimestamp(),
          'initializedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Counter exists - increment it
        batch.update(counterRef, {'count': FieldValue.increment(1), 'lastUpdated': FieldValue.serverTimestamp()});
      }

      await batch.commit();
      print("${post.id} Post saved successfully. ${post.text}");
    } catch (e) {
      print("Error saving post ${post.id}: $e");
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection(_postsCollection).doc(postId).delete();
      print("Post ${postId} deleted successfully.");
    } catch (e) {
      print("Error deleting post ${postId}: $e");
      rethrow;
    }
  }

  Future<int> getTotalPostCount() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection(_postsCollection).count().get();
      return querySnapshot.count!;
    } catch (e) {
      print('Error getting post count: $e');
      return -1; // Return -1 to indicate error
    }
  }

  // Stream<MemoModelPost?> getPostStream(String postId) {
  //   return _firestore
  //       .collection(_postsCollection)
  //       .doc(postId)
  //       .snapshots()
  //       .map((snapshot) {
  //         if (snapshot.exists) {
  //           return MemoModelPost.fromSnapshot(snapshot);
  //         } else {
  //           return null;
  //         }
  //       })
  //       .handleError((error) {
  //         print("Error in post stream for $postId: $error");
  //         return null;
  //       });
  // }

  Stream<List<MemoModelPost>> getPostsByCreatorIdStream(String creatorId) {
    return _firestore
        .collection(_postsCollection)
        .where('creatorId', isEqualTo: creatorId)
        .orderBy(orderByField, descending: descendingOrder)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MemoModelPost.fromSnapshot(doc)).toList())
        .handleError((error) {
          print("Error fetching posts for creator $creatorId: $error.");
          return <MemoModelPost>[];
        });
  }

  //
  // // Your original getAllPostsStream - uses fromSnapshot
  // Stream<List<MemoModelPost>> getAllPostsStream() {
  //   return _firestore
  //       .collection(_postsCollection)
  //       .orderBy(orderByField, descending: descendingOrder)
  //       .snapshots()
  //       .map((snapshot) => snapshot.docs.map((doc) => MemoModelPost.fromSnapshot(doc)).toList())
  //       .handleError((error) {
  //         print("Error in all posts stream: $error");
  //         return <MemoModelPost>[];
  //       });
  // }
}
