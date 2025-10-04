// Updated feed_post_cache.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mahakka/provider/feed_posts_provider.dart';

import '../memo/isar/memo_model_post_db.dart';
import '../memo/model/memo_model_post.dart';
import '../provider/isar_provider.dart';
import '../provider/mute_creator_provider.dart';

final feedPostCacheProvider = Provider((ref) => FeedPostCache(ref));

class FeedPostCache {
  final Ref ref;
  int _totalLoadedItemsFromCache = 0;

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

  static const int _maxDiskCacheSizeFeed = 50;
  static const int _diskCleanupThresholdFeed = 60;

  // Get muted creators list
  List<String> get _mutedCreators {
    return ref.read(muteCreatorProvider);
  }

  // Check if we can load more items
  bool get canLoadMore {
    return _totalLoadedItemsFromCache < FeedPostsNotifier.maxLoadItems;
  }

  // Reset loaded items counter (call this when feed is rebuilt)
  void resetLoadedItems() {
    print('🔄 FPC: Resetting loaded items counter');
    _totalLoadedItemsFromCache = 0;
  }

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

    // Filter out posts from muted creators before saving
    // final mutedCreators = _mutedCreators;
    final validPosts = posts.where((post) => post.id != null && post.id!.isNotEmpty).toList();

    if (validPosts.isEmpty) {
      print('❌ FPC: No valid posts to save (all muted or invalid)');
      return;
    }
    print('💾 FPC: Saving ${validPosts.length} valid posts to feed cache (filtered from ${posts.length})');

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

  Future<List<MemoModelPost>?> getFeedPage(int pageNumber) async {
    print('📄 FPC: getFeedPage called - page: $pageNumber');

    // Check if we can load more items
    if (!canLoadMore) {
      print('🚫 FPC: Maximum load limit reached, current {$_totalLoadedItemsFromCache} (max ${FeedPostsNotifier.maxLoadItems} items)');
      return null;
    }

    // If not in memory, try disk cache
    final isar = await _feedIsar;
    try {
      // Calculate the offset for pagination
      final offset = (pageNumber - 1) * FeedPostsNotifier.pageSize;

      // Get muted creators for filtering
      final mutedCreators = _mutedCreators;

      final postsDb;
      // If there are muted creators, filter them out
      if (mutedCreators.isNotEmpty) {
        postsDb = await isar.memoModelPostDbs
            .filter()
            .not()
            .anyOf(mutedCreators, (q, String creatorId) => q.creatorIdEqualTo(creatorId))
            .sortByCreatedDateTimeDesc()
            .offset(offset)
            .limit(FeedPostsNotifier.pageSize)
            .findAll();
      } else {
        postsDb = await isar.memoModelPostDbs.where().sortByCreatedDateTimeDesc().offset(offset).limit(FeedPostsNotifier.pageSize).findAll();
      }

      // final posts = postsDb.map((db) => db.toAppModel()).toList();

      final List<MemoModelPost> posts = [];
      for (final db in postsDb) {
        posts.add(db.toAppModel());
      }

      if (posts.isNotEmpty) {
        _totalLoadedItemsFromCache += posts.length;
        print(
          '✅ FPC: Returning feed page from disk cache: ${posts.length} posts (total loaded: $_totalLoadedItemsFromCache/${FeedPostsNotifier.maxLoadItems})',
        );
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

    final oldEntries = await isar.memoModelPostDbs.where().sortByCachedAt().limit(entriesToRemove).findAll();

    print('🧹 FPC: Found ${oldEntries.length} old feed entries to remove');
    await isar.memoModelPostDbs.deleteAll(oldEntries.map((e) => e.id).toList());

    print('🧹 FPC: Removed $entriesToRemove entries from feed cache (was $currentSize)');
  }
}
