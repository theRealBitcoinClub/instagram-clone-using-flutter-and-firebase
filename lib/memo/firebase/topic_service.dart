import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:mahakka/config.dart';
import 'package:mahakka/memo/model/memo_model_topic.dart';

class TopicService {
  final FirebaseFirestore _firestore;
  final String _collectionName;

  // FIFO cache for tracking persisted topic IDs
  static final _persistedTopicIds = Queue<String>();
  static const int _maxCacheSize = 10000;

  // Batch processing variables
  static final _batchQueue = Queue<MemoModelTopic>();
  static Timer? _batchTimer;
  static const int _maxBatchSize = 500;
  static const Duration _batchTimeout = Duration(minutes: 5);
  static Function(bool success, int processedCount, List<String>? failedTopicIds)? _currentOnFinishCallback;

  TopicService({FirebaseFirestore? firestore, String collectionName = FirestoreCollections.topic})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _collectionName = collectionName;

  // Check if topic is already persisted
  static bool _isTopicAlreadyPersisted(String topicId) {
    return _persistedTopicIds.contains(topicId);
  }

  // Add topic ID to cache with FIFO eviction
  static void _addToPersistedCache(String topicId) {
    if (_persistedTopicIds.length >= _maxCacheSize) {
      _persistedTopicIds.removeFirst();
    }
    _persistedTopicIds.add(topicId);
  }

  // Remove topic ID from cache
  static void _removeFromPersistedCache(String topicId) {
    _persistedTopicIds.remove(topicId);
  }

  // Clear entire cache
  static void clearPersistedCache() {
    _persistedTopicIds.clear();
  }

  // Get current cache size
  static int getPersistedCacheSize() {
    return _persistedTopicIds.length;
  }

  // Batch processing methods
  static int getBatchQueueSize() {
    return _batchQueue.length;
  }

  void clearBatchQueue() {
    _batchQueue.clear();
    _cancelTimer();
    print("Topic batch queue cleared");
  }

  /// Manually forces the batch to process immediately
  void forceProcessBatch() {
    if (_batchQueue.isEmpty) {
      print("Topic batch queue is empty, nothing to process");
      _executeCallbackIfNeeded(true, 0, null);
      return;
    }

    print("🔄 Manually forcing topic batch processing with ${_batchQueue.length} topics...");
    _processBatch();
  }

  /// Saves topics using batching with timeout and duplicate prevention
  void saveTopicsBatch(List<MemoModelTopic> topics, {Function(bool success, int processedCount, List<String>? failedTopicIds)? onFinish}) {
    if (_currentOnFinishCallback == null && onFinish != null) {
      _currentOnFinishCallback = onFinish;
    }

    final newTopics = _filterDuplicates(topics);

    if (newTopics.isEmpty) {
      print("All topics in the batch are duplicates, skipping...");
      _executeCallbackIfNeeded(true, 0, null);
      return;
    }

    _addToBatchQueue(newTopics);
    _startOrResetTimer();

    if (_batchQueue.length >= _maxBatchSize) {
      _processBatch();
    }
  }

  /// Filters out duplicates from both memory cache and Firebase persistence
  List<MemoModelTopic> _filterDuplicates(List<MemoModelTopic> topics) {
    final uniqueTopics = <MemoModelTopic>[];
    final duplicateIds = <String>[];

    for (final topic in topics) {
      if (topic.id == null || topic.id!.isEmpty) {
        print("Topic has null or empty ID, skipping");
        continue;
      }

      final sanitizedId = sanitizeFirestoreId(topic.id!);

      // Check memory cache first
      if (_batchQueue.any((t) => sanitizeFirestoreId(t.id!) == sanitizedId)) {
        duplicateIds.add(topic.id!);
        continue;
      }

      // Check persisted cache
      if (_isTopicAlreadyPersisted(sanitizedId)) {
        duplicateIds.add(topic.id!);
        continue;
      }

      uniqueTopics.add(topic);
    }

    if (duplicateIds.isNotEmpty) {
      if (kDebugMode) print("Filtered out ${duplicateIds.length} duplicate topics: ${duplicateIds.join(', ')}");
    }

    return uniqueTopics;
  }

