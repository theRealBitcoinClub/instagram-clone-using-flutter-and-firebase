import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../memo/isar/memo_model_post_db.dart';
import '../memo/model/memo_model_post.dart';
import '../provider/isar_provider.dart';

final profilePostCacheProvider = Provider((ref) => ProfilePostCache(ref));

const int profileCacheAndFirebaseLimit = 18;

class ProfilePostCache {
  final Ref ref;
  final bool _debugMode = kDebugMode;

  ProfilePostCache(this.ref) {
    if (_debugMode) print('🔄 PPC: ProfilePostCache constructor called');
  }

  Future<Isar> get _profileIsar async {
    if (_debugMode) print('💾 PPC: Getting Profile Isar instance');
    final isar = await ref.read(profilePostsIsarProvider.future);
    if (_debugMode) print('💾 PPC: Profile Isar instance obtained');
    return isar;
  }

  static const int _maxDiskCacheSizeProfile = 5000;
  static const int _diskCleanupThresholdProfile = 6000;

  // Update post in both feed and profile databases
  Future<void> updatePostInProfileDatabase(MemoModelPost post) async {
    try {
      final postDb = MemoModelPostDb.fromAppModel(post);

      // Update in feed database
      final feedIsar = await _profileIsar;
      await feedIsar.writeTxn(() async {
        await feedIsar.memoModelPostDbs.put(postDb);
      });

      print('💾 FPC: Updated post in feed database: ${post.id}');
    } catch (e) {
      print('⚠️ FPC: Failed to update post in feed database: $e');
    }
  }

  Future<void> saveProfilePosts(String creatorId, List<MemoModelPost> posts) async {
    if (_debugMode) print('👤 PPC: saveProfilePosts called for creator: $creatorId, posts: ${posts.length}');

    final validPosts = posts.where((post) => post.id != null && post.id!.isNotEmpty).toList();
    if (validPosts.isEmpty) {
      if (_debugMode) print('❌ PPC: No valid posts to save');
      return;
    }

    if (_debugMode) print('💾 PPC: Saving ${validPosts.length} valid posts to profile cache for creator: $creatorId');

    final isar = await _profileIsar;
    final postsDb = validPosts.map((post) => MemoModelPostDb.fromAppModel(post)).toList();

    try {
      if (_debugMode) print('💾 PPC: Starting Isar transaction for saveProfilePosts');
      await isar.writeTxn(() async {
        // Delete existing posts for this creator
        if (_debugMode) print('💾 PPC: Removing existing profile posts for creator: $creatorId');
        await isar.memoModelPostDbs.where().filter().creatorIdEqualTo(creatorId).deleteAll();

        if (_debugMode) print('💾 PPC: Inserting ${postsDb.length} posts to profile cache');
        await isar.memoModelPostDbs.putAll(postsDb);

        if (_debugMode) print('✅ PPC: Successfully saved ${postsDb.length} posts to profile cache for creator: $creatorId');

        await _enforceProfileDiskSizeLimit(isar);
      });
      if (_debugMode) print('✅ PPC: saveProfilePosts transaction completed successfully');
    } catch (e, stack) {
      if (_debugMode) print('❌ PPC: ERROR in saveProfilePosts transaction: $e');
      if (_debugMode) print('❌ PPC: Stack trace: $stack');
    }
  }

  Future<void> cacheProfilePosts(String creatorId, List<MemoModelPost> posts) async {
    if (_debugMode) print('👤 PPC: cacheProfilePosts called for creator: $creatorId, posts: ${posts.length}');
    await saveProfilePosts(creatorId, posts);
    if (_debugMode) print('✅ PPC: cacheProfilePosts completed for creator: $creatorId');
  }

