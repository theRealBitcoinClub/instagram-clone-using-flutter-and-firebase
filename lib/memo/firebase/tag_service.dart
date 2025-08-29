import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mahakka/memo/firebase/memo_firebase_service.dart';
import 'package:mahakka/memo/model/memo_model_tag.dart';

// Extends the abstract service, providing the model type.
class TagService extends MemoFirebaseService<MemoModelTag> {
  // 1. Override the abstract getter.
  @override
  String get collectionName => 'tags';

  // 2. Override the abstract fromSnapshot method.
  @override
  MemoModelTag fromSnapshot(DocumentSnapshot<Object?> snapshot) {
    return MemoModelTag.fromJson(snapshot.data()! as Map<String, dynamic>)..id = snapshot.id;
  }

  Future<List<MemoModelTag>> getAllTags() async {
    try {
      QuerySnapshot querySnapshot = await firestore.collection(collectionName).get();
      return querySnapshot.docs.map((doc) => fromSnapshot(doc)).toList();
    } catch (e, s) {
      print("Error fetching all tags: $e");
      print(s);
      return [];
    }
  }

  // This is specific to your search logic.
  Future<List<MemoModelTag>> searchTags(String query) async {
    if (query.isEmpty) return [];
    final String lowerQuery = query.toLowerCase();
    QuerySnapshot snapshot = await firestore
        .collection(collectionName)
        .where('name_lowercase', isGreaterThanOrEqualTo: lowerQuery)
        .where('name_lowercase', isLessThanOrEqualTo: lowerQuery + '\uf8ff')
        .limit(10)
        .get();
    return snapshot.docs.map((doc) => fromSnapshot(doc)).toList();
  }

  Future<void> incrementPostCountForTags(List<String> tagIds) async {
    if (tagIds.isEmpty) return;
    WriteBatch batch = firestore.batch();
    for (String tagId in tagIds) {
      DocumentReference tagRef = firestore.collection(collectionName).doc(tagId);
      batch.update(tagRef, {'postCount': FieldValue.increment(1)});
    }
    try {
      await batch.commit();
      print("Incremented postCount for tags: ${tagIds.join(', ')}");
    } catch (e) {
      print("Error incrementing postCount for tags: $e");
      rethrow;
    }
  }
}
