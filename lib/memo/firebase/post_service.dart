import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';

import '../../screens/feed_screen.dart';

// Assuming PostFilterType is defined elsewhere and accessible if needed here
// import 'package:mahakka/screens/feed_screen.dart'; // For PostFilterType

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _postsCollection = 'posts';
  static const String orderByField = "createdDateTime"; // Consistent field name
  static const bool descendingOrder = true;

  // // --- PAGINATION METHOD (Primary method for the feed) ---
  // Future<List<MemoModelPost>> getPostsPaginated({
  //   required int limit,
  //   DocumentSnapshot? startAfterDoc,
  //   // activeFilters are not used for Firestore query here, filtering is client-side
  // }) async {
  //   Query query = _firestore.collection(_postsCollection).orderBy(orderByField, descending: descendingOrder);
  //
  //   if (startAfterDoc != null) {
  //     query = query.startAfterDocument(startAfterDoc);
  //   }
  //
  //   final querySnapshot = await query.limit(limit).get();
  //
  //   return querySnapshot.docs.map((doc) {
  //     // Use the new factory constructor that includes the snapshot
  //     return MemoModelPost.fromSnapshot(doc);
  //   }).toList();
  // }

  Future<List<MemoModelPost>> getPostsPaginated({
    required int limit,
    DocumentSnapshot? startAfterDoc,
    PostFilterType? activeFilter, // Single active filter or null for all posts
  }) async {
    Query query = _firestore.collection(_postsCollection);

    // Apply filter if one is active
    if (activeFilter != null) {
      switch (activeFilter) {
        case PostFilterType.images:
          // Assumes you have an 'imgurUrl' field and want non-null/non-empty ones.
          // Firestore doesn't directly support "is not empty".
          // A common practice is to query for 'imgurUrl > ""' if empty strings are possible
          // or rely on the fact that if the field exists, it's likely not empty.
          // For simplicity, checking for non-null (which '!=' null does).
          // You might need a dedicated boolean field like 'hasImage' for best performance.
          query = query.where('imgurUrl', isNotEqualTo: null);
          // Add .where('imgurUrl', isNotEqualTo: '') if you also store empty strings
          break;
        case PostFilterType.videos:
          query = query.where('youtubeId', isNotEqualTo: null);
          break;
        case PostFilterType.hashtags:
          // Query for posts where 'tagIds' array is not empty.
          // Firestore doesn't have a direct "is not empty" for arrays.
          // A common workaround is to have a boolean 'hasTags' field.
          // Or, if you always have at least one tag if the array exists,
          // you might fetch and filter client-side for "is empty".
          // For true server-side, a 'tagCount > 0' or 'hasTags == true' field is better.
          // For this example, we'll assume a 'hasTags': true field. If not, this filter won't work server-side.
          query = query.where('hasTags', isEqualTo: true); // Requires 'hasTags' boolean field
          break;
        case PostFilterType.topics:
          query = query.where('topicId', isNotEqualTo: null).where('topicId', isNotEqualTo: '');
          break;
      }
    }

    // Always order, this must be the last field in equality checks or first in range/inequality
    // If you have inequality filters (like isNotEqualTo null), orderBy must be on a different field
    // OR if ordering by the same field, it must be the first orderBy.
    // If activeFilter applies an inequality, and you order by createdDateTime, ensure createdDateTime is indexed with that field.
    query = query.orderBy(orderByField, descending: descendingOrder);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    final querySnapshot = await query.limit(limit).get();
    if (querySnapshot.docs.isEmpty && activeFilter != null) {
      print("Query for filter $activeFilter with current pagination returned 0 docs. Check data and indexes.");
    }

    return querySnapshot.docs.map((doc) => MemoModelPost.fromSnapshot(doc)).toList();
  }

  // --- Your existing methods (ensure they use .fromSnapshot or .fromJson appropriately) ---

  Future<MemoModelPost?> getPostOnce(String postId) async {
    try {
      final DocumentSnapshot snapshot = await _firestore.collection(_postsCollection).doc(postId).get();
      if (snapshot.exists) {
        // Use fromSnapshot here as well if you might need the docSnapshot later
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

  Future<void> savePost(MemoModelPost post) async {
    try {
      // .id should be set on the post object before calling save
      await _firestore.collection(_postsCollection).doc(post.id).set(post.toJson(), SetOptions(merge: true));
      print("Post ${post.id} saved successfully.");
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

  Stream<MemoModelPost?> getPostStream(String postId) {
    return _firestore
        .collection(_postsCollection)
        .doc(postId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return MemoModelPost.fromSnapshot(snapshot);
          } else {
            return null;
          }
        })
        .handleError((error) {
          print("Error in post stream for $postId: $error");
          return null;
        });
  }

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

  // Your original getAllPostsStream - uses fromSnapshot
  Stream<List<MemoModelPost>> getAllPostsStream() {
    return _firestore
        .collection(_postsCollection)
        .orderBy(orderByField, descending: descendingOrder)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MemoModelPost.fromSnapshot(doc)).toList())
        .handleError((error) {
          print("Error in all posts stream: $error");
          return <MemoModelPost>[];
        });
  }

  // Removed the other stream methods for brevity, assuming they'd follow the same pattern
  // of using MemoModelPost.fromSnapshot(doc) if they map from DocumentSnapshots.
}

