import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mahakka/config.dart';
// Adjust the import path to where your MemoModelTopic is located
import 'package:mahakka/memo/model/memo_model_topic.dart';

class TopicService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Choose a distinct collection name for topics
  static const String _topicsCollection = FirestoreCollections.topic; // Or 'topics_v1', etc.

  /// Saves a topic to Firestore.
  /// If a topic with the same ID already exists, it will be updated (merged).
  /// If it doesn't exist, it will be created.
  Future<void> saveTopic(MemoModelTopic topic) async {
    try {
      final String safeTopicId = sanitizeFirestoreId(topic.id);
      final DocumentReference docRef = _firestore.collection(_topicsCollection).doc(safeTopicId);
      // Assuming MemoModelTopic has a toJson() method
      final Map<String, dynamic> topicJson = topic.toJson();
      await docRef.set(topicJson, SetOptions(merge: true));
      print("Topic ${topic.id} saved successfully to Firestore in collection '$_topicsCollection'.");
    } catch (e) {
      print("Error saving topic ${topic.id} to Firestore: $e");
      rethrow; // Re-throw the error to be handled by the caller
    }
  }

  String sanitizeFirestoreId(String id) {
    return id.replaceAll('/', '__'); // Or your chosen replacement
  }

  String desanitizeFirestoreId(String firestoreId) {
    return firestoreId.replaceAll('__', '/'); // Or your chosen replacement
  }

  /// Deletes a topic from Firestore based on its ID.
  Future<void> deleteTopic(String topicId) async {
    try {
      await _firestore.collection(_topicsCollection).doc(topicId).delete();
      print("Topic ${topicId} deleted successfully from Firestore.");
    } catch (e) {
      print("Error deleting topic ${topicId} from Firestore: $e");
      rethrow;
    }
  }

  /// Retrieves a real-time stream of a single topic from Firestore.
  /// Emits null if the topic doesn't exist or if there's an error.
  Stream<MemoModelTopic?> getTopicStream(String topicId) {
    try {
      final String safeTopicId = sanitizeFirestoreId(topicId);
      final DocumentReference docRef = _firestore.collection(_topicsCollection).doc(safeTopicId);

      return docRef
          .snapshots()
          .map((snapshot) {
            if (snapshot.exists && snapshot.data() != null) {
              // Assuming MemoModelTopic has a fromJson factory
              return MemoModelTopic.fromJson(snapshot.data()! as Map<String, dynamic>);
            } else {
              print("Topic with ID $topicId not found in Firestore stream.");
              return null;
            }
          })
          .handleError((error) {
            print("Error in topic stream for $topicId: $error");
            // Depending on how you want to handle stream errors,
            // you might emit null or let the error propagate.
            return null;
          });
    } catch (e) {
      print("Error getting topic stream for $topicId: $e");
      return Stream.value(null); // Return a stream that emits null immediately
    }
  }

  /// Retrieves a real-time stream of all topics from Firestore.
  /// Emits an empty list if there are no topics or if there's an error.
  Stream<List<MemoModelTopic>> getAllTopicsStream({
    String orderByField = 'followerCount', // Default field to order by
    bool descending = true, // Default to descending (newest first)
  }) {
    try {
      // Start with the base collection reference
      Query query = _firestore.collection(_topicsCollection);

      // Apply the ordering
      // Ensure the orderByField is not empty if you want to make it truly optional later
      if (orderByField.isNotEmpty) {
        query = query.orderBy(orderByField, descending: descending);
      }
      // If orderByField can be empty/null, you might want a different default like:
      // else {
      //   query = query.orderBy('name'); // Default to ordering by name if no field is specified
      // }

      final CollectionReference colRef = _firestore.collection(_topicsCollection);

      // Apply the ordering to your query
      Query orderedQuery = colRef.orderBy(
        orderByField,
        descending: descending, // Use the parameter, defaulting to true
      );

      return orderedQuery // Use the orderedQuery here
          .snapshots()
          .map((querySnapshot) {
            return querySnapshot.docs.map((doc) {
              // Assuming MemoModelTopic has a fromJson factory
              return MemoModelTopic.fromJson(doc.data()! as Map<String, dynamic>);
            }).toList();
          })
          .handleError((error) {
            print("Error in all topics stream: $error. Ensure Firestore index exists for field '$orderByField'.");
            return []; // Emit an empty list on error
          });
    } catch (e) {
      print("Error getting all topics stream: $e");
      return Stream.value([]); // Return a stream that emits an empty list immediately
    }
  }

  /// Fetches a single topic from Firestore once (not a stream).
  /// Returns null if the topic doesn't exist or if there's an error.
  Future<MemoModelTopic?> getTopicOnce(String topicId) async {
    try {
      topicId = topicId.toLowerCase();
      final String safeTopicId = sanitizeFirestoreId(topicId);
      final DocumentReference docRef = _firestore.collection(_topicsCollection).doc(safeTopicId);
      final DocumentSnapshot snapshot = await docRef.get();

      if (snapshot.exists && snapshot.data() != null) {
        // Assuming MemoModelTopic has a fromJson factory
        return MemoModelTopic.fromJson(snapshot.data()! as Map<String, dynamic>);
      } else {
        print("Topic with ID $topicId not found when fetching once.");
        return null;
      }
    } catch (e) {
      print("Error fetching topic $topicId once: $e");
      return null;
    }
  }

  Future<List<MemoModelTopic>> getAllTopics() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_topicsCollection)
          // Optionally order them if needed for consistency, e.g., by header
          // .orderBy('header_lowercase') // Add an index for this if you use it
          .get(); // Consider adding .limit( énorme_nombre ) if your topics list is huge
      // but for caching all, you'd fetch all or paginate if truly massive.

      if (querySnapshot.docs.isEmpty) {
        return [];
      }
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return MemoModelTopic.fromJson(data)..id = doc.id; // Ensure ID is set
      }).toList();
    } catch (e, s) {
      print("Error fetching all topics: $e");
      print(s);
      // Depending on your error strategy, you might rethrow or return empty list
      // For caching, returning an empty list on error might be safer than crashing.
      return [];
    }
  }

  // Your existing searchTopics (on-demand) can remain if you want to switch strategies
  // or for other parts of the app, but SearchViewModel will now primarily use the cache.
  Future<List<MemoModelTopic>> searchTopics(String query) async {
    // ... (your existing on-demand search logic) ...
    // This will likely involve querying Firestore with a 'where' clause.
    // Example:
    if (query.isEmpty) return [];
    final String lowerQuery = query.toLowerCase();
    QuerySnapshot snapshot = await _firestore
        .collection(_topicsCollection)
        .where('header_lowercase', isGreaterThanOrEqualTo: lowerQuery) // Assumes you have 'header_lowercase'
        .where('header_lowercase', isLessThanOrEqualTo: lowerQuery + '\uf8ff')
        .limit(10) // Always limit on-demand searches
        .get();
    return snapshot.docs.map((doc) => MemoModelTopic.fromJson(doc.data() as Map<String, dynamic>)..id = doc.id).toList();
  }
}
