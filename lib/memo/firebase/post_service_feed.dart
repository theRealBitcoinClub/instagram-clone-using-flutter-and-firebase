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

  Future<int> getTotalPostCount() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection(_collectionName).count().get();
      return querySnapshot.count!;
    } catch (e) {
      print('Error getting post count: $e');
      return -1;
    }
  }
}
