import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:mahakka/config.dart';
import 'package:mahakka/memo/model/memo_model_tag.dart';

class TagService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _tagsCollection = FirestoreCollections.tag;

  // FIFO cache for tracking persisted tag IDs
  static final _persistedTagIds = Queue<String>();
  static const int _maxCacheSize = 10000;

  // Batch processing variables
  static final _batchQueue = Queue<MemoModelTag>();
  static Timer? _batchTimer;
  static const int _maxBatchSize = 500;
  static const Duration _batchTimeout = Duration(minutes: 5);
  static Function(bool success, int processedCount, List<String>? failedTagIds)? _currentOnFinishCallback;

  // Check if tag is already persisted
  static bool _isTagAlreadyPersisted(String tagId) {
    return _persistedTagIds.contains(tagId);
  }

  // Add tag ID to cache with FIFO eviction
  static void _addToPersistedCache(String tagId) {
    if (_persistedTagIds.length >= _maxCacheSize) {
      _persistedTagIds.removeFirst();
    }
    _persistedTagIds.add(tagId);
  }

  // Remove tag ID from cache
  static void _removeFromPersistedCache(String tagId) {
    _persistedTagIds.remove(tagId);
  }

  // Clear entire cache
  static void clearPersistedCache() {
    _persistedTagIds.clear();
  }

  // Get current cache size
  static int getPersistedCacheSize() {
    return _persistedTagIds.length;
  }

  // Batch processing methods
  static int getBatchQueueSize() {
    return _batchQueue.length;
  }

  void clearBatchQueue() {
    _batchQueue.clear();
    _cancelTimer();
    print("Tag batch queue cleared");
  }

  /// Manually forces the batch to process immediately
  void forceProcessBatch() {
    if (_batchQueue.isEmpty) {
      print("Tag batch queue is empty, nothing to process");
      _executeCallbackIfNeeded(true, 0, null);
      return;
    }

    print("🔄 Manually forcing tag batch processing with ${_batchQueue.length} tags...");
    _processBatch();
  }

  /// Saves tags using batching with timeout and duplicate prevention
  void saveTagsBatch(List<MemoModelTag> tags, {Function(bool success, int processedCount, List<String>? failedTagIds)? onFinish}) {
    if (_currentOnFinishCallback == null && onFinish != null) {
      _currentOnFinishCallback = onFinish;
    }

    final newTags = _filterDuplicates(tags);

    if (newTags.isEmpty) {
      print("All tags in the batch are duplicates, skipping...");
      _executeCallbackIfNeeded(true, 0, null);
      return;
    }

    _addToBatchQueue(newTags);
    _startOrResetTimer();

    if (_batchQueue.length >= _maxBatchSize) {
      _processBatch();
    }
  }

  /// Filters out duplicates from both memory cache and Firebase persistence
  List<MemoModelTag> _filterDuplicates(List<MemoModelTag> tags) {
    final uniqueTags = <MemoModelTag>[];
    final duplicateIds = <String>[];

    for (final tag in tags) {
      final tagId = tag.id;
      if (tagId.isEmpty) {
        print("Tag has empty ID, skipping");
        continue;
      }

      // Check memory cache first
      if (_batchQueue.any((t) => t.id == tagId)) {
        duplicateIds.add(tagId);
        continue;
      }

      // Check persisted cache
      if (_isTagAlreadyPersisted(tagId)) {
        duplicateIds.add(tagId);
        continue;
      }

      uniqueTags.add(tag);
    }

    if (duplicateIds.isNotEmpty) {
      if (kDebugMode) print("Filtered out ${duplicateIds.length} duplicate tags: ${duplicateIds.join(', ')}");
    }

    return uniqueTags;
  }

  void _addToBatchQueue(List<MemoModelTag> tags) {
    for (final tag in tags) {
      if (tag.lastPostCount == 0) _batchQueue.add(tag);
    }
    print("Added ${tags.length} tags to batch queue. Queue size: ${_batchQueue.length}");
  }

  void _startOrResetTimer() {
    _cancelTimer();

    _batchTimer = Timer(_batchTimeout, () {
      print("Tag batch timeout reached after ${_batchTimeout.inMinutes} minutes");
      if (_batchQueue.isNotEmpty) {
        _processBatch();
      } else {
        _executeCallbackIfNeeded(true, 0, null);
      }
    });

    // print("Tag batch timer started/reset (${_batchTimeout.inMinutes} minutes)");
  }

  void _cancelTimer() {
    _batchTimer?.cancel();
    _batchTimer = null;
  }

  Future<void> _processBatch() async {
    if (_batchQueue.isEmpty) {
      print("Tag batch queue is empty, nothing to process");
      _executeCallbackIfNeeded(true, 0, null);
      return;
    }

    _cancelTimer();

    final tagsToProcess = _batchQueue.toList();
    _batchQueue.clear();

    print("Processing tag batch of ${tagsToProcess.length} tags...");

    try {
      final batch = _firestore.batch();
      final failedTagIds = <String>[];
      int successfulSaves = 0;

      for (final tag in tagsToProcess) {
        final tagId = tag.id;
        if (tagId.isEmpty) {
          print("Skipping tag with empty ID");
          failedTagIds.add('empty_id_${tagsToProcess.indexOf(tag)}');
          continue;
        }

        try {
          final docRef = _firestore.collection(_tagsCollection).doc(tagId);
          batch.set(docRef, tag.toJson(), SetOptions(merge: true));
          successfulSaves++;
        } catch (e) {
          print("Error adding tag $tagId to batch: $e");
          failedTagIds.add(tagId);
        }
      }

      if (successfulSaves > 0) {
        await batch.commit();
        print("✅ Tag batch commit successful! Saved $successfulSaves tags in 1 write operation");

        // Add successful tags to persistence cache
        for (final tag in tagsToProcess) {
          final tagId = tag.id;
          if (tagId.isNotEmpty && !failedTagIds.contains(tagId)) {
            _addToPersistedCache(tagId);
          }
        }
      } else {
        print("❌ No tags were successfully added to the batch");
      }

      _executeCallbackIfNeeded(true, successfulSaves, failedTagIds.isNotEmpty ? failedTagIds : null);
    } catch (e) {
      print("❌ Tag batch commit failed: $e");

      final failedIds = tagsToProcess.where((t) => t.id.isNotEmpty).map((t) => t.id).toList();
      _executeCallbackIfNeeded(false, 0, failedIds.isNotEmpty ? failedIds : null);
    }
  }

  void _executeCallbackIfNeeded(bool success, int processedCount, List<String>? failedTagIds) {
    final callback = _currentOnFinishCallback;
    if (callback != null) {
      callback(success, processedCount, failedTagIds);
      _currentOnFinishCallback = null;
    }
  }

  // Original single save method (for backward compatibility)
  Future<void> saveTag(MemoModelTag tag) async {
    final tagId = tag.id;
    if (tagId.isEmpty) {
      throw ArgumentError("Tag ID cannot be empty");
    }

    if (_isTagAlreadyPersisted(tagId)) {
      print("Tag $tagId already persisted, skipping save.");
      return;
    }

    try {
      final DocumentReference docRef = _firestore.collection(_tagsCollection).doc(tagId);
      await docRef.set(tag.toJson(), SetOptions(merge: true));
      _addToPersistedCache(tagId);
      print("Tag '$tagId' saved successfully.");
    } catch (e) {
      print("Error saving tag '$tagId': $e");
      rethrow;
    }
  }

  // Batch version of incrementPostCountForTags
  Future<void> incrementPostCountForTagsBatch(List<String> tagIds) async {
    if (tagIds.isEmpty) return;

    try {
      final batch = _firestore.batch();
      int successfulIncrements = 0;

      for (String tagId in tagIds) {
        if (tagId.isEmpty) continue;

        try {
          DocumentReference tagRef = _firestore.collection(_tagsCollection).doc(tagId);
          batch.update(tagRef, {'postCount': FieldValue.increment(1), 'lastPost': FieldValue.serverTimestamp()});
          successfulIncrements++;
        } catch (e) {
          print("Error adding tag $tagId to increment batch: $e");
        }
      }

      if (successfulIncrements > 0) {
        await batch.commit();
        print("✅ Incremented postCount for $successfulIncrements tags in 1 write operation");
      }
    } catch (e) {
      print("❌ Error in incrementPostCountForTagsBatch: $e");
      rethrow;
    }
  }

  // Existing methods remain unchanged below...
  Future<List<MemoModelTag>> getAllTags() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection(_tagsCollection).get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return MemoModelTag.fromJson(data)..id = doc.id;
      }).toList();
    } catch (e, s) {
      print("Error fetching all tags: $e");
      print(s);
      return [];
    }
  }

  Future<List<MemoModelTag>> getTagsPaginated({required int limit, DocumentSnapshot? startAfterDoc}) async {
    Query query = _firestore.collection(_tagsCollection);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    final querySnapshot = await query.limit(limit).get();

    return querySnapshot.docs.map((doc) {
      return MemoModelTag.fromSnapshot(doc);
    }).toList();
  }

  Future<List<MemoModelTag>> searchTags(String query) async {
    if (query.isEmpty) return [];
    final String lowerQuery = query.toLowerCase();
    QuerySnapshot snapshot = await _firestore
        .collection(_tagsCollection)
        .where('name_lowercase', isGreaterThanOrEqualTo: lowerQuery)
        .where('name_lowercase', isLessThanOrEqualTo: lowerQuery + '\uf8ff')
        .limit(10)
        .get();
    return snapshot.docs.map((doc) => MemoModelTag.fromJson(doc.data() as Map<String, dynamic>)..id = doc.id).toList();
  }

  Future<void> deleteTag(String tagId) async {
    try {
      await _firestore.collection(_tagsCollection).doc(tagId).delete();
      _removeFromPersistedCache(tagId);
      print("Tag '$tagId' deleted successfully.");
    } catch (e) {
      print("Error deleting tag '$tagId': $e");
      rethrow;
    }
  }

  Stream<MemoModelTag?> getTagStream(String tagId) {
    try {
      final DocumentReference docRef = _firestore.collection(_tagsCollection).doc(tagId);

      return docRef
          .snapshots()
          .map((snapshot) {
            if (snapshot.exists && snapshot.data() != null) {
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

  Stream<List<MemoModelTag>> getAllTagsStream() {
    try {
      final CollectionReference colRef = _firestore.collection(_tagsCollection);

      return colRef
          .snapshots()
          .map((querySnapshot) {
            return querySnapshot.docs.map((doc) {
              return MemoModelTag.fromJson(doc.data()! as Map<String, dynamic>);
            }).toList();
          })
          .handleError((error) {
            print("Error in all tags stream: $error");
            return [];
          });
    } catch (e) {
      print("Error getting all tags stream: $e");
      return Stream.value([]);
    }
  }

  Future<MemoModelTag?> getTagOnce(String tagId) async {
    try {
      final DocumentSnapshot snapshot = await _firestore.collection(_tagsCollection).doc(tagId).get();
      if (snapshot.exists && snapshot.data() != null) {
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

  //
  // // Original increment method (for backward compatibility)
  // Future<void> incrementPostCountForTags(List<String> tagIds) async {
  //   if (tagIds.isEmpty) return;
  //
  //   WriteBatch batch = _firestore.batch();
  //   for (String tagId in tagIds) {
  //     DocumentReference tagRef = _firestore.collection(_tagsCollection).doc(tagId);
  //     batch.update(tagRef, {'postCount': FieldValue.increment(1)});
  //   }
  //   try {
  //     await batch.commit();
  //     print("Incremented postCount for tags: ${tagIds.join(', ')}");
  //   } catch (e) {
  //     print("Error incrementing postCount for tags: $e");
  //     rethrow;
  //   }
  // }
}
