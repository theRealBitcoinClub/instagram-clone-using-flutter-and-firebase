import 'package:cloud_firestore/cloud_firestore.dart';
// Adjust the import path to where your MemoModelTag is located
import 'package:mahakka/memo/model/memo_model_tag.dart';

class TagService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Choose a distinct collection name for tags
  static const String _tagsCollection = 'tags'; // Or 'tags_v1', etc.

  Future<List<MemoModelTag>> getAllTags() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_tagsCollection)
          // .orderBy('name_lowercase') // Optionally order
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return MemoModelTag.fromJson(data)..id = doc.id; // Ensure ID is set
      }).toList();
    } catch (e, s) {
      print("Error fetching all tags: $e");
      print(s);
      return []; // Return empty on error for caching robustness
    }
  }

  // --- PAGINATION METHOD (Primary method for the feed) ---
  Future<List<MemoModelTag>> getTagsPaginated({
    required int limit,
    DocumentSnapshot? startAfterDoc,
    // activeFilters are not used for Firestore query here, filtering is client-side
  }) async {
    Query query = _firestore.collection(_tagsCollection);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    final querySnapshot = await query.limit(limit).get();

    return querySnapshot.docs.map((doc) {
      // Use the new factory constructor that includes the snapshot
      return MemoModelTag.fromSnapshot(doc);
    }).toList();
  }

  // Future<List<MemoModelTag>> getTagsPaginated({
  //   required int limit,
  //   DocumentSnapshot? startAfterDoc,
  //   String orderByField = 'lastPost',
  //   bool descendingOrder = true,
  // }) async {
  //   Query query = _firestore.collection(_tagsCollection).orderBy(orderByField, descending: descendingOrder);
  //
  //   if (startAfterDoc != null) {
  //     query = query.startAfterDocument(startAfterDoc);
  //   }
  //
  //   final querySnapshot = await query.limit(limit).get();
  //
  //   return querySnapshot.docs.map((doc) {
  //     // Make sure your MemoModelTag has a fromSnapshot constructor
  //     // that accepts a DocumentSnapshot.
  //     return MemoModelTag.fromSnapshot(doc);
  //   }).toList();
  // }

  // Your existing searchTags (on-demand)
  Future<List<MemoModelTag>> searchTags(String query) async {
    // ... (your existing on-demand search logic) ...
    if (query.isEmpty) return [];
    final String lowerQuery = query.toLowerCase();
    QuerySnapshot snapshot = await _firestore
        .collection(_tagsCollection)
        .where('name_lowercase', isGreaterThanOrEqualTo: lowerQuery) // Assumes you have 'name_lowercase'
        .where('name_lowercase', isLessThanOrEqualTo: lowerQuery + '\uf8ff')
        .limit(10)
        .get();
    return snapshot.docs.map((doc) => MemoModelTag.fromJson(doc.data() as Map<String, dynamic>)..id = doc.id).toList();
  }

  /// Saves a tag to Firestore.
  /// If a tag with the same ID already exists, it will be updated (merged).
  /// If it doesn't exist, it will be created.
  /// The tag's 'id' is used as the document ID.
  Future<void> saveTag(MemoModelTag tag) async {
    try {
      // The 'id' of MemoModelTag is its name and Firestore document ID
      final DocumentReference docRef = _firestore.collection(_tagsCollection).doc(tag.id);
      // Assuming MemoModelTag has a toJson() method
      final Map<String, dynamic> tagJson = tag.toJson();
      await docRef.set(tagJson, SetOptions(merge: true));
      print("Tag '${tag.id}' saved successfully to Firestore in collection '$_tagsCollection'.");
    } catch (e) {
      print("Error saving tag '${tag.id}' to Firestore: $e");
      rethrow; // Re-throw the error to be handled by the caller
    }
  }

  /// Deletes a tag from Firestore based on its ID (which is its name).
  Future<void> deleteTag(String tagId) async {
    try {
      await _firestore.collection(_tagsCollection).doc(tagId).delete();
      print("Tag '${tagId}' deleted successfully from Firestore.");
    } catch (e) {
      print("Error deleting tag '${tagId}' from Firestore: $e");
      rethrow;
    }
  }

  /// Retrieves a real-time stream of a single tag from Firestore.
  /// Emits null if the tag doesn't exist or if there's an error.
  Stream<MemoModelTag?> getTagStream(String tagId) {
    try {
      final DocumentReference docRef = _firestore.collection(_tagsCollection).doc(tagId);

      return docRef
          .snapshots()
          .map((snapshot) {
            if (snapshot.exists && snapshot.data() != null) {
              // Assuming MemoModelTag has a fromJson factory
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

  /// Retrieves a real-time stream of all tags from Firestore.
  /// Emits an empty list if there are no tags or if there's an error.
  Stream<List<MemoModelTag>> getAllTagsStream() {
    try {
      final CollectionReference colRef = _firestore.collection(_tagsCollection);

      return colRef
          .snapshots()
          .map((querySnapshot) {
            return querySnapshot.docs.map((doc) {
              // Assuming MemoModelTag has a fromJson factory
              return MemoModelTag.fromJson(doc.data()! as Map<String, dynamic>);
            }).toList();
          })
          .handleError((error) {
            print("Error in all tags stream: $error");
            return []; // Emit an empty list on error
          });
    } catch (e) {
      print("Error getting all tags stream: $e");
      return Stream.value([]);
    }
  }

  /// Fetches a single tag from Firestore once (not a stream).
  /// Returns null if the tag doesn't exist or if there's an error.
  Future<MemoModelTag?> getTagOnce(String tagId) async {
    try {
      final DocumentReference docRef = _firestore.collection(_tagsCollection).doc(tagId);
      final DocumentSnapshot snapshot = await docRef.get();

      if (snapshot.exists && snapshot.data() != null) {
        // Assuming MemoModelTag has a fromJson factory
        return MemoModelTag.fromJson(snapshot.data()! as Map<String, dynamic>);
      } else {
        print("Tag with ID '$tagId' not found when fetching once.");
        return null;
      }
    } catch (e) {
      print("Error fetching tag '$tagId' once: $e");
      return null;
    }
  }

  /// Special method to increment postCount for multiple tags.
  /// This is useful when a new post is created with several tags.
  Future<void> incrementPostCountForTags(List<String> tagIds) async {
    if (tagIds.isEmpty) return;

    WriteBatch batch = _firestore.batch();
    for (String tagId in tagIds) {
      DocumentReference tagRef = _firestore.collection(_tagsCollection).doc(tagId);
      // Atomically increment the postCount.
      // If the tag document doesn't exist, this write in the batch might fail
      // or create it depending on your rules and if you use set vs update.
      // For a robust solution, you might check existence or use a Cloud Function.
      // For simplicity here, we assume tags are created before post counts are incremented,
      // or that 'set' with merge option in saveTag handles initial creation.
      batch.update(tagRef, {'postCount': FieldValue.increment(1)});
      // Optionally, update lastPost timestamp here as well if needed:
      // batch.update(tagRef, {'lastPost': Timestamp.now()}); // Or your desired date format
    }
    try {
      await batch.commit();
      print("Incremented postCount for tags: ${tagIds.join(', ')}");
    } catch (e) {
      print("Error incrementing postCount for tags: $e");
      rethrow;
    }
  }

  // You might also want a decrementPostCountForTags if posts can be deleted
  // or tags can be removed from posts.
}
