import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mahakka/config.dart';
import 'package:mahakka/memo/model/memo_model_topic.dart';

class TopicServiceAdmin {
  final FirebaseFirestore _firestore;
  final String _collectionName;

  TopicServiceAdmin({FirebaseFirestore? firestore, String collectionName = FirestoreCollections.topic})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _collectionName = collectionName;

  String sanitizeFirestoreId(String id) {
    return id.replaceAll('/', '__');
  }

  String desanitizeFirestoreId(String firestoreId) {
    return firestoreId.replaceAll('__', '/');
  }

  // Existing methods remain unchanged below...
  Future<void> deleteTopic(String topicId) async {
    try {
      final String safeTopicId = sanitizeFirestoreId(topicId);
      await _firestore.collection(_collectionName).doc(safeTopicId).delete();
      print("Topic $topicId deleted successfully.");
    } catch (e) {
      print("Error deleting topic $topicId: $e");
      rethrow;
    }
  }

  Stream<List<MemoModelTopic>> getAllTopicsStream({String orderByField = 'followerCount', bool descending = true}) {
    try {
      Query query = _firestore.collection(_collectionName);

      if (orderByField.isNotEmpty) {
        query = query.orderBy(orderByField, descending: descending);
      }

      return query
          .snapshots()
          .map((querySnapshot) {
            return querySnapshot.docs.map((doc) {
              return MemoModelTopic.fromJson(doc.data()! as Map<String, dynamic>);
            }).toList();
          })
          .handleError((error) {
            print("Error in all topics stream: $error. Ensure Firestore index exists for field '$orderByField'.");
            return [];
          });
    } catch (e) {
      print("Error getting all topics stream: $e");
      return Stream.value([]);
    }
  }
}