  Future<List<MemoModelPost>> getCachedProfilePosts(String creatorId) async {
    if (_debugMode) print('👤 PPC: getCachedProfilePosts called for creator: $creatorId');

    final isar = await _profileIsar;
    try {
      final postsDb = await isar.memoModelPostDbs
          .where()
          .filter()
          .creatorIdEqualTo(creatorId)
          .sortByCreatedDateTimeDesc()
          .limit(profileCacheAndFirebaseLimit)
          .findAll();

      final posts = postsDb.map((db) => db.toAppModel()).toList();
      if (_debugMode) print('💾 PPC: Found ${posts.length} profile posts in disk cache for creator: $creatorId');

      if (_debugMode) print('✅ PPC: getCachedProfilePosts completed');
      return posts;
    } catch (e) {
      if (_debugMode) print('❌ PPC: Error loading profile posts from disk: $e');
      return [];
    }
  }

  // --- Size Limit Enforcement ---
  Future<void> _enforceProfileDiskSizeLimit(Isar isar) async {
    if (_debugMode) print('🧹 PPC: Checking profile disk size limit');
    final currentSize = await isar.memoModelPostDbs.count();
    if (_debugMode) print('🧹 PPC: Current profile disk cache size: $currentSize, threshold: $_diskCleanupThresholdProfile');

    if (currentSize <= _diskCleanupThresholdProfile) {
      if (_debugMode) print('ℹ️ PPC: Profile disk size within limits, no cleanup needed');
      return;
    }

    final entriesToRemove = currentSize - _maxDiskCacheSizeProfile;
    if (_debugMode) print('🧹 PPC: Need to remove $entriesToRemove entries from profile cache');

    // Remove oldest entries based on createdDateTime
    final oldEntries = await isar.memoModelPostDbs.where().sortByCreatedDateTime().limit(entriesToRemove).findAll();

    if (_debugMode) print('🧹 PPC: Found ${oldEntries.length} old profile entries to remove');
    await isar.writeTxn(() async {
      await isar.memoModelPostDbs.deleteAll(oldEntries.map((e) => e.id).toList());
    });

    if (_debugMode) print('🧹 PPC: Removed ${oldEntries.length} entries from profile cache (was $currentSize)');
  }
}

// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:isar_community/isar.dart';
//
// import '../memo/isar/memo_model_post_db.dart';
// import '../memo/model/memo_model_post.dart';
// import '../provider/isar_provider.dart';
//
// final profilePostCacheProvider = Provider((ref) => ProfilePostCache(ref));
//
// const int profileCacheAndFirebaseLimit = 18;
//
// class ProfilePostCache {
//   final Ref ref;
//
//   ProfilePostCache(this.ref) {
//     print('🔄 PPC: ProfilePostCache constructor called');
//   }
//
//   Future<Isar> get _profileIsar async {
//     print('💾 PPC: Getting Profile Isar instance');
//     final isar = await ref.read(profilePostsIsarProvider.future);
//     print('💾 PPC: Profile Isar instance obtained');
//     return isar;
//   }
//
//   static const int _maxDiskCacheSizeProfile = 5000; // Increased disk cache size
//   static const int _diskCleanupThresholdProfile = 6000; // 20% tolerance (6000 items)
//
//   Future<void> updatePostInProfileDatabase(MemoModelPost post) async {
//     try {
//       final postDb = MemoModelPostDb.fromAppModel(post);
//
//       // Update in profile database
//       final profileIsar = await _profileIsar;
//       await profileIsar.writeTxn(() async {
//         await profileIsar.memoModelPostDbs.put(postDb);
//       });
//
//       print('💾 PPC: Updated post in profile databases: ${post.id}');
//     } catch (e) {
//       print('⚠️ PPC: Failed to update post in profile databases: $e');
//     }
//   }
//
//   // --- Profile Posts Operations ---
//
//   Future<void> saveProfilePosts(String creatorId, List<MemoModelPost> posts) async {
//     print('👤 PPC: saveProfilePosts called for creator: $creatorId, posts: ${posts.length}');
//     final validPosts = posts.where((post) => post.id != null && post.id!.isNotEmpty).toList();
//     if (validPosts.isEmpty) {
//       print('❌ PPC: No valid posts to save');
//       return;
//     }
//     print('💾 PPC: Saving ${validPosts.length} valid posts to profile cache for creator: $creatorId');
//
//     final isar = await _profileIsar;
//     final postsDb = validPosts.map((post) => MemoModelPostDb.fromAppModel(post)).toList();
//
//     try {
//       print('💾 PPC: Starting Isar transaction for saveProfilePosts');
//       await isar.writeTxn(() async {
//         // Delete existing posts then insert new ones
//         final postIds = postsDb.map((p) => p.postId).toList();
//
//         print('💾 PPC: Removing any existing profile posts with same IDs');
//         for (final postId in postIds) {
//           await isar.memoModelPostDbs.where().postIdEqualTo(postId).deleteAll();
//         }
//
//         print('💾 PPC: Inserting ${postsDb.length} posts to profile cache');
//         await isar.memoModelPostDbs.putAll(postsDb);
//
//         print('✅ PPC: Successfully saved ${postsDb.length} posts to profile cache for creator: $creatorId');
//
//         await _enforceProfileDiskSizeLimit(isar);
//       });
//       print('✅ PPC: saveProfilePosts transaction completed successfully');
//     } catch (e, stack) {
//       print('❌ PPC: ERROR in saveProfilePosts transaction: $e');
//       print('❌ PPC: Stack trace: $stack');
//     }
//   }
//
//   Future<void> cacheProfilePosts(String creatorId, List<MemoModelPost> posts) async {
//     print('👤 PPC: cacheProfilePosts called for creator: $creatorId, posts: ${posts.length}');
//     await saveProfilePosts(creatorId, posts);
//     print('✅ PPC: cacheProfilePosts completed for creator: $creatorId');
//   }
//
//   Future<List<MemoModelPost>> getCachedProfilePosts(String creatorId) async {
//     print('👤 PPC: getCachedProfilePosts called for creator: $creatorId');
//
//     // If not in memory, try disk cache
//     final isar = await _profileIsar;
//     try {
//       final postsDb = await isar.memoModelPostDbs
//           .where()
//           .filter()
//           .creatorIdEqualTo(creatorId)
//           .sortByCreatedDateTimeDesc()
//           .limit(profileCacheAndFirebaseLimit)
//           .findAll();
//
//       final posts = postsDb.map((db) => db.toAppModel()).toList();
//       print('💾 PPC: Found ${posts.length} profile posts in disk cache');
//
//       print('✅ PPC: getCachedProfilePosts completed');
//       return posts;
//     } catch (e) {
//       print('❌ PPC: Error loading profile posts from disk: $e');
//       return [];
//     }
//   }
//
//   // --- Size Limit Enforcement ---
//
//   Future<void> _enforceProfileDiskSizeLimit(Isar isar) async {
//     print('🧹 PPC: Checking profile disk size limit');
//     final currentSize = await isar.memoModelPostDbs.count();
//     print('🧹 PPC: Current profile disk cache size: $currentSize, threshold: $_diskCleanupThresholdProfile');
//
//     if (currentSize <= _diskCleanupThresholdProfile) {
//       print('ℹ️ PPC: Profile disk size within limits, no cleanup needed');
//       return;
//     }
//
//     final entriesToRemove = currentSize - _maxDiskCacheSizeProfile;
//     print('🧹 PPC: Need to remove $entriesToRemove entries from profile cache');
//
//     final oldEntries = await isar.memoModelPostDbs.where().limit(entriesToRemove).findAll();
//
//     print('🧹 PPC: Found ${oldEntries.length} old profile entries to remove');
//     await isar.memoModelPostDbs.deleteAll(oldEntries.map((e) => e.id).toList());
//
//     print('🧹 PPC: Removed $entriesToRemove entries from profile cache (was $currentSize)');
//   }
// }
