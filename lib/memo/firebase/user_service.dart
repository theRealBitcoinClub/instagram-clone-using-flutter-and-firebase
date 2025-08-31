import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mahakka/memo/model/memo_model_user.dart'; // Your model path

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = '_users';

  Future<void> saveUser(MemoModelUser user) async {
    try {
      final DocumentReference docRef = _firestore.collection(_usersCollection).doc(user.id);
      await docRef.set(user.toJson(), SetOptions(merge: true));
      print("User ${user.id} saved successfully to Firestore.");
    } catch (e) {
      print("Error saving user ${user.id} to Firestore: $e");
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).delete();
      print("User ${userId} deleted successfully from Firestore.");
    } catch (e) {
      print("Error deleting user ${userId} from Firestore: $e");
      rethrow;
    }
  }

  Future<MemoModelUser?> getUserOnce(String userId) async {
    try {
      final DocumentReference docRef = _firestore.collection(_usersCollection).doc(userId);
      final DocumentSnapshot snapshot = await docRef.get();

      if (snapshot.exists && snapshot.data() != null) {
        return MemoModelUser.fromJson(snapshot.data()! as Map<String, dynamic>);
      } else {
        return null;
      }
    } catch (e) {
      print("Error fetching user $userId once: $e");
      return null;
    }
  }

  Stream<List<MemoModelUser>> getAllUsersStream() {
    try {
      final CollectionReference colRef = _firestore.collection(_usersCollection);
      return colRef
          .snapshots()
          .map((querySnapshot) {
            return querySnapshot.docs.map((doc) {
              return MemoModelUser.fromJson(doc.data()! as Map<String, dynamic>);
            }).toList();
          })
          .handleError((error) {
            print("Error in all users stream: $error");
            return [];
          });
    } catch (e) {
      print("Error getting all users stream: $e");
      return Stream.value([]);
    }
  }

  Stream<MemoModelUser?> getUserStream(String userId) {
    try {
      final DocumentReference docRef = _firestore.collection(_usersCollection).doc(userId);
      return docRef
          .snapshots()
          .map((snapshot) {
            if (snapshot.exists && snapshot.data() != null) {
              return MemoModelUser.fromJson(snapshot.data()! as Map<String, dynamic>);
            } else {
              print("User with ID $userId not found in Firestore stream.");
              return null;
            }
          })
          .handleError((error) {
            print("Error in user stream for $userId: $error");
            return null;
          });
    } catch (e) {
      print("Error getting user stream for $userId: $e");
      return Stream.value(null);
    }
  }
}
