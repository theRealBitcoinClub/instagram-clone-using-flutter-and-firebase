import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mahakka/memo/firebase/memo_firebase_service.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';

// Extends the abstract service, providing the model type.
class UserService extends MemoFirebaseService<MemoModelUser> {
  // 1. Override the abstract getter.
  @override
  String get collectionName => 'users';

  // 2. Override the abstract fromSnapshot method.
  @override
  MemoModelUser fromSnapshot(DocumentSnapshot<Object?> snapshot) {
    return MemoModelUser.fromJson(snapshot.data()! as Map<String, dynamic>);
  }

  // All methods like saveUser, deleteUser, getUserOnce, etc.,
  // are now inherited from the superclass.
  // For example, `saveUser` becomes `save`.
}
