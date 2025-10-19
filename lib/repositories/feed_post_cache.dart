// Updated feed_post_cache.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../main.dart';
import '../memo/isar/memo_model_post_db.dart';
import '../memo/model/memo_model_post.dart';
import '../provider/mute_creator_provider.dart';

final feedPostCacheProvider = Provider((ref) => FeedPostCache(ref));

class FeedPostCache {
  final Ref ref;
  int _totalLoadedItemsFromCache = 0;

  FeedPostCache(this.ref) {
    _print('🔄 FPC: FeedPostCache constructor called');
  }

  // Separate database getters
  Future<Isar> get _feedIsar async {
    _print('💾 FPC: Getting Feed Isar instance');
    final isar = ref.read(isarProvider);
    _print('💾 FPC: Feed Isar instance obtained');
    return isar;
  }

  static const int _maxDiskCacheSizeFeed = 10000;
  static const int _diskCleanupThresholdFeed = 12000;

  // Get muted creators list
  List<String> get _mutedCreators {
    return ref.read(muteCreatorProvider);
  }

  // Check if we can load more items
  // bool get canLoadMore {
  //   return _totalLoadedItemsFromCache < _currentFeedLimit;
  // }

  // Reset loaded items counter (call this when feed is rebuilt)
  void resetLoadedItems() {
    _print('🔄 FPC: Resetting loaded items counter');
    _totalLoadedItemsFromCache = 0;
  }

  // --- Feed Posts Operations ---

  Future<void> saveFeedPosts(List<MemoModelPost> posts) async {
    _print('💾 FPC: saveFeedPosts called with ${posts.length} posts');
    final validPosts = posts.where((post) => post.id != null && post.id!.isNotEmpty).toList();

    if (validPosts.isEmpty) {
      _print('❌ FPC: No valid posts to save (all muted or invalid)');
      return;
    }
    _print('💾 FPC: Saving ${validPosts.length} valid posts to feed cache (filtered from ${posts.length})');

    final isar = await _feedIsar;
    final postsDb = validPosts.map((post) => MemoModelPostDb.fromAppModel(post, postType: PostTypes.feed)).toList();

    try {
      _print('💾 FPC: Starting Isar transaction for saveFeedPosts');
      await isar.writeTxn(() async {
        // Delete existing posts then insert new ones
        final postIds = postsDb.map((p) => p.postId).toList();

        _print('💾 FPC: Removing any existing feed posts with same IDs');
        for (final postId in postIds) {
          await isar.memoModelPostDbs.where().postIdPostTypeEqualTo(postId, PostTypes.feed.id).deleteAll();
        }

        _print('💾 FPC: Inserting ${postsDb.length} posts to feed cache');
        await isar.memoModelPostDbs.putAll(postsDb);

        _print('✅ FPC: Successfully saved ${postsDb.length} posts to feed cache');

        await _enforceFeedDiskSizeLimit(isar);
      });
      _print('✅ FPC: saveFeedPosts transaction completed successfully');
    } catch (e, stack) {
      _print('❌ FPC: ERROR in saveFeedPosts transaction: $e');
      _print('❌ FPC: Stack trace: $stack');
    }
  }

  Future<List<MemoModelPost>?> getFeedPage(int pageNumber, int limit) async {
    _print('📄 FPC: getFeedPage called - page: $pageNumber');

    // Check if we can load more items
    if (_totalLoadedItemsFromCache >= limit) {
      _print('🚫 FPC: Maximum load limit reached, current {$_totalLoadedItemsFromCache} (max $limit items)');
      return null;
    }

    // If not in memory, try disk cache
    final isar = await _feedIsar;
    var count = await isar.memoModelPostDbs.count();
    _print('📄 FPC: total count isar: $count');
    try {
      // Calculate the offset for pagination
      // final offset = (pageNumber - 1) * FeedPostsNotifier.pageSize;

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
            // .offset(offset)
            // .limit(FeedPostsNotifier.pageSize)
            .findAll();
      } else {
        postsDb = await isar.memoModelPostDbs
            .where()
            .sortByCreatedDateTimeDesc()
            // .offset(offset)
            // .limit(FeedPostsNotifier.pageSize)
            .findAll();
      }

      // final posts = postsDb.map((db) => db.toAppModel()).toList();

      final List<MemoModelPost> posts = [];
      for (final db in postsDb) {
        posts.add(db.toAppModel());
      }

      if (posts.isNotEmpty) {
        _totalLoadedItemsFromCache += posts.length;
        _print('✅ FPC: Returning feed page from disk cache: ${posts.length} posts (total loaded: $_totalLoadedItemsFromCache/$limit)');
        return posts;
      }
    } catch (e) {
      _print('❌ FPC: Error loading feed page from disk: $e');
    }

    _print('❌ FPC: Feed page not found in cache: $pageNumber');
    return null;
  }

  // --- Size Limit Enforcement ---

  Future<void> _enforceFeedDiskSizeLimit(Isar isar) async {
    _print('🧹 FPC: Checking feed disk size limit');
    final currentSize = await isar.memoModelPostDbs.where().postTypeEqualTo(PostTypes.feed.id).count();
    _print('🧹 FPC: Current feed disk cache size: $currentSize, threshold: $_diskCleanupThresholdFeed');

    if (currentSize <= _diskCleanupThresholdFeed) {
      _print('ℹ️ FPC: Feed disk size within limits, no cleanup needed');
      return;
    }

    final entriesToRemove = currentSize - _maxDiskCacheSizeFeed;
    _print('🧹 FPC: Need to remove $entriesToRemove entries from feed cache');

    final oldEntries = await isar.memoModelPostDbs.where().postTypeEqualTo(PostTypes.feed.id).sortByCachedAt().limit(entriesToRemove).findAll();

    _print('🧹 FPC: Found ${oldEntries.length} old feed entries to remove');
    await isar.memoModelPostDbs.deleteAll(oldEntries.map((e) => e.id).toList());

    _print('🧹 FPC: Removed $entriesToRemove entries from feed cache (was $currentSize)');
  }

  void _print(String s) {
    if (kDebugMode) print(s);
  }
}
