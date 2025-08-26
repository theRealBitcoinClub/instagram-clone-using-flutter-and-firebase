import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart'; // Your model path
// If MemoModelCreator includes MemoModelPost, ensure it's imported if needed here,
// though json_serializable handles the nesting.

class CreatorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Define a top-level collection name for creators
  static const String _creatorsCollection = 'creators';

  /// Saves or updates a MemoModelCreator document in Firestore.
  /// If a document with the creator's ID already exists, it will be updated.
  /// Otherwise, a new document will be created.
  Future<void> saveCreator(MemoModelCreator creator) async {
    try {
      final DocumentReference docRef = _firestore.collection(_creatorsCollection).doc(creator.id);
      // Convert the MemoModelCreator object to a JSON map
      final Map<String, dynamic> creatorJson = creator.toJson();
      await docRef.set(creatorJson, SetOptions(merge: true)); // merge: true to update existing fields
      print("Creator ${creator.id} saved successfully to Firestore.");
    } catch (e) {
      print("Error saving creator ${creator.id} to Firestore: $e");
      rethrow; // Or handle more gracefully
    }
  }

  /// Retrieves a single MemoModelCreator as a stream from Firestore.
  /// This is useful for listening to real-time updates for a specific creator.
  Stream<MemoModelCreator?> getCreatorStream(String creatorId) {
    try {
      final DocumentReference docRef = _firestore.collection(_creatorsCollection).doc(creatorId);

      return docRef
          .snapshots()
          .map((snapshot) {
            if (snapshot.exists && snapshot.data() != null) {
              // Convert the JSON map from Firestore back to a MemoModelCreator object
              return MemoModelCreator.fromJson(snapshot.data()! as Map<String, dynamic>);
            } else {
              print("Creator with ID $creatorId not found in Firestore stream.");
              return null; // Document doesn't exist or has no data
            }
          })
          .handleError((error) {
            print("Error in creator stream for $creatorId: $error");
            // Optionally, you could return a stream of an error state or rethrow
            return null;
          });
    } catch (e) {
      print("Error getting creator stream for $creatorId: $e");
      return Stream.value(null); // Return a stream with null on initial error
    }
  }

  /// Retrieves a list of all MemoModelCreators as a stream from Firestore.
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
            return []; // Return an empty list on error
          });
    } catch (e) {
      print("Error getting all creators stream: $e");
      return Stream.value([]); // Return a stream with an empty list on initial error
    }
  }

  /// Fetches a single MemoModelCreator once (not a stream).
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
