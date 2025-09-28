import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';

// Provider for the metadata service
final postMetadataServiceProvider = Provider<PostMetadataService>((ref) {
  return PostMetadataService(FirebaseFirestore.instance);
});

class PostMetadataService {
  final FirebaseFirestore _firestore;

  PostMetadataService(this._firestore);

  // Collection names (should match what you use in savePost)
  static const String postsCollection = FirestoreCollections.posts;
  static const String metadataCollection = FirestoreCollections.metadata;
  static const String postsCounterDoc = FirestoreCollections.posts;

  /// Gets the current post count from metadata
  Future<int> getPostCount() async {
    try {
      final counterDoc = await _firestore.collection(metadataCollection).doc(postsCounterDoc).get();

      if (!counterDoc.exists) {
        return 0;
      }

      return counterDoc.data()?['count'] as int? ?? 0;
    } catch (e) {
      print('Error getting post count: $e');
      rethrow;
    }
  }

  /// Stream for real-time post count updates
  Stream<int> watchPostCount() {
    return _firestore
        .collection(metadataCollection)
        .doc(postsCounterDoc)
        .snapshots()
        .handleError((error) {
          print('Error watching post count: $error');
        })
        .map((snapshot) {
          if (!snapshot.exists) {
            return 0;
          }
          return snapshot.data()?['count'] as int? ?? 0;
        });
  }

  /// Gets the last updated timestamp
  Future<DateTime?> getLastUpdated() async {
    try {
      final counterDoc = await _firestore.collection(metadataCollection).doc(postsCounterDoc).get();

      if (!counterDoc.exists) {
        return null;
      }

      final timestamp = counterDoc.data()?['lastUpdated'] as Timestamp?;
      return timestamp?.toDate();
    } catch (e) {
      print('Error getting last updated timestamp: $e');
      rethrow;
    }
  }

  /// Gets the initialization timestamp
  Future<DateTime?> getInitializedAt() async {
    try {
      final counterDoc = await _firestore.collection(metadataCollection).doc(postsCounterDoc).get();

      if (!counterDoc.exists) {
        return null;
      }

      final timestamp = counterDoc.data()?['initializedAt'] as Timestamp?;
      return timestamp?.toDate();
    } catch (e) {
      print('Error getting initialized at timestamp: $e');
      rethrow;
    }
  }

  /// Gets all metadata as a map
  Future<Map<String, dynamic>> getMetadata() async {
    try {
      final counterDoc = await _firestore.collection(metadataCollection).doc(postsCounterDoc).get();

      if (!counterDoc.exists) {
        return {};
      }

      return counterDoc.data() ?? {};
    } catch (e) {
      print('Error getting metadata: $e');
      rethrow;
    }
  }

  /// Stream for real-time metadata updates
  Stream<Map<String, dynamic>> watchMetadata() {
    return _firestore
        .collection(metadataCollection)
        .doc(postsCounterDoc)
        .snapshots()
        .handleError((error) {
          print('Error watching metadata: $error');
        })
        .map((snapshot) {
          if (!snapshot.exists) {
            return {};
          }
          return snapshot.data() ?? {};
        });
  }

  /// Gets the total post count by querying the posts collection directly
  /// This is useful for verifying the counter accuracy
  Future<int> getActualPostCount() async {
    try {
      final querySnapshot = await _firestore.collection(postsCollection).count().get();

      return querySnapshot.count ?? -1;
    } catch (e) {
      print('Error getting actual post count: $e');
      rethrow;
    }
  }

  /// Verifies if the counter is accurate by comparing with actual post count
  Future<bool> isCounterAccurate() async {
    try {
      final counterCount = await getPostCount();
      final actualCount = await getActualPostCount();

      return counterCount == actualCount;
    } catch (e) {
      print('Error verifying counter accuracy: $e');
      return false;
    }
  }

  /// Gets metadata with additional statistics
  Future<Map<String, dynamic>> getDetailedMetadata() async {
    try {
      final counterDoc = await _firestore.collection(metadataCollection).doc(postsCounterDoc).get();

      if (!counterDoc.exists) {
        return {'count': 0, 'exists': false, 'initialized': false};
      }

      final data = counterDoc.data() ?? {};
      final actualCount = await getActualPostCount();
      final isAccurate = data['count'] == actualCount;

      return {
        ...data,
        'actualCount': actualCount,
        'isAccurate': isAccurate,
        'exists': true,
        'initialized': true,
        'discrepancy': (data['count'] as int? ?? 0) - actualCount,
      };
    } catch (e) {
      print('Error getting detailed metadata: $e');
      rethrow;
    }
  }

  /// Resets the counter to match the actual post count
  /// Use with caution - only for maintenance purposes
  Future<void> resetCounter() async {
    try {
      final actualCount = await getActualPostCount();

      await _firestore.collection(metadataCollection).doc(postsCounterDoc).set({
        'count': actualCount,
        'lastUpdated': FieldValue.serverTimestamp(),
        'resetAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Counter reset to $actualCount');
    } catch (e) {
      print('Error resetting counter: $e');
      rethrow;
    }
  }
}

// Example usage providers
final postCountProvider = StreamProvider<int>((ref) {
  final service = ref.watch(postMetadataServiceProvider);
  return service.watchPostCount();
});

final postMetadataProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final service = ref.watch(postMetadataServiceProvider);
  return service.watchMetadata();
});

final postCountAccuracyProvider = FutureProvider<bool>((ref) {
  final service = ref.watch(postMetadataServiceProvider);
  return service.isCounterAccurate();
});