  void _addToBatchQueue(List<MemoModelTopic> topics) {
    for (final topic in topics) {
      _batchQueue.add(topic);
    }
    print("Added ${topics.length} topics to batch queue. Queue size: ${_batchQueue.length}");
  }

  void _startOrResetTimer() {
    _cancelTimer();

    _batchTimer = Timer(_batchTimeout, () {
      print("Topic batch timeout reached after ${_batchTimeout.inMinutes} minutes");
      if (_batchQueue.isNotEmpty) {
        _processBatch();
      } else {
        _executeCallbackIfNeeded(true, 0, null);
      }
    });

    // print("Topic batch timer started/reset (${_batchTimeout.inMinutes} minutes)");
  }

  void _cancelTimer() {
    _batchTimer?.cancel();
    _batchTimer = null;
  }

  Future<void> _processBatch() async {
    if (_batchQueue.isEmpty) {
      print("Topic batch queue is empty, nothing to process");
      _executeCallbackIfNeeded(true, 0, null);
      return;
    }

    _cancelTimer();

    final topicsToProcess = _batchQueue.toList();
    _batchQueue.clear();

    print("Processing topic batch of ${topicsToProcess.length} topics...");

    try {
      final batch = _firestore.batch();
      final failedTopicIds = <String>[];
      int successfulSaves = 0;

      for (final topic in topicsToProcess) {
        if (topic.id == null || topic.id!.isEmpty) {
          print("Skipping topic with null or empty ID");
          failedTopicIds.add('null_id_${topicsToProcess.indexOf(topic)}');
          continue;
        }

        try {
          final String safeTopicId = sanitizeFirestoreId(topic.id!);
          final docRef = _firestore.collection(_collectionName).doc(safeTopicId);
          batch.set(docRef, topic.toJson(), SetOptions(merge: true));
          successfulSaves++;
        } catch (e) {
          print("Error adding topic ${topic.id} to batch: $e");
          failedTopicIds.add(topic.id!);
        }
      }

      if (successfulSaves > 0) {
        await batch.commit();
        print("✅ Topic batch commit successful! Saved $successfulSaves topics in 1 write operation");

        // Add successful topics to persistence cache
        for (final topic in topicsToProcess) {
          if (topic.id != null && !failedTopicIds.contains(topic.id)) {
            _addToPersistedCache(sanitizeFirestoreId(topic.id!));
          }
        }
      } else {
        print("❌ No topics were successfully added to the batch");
      }

      _executeCallbackIfNeeded(true, successfulSaves, failedTopicIds.isNotEmpty ? failedTopicIds : null);
    } catch (e) {
      print("❌ Topic batch commit failed: $e");

      _executeCallbackIfNeeded(false, 0, topicsToProcess.where((t) => t.id != null).map((t) => t.id!).toList());
    }
  }

  void _executeCallbackIfNeeded(bool success, int processedCount, List<String>? failedTopicIds) {
    if (_currentOnFinishCallback != null) {
      _currentOnFinishCallback!(success, processedCount, failedTopicIds);
      _currentOnFinishCallback = null;
    }
  }

  // Original single save method (for backward compatibility)
  Future<void> saveTopic(MemoModelTopic topic) async {
    if (topic.id == null || topic.id!.isEmpty) {
      throw ArgumentError("Topic ID cannot be null or empty");
    }

    final String safeTopicId = sanitizeFirestoreId(topic.id!);

    if (_isTopicAlreadyPersisted(safeTopicId)) {
      print("Topic ${topic.id} already persisted, skipping save.");
      return;
    }

    try {
      final DocumentReference docRef = _firestore.collection(_collectionName).doc(safeTopicId);
      final Map<String, dynamic> topicJson = topic.toJson();
      await docRef.set(topicJson, SetOptions(merge: true));
      _addToPersistedCache(safeTopicId);
      print("Topic ${topic.id} saved successfully.");
    } catch (e) {
      print("Error saving topic ${topic.id}: $e");
      rethrow;
    }
  }

  String sanitizeFirestoreId(String id) {
    return id.replaceAll('/', '__');
  }

  String desanitizeFirestoreId(String firestoreId) {
    return firestoreId.replaceAll('__', '/');
  }