// import 'package:cloud_firestore/cloud_firestore.dart';
// // Adjust the import path to where your MemoModelPost is located
// import 'package:mahakka/memo/model/memo_model_post.dart';
// // Potentially import other services if you need to perform cascading operations
// // or update related data, e.g., TagService.
// // import 'tag_service.dart';
//
// class PostService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   // Choose a distinct collection name for posts
//   static const String _postsCollection = 'posts'; // Or 'posts_v1', etc.]
//   static const String orderBy = "createdDateTime";
//   static const bool descending = true;
//
//   /// Fetches a single post from Firestore once (not a stream).
//   /// Returns null if the post doesn't exist or if there's an error.
//   Future<MemoModelPost?> getPostOnce(String postId) async {
//     try {
//       final DocumentReference docRef = _firestore.collection(_postsCollection).doc(postId);
//       final DocumentSnapshot snapshot = await docRef.get();
//
//       if (snapshot.exists && snapshot.data() != null) {
//         return MemoModelPost.fromJson(snapshot.data()! as Map<String, dynamic>);
//       } else {
//         print("Post with ID $postId not found when fetching once.");
//         return null;
//       }
//     } catch (e) {
//       print("Error fetching post $postId once: $e");
//       return null;
//     }
//   }
//
//   // Optional: If you often need to interact with other services
//   // final TagService _tagService = TagService(); // Example
//
//   /// Saves a post to Firestore.
//   /// If a post with the same ID already exists, it will be updated (merged).
//   /// If it doesn't exist, it will be created.
//   Future<void> savePost(MemoModelPost post) async {
//     try {
//       final DocumentReference docRef = _firestore.collection(_postsCollection).doc(post.id);
//       final Map<String, dynamic> postJson = post.toJson();
//       await docRef.set(postJson, SetOptions(merge: true));
//       print("Post ${post.id} saved successfully to Firestore in collection '$_postsCollection'.");
//     } catch (e) {
//       print("Error saving post ${post.id} to Firestore: $e");
//       rethrow;
//     }
//   }
//
//   /// Deletes a post from Firestore based on its ID.
//   /// Consider if you need to also decrement tag counts or perform other cleanup.
//   Future<void> deletePost(String postId) async {
//     try {
//       await _firestore.collection(_postsCollection).doc(postId).delete();
//       print("Post ${postId} deleted successfully from Firestore.");
//     } catch (e) {
//       print("Error deleting post ${postId} from Firestore: $e");
//       rethrow;
//     }
//   }
//
//   /// Retrieves a real-time stream of a single post from Firestore.
//   /// Emits null if the post doesn't exist or if there's an error.
//   Stream<MemoModelPost?> getPostStream(String postId) {
//     try {
//       final DocumentReference docRef = _firestore.collection(_postsCollection).doc(postId);
//
//       return docRef
//           .snapshots()
//           .map((snapshot) {
//             if (snapshot.exists && snapshot.data() != null) {
//               return MemoModelPost.fromJson(snapshot.data()! as Map<String, dynamic>);
//             } else {
//               print("Post with ID $postId not found in Firestore stream.");
//               return null;
//             }
//           })
//           .handleError((error) {
//             print("Error in post stream for $postId: $error");
//             return null;
//           });
//     } catch (e) {
//       print("Error getting post stream for $postId: $e");
//       return Stream.value(null);
//     }
//   }
//
//   // In your PostService class:
//   Stream<List<MemoModelPost>> getPostsByCreatorIdStream(String creatorId, {String order = orderBy, bool desc = descending}) {
//     Query query = _firestore.collection(_postsCollection).where('creatorId', isEqualTo: creatorId); // Filter by creatorId
//
//     query = query.orderBy(order, descending: desc);
//
//     return query
//         .snapshots()
//         .map((snapshot) {
//           return snapshot.docs.map((doc) {
//             final data = doc.data()! as Map<String, dynamic>;
//             // Crucially, set the document ID on your model
//             return MemoModelPost.fromJson(data)..id = doc.id;
//           }).toList();
//         })
//         .handleError((error) {
//           print("Error fetching posts for creator $creatorId: $error. Check Firestore indexes (creatorId, $order).");
//           return <MemoModelPost>[];
//         });
//   }
//
//   // Fetches posts with simple pagination.
//   // Filtering for specific types (image, video, etc.) will be applied client-side
//   // from the results of this paginated query.
//   Future<List<MemoModelPost>> getPostsPaginated({
//     required int limit,
//     DocumentSnapshot? startAfterDoc,
//     // activeFilters are not directly used for Firestore query construction here
//     // due to limitations with "OR" conditions across different fields.
//     // The query will be general, and filtering happens client-side.
//   }) async {
//     Query query = _firestore.collection(_postsCollection).orderBy('createdDateTime', descending: true); // Primary order for the feed
//
//     if (startAfterDoc != null) {
//       query = query.startAfterDocument(startAfterDoc);
//     }
//
//     final querySnapshot = await query.limit(limit).get();
//
//     return querySnapshot.docs.map((doc) {
//       // Ensure MemoModelPost.fromSnap stores the snapshot
//       return MemoModelPost.fromSnap(doc);
//     }).toList();
//   }
//
//   // Helper to get a specific document snapshot if needed (e.g., for verifying hasMorePosts)
//   // This might not be strictly necessary if newPosts.length < limit is used.
//   Future<DocumentSnapshot?> getDocumentSnapshot(String postId) async {
//     try {
//       return await _firestore.collection(_postsCollection).doc(postId).get();
//     } catch (e) {
//       print("Error fetching document snapshot for $postId: $e");
//       return null;
//     }
//   }
//   //
//   // /// Fetches a paginated list of posts.
//   // Stream<QuerySnapshot> getPostsPaginated({
//   //   required int limit,
//   //   DocumentSnapshot? startAfterDoc,
//   //   String order = orderBy, // Ensure this field exists and is indexed
//   //   bool desc = descending,
//   // }) {
//   //   Query query = _firestore.collection(_postsCollection).orderBy(order, descending: desc).limit(limit);
//   //
//   //   if (startAfterDoc != null) {
//   //     query = query.startAfterDocument(startAfterDoc);
//   //   }
//   //
//   //   return query.snapshots().handleError((error) {
//   //     print("Error in paginated posts stream for field '$order': $error. Check Firestore indexes.");
//   //     // Depending on how you consume this, you might rethrow or return an empty snapshot stream
//   //     throw error; // Or handle more gracefully
//   //   });
//   // }
//
//   /// Retrieves a real-time stream of all posts from Firestore.
//   /// Consider adding querying capabilities (e.g., by creatorId, topicId, tags)
//   /// and pagination for larger datasets.
//   Stream<List<MemoModelPost>> getAllPostsStream({String order = orderBy, bool desc = descending}) {
//     try {
//       Query query = _firestore.collection(_postsCollection);
//
//       query = query.orderBy(order, descending: desc);
//
//       return _query(query).handleError((error) {
//         print("Error in all posts stream: $error");
//         return [];
//       });
//     } catch (e) {
//       print("Error getting all posts stream: $e");
//       return Stream.value([]);
//     }
//   }
//
//   // --- Example Query Methods (add more as needed) ---
//
//   /// Retrieves a stream of posts by a specific creator.
//   Stream<List<MemoModelPost>> getPostsByCreatorStream(String creatorId, {String order = orderBy, bool desc = descending}) {
//     try {
//       Query query = _firestore.collection(_postsCollection).where('creatorId', isEqualTo: creatorId);
//
//       query = query.orderBy(order, descending: desc);
//
//       return _query(query).handleError((error) {
//         print("Error in posts by creator stream for $creatorId: $error");
//         return [];
//       });
//     } catch (e) {
//       print("Error getting posts by creator stream for $creatorId: $e");
//       return Stream.value([]);
//     }
//   }
//
//   /// Retrieves a stream of posts for a specific topic.
//   Stream<List<MemoModelPost>> getPostsByTopicStream(String topicId, {String order = orderBy, bool desc = descending}) {
//     try {
//       Query query = _firestore.collection(_postsCollection).where('topicId', isEqualTo: topicId);
//
//       query = query.orderBy(order, descending: desc);
//
//       return _query(query).handleError((error) {
//         print("Error in posts by topic stream for $topicId: $error");
//         return [];
//       });
//     } catch (e) {
//       print("Error getting posts by topic stream for $topicId: $e");
//       return Stream.value([]);
//     }
//   }
//
//   /// Retrieves a stream of posts containing a specific tag.
//   /// Note: Firestore 'array-contains' is good for one tag. For multiple, you might need more complex queries or data duplication.
//   Stream<List<MemoModelPost>> getPostsByTagStream(String tagId, {String order = orderBy, bool desc = descending}) {
//     try {
//       Query query = _firestore.collection(_postsCollection).where('tagIds', arrayContains: tagId); // Assumes 'tagIds' is an array in Firestore
//
//       query = query.orderBy(order, descending: desc);
//
//       return _handleError(query, tagId);
//     } catch (e) {
//       return _handleException(tagId, e);
//     }
//   }
//
//   Stream<List<MemoModelPost>> _handleError(Query<Object?> query, String id) {
//     return _query(query).handleError((error) {
//       return _handleException(id, error);
//     });
//   }
//
//   Stream<List<MemoModelPost>> _handleException(String id, error) {
//     print("Error in posts by tag stream for $id: $error");
//     return Stream.value([]);
//   }
//
//   Stream<List<MemoModelPost>> _query(Query<Object?> query) {
//     return query.snapshots().map((querySnapshot) {
//       return querySnapshot.docs.map((doc) {
//         return MemoModelPost.fromJson(doc.data()! as Map<String, dynamic>);
//       }).toList();
//     });
//   }
// }
