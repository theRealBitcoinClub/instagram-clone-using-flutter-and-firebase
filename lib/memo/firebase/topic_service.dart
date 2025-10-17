import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:mahakka/config.dart';
import 'package:mahakka/memo/model/memo_model_topic.dart';

import '../model/memo_model_topic_light.dart';

class TopicService {
  final FirebaseFirestore _firestore;
  final String _collectionName;
  final String _topicListDocumentId;

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
      _collectionName = collectionName,
      _topicListDocumentId = "${collectionName}topic_list";

  /// Retrieves all lightweight topics from the topic list document
  /// Automatically initializes the document if it doesn't exist
  Future<List<MemoModelTopicLight>> getLightweightTopics() async {
    try {
      final topicListDocRef = _firestore.collection(_collectionName).doc(_topicListDocumentId);
      final topicListDoc = await topicListDocRef.get();

      // Initialize document if it doesn't exist
      if (!topicListDoc.exists) {
        print("🔄 Topic list document not found, initializing with existing topics...");

        // Get all existing topics from the collection
        final allTopics = await getAllTopics();

        if (allTopics.isEmpty) {
          print("No existing topics found to initialize the topic list");
          return [];
        }

        // Convert to lightweight format for the topic list
        final lightTopics = allTopics.map((topic) => {'id': sanitizeFirestoreId(topic.id), 'count': topic.lastPostCount}).toList();

        // Create the topic list document
        await topicListDocRef.set({'topics': lightTopics, 'last_updated': FieldValue.serverTimestamp(), 'total_count': lightTopics.length});

        print("✅ Topic list document initialized with ${lightTopics.length} existing topics");
      }

      // Document exists, proceed with normal retrieval
      final data = topicListDoc.data();
      if (data == null || !data.containsKey('topics')) {
        return [];
      }

      final topicsList = List<Map<String, dynamic>>.from(data['topics'] ?? []);
      final lightTopics = topicsList
          .map((topicData) => MemoModelTopicLight(id: topicData['id'] ?? '', count: topicData['count'] ?? 0))
          .toList();

      print("Retrieved ${lightTopics.length} lightweight topics from topic list");
      return lightTopics;
    } catch (e) {
      print("Error retrieving lightweight topics: $e");
      return [];
    }
  }

  Future<void> _updateTopicListWithNewIds(List<MemoModelTopic> newTopics) async {
    if (newTopics.isEmpty) return;

    try {
      final topicListDocRef = _firestore.collection(_collectionName).doc(_topicListDocumentId);

      await _firestore.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(topicListDocRef);

        Map<String, dynamic> existingTopics = {};
        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          if (data != null && data.containsKey('topics')) {
            // Convert list to map for easier updates
            final topicsList = List<Map<String, dynamic>>.from(data['topics'] ?? []);
            for (final topicData in topicsList) {
              existingTopics[topicData['id']] = topicData['count'];
            }
          }
        }

        // Update with new topics (overwrite existing counts if topics already exist)
        for (final topic in newTopics) {
          final sanitizedId = sanitizeFirestoreId(topic.id);
          existingTopics[sanitizedId] = topic.postCount;
        }

        // Convert back to list format for Firestore
        final updatedTopicsList = existingTopics.entries.map((entry) => {'id': entry.key, 'count': entry.value}).toList();

        transaction.set(topicListDocRef, {
          'topics': updatedTopicsList,
          'last_updated': FieldValue.serverTimestamp(),
          'total_count': updatedTopicsList.length,
        }, SetOptions(merge: true));
      });

      print("✅ Topic list updated with ${newTopics.length} new topics");
    } catch (e) {
      print("❌ Error updating topic list: $e");
    }
  }

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
      final topicId = topic.id;
      if (topicId.isEmpty) {
        print("Topic has empty ID, skipping");
        continue;
      }

      final sanitizedId = sanitizeFirestoreId(topicId);

      // Check memory cache first
      if (_batchQueue.any((t) => sanitizeFirestoreId(t.id) == sanitizedId)) {
        duplicateIds.add(topicId);
        continue;
      }

      // Check persisted cache
      if (_isTopicAlreadyPersisted(sanitizedId)) {
        duplicateIds.add(topicId);
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
      if (topic.lastPostCount == 0) _batchQueue.add(topic);
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
        final topicId = topic.id;
        if (topicId.isEmpty) {
          print("Skipping topic with empty ID");
          failedTopicIds.add('empty_id_${topicsToProcess.indexOf(topic)}');
          continue;
        }

        try {
          final String safeTopicId = sanitizeFirestoreId(topicId);
          final docRef = _firestore.collection(_collectionName).doc(safeTopicId);
          batch.set(docRef, topic.toJson(), SetOptions(merge: true));
          successfulSaves++;
        } catch (e) {
          print("Error adding topic $topicId to batch: $e");
          failedTopicIds.add(topicId);
        }
      }

      if (successfulSaves > 0) {
        await batch.commit();
        print("✅ Topic batch commit successful! Saved $successfulSaves topics in 1 write operation");

        // Add successful topics to persistence cache
        for (final topic in topicsToProcess) {
          final topicId = topic.id;
          if (topicId.isNotEmpty && !failedTopicIds.contains(topicId)) {
            _addToPersistedCache(sanitizeFirestoreId(topicId));
          }
        }

        // ✅ NEW: Update the topic list with successfully processed topics
        final successfulTopics = topicsToProcess.where((t) => t.id.isNotEmpty && !failedTopicIds.contains(t.id)).toList();
        await _updateTopicListWithNewIds(successfulTopics);
      } else {
        print("❌ No topics were successfully added to the batch");
      }

      _executeCallbackIfNeeded(true, successfulSaves, failedTopicIds.isNotEmpty ? failedTopicIds : null);
    } catch (e) {
      print("❌ Topic batch commit failed: $e");

      final failedIds = topicsToProcess.where((t) => t.id.isNotEmpty).map((t) => t.id).toList();
      _executeCallbackIfNeeded(false, 0, failedIds.isNotEmpty ? failedIds : null);
    }
  }

  void _executeCallbackIfNeeded(bool success, int processedCount, List<String>? failedTopicIds) {
    final callback = _currentOnFinishCallback;
    if (callback != null) {
      callback(success, processedCount, failedTopicIds);
      _currentOnFinishCallback = null;
    }
  }

  String sanitizeFirestoreId(String id) {
    return id.replaceAll('/', '__');
  }

  String desanitizeFirestoreId(String firestoreId) {
    return firestoreId.replaceAll('__', '/');
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
}
