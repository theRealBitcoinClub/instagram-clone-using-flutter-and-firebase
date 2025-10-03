import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../memo/isar/memo_model_post_db.dart';
import '../memo/model/memo_model_post.dart';
import '../provider/isar_provider.dart';

final feedPostCacheProvider = Provider((ref) => FeedPostCache(ref));

class FeedPostCache {
  final Ref ref;

  FeedPostCache(this.ref) {
    print('🔄 FPC: FeedPostCache constructor called');
  }

  // Separate database getters
  Future<Isar> get _feedIsar async {
    print('💾 FPC: Getting Feed Isar instance');
    final isar = await ref.read(feedPostsIsarProvider.future);
    print('💾 FPC: Feed Isar instance obtained');
    return isar;
  }

  static const int _maxDiskCacheSizeFeed = 5000; // Increased disk cache size
  static const int _diskCleanupThresholdFeed = 6000; // 20% tolerance (6000 items)

  // Update post in both feed and profile databases
  Future<void> updatePostInFeedDatabase(MemoModelPost post) async {
    try {
      final postDb = MemoModelPostDb.fromAppModel(post);

      // Update in feed database
      final feedIsar = await _feedIsar;
      await feedIsar.writeTxn(() async {
        await feedIsar.memoModelPostDbs.put(postDb);
      });

      print('💾 FPC: Updated post in feed database: ${post.id}');
    } catch (e) {
      print('⚠️ FPC: Failed to update post in feed database: $e');
    }
  }

  // --- Feed Posts Operations ---

  Future<void> saveFeedPosts(List<MemoModelPost> posts) async {
    print('💾 FPC: saveFeedPosts called with ${posts.length} posts');
    final validPosts = posts.where((post) => post.id != null && post.id!.isNotEmpty).toList();
    if (validPosts.isEmpty) {
      print('❌ FPC: No valid posts to save');
      return;
    }
    print('💾 FPC: Saving ${validPosts.length} valid posts to feed cache');

    final isar = await _feedIsar;
    final postsDb = validPosts.map((post) => MemoModelPostDb.fromAppModel(post)).toList();

    try {
      print('💾 FPC: Starting Isar transaction for saveFeedPosts');
      await isar.writeTxn(() async {
        // Delete existing posts then insert new ones
        final postIds = postsDb.map((p) => p.postId).toList();

        print('💾 FPC: Removing any existing feed posts with same IDs');
        for (final postId in postIds) {
          await isar.memoModelPostDbs.where().postIdEqualTo(postId).deleteAll();
        }

        print('💾 FPC: Inserting ${postsDb.length} posts to feed cache');
        await isar.memoModelPostDbs.putAll(postsDb);

        print('✅ FPC: Successfully saved ${postsDb.length} posts to feed cache');

        await _enforceFeedDiskSizeLimit(isar);
      });
      print('✅ FPC: saveFeedPosts transaction completed successfully');
    } catch (e, stack) {
      print('❌ FPC: ERROR in saveFeedPosts transaction: $e');
      print('❌ FPC: Stack trace: $stack');
    }
  }

  Future<void> debugCheckFeedDiskCache() async {
    print('🔍 FPC: DEBUG - Checking feed disk cache contents');
    final isar = await _feedIsar;
    final currentSize = await isar.memoModelPostDbs.count();
    print('🔍 FPC: DEBUG - Feed disk cache size: $currentSize posts');

    // Also check what posts are actually in the cache
    final allPosts = await isar.memoModelPostDbs.where().findAll();
    print('🔍 FPC: DEBUG - Total posts in disk cache: ${allPosts.length}');

    // Group by creator to see distribution
    final creatorCounts = <String, int>{};
    for (final post in allPosts) {
      final creator = post.creatorId ?? 'unknown';
      creatorCounts[creator] = (creatorCounts[creator] ?? 0) + 1;
    }

    print('🔍 FPC: DEBUG - Posts by creator:');
    creatorCounts.forEach((creator, count) {
      print('🔍 FPC: DEBUG   - $creator: $count posts');
    });

    await _enforceFeedDiskSizeLimit(isar);
  }

  Future<List<MemoModelPost>?> getFeedPage(int pageNumber) async {
    print('📄 FPC: getFeedPage called - page: $pageNumber');

    // If not in memory, try disk cache
    final isar = await _feedIsar;
    try {
      final pageSize = 10;
      final offset = (pageNumber - 1) * pageSize;

      final postsDb = await isar.memoModelPostDbs.where().sortByCreatedDateTimeDesc().offset(offset).limit(pageSize).findAll();

      final posts = postsDb.map((db) => db.toAppModel()).toList();

      if (posts.isNotEmpty) {
        // _addPageToMemoryCache(cacheKey, posts, isFeed: true);
        print('✅ FPC: Returning feed page from disk cache: ${posts.length} posts');
        return posts;
      }
    } catch (e) {
      print('❌ FPC: Error loading feed page from disk: $e');
    }

    print('❌ FPC: Feed page not found in cache: $pageNumber');
    return null;
  }

  // --- Size Limit Enforcement ---

  Future<void> _enforceFeedDiskSizeLimit(Isar isar) async {
    print('🧹 FPC: Checking feed disk size limit');
    final currentSize = await isar.memoModelPostDbs.count();
    print('🧹 FPC: Current feed disk cache size: $currentSize, threshold: $_diskCleanupThresholdFeed');

    if (currentSize <= _diskCleanupThresholdFeed) {
      print('ℹ️ FPC: Feed disk size within limits, no cleanup needed');
      return;
    }

    final entriesToRemove = currentSize - _maxDiskCacheSizeFeed;
    print('🧹 FPC: Need to remove $entriesToRemove entries from feed cache');

    final oldEntries = await isar.memoModelPostDbs.where().limit(entriesToRemove).findAll();

    print('🧹 FPC: Found ${oldEntries.length} old feed entries to remove');
    await isar.memoModelPostDbs.deleteAll(oldEntries.map((e) => e.id).toList());

    print('🧹 FPC: Removed $entriesToRemove entries from feed cache (was $currentSize)');
  }

  Future<void> _enforceProfileDiskSizeLimit(Isar isar) async {
    print('🧹 FPC: Checking profile disk size limit');
    final currentSize = await isar.memoModelPostDbs.count();
    print('🧹 FPC: Current profile disk cache size: $currentSize, threshold: $_diskCleanupThresholdFeed');

    if (currentSize <= _diskCleanupThresholdFeed) {
      print('ℹ️ FPC: Profile disk size within limits, no cleanup needed');
      return;
    }

    final entriesToRemove = currentSize - _maxDiskCacheSizeFeed;
    print('🧹 FPC: Need to remove $entriesToRemove entries from profile cache');

    final oldEntries = await isar.memoModelPostDbs.where().limit(entriesToRemove).findAll();

    print('🧹 FPC: Found ${oldEntries.length} old profile entries to remove');
    await isar.memoModelPostDbs.deleteAll(oldEntries.map((e) => e.id).toList());

    print('🧹 FPC: Removed $entriesToRemove entries from profile cache (was $currentSize)');
  }
}
