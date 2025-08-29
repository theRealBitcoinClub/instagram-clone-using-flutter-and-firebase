import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mahakka/memo/firebase/memo_firebase_service.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';

import '../../screens/feed_screen.dart';

// Extends the abstract service, providing the model type.
class PostService extends MemoFirebaseService<MemoModelPost> {
  // 1. Override the abstract getter.
  @override
  String get collectionName => 'posts';

  // 2. Override the abstract fromSnapshot method.
  @override
  MemoModelPost fromSnapshot(DocumentSnapshot<Object?> snapshot) {
    return MemoModelPost.fromSnapshot(snapshot);
  }

  // All other generic methods (save, delete, getOnce, etc.) are now inherited.
  // You only need to keep methods that have specific, non-generic logic.

  // This method is specific to posts due to filtering, so we keep it here.
  Future<List<MemoModelPost>> getPostsPaginatedFiltered({
    required int limit,
    DocumentSnapshot? startAfterDoc,
    PostFilterType? activeFilter,
  }) async {
    Query query = firestore.collection(collectionName);

    // Apply specific filtering logic
    if (activeFilter != null) {
      switch (activeFilter) {
        case PostFilterType.images:
          query = query.where('imgurUrl', isNotEqualTo: "");
          break;
        case PostFilterType.topics:
          query = query.where('topicId', isNotEqualTo: "");
          break;
      }
    }

    query = query.orderBy("createdDateTime", descending: true);
    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    final querySnapshot = await query.limit(limit).get();
    return querySnapshot.docs.map((doc) => fromSnapshot(doc)).toList();
  }

  // This is a custom query, so it stays here.
  Stream<List<MemoModelPost>> getPostsByCreatorIdStream(String creatorId) {
    return firestore
        .collection(collectionName)
        .where('creatorId', isEqualTo: creatorId)
        .orderBy("createdDateTime", descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => fromSnapshot(doc)).toList())
        .handleError((error) {
          print("Error fetching posts for creator $creatorId: $error.");
          return <MemoModelPost>[];
        });
  }

  // The rest of your specific methods (like the old deletePost) are now handled by the superclass.
  // For example, you would now use `await postService.delete('some-post-id')`.
}
