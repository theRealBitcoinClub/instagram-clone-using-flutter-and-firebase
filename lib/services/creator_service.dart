// // services/creator_service.dart
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:mahakka/memo/model/memo_model_creator.dart';
//
// // Your existing CreatorService class, now managed by a provider.
// class CreatorService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   static const String _creatorsCollection = 'creators';
//
//   Future<void> saveCreator(MemoModelCreator creator) async {
//     // ... existing implementation ...
//     try {
//       final DocumentReference docRef = _firestore.collection(_creatorsCollection).doc(creator.id);
//       final Map<String, dynamic> creatorJson = creator.toJson(); // Still works
//       await docRef.set(creatorJson, SetOptions(merge: true));
//       print("Creator ${creator.id} saved successfully to Firestore.");
//     } catch (e) {
//       print("Error saving creator ${creator.id} to Firestore: $e");
//       rethrow;
//     }
//   }
//
//   Future<MemoModelCreator?> getCreatorOnce(String creatorId) async {
//     // ... existing implementation ...
//     try {
//       final DocumentReference docRef = _firestore.collection(_creatorsCollection).doc(creatorId);
//       final DocumentSnapshot snapshot = await docRef.get();
//
//       if (snapshot.exists && snapshot.data() != null) {
//         return MemoModelCreator.fromJson(snapshot.data()! as Map<String, dynamic>);
//       } else {
//         return null;
//       }
//     } catch (e) {
//       print("Error fetching creator $creatorId once: $e");
//       return null;
//     }
//   }
//
//   // NOTE: You can add other methods from your original CreatorService here
//   // or keep them as-is if they are not used by the repository.
// }
//
// final creatorServiceProvider = Provider((ref) => CreatorService());
