import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart'; // Your model path

class CreatorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _creatorsCollection = 'creators'; // Using a new collection name or path for safety

  Future<void> saveCreator(MemoModelCreator creator) async {
    try {
      final DocumentReference docRef = _firestore.collection(_creatorsCollection).doc(creator.id);
      final Map<String, dynamic> creatorJson = creator.toJson(); // Still works
      await docRef.set(creatorJson, SetOptions(merge: true));
      print("Creator ${creator.id} saved successfully to Firestore.");
    } catch (e) {
      print("Error saving creator ${creator.id} to Firestore: $e");
      rethrow;
    }
  }

  Future<void> deleteCreator(String creatorId) async {
    try {
      await _firestore.collection(_creatorsCollection).doc(creatorId).delete();
      print("Creator ${creatorId} deleted successfully from Firestore.");
    } catch (e) {
      print("Error deleting creator ${creatorId} from Firestore: $e");
      rethrow; // Or handle more gracefully depending on your app's needs
    }
  }

  Stream<MemoModelCreator?> getCreatorStream(String creatorId) {
    try {
      final DocumentReference docRef = _firestore.collection(_creatorsCollection).doc(creatorId);

      return docRef
          .snapshots()
          .map((snapshot) {
            if (snapshot.exists && snapshot.data() != null) {
              return MemoModelCreator.fromJson(snapshot.data()! as Map<String, dynamic>); // Still works
            } else {
              print("Creator with ID $creatorId not found in Firestore stream.");
              return null;
            }
          })
          .handleError((error) {
            print("Error in creator stream for $creatorId: $error");
            return null;
          });
    } catch (e) {
      print("Error getting creator stream for $creatorId: $e");
      return Stream.value(null);
    }
  }

  Stream<List<MemoModelCreator>> getAllCreatorsStream() {
    try {
      final CollectionReference colRef = _firestore.collection(_creatorsCollection);

      return colRef
          .snapshots()
          .map((querySnapshot) {
            return querySnapshot.docs.map((doc) {
              return MemoModelCreator.fromJson(doc.data()! as Map<String, dynamic>);
            }).toList();
          })
          .handleError((error) {
            print("Error in all creators stream: $error");
            return [];
          });
    } catch (e) {
      print("Error getting all creators stream: $e");
      return Stream.value([]);
    }
  }

  Future<MemoModelCreator?> getCreatorOnce(String creatorId) async {
    try {
      final DocumentReference docRef = _firestore.collection(_creatorsCollection).doc(creatorId);
      final DocumentSnapshot snapshot = await docRef.get();

      if (snapshot.exists && snapshot.data() != null) {
        return MemoModelCreator.fromJson(snapshot.data()! as Map<String, dynamic>);
      } else {
        return null;
      }
    } catch (e) {
      print("Error fetching creator $creatorId once: $e");
      return null;
    }
  }
}

final creatorServiceProvider = Provider((ref) => CreatorService());
