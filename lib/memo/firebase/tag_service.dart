import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:mahakka/config.dart';
import 'package:mahakka/memo/model/memo_model_tag.dart';

import '../model/memo_model_tag_light.dart';

class TagService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _tagsCollection = FirestoreCollections.tag;
  final String _tagListCollectionAndDocumentId = "${FirestoreCollections.tag}_map";

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
    _print("Tag batch queue cleared");
  }

  /// Manually forces the batch to process immediately
  void forceProcessBatch() {
    if (_batchQueue.isEmpty) {
      _print("Tag batch queue is empty, nothing to process");
      _executeCallbackIfNeeded(true, 0, null);
      return;
    }

    _print("🔄 Manually forcing tag batch processing with ${_batchQueue.length} tags...");
    _processBatch();
  }

  /// Saves tags using batching with timeout and duplicate prevention
  void saveTagsBatch(List<MemoModelTag> tags, {Function(bool success, int processedCount, List<String>? failedTagIds)? onFinish}) {
    if (_currentOnFinishCallback == null && onFinish != null) {
      _currentOnFinishCallback = onFinish;
    }

    final newTags = _filterDuplicates(tags);

    if (newTags.isEmpty) {
      _print("All tags in the batch are duplicates, skipping...");
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
        _print("Tag has empty ID, skipping");
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
      if (kDebugMode) _print("Filtered out ${duplicateIds.length} duplicate tags: ${duplicateIds.join(', ')}");
    }

    return uniqueTags;
  }

  void _addToBatchQueue(List<MemoModelTag> tags) {
    for (final tag in tags) {
      _batchQueue.add(tag);
    }
    _print("Added ${tags.length} tags to batch queue. Queue size: ${_batchQueue.length}");
  }

  void _startOrResetTimer() {
    _cancelTimer();

    _batchTimer = Timer(_batchTimeout, () {
      _print("Tag batch timeout reached after ${_batchTimeout.inMinutes} minutes");
      if (_batchQueue.isNotEmpty) {
        _processBatch();
      } else {
        _executeCallbackIfNeeded(true, 0, null);
      }
    });

    // _print("Tag batch timer started/reset (${_batchTimeout.inMinutes} minutes)");
  }

  void _cancelTimer() {
    _batchTimer?.cancel();
    _batchTimer = null;
  }

  Future<void> _processBatch() async {
    if (_batchQueue.isEmpty) {
      _print("Tag batch queue is empty, nothing to process");
      _executeCallbackIfNeeded(true, 0, null);
      return;
    }

    _cancelTimer();

    final tagsToProcess = _batchQueue.toList();
    _batchQueue.clear();

    _print("Processing tag batch of ${tagsToProcess.length} tags...");

    try {
      final batch = _firestore.batch();
      final failedTagIds = <String>[];
      int successfulSaves = 0;

      for (final tag in tagsToProcess) {
        final tagId = tag.id;
        if (tagId.isEmpty) {
          _print("Skipping tag with empty ID");
          failedTagIds.add('empty_id_${tagsToProcess.indexOf(tag)}');
          continue;
        }

        try {
          final docRef = _firestore.collection(_tagsCollection).doc(tagId);
          batch.set(docRef, tag.toJson(), SetOptions(merge: true));
          successfulSaves++;
        } catch (e) {
          _print("Error adding tag $tagId to batch: $e");
          failedTagIds.add(tagId);
        }
      }

      if (successfulSaves > 0) {
        await batch.commit();
        _print("✅ Tag batch commit successful! Saved $successfulSaves tags in 1 write operation");

        // Add successful tags to persistence cache
        for (final tag in tagsToProcess) {
          final tagId = tag.id;
          if (tagId.isNotEmpty && !failedTagIds.contains(tagId)) {
            _addToPersistedCache(tagId);
          }
        }

        // ✅ NEW: Update the tag list with successfully processed tags
        final successfulTags = tagsToProcess.where((t) => t.id.isNotEmpty && !failedTagIds.contains(t.id)).toList();
        await _updateTagListWithNewIds(successfulTags);
      } else {
        _print("❌ No tags were successfully added to the batch");
      }

      _executeCallbackIfNeeded(true, successfulSaves, failedTagIds.isNotEmpty ? failedTagIds : null);
    } catch (e) {
      _print("❌ Tag batch commit failed: $e");

      final failedIds = tagsToProcess.where((t) => t.id.isNotEmpty).map((t) => t.id).toList();
      _executeCallbackIfNeeded(false, 0, failedIds.isNotEmpty ? failedIds : null);
    }
  }

  /// Updates the tag list document with new tag IDs and their counts
  Future<void> _updateTagListWithNewIds(List<MemoModelTag> newTags) async {
    if (newTags.isEmpty) return;

    try {
      final tagListDocRef = _firestore.collection(_tagListCollectionAndDocumentId).doc(_tagListCollectionAndDocumentId);

      // Get current document WITHOUT transaction
      final docSnapshot = await tagListDocRef.get();

      Map<String, dynamic> existingTags = {};
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data.containsKey('tags')) {
          final tagsList = List<Map<String, dynamic>>.from(data['tags'] ?? []);
          for (final tagData in tagsList) {
            existingTags[tagData['id']] = tagData['count'];
          }
        }
      }

      // Update with new tags
      for (final tag in newTags) {
        existingTags[tag.id] = tag.postCount;
      }

      // Convert back to list format
      final updatedTagsList = existingTags.entries.map((entry) => {'id': entry.key, 'count': entry.value}).toList();

      // Update WITHOUT transaction
      await tagListDocRef.set({
        'tags': updatedTagsList,
        'last_updated': FieldValue.serverTimestamp(),
        'total_count': updatedTagsList.length,
      }, SetOptions(merge: true));

      _print("✅ Tag list updated with ${newTags.length} new tags");
    } catch (e) {
      _print("❌ Error updating tag list: $e");
    }
  }

  /// Retrieves all lightweight tags from the tag list document
  /// Automatically initializes the document if it doesn't exist
  Future<List<MemoModelTagLight>> getLightweightTags() async {
    try {
      final tagListDocRef = _firestore.collection(_tagListCollectionAndDocumentId).doc(_tagListCollectionAndDocumentId);
      final tagListDoc = await tagListDocRef.get();

      //TODO this is created during batch process
      // Initialize document if it doesn't exist
      // if (!tagListDoc.exists) {
      //   _print("🔄 Tag list document not found, initializing with existing tags...");
      //
      //   // Get all existing tags from the collection
      //   final allTags = await getAllTags();
      //
      //   if (allTags.isEmpty) {
      //     _print("No existing tags found to initialize the tag list");
      //     return [];
      //   }
      //
      //   // Convert to lightweight format for the tag list
      //   final lightTags = allTags.map((tag) => {'id': tag.id, 'count': tag.postCount}).toList();
      //
      //   // Create the tag list document
      //   await tagListDocRef.set({'tags': lightTags, 'last_updated': FieldValue.serverTimestamp(), 'total_count': lightTags.length});
      //
      //   _print("✅ Tag list document initialized with ${lightTags.length} existing tags");
      // }

      // Document exists, proceed with normal retrieval
      final data = tagListDoc.data();
      if (data == null || !data.containsKey('tags')) {
        return [];
      }

      final tagsList = List<Map<String, dynamic>>.from(data['tags'] ?? []);
      final lightTags = tagsList.map((tagData) => MemoModelTagLight(id: tagData['id'] ?? '', count: tagData['count'] ?? 0)).toList();

      _print("Retrieved ${lightTags.length} lightweight tags from tag list");
      return lightTags;
    } catch (e) {
      _print("Error retrieving lightweight tags: $e");
      return [];
    }
  }

  void _executeCallbackIfNeeded(bool success, int processedCount, List<String>? failedTagIds) {
    final callback = _currentOnFinishCallback;
    if (callback != null) {
      callback(success, processedCount, failedTagIds);
      _currentOnFinishCallback = null;
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
      _print("Error fetching all tags: $e");
      print(s);
      return [];
    }
  }

  void _print(String s) {
    if (kDebugMode) print("TAGSERVICE: " + s);
  }
}
