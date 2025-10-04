import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';

import '../../config.dart';

class PostServiceFeed {
  static const String orderByField = "createdDateTime";
  static const bool descendingOrder = true;
  final FirebaseFirestore _firestore;
  final String _collectionName;

  PostServiceFeed({FirebaseFirestore? firestore, String collectionName = FirestoreCollections.posts})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _collectionName = collectionName;

  //TODO LIMIT THE TOTAL POSTS THAT CAN BE RETRIEVED IN FREE MODE TO 100
  // --- PAGINATION METHOD (Primary method for the feed) ---
  Future<List<MemoModelPost>> getPostsPaginated({required int limit, String? postId, List<String> mutedCreators = const []}) async {
    Query query = _firestore.collection(_collectionName).orderBy(orderByField, descending: descendingOrder);
    var startAfterDoc = postId == null ? null : await _getDocumentSnapshot(postId);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    if (mutedCreators.isNotEmpty) {
      query = query.where("creatorId", whereNotIn: mutedCreators);
    }

    final querySnapshot = await query.limit(limit).get();

    return querySnapshot.docs.map((doc) {
      return MemoModelPost.fromSnapshot(doc);
    }).toList();
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

  Future<DocumentSnapshot?> _getDocumentSnapshot(String postId) async {
    print('PostServiceFeed:🔍 Getting document snapshot for post: $postId');
    try {
      final doc = await FirebaseFirestore.instance.collection(FirestoreCollections.posts).doc(postId).get();
      return doc.exists ? doc : null;
    } catch (e) {
      print('PostServiceFeed:❌ Error getting document snapshot: $e');
      return null;
    }
  }
}
