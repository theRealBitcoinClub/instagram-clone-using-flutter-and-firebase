// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:mahakka/memo/model/memo_model_post.dart';
//
// // Assuming PostFilterType is defined elsewhere and accessible if needed here
// // import 'package:mahakka/screens/feed_screen.dart'; // For PostFilterType
//
// class PostService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   static const String _postsCollection = 'posts';
//   static const String orderByField = "createdDateTime"; // Consistent field name
//   static const bool descendingOrder = true;
//
//   // --- PAGINATION METHOD (Primary method for the feed) ---
//   Future<List<MemoModelPost>> getPostsPaginated({
//     required int limit,
//     DocumentSnapshot? startAfterDoc,
//     // activeFilters are not used for Firestore query here, filtering is client-side
//   }) async {
//     Query query = _firestore.collection(_postsCollection).orderBy(orderByField, descending: descendingOrder);
//
//     if (startAfterDoc != null) {
//       query = query.startAfterDocument(startAfterDoc);
//     }
//
//     final querySnapshot = await query.limit(limit).get();
//
//     return querySnapshot.docs.map((doc) {
//       // Use the new factory constructor that includes the snapshot
//       return MemoModelPost.fromSnapshot(doc);
//     }).toList();
//   }
//
//   // --- Your existing methods (ensure they use .fromSnapshot or .fromJson appropriately) ---
//
//   Future<MemoModelPost?> getPostOnce(String postId) async {
//     try {
//       final DocumentSnapshot snapshot = await _firestore.collection(_postsCollection).doc(postId).get();
//       if (snapshot.exists) {
//         // Use fromSnapshot here as well if you might need the docSnapshot later
//         return MemoModelPost.fromSnapshot(snapshot);
//       } else {
//         print("Post with ID $postId not found.");
//         return null;
//       }
//     } catch (e) {
//       print("Error fetching post $postId once: $e");
//       return null;
//     }
//   }
//
//   Future<void> savePost(MemoModelPost post) async {
//     try {
//       // .id should be set on the post object before calling save
//       await _firestore.collection(_postsCollection).doc(post.id).set(post.toJson(), SetOptions(merge: true));
//       print("Post ${post.id} saved successfully.");
//     } catch (e) {
//       print("Error saving post ${post.id}: $e");
//       rethrow;
//     }
//   }
//
//   Future<void> deletePost(String postId) async {
//     try {
//       await _firestore.collection(_postsCollection).doc(postId).delete();
//       print("Post ${postId} deleted successfully.");
//     } catch (e) {
//       print("Error deleting post ${postId}: $e");
//       rethrow;
//     }
//   }
//
//   Stream<MemoModelPost?> getPostStream(String postId) {
//     return _firestore
//         .collection(_postsCollection)
//         .doc(postId)
//         .snapshots()
//         .map((snapshot) {
//           if (snapshot.exists) {
//             return MemoModelPost.fromSnapshot(snapshot);
//           } else {
//             return null;
//           }
//         })
//         .handleError((error) {
//           print("Error in post stream for $postId: $error");
//           return null;
//         });
//   }
//
//   Stream<List<MemoModelPost>> getPostsByCreatorIdStream(String creatorId) {
//     return _firestore
//         .collection(_postsCollection)
//         .where('creatorId', isEqualTo: creatorId)
//         .orderBy(orderByField, descending: descendingOrder)
//         .snapshots()
//         .map((snapshot) => snapshot.docs.map((doc) => MemoModelPost.fromSnapshot(doc)).toList())
//         .handleError((error) {
//           print("Error fetching posts for creator $creatorId: $error.");
//           return <MemoModelPost>[];
//         });
//   }
//
//   // Your original getAllPostsStream - uses fromSnapshot
//   Stream<List<MemoModelPost>> getAllPostsStream() {
//     return _firestore
//         .collection(_postsCollection)
//         .orderBy(orderByField, descending: descendingOrder)
//         .snapshots()
//         .map((snapshot) => snapshot.docs.map((doc) => MemoModelPost.fromSnapshot(doc)).toList())
//         .handleError((error) {
//           print("Error in all posts stream: $error");
//           return <MemoModelPost>[];
//         });
//   }
//
//   // Removed the other stream methods for brevity, assuming they'd follow the same pattern
//   // of using MemoModelPost.fromSnapshot(doc) if they map from DocumentSnapshots.
// }
