import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';

import '../../config.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = FirestoreCollections.user;

  Future<void> saveUser(MemoModelUser user) async {
    try {
      final DocumentReference docRef = _firestore.collection(_usersCollection).doc(user.id);
      await docRef.set(user.toJson(), SetOptions(merge: true));
      print("UserService: User ${user.id} saved successfully to Firestore.");
    } catch (e) {
      print("UserService: Error saving user ${user.id} to Firestore: $e");
      rethrow;
    }
  }
  //
  // Future<void> updateUserIpfsUrls(String userId, List<String> ipfsUrls) async {
  //   try {
  //     await _firestore.collection(_usersCollection).doc(userId).update({'ipfsUrls': ipfsUrls});
  //     print("UserService: Updated IPFS URLs for user $userId");
  //   } catch (e) {
  //     print("UserService: Error updating IPFS URLs for user $userId: $e");
  //     rethrow;
  //   }
  // }
  //
  // Future<void> addUserIpfsUrl(String userId, String ipfsCid) async {
  //   try {
  //     await _firestore.collection(_usersCollection).doc(userId).update({
  //       'ipfsUrls': FieldValue.arrayUnion([ipfsCid]),
  //     });
  //     print("UserService: Added IPFS URL $ipfsCid for user $userId");
  //   } catch (e) {
  //     print("UserService: Error adding IPFS URL for user $userId: $e");
  //     rethrow;
  //   }
  // }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).delete();
      print("UserService: User ${userId} deleted successfully from Firestore.");
    } catch (e) {
      print("UserService: Error deleting user ${userId} from Firestore: $e");
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
      print("UserService: Error fetching user $userId once: $e");
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
            print("UserService: Error in all users stream: $error");
            return [];
          });
    } catch (e) {
      print("UserService: Error getting all users stream: $e");
      return Stream.value([]);
    }
  }
}
