import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mahakka/config.dart';
import 'package:mahakka/memo/model/memo_model_tag.dart';

class TagServiceAdmin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _tagsCollection = FirestoreCollections.tag;

  Future<List<MemoModelTag>> getTagsPaginated({required int limit, DocumentSnapshot? startAfterDoc}) async {
    Query query = _firestore.collection(_tagsCollection);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    final querySnapshot = await query.limit(limit).get();

    return querySnapshot.docs.map((doc) {
      return MemoModelTag.fromSnapshot(doc);
    }).toList();
  }

  Future<void> deleteTag(String tagId) async {
    try {
      await _firestore.collection(_tagsCollection).doc(tagId).delete();
      print("Tag '$tagId' deleted successfully.");
    } catch (e) {
      print("Error deleting tag '$tagId': $e");
      rethrow;
    }
  }

  Stream<MemoModelTag?> getTagStream(String tagId) {
    try {
      final DocumentReference docRef = _firestore.collection(_tagsCollection).doc(tagId);

      return docRef
          .snapshots()
          .map((snapshot) {
            if (snapshot.exists && snapshot.data() != null) {
              return MemoModelTag.fromJson(snapshot.data()! as Map<String, dynamic>);
            } else {
              print("Tag with ID '$tagId' not found in Firestore stream.");
              return null;
            }
          })
          .handleError((error) {
            print("Error in tag stream for '$tagId': $error");
            return null;
          });
    } catch (e) {
      print("Error getting tag stream for '$tagId': $e");
      return Stream.value(null);
    }
  }
}
