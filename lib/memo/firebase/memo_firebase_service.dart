// memo_firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class MemoFirebaseService<T> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // This getter must be overridden by each subclass to specify its collection.
  String get collectionName;

  // This abstract method forces each subclass to provide its specific
  // logic for converting a DocumentSnapshot to a model instance.
  T fromSnapshot(DocumentSnapshot<Object?> snapshot);

  // A reusable method to save a document.
  Future<void> save(T model, String id) async {
    try {
      final DocumentReference docRef = firestore.collection(collectionName).doc(id);
      final Map<String, dynamic> json = (model as dynamic).toJson();
      await docRef.set(json, SetOptions(merge: true));
      print("Document '$id' saved successfully to '$collectionName'.");
    } catch (e) {
      print("Error saving document '$id' to '$collectionName': $e");
      rethrow;
    }
  }

  // A reusable method to delete a document.
  Future<void> delete(String id) async {
    try {
      await firestore.collection(collectionName).doc(id).delete();
      print("Document '$id' deleted successfully from '$collectionName'.");
    } catch (e) {
      print("Error deleting document '$id' from '$collectionName': $e");
      rethrow;
    }
  }

  // A reusable method to get a single document once.
  Future<T?> getOnce(String id) async {
    try {
      final DocumentSnapshot snapshot = await firestore.collection(collectionName).doc(id).get();
      if (snapshot.exists) {
        return fromSnapshot(snapshot);
      }
      return null;
    } catch (e) {
      print("Error fetching document '$id' from '$collectionName': $e");
      return null;
    }
  }

  // A reusable method to get a real-time stream of a single document.
  Stream<T?> getStream(String id) {
    try {
      return firestore
          .collection(collectionName)
          .doc(id)
          .snapshots()
          .map((snapshot) {
            if (snapshot.exists) {
              return fromSnapshot(snapshot);
            } else {
              print("Document '$id' not found in Firestore stream.");
              return null;
            }
          })
          .handleError((error) {
            print("Error in stream for '$id': $error");
            return null;
          });
    } catch (e) {
      print("Error getting stream for '$id': $e");
      return Stream.value(null);
    }
  }

  // A reusable method to get a real-time stream of the entire collection.
  Stream<List<T>> getAllStream() {
    try {
      return firestore
          .collection(collectionName)
          .snapshots()
          .map((querySnapshot) {
            return querySnapshot.docs.map((doc) => fromSnapshot(doc)).toList();
          })
          .handleError((error) {
            print("Error in all stream for '$collectionName': $error");
            return [];
          });
    } catch (e) {
      print("Error getting all stream for '$collectionName': $e");
      return Stream.value([]);
    }
  }

  // Reusable method for pagination. It returns a future.
  Future<List<T>> getPaginated({
    required int limit,
    DocumentSnapshot? startAfterDoc,
    String orderByField = 'createdDateTime',
    bool descending = true,
  }) async {
    Query query = firestore.collection(collectionName).orderBy(orderByField, descending: descending);
    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }
    final querySnapshot = await query.limit(limit).get();
    return querySnapshot.docs.map((doc) => fromSnapshot(doc)).toList();
  }

  // Reusable method to get the total count.
  Stream<int> getTotalCountStream() {
    return firestore.collection(collectionName).snapshots().map((snapshot) => snapshot.docs.length).handleError((e) {
      print("Error getting total count for '$collectionName': $e");
      return 0;
    });
  }
}