  // Batch version for bulk operations (e.g., updating follower counts)
  Future<void> updateTopicsBatch(Map<String, Map<String, dynamic>> updates) async {
    if (updates.isEmpty) return;

    try {
      final batch = _firestore.batch();
      int successfulUpdates = 0;

      updates.forEach((topicId, updateData) {
        if (topicId.isEmpty) return;

        try {
          final String safeTopicId = sanitizeFirestoreId(topicId);
          DocumentReference topicRef = _firestore.collection(_collectionName).doc(safeTopicId);
          batch.update(topicRef, updateData);
          successfulUpdates++;
        } catch (e) {
          print("Error adding topic $topicId to update batch: $e");
        }
      });

      if (successfulUpdates > 0) {
        await batch.commit();
        print("✅ Updated $successfulUpdates topics in 1 write operation");
      }
    } catch (e) {
      print("❌ Error in updateTopicsBatch: $e");
      rethrow;
    }
  }

  // Existing methods remain unchanged below...
  Future<void> deleteTopic(String topicId) async {
    try {
      final String safeTopicId = sanitizeFirestoreId(topicId);
      await _firestore.collection(_collectionName).doc(safeTopicId).delete();
      _removeFromPersistedCache(safeTopicId);
      print("Topic ${topicId} deleted successfully.");
    } catch (e) {
      print("Error deleting topic ${topicId}: $e");
      rethrow;
    }
  }

  Stream<MemoModelTopic?> getTopicStream(String topicId) {
    try {
      final String safeTopicId = sanitizeFirestoreId(topicId);
      final DocumentReference docRef = _firestore.collection(_collectionName).doc(safeTopicId);

      return docRef
          .snapshots()
          .map((snapshot) {
            if (snapshot.exists && snapshot.data() != null) {
              return MemoModelTopic.fromJson(snapshot.data()! as Map<String, dynamic>);
            } else {
              print("Topic with ID $topicId not found in Firestore stream.");
              return null;
            }
          })
          .handleError((error) {
            print("Error in topic stream for $topicId: $error");
            return null;
          });
    } catch (e) {
      print("Error getting topic stream for $topicId: $e");
      return Stream.value(null);
    }
  }

  Stream<List<MemoModelTopic>> getAllTopicsStream({String orderByField = 'followerCount', bool descending = true}) {
    try {
      Query query = _firestore.collection(_collectionName);

      if (orderByField.isNotEmpty) {
        query = query.orderBy(orderByField, descending: descending);
      }

      return query
          .snapshots()
          .map((querySnapshot) {
            return querySnapshot.docs.map((doc) {
              return MemoModelTopic.fromJson(doc.data()! as Map<String, dynamic>);
            }).toList();
          })
          .handleError((error) {
            print("Error in all topics stream: $error. Ensure Firestore index exists for field '$orderByField'.");
            return [];
          });
    } catch (e) {
      print("Error getting all topics stream: $e");
      return Stream.value([]);
    }
  }

  Future<MemoModelTopic?> getTopicOnce(String topicId) async {
    try {
      topicId = topicId.toLowerCase();
      final String safeTopicId = sanitizeFirestoreId(topicId);
      final DocumentSnapshot snapshot = await _firestore.collection(_collectionName).doc(safeTopicId).get();

      if (snapshot.exists && snapshot.data() != null) {
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
      QuerySnapshot querySnapshot = await _firestore.collection(_collectionName).get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return MemoModelTopic.fromJson(data)..id = doc.id;
      }).toList();
    } catch (e, s) {
      print("Error fetching all topics: $e");
      print(s);
      return [];
    }
  }

  Future<List<MemoModelTopic>> searchTopics(String query) async {
    if (query.isEmpty) return [];
    final String lowerQuery = query.toLowerCase();
    QuerySnapshot snapshot = await _firestore
        .collection(_collectionName)
        .where('header_lowercase', isGreaterThanOrEqualTo: lowerQuery)
        .where('header_lowercase', isLessThanOrEqualTo: lowerQuery + '\uf8ff')
        .limit(10)
        .get();
    return snapshot.docs.map((doc) => MemoModelTopic.fromJson(doc.data() as Map<String, dynamic>)..id = doc.id).toList();
  }
}
