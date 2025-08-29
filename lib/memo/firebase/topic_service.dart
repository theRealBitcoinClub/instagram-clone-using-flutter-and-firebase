import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mahakka/memo/firebase/memo_firebase_service.dart';
import 'package:mahakka/memo/model/memo_model_topic.dart';

// Extends the abstract service, providing the model type.
class TopicService extends MemoFirebaseService<MemoModelTopic> {
  // 1. Override the abstract getter.
  @override
  String get collectionName => 'topics';

  // 2. Override the abstract fromSnapshot method.
  @override
  MemoModelTopic fromSnapshot(DocumentSnapshot<Object?> snapshot) {
    return MemoModelTopic.fromJson(snapshot.data()! as Map<String, dynamic>);
  }

  // Keep specific methods like sanitizing IDs.
  String sanitizeFirestoreId(String id) {
    return id.replaceAll('/', '__');
  }

  String desanitizeFirestoreId(String firestoreId) {
    return firestoreId.replaceAll('__', '/');
  }

  // You would update your `saveTopic` to use the superclass method,
  // but with the sanitized ID.
  Future<void> saveTopic(MemoModelTopic topic) async {
    final String safeTopicId = sanitizeFirestoreId(topic.id);
    // Use the inherited save method with the safe ID.
    await save(topic, safeTopicId);
  }

  // And `getTopicOnce`
  @override
  Future<MemoModelTopic?> getOnce(String topicId) {
    final String safeTopicId = sanitizeFirestoreId(topicId);
    return super.getOnce(safeTopicId);
  }

  Future<List<MemoModelTopic>> getAllTopics() async {
    try {
      QuerySnapshot querySnapshot = await firestore.collection(collectionName).get();
      return querySnapshot.docs.map((doc) => fromSnapshot(doc)).toList();
    } catch (e) {
      print("Error fetching all topics: $e");
      return [];
    }
  }

  Future<List<MemoModelTopic>> searchTopics(String query) async {
    if (query.isEmpty) return [];
    final String lowerQuery = query.toLowerCase();
    QuerySnapshot snapshot = await firestore
        .collection(collectionName)
        .where('header_lowercase', isGreaterThanOrEqualTo: lowerQuery)
        .where('header_lowercase', isLessThanOrEqualTo: lowerQuery + '\uf8ff')
        .limit(10)
        .get();
    return snapshot.docs.map((doc) => fromSnapshot(doc)).toList();
  }

  // The rest of the generic methods are now inherited.
}
