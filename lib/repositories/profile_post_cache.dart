import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mahakka/providers/token_limits_provider.dart';

import '../memo/isar/memo_model_post_db.dart';
import '../memo/model/memo_model_post.dart';
import '../provider/isar_provider.dart';

final profilePostCacheProvider = Provider((ref) => ProfilePostCache(ref));

class ProfilePostCache {
  final Ref ref;

  ProfilePostCache(this.ref) {
    _print('🔄 PPC: ProfilePostCache constructor called');
  }

  Future<Isar> get _profileIsar async {
    _print('💾 PPC: Getting Profile Isar instance');
    final isar = await ref.read(unifiedIsarProvider.future);
    _print('💾 PPC: Profile Isar instance obtained');
    return isar;
  }

  static const int _maxDiskCacheSizeProfile = 10000;
  static const int _diskCleanupThresholdProfile = 12000;

  Future<void> saveProfilePosts(String creatorId, List<MemoModelPost> posts) async {
    _print('👤 PPC: saveProfilePosts called for creator: $creatorId, posts: ${posts.length}');

    final validPosts = posts.where((post) => post.id != null && post.id!.isNotEmpty).toList();
    if (validPosts.isEmpty) {
      _print('❌ PPC: No valid posts to save');
      return;
    }

    _print('💾 PPC: Saving ${validPosts.length} valid posts to profile cache for creator: $creatorId');

    final isar = await _profileIsar;
    final postsDb = validPosts.map((post) => MemoModelPostDb.fromAppModel(post, postType: PostTypes.profile)).toList();

    try {
      _print('💾 PPC: Starting Isar transaction for saveProfilePosts');
      await isar.writeTxn(() async {
        // Delete existing posts for this creator
        _print('💾 PPC: Removing existing profile posts for creator: $creatorId');
        await isar.memoModelPostDbs.where().filter().creatorIdEqualTo(creatorId).postTypeEqualTo(PostTypes.profile.id).deleteAll();

        _print('💾 PPC: Inserting ${postsDb.length} posts to profile cache');
        await isar.memoModelPostDbs.putAll(postsDb);

        _print('✅ PPC: Successfully saved ${postsDb.length} posts to profile cache for creator: $creatorId');

        await _enforceProfileDiskSizeLimit(isar);
      });
      _print('✅ PPC: saveProfilePosts transaction completed successfully');
    } catch (e, stack) {
      _print('❌ PPC: ERROR in saveProfilePosts transaction: $e');
      _print('❌ PPC: Stack trace: $stack');
    }
  }
  //
  // Future<void> cacheProfilePosts(String creatorId, List<MemoModelPost> posts) async {
  //   _print('👤 PPC: cacheProfilePosts called for creator: $creatorId, posts: ${posts.length}');
  //   await saveProfilePosts(creatorId, posts);
  //   _print('✅ PPC: cacheProfilePosts completed for creator: $creatorId');
  // }

  Future<List<MemoModelPost>> getCachedProfilePosts(String creatorId) async {
    _print('👤 PPC: getCachedProfilePosts called for creator: $creatorId');

    final isar = await _profileIsar;
    try {
      final postsDb = await isar.memoModelPostDbs
          .where()
          .filter()
          .creatorIdEqualTo(creatorId)
          .postTypeEqualTo(PostTypes.profile.id)
          .sortByCreatedDateTimeDesc()
          .limit(ref.read(profileLimitProvider))
          .findAll();

      final posts = postsDb.map((db) => db.toAppModel()).toList();
      _print('💾 PPC: Found ${posts.length} profile posts in disk cache for creator: $creatorId');

      _print('✅ PPC: getCachedProfilePosts completed');
      return posts;
    } catch (e) {
      _print('❌ PPC: Error loading profile posts from disk: $e');
      return [];
    }
  }

  // --- Size Limit Enforcement ---
  Future<void> _enforceProfileDiskSizeLimit(Isar isar) async {
    _print('🧹 PPC: Checking profile disk size limit');
    final currentSize = await isar.memoModelPostDbs.where().postTypeEqualTo(PostTypes.profile.id).count();
    _print('🧹 PPC: Current profile disk cache size: $currentSize, threshold: $_diskCleanupThresholdProfile');

    if (currentSize <= _diskCleanupThresholdProfile) {
      _print('ℹ️ PPC: Profile disk size within limits, no cleanup needed');
      return;
    }

    final entriesToRemove = currentSize - _maxDiskCacheSizeProfile;
    _print('🧹 PPC: Need to remove $entriesToRemove entries from profile cache');

    // Remove oldest entries based on createdDateTime
    final oldEntries = await isar.memoModelPostDbs
        .where()
        .postTypeEqualTo(PostTypes.profile.id)
        .sortByCachedAt()
        .limit(entriesToRemove)
        .findAll();

    _print('🧹 PPC: Found ${oldEntries.length} old profile entries to remove');
    await isar.writeTxn(() async {
      await isar.memoModelPostDbs.deleteAll(oldEntries.map((e) => e.id).toList());
    });

    _print('🧹 PPC: Removed ${oldEntries.length} entries from profile cache (was $currentSize)');
  }

  void _print(String s) {
    if (kDebugMode) print(s);
  }
}
