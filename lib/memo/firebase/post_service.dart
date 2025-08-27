import 'package:cloud_firestore/cloud_firestore.dart';
// Adjust the import path to where your MemoModelPost is located
import 'package:mahakka/memo/model/memo_model_post.dart';
// Potentially import other services if you need to perform cascading operations
// or update related data, e.g., TagService.
// import 'tag_service.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Choose a distinct collection name for posts
  static const String _postsCollection = 'posts'; // Or 'posts_v1', etc.

  // In your PostService class:
  Stream<List<MemoModelPost>> getPostsByCreatorIdStream(String creatorId, {String? orderByField, bool descending = false}) {
    Query query = _firestore.collection(_postsCollection).where('creatorId', isEqualTo: creatorId); // Filter by creatorId

    if (orderByField != null) {
      query = query.orderBy(orderByField, descending: descending);
    }
    return query
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data()! as Map<String, dynamic>;
            // Crucially, set the document ID on your model
            return MemoModelPost.fromJson(data)..id = doc.id;
          }).toList();
        })
        .handleError((error) {
          print("Error fetching posts for creator $creatorId: $error. Check Firestore indexes (creatorId, $orderByField).");
          return <MemoModelPost>[];
        });
  }

  /// Fetches a paginated list of posts.
  ///
  /// [limit]: The number of documents to retrieve.
  /// [startAfterDoc]: Optional. The DocumentSnapshot to start retrieving documents after.
  /// [orderByField]: The field to order by (e.g., 'createdDateTime').
  /// [descending]: Whether the order should be descending.
  Stream<QuerySnapshot> getPostsPaginated({
    required int limit,
    DocumentSnapshot? startAfterDoc,
    String orderByField = 'createdDateTime', // Ensure this field exists and is indexed
    bool descending = true,
  }) {
    Query query = _firestore.collection(_postsCollection).orderBy(orderByField, descending: descending).limit(limit);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    return query.snapshots().handleError((error) {
      print("Error in paginated posts stream for field '$orderByField': $error. Check Firestore indexes.");
      // Depending on how you consume this, you might rethrow or return an empty snapshot stream
      throw error; // Or handle more gracefully
    });
  }

  // Optional: If you often need to interact with other services
  // final TagService _tagService = TagService(); // Example

  /// Saves a post to Firestore.
  /// If a post with the same ID already exists, it will be updated (merged).
  /// If it doesn't exist, it will be created.
  Future<void> savePost(MemoModelPost post) async {
    try {
      final DocumentReference docRef = _firestore.collection(_postsCollection).doc(post.id);
      final Map<String, dynamic> postJson = post.toJson();
      await docRef.set(postJson, SetOptions(merge: true));
      print("Post ${post.id} saved successfully to Firestore in collection '$_postsCollection'.");

      // OPTIONAL: If creating a NEW post, you might want to update tag counts
      // This logic can become complex and might be better suited for a Cloud Function
      // if it involves multiple writes or checks for new vs. existing post.
      // For simplicity, this is commented out. If you call this after creating a post:
      // if (post.tagIds.isNotEmpty) {
      //   await _tagService.incrementPostCountForTags(post.tagIds);
      // }
    } catch (e) {
      print("Error saving post ${post.id} to Firestore: $e");
      rethrow;
    }
  }

  /// Deletes a post from Firestore based on its ID.
  /// Consider if you need to also decrement tag counts or perform other cleanup.
  Future<void> deletePost(String postId) async {
    try {
      // Optional: Fetch the post first if you need its tagIds to decrement counts
      // MemoModelPost? postToDelete = await getPostOnce(postId);

      await _firestore.collection(_postsCollection).doc(postId).delete();
      print("Post ${postId} deleted successfully from Firestore.");

      // OPTIONAL: Decrement tag counts
      // if (postToDelete != null && postToDelete.tagIds.isNotEmpty) {
      //   // You'd need a _tagService.decrementPostCountForTags(postToDelete.tagIds) method
      //   // Be careful with atomicity and potential race conditions here if not using transactions/batch.
      // }
    } catch (e) {
      print("Error deleting post ${postId} from Firestore: $e");
      rethrow;
    }
  }

  /// Retrieves a real-time stream of a single post from Firestore.
  /// Emits null if the post doesn't exist or if there's an error.
  Stream<MemoModelPost?> getPostStream(String postId) {
    try {
      final DocumentReference docRef = _firestore.collection(_postsCollection).doc(postId);

      return docRef
          .snapshots()
          .map((snapshot) {
            if (snapshot.exists && snapshot.data() != null) {
              return MemoModelPost.fromJson(snapshot.data()! as Map<String, dynamic>);
            } else {
              print("Post with ID $postId not found in Firestore stream.");
              return null;
            }
          })
          .handleError((error) {
            print("Error in post stream for $postId: $error");
            return null;
          });
    } catch (e) {
      print("Error getting post stream for $postId: $e");
      return Stream.value(null);
    }
  }

  /// Retrieves a real-time stream of all posts from Firestore.
  /// Consider adding querying capabilities (e.g., by creatorId, topicId, tags)
  /// and pagination for larger datasets.
  Stream<List<MemoModelPost>> getAllPostsStream({String? orderByField, bool descending = false}) {
    try {
      Query query = _firestore.collection(_postsCollection);

      if (orderByField != null) {
        query = query.orderBy(orderByField, descending: descending);
      }
      // Example: Default ordering by creation time if available
      // else if (/* MemoModelPost has a createdDateTime field */) {
      //   query = query.orderBy('createdDateTime', descending: true);
      // }

      return query
          .snapshots()
          .map((querySnapshot) {
            return querySnapshot.docs.map((doc) {
              return MemoModelPost.fromJson(doc.data()! as Map<String, dynamic>);
            }).toList();
          })
          .handleError((error) {
            print("Error in all posts stream: $error");
            return [];
          });
    } catch (e) {
      print("Error getting all posts stream: $e");
      return Stream.value([]);
    }
  }

  /// Fetches a single post from Firestore once (not a stream).
  /// Returns null if the post doesn't exist or if there's an error.
  Future<MemoModelPost?> getPostOnce(String postId) async {
    try {
      final DocumentReference docRef = _firestore.collection(_postsCollection).doc(postId);
      final DocumentSnapshot snapshot = await docRef.get();

      if (snapshot.exists && snapshot.data() != null) {
        return MemoModelPost.fromJson(snapshot.data()! as Map<String, dynamic>);
      } else {
        print("Post with ID $postId not found when fetching once.");
        return null;
      }
    } catch (e) {
      print("Error fetching post $postId once: $e");
      return null;
    }
  }

  // --- Example Query Methods (add more as needed) ---

  /// Retrieves a stream of posts by a specific creator.
  Stream<List<MemoModelPost>> getPostsByCreatorStream(String creatorId, {String? orderByField, bool descending = true}) {
    try {
      Query query = _firestore.collection(_postsCollection).where('creatorId', isEqualTo: creatorId);

      if (orderByField != null) {
        query = query.orderBy(orderByField, descending: descending);
      } else {
        // Default order for creator's posts, e.g., by creation time
        query = query.orderBy('createdDateTime', descending: true); // Assuming 'createdDateTime' field
      }

      return query
          .snapshots()
          .map((querySnapshot) {
            return querySnapshot.docs.map((doc) {
              return MemoModelPost.fromJson(doc.data()! as Map<String, dynamic>);
            }).toList();
          })
          .handleError((error) {
            print("Error in posts by creator stream for $creatorId: $error");
            return [];
          });
    } catch (e) {
      print("Error getting posts by creator stream for $creatorId: $e");
      return Stream.value([]);
    }
  }

  /// Retrieves a stream of posts for a specific topic.
  Stream<List<MemoModelPost>> getPostsByTopicStream(String topicId, {String? orderByField, bool descending = true}) {
    try {
      Query query = _firestore.collection(_postsCollection).where('topicId', isEqualTo: topicId);

      if (orderByField != null) {
        query = query.orderBy(orderByField, descending: descending);
      } else {
        query = query.orderBy('createdDateTime', descending: true); // Assuming 'createdDateTime' field
      }

      return query
          .snapshots()
          .map((querySnapshot) {
            return querySnapshot.docs.map((doc) {
              return MemoModelPost.fromJson(doc.data()! as Map<String, dynamic>);
            }).toList();
          })
          .handleError((error) {
            print("Error in posts by topic stream for $topicId: $error");
            return [];
          });
    } catch (e) {
      print("Error getting posts by topic stream for $topicId: $e");
      return Stream.value([]);
    }
  }

  /// Retrieves a stream of posts containing a specific tag.
  /// Note: Firestore 'array-contains' is good for one tag. For multiple, you might need more complex queries or data duplication.
  Stream<List<MemoModelPost>> getPostsByTagStream(String tagId, {String? orderByField, bool descending = true}) {
    try {
      Query query = _firestore.collection(_postsCollection).where('tagIds', arrayContains: tagId); // Assumes 'tagIds' is an array in Firestore

      if (orderByField != null) {
        query = query.orderBy(orderByField, descending: descending);
      } else {
        query = query.orderBy('createdDateTime', descending: true); // Assuming 'createdDateTime' field
      }

      return query
          .snapshots()
          .map((querySnapshot) {
            return querySnapshot.docs.map((doc) {
              return MemoModelPost.fromJson(doc.data()! as Map<String, dynamic>);
            }).toList();
          })
          .handleError((error) {
            print("Error in posts by tag stream for $tagId: $error");
            return [];
          });
    } catch (e) {
      print("Error getting posts by tag stream for $tagId: $e");
      return Stream.value([]);
    }
  }
}
