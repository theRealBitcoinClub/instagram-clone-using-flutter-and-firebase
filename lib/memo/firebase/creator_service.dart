import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mahakka/memo/firebase/memo_firebase_service.dart'; // Import the abstract class
import 'package:mahakka/memo/model/memo_model_creator.dart'; // Your model path

class CreatorService extends MemoFirebaseService<MemoModelCreator> {
  // 1. Override the abstract getter to provide the collection name.
  @override
  String get collectionName => 'creators';

  // 2. Override the abstract method to provide the conversion logic.
  // We use .fromJson here because that's what your existing code uses.
  @override
  MemoModelCreator fromSnapshot(DocumentSnapshot<Object?> snapshot) {
    return MemoModelCreator.fromJson(snapshot.data()! as Map<String, dynamic>);
  }

  // All other methods are now inherited from MemoFirebaseService.
  // You no longer need to write:
  // - saveCreator (use save)
  // - deleteCreator (use delete)
  // - getCreatorStream (use getStream)
  // - getAllCreatorsStream (use getAllStream)
  // - getCreatorOnce (use getOnce)
}
