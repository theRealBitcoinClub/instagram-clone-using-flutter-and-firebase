import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../memo/isar/memo_model_post_db.dart';
import '../memo/model/memo_model_post.dart';
import '../memo/model/memo_model_user.dart';
import '../provider/isar_provider.dart';
import '../provider/popularity_score_cache.dart';
import '../provider/post_update_provider.dart';
import '../provider/user_provider.dart';

final postCacheRepositoryProvider = Provider((ref) => PostCacheRepository(ref));

class PostCacheRepository {
  final Ref ref;

  // Memory cache for posts - NO TIME EXPIRATION NEEDED
  final _memoryCache = LinkedHashMap<String, MemoModelPost>();
  static const int _maxMemoryCacheSize = 500;

  // Memory cache for paginated results - NO TIME EXPIRATION NEEDED
  final _pageCache = LinkedHashMap<String, List<String>>();
  static const int _maxPageCacheSize = 50;

  // Popularity score cache - THIS STILL NEEDS EXPIRATION
  final PopularityScoreCache _popularityCache = PopularityScoreCache();

  PostCacheRepository(this.ref);

  Future<Isar> get _isar async => await ref.read(isarProvider.future);

  static const int _maxDiskCacheSize = 5000; // Increased disk cache size
  static const int _diskCleanupThreshold = 6000; // 20% tolerance (6000 items)

  Future<void> updatePopularityScore(String postId, {int tipAmount = 0, MemoModelPost? scrapedPost, bool saveToFirebase = false}) async {
    MemoModelPost? post = await _getPostWithPopularityScore(postId);
    if (post == null) return;

    final TipReceiver receiver = ref.read(userProvider)!.tipReceiver;
    if (receiver == TipReceiver.app) return;

    final (int burnAmount, int creatorAmount) = receiver.calculateAmounts(tipAmount);
    final int creatorTipAmount = creatorAmount;

    int newScore;
    if (scrapedPost == null) {
      print("UPDATE POPULARITY FETCH UP TO DATE SCORE FAILED");
      newScore = post.popularityScore + creatorTipAmount;
    } else {
      newScore = scrapedPost.popularityScore + creatorTipAmount;
    }

    // Update popularity cache (this still needs expiration)
    _popularityCache.put(postId, newScore);

    // Update memory cache if post exists
    if (_memoryCache.containsKey(postId)) {
      final updatedPost = _memoryCache[postId]!.copyWith(popularityScore: newScore);
      _memoryCache[postId] = updatedPost;
    }

    // Update disk cache
    final updatedPost = post.copyWith(popularityScore: newScore);
    await savePosts([updatedPost]);

    ref.read(postPopularityProvider.notifier).updatePopularityScore(postId, newScore);
  }

  // --- Memory Cache Management ---

  void _addToMemoryCache(MemoModelPost post) {
    if (post.id == null) return;

    // NO TIME-BASED CLEANUP - posts are immutable
    _memoryCache.remove(post.id!);
    _memoryCache[post.id!] = post;

    // Only enforce size limit
    if (_memoryCache.length > _maxMemoryCacheSize) {
      final lruKey = _memoryCache.keys.first;
      _memoryCache.remove(lruKey);
    }
  }

  void _addPageToMemoryCache(String cacheKey, List<MemoModelPost> posts) {
    final postIds = posts.where((p) => p.id != null).map((p) => p.id!).toList();

    // NO TIME-BASED CLEANUP - pages are immutable
    _pageCache.remove(cacheKey);
    _pageCache[cacheKey] = postIds;

    // Only enforce size limit
    if (_pageCache.length > _maxPageCacheSize) {
      final lruKey = _pageCache.keys.first;
      _pageCache.remove(lruKey);
    }

    for (final post in posts) {
      if (post.id != null) {
        _addToMemoryCache(post);
      }
    }
  }

  // void clearMemoryCache() {
  //   _memoryCache.clear();
  //   _pageCache.clear();
  // }

  // --- Core Cache Operations ---

  Future<void> savePosts(List<MemoModelPost> posts) async {
    final validPosts = posts.where((post) => post.id != null && post.id!.isNotEmpty).toList();
    if (validPosts.isEmpty) return;

    for (final post in validPosts) {
      _addToMemoryCache(post);
    }

    final isar = await _isar;
    final postsDb = validPosts.map((post) => MemoModelPostDb.fromAppModel(post)).toList();

    await isar.writeTxn(() async {
      // Use upsert to handle duplicates via the unique postId index
      await isar.memoModelPostDbs.putAll(postsDb);

      // Enforce FIFO size limit with tolerance
      await _enforceDiskSizeLimit(isar);
    });
  }

  // Future<void> savePosts(List<MemoModelPost> posts) async {
  //   final validPosts = posts.where((post) => post.id != null && post.id!.isNotEmpty).toList();
  //   if (validPosts.isEmpty) return;
  //
  //   for (final post in validPosts) {
  //     _addToMemoryCache(post);
  //   }
  //
  //   final isar = await _isar;
  //   final postsDb = validPosts.map((post) => MemoModelPostDb.fromAppModel(post)).toList();
  //
  //   await isar.writeTxn(() async {
  //     await isar.memoModelPostDbs.putAll(postsDb);
  //   });
  // }

  /// Enforce FIFO size limit only when significantly over limit
  Future<void> _enforceDiskSizeLimit(Isar isar) async {
    final currentSize = await isar.memoModelPostDbs.count();
    if (currentSize <= _diskCleanupThreshold) return;

    final entriesToRemove = currentSize - _maxDiskCacheSize;

    // Fast FIFO using primary key sort (autoIncrement ID = insertion order)
    final oldEntries = await isar.memoModelPostDbs
        .where()
        .limit(entriesToRemove) // No sort needed - natural order is FIFO!
        .findAll();

    await isar.memoModelPostDbs.deleteAll(oldEntries.map((e) => e.id).toList());

    print('🧹 PostCache: Removed $entriesToRemove entries (was $currentSize)');
  }

  // Update getPost to use the postId index:
  Future<MemoModelPost?> _getPostWithPopularityScore(String postId) async {
    // Check memory cache - NO EXPIRATION CHECK
    final memoryCached = _memoryCache[postId];
    if (memoryCached != null) {
      return _enhancePostWithLatestPopularity(memoryCached);
    }

    // Check disk cache using postId index
    final isar = await _isar;
    final postDb = await isar.memoModelPostDbs.where().postIdEqualTo(postId).findFirst();

    if (postDb != null) {
      final post = postDb.toAppModel();
      _addToMemoryCache(post);
      return _enhancePostWithLatestPopularity(post);
    }

    return null;
  }

  MemoModelPost _enhancePostWithLatestPopularity(MemoModelPost post) {
    final latestScore = _popularityCache.get(post.id!);
    if (latestScore != null && latestScore != post.popularityScore) {
      return post.copyWith(popularityScore: latestScore);
    }
    return post;
  }

  // --- Pagination Support ---

  String _getPageCacheKey(int pageNumber, String? filter) {
    return 'page_${filter ?? 'all'}_$pageNumber';
  }

  Future<void> savePage(List<MemoModelPost> posts, int pageNumber, {String? filter}) async {
    if (posts.isEmpty) return;

    final cacheKey = _getPageCacheKey(pageNumber, filter);

    _addPageToMemoryCache(cacheKey, posts);
    await savePosts(posts);

    final isar = await _isar;
    await isar.writeTxn(silent: true, () async {});
  }

  Future<List<MemoModelPost>?> getPage(int pageNumber, {String? filter, Duration maxAge = const Duration(minutes: 15)}) async {
    final cacheKey = _getPageCacheKey(pageNumber, filter);

    // IGNORE maxAge parameter - posts are immutable, cache never expires
    final memoryPageIds = _pageCache[cacheKey];
    if (memoryPageIds != null) {
      final posts = <MemoModelPost>[];
      for (final id in memoryPageIds) {
        final post = _memoryCache[id];
        if (post != null) {
          posts.add(_enhancePostWithLatestPopularity(post));
        }
      }

      if (posts.length == memoryPageIds.length) {
        return posts;
      } else {
        // Some posts missing from memory cache, remove the page
        _pageCache.remove(cacheKey);
      }
    }

    return null;
  }

  // bool hasPage(int pageNumber, {String? filter}) {
  //   final cacheKey = _getPageCacheKey(pageNumber, filter);
  //
  //   // Simply check if page exists - no expiration
  //   return _pageCache.containsKey(cacheKey);
  // }
  //
  // void clearPage(int pageNumber, {String? filter}) {
  //   final cacheKey = _getPageCacheKey(pageNumber, filter);
  //   _pageCache.remove(cacheKey);
  // }

  void clearPagesForFilter(String? filter) {
    final keysToRemove = _pageCache.keys.where((key) => key.contains('_${filter ?? 'all'}_')).toList();
    for (final key in keysToRemove) {
      _pageCache.remove(key);
    }
  }

  // --- Profile Posts Support ---

  Future<void> cacheProfilePosts(String creatorId, List<MemoModelPost> posts) async {
    await savePosts(posts);
    final cacheKey = 'profile_$creatorId';
    _addPageToMemoryCache(cacheKey, posts);
  }

  Future<List<MemoModelPost>> getCachedProfilePosts(String creatorId) async {
    final cacheKey = 'profile_$creatorId';
    final memoryPageIds = _pageCache[cacheKey];

    if (memoryPageIds != null) {
      final posts = memoryPageIds.map((id) => _memoryCache[id]).whereType<MemoModelPost>().toList();
      if (posts.isNotEmpty) {
        return posts.map(_enhancePostWithLatestPopularity).toList();
      }
    }

    final isar = await _isar;
    final postsDb = await isar.memoModelPostDbs.where().filter().creatorIdEqualTo(creatorId).sortByCreatedDateTimeDesc().limit(100).findAll();

    final posts = postsDb.map((db) => db.toAppModel()).toList();

    if (posts.isNotEmpty) {
      _addPageToMemoryCache(cacheKey, posts);
    }

    return posts;
  }

  // --- Cache Management ---

  // Future<int> clearExpiredCache({Duration maxAge = const Duration(days: 7)}) async {
  //   final isar = await _isar;
  //   final cutoff = DateTime.now().toUtc().subtract(maxAge);
  //
  //   // Only clear popularity cache (posts don't expire)
  //   _popularityCache.clearExpired();
  //
  //   // Disk cache cleanup for very old entries (optional housekeeping)
  //   return await isar.writeTxn(() async {
  //     return await isar.memoModelPostDbs.where().cachedAtLessThan(cutoff).deleteAll();
  //   });
  // }
  //
  // Future<void> clearAllCache() async {
  //   clearMemoryCache();
  //   _popularityCache.clearExpired();
  //
  //   final isar = await _isar;
  //   await isar.writeTxn(() async {
  //     await isar.memoModelPostDbs.clear();
  //   });
  // }
  //
  // Map<String, dynamic> getCacheStats() {
  //   return {'memoryPosts': _memoryCache.length, 'memoryPages': _pageCache.length, 'popularityScores': _popularityCache.scoreCache.length};
  // }

  // Update preloadPosts to use postId index:
  // Future<void> preloadPosts(List<String> postIds) async {
  //   final postsToLoad = <String>[];
  //
  //   for (final postId in postIds) {
  //     if (!_memoryCache.containsKey(postId)) {
  //       postsToLoad.add(postId);
  //     }
  //   }
  //
  //   if (postsToLoad.isEmpty) return;
  //
  //   final isar = await _isar;
  //
  //   // Load posts using postId index in batches for efficiency
  //   for (final postId in postsToLoad) {
  //     final postDb = await isar.memoModelPostDbs
  //         .where()
  //         .postIdEqualTo(postId)
  //         .findFirst();
  //
  //     if (postDb != null) {
  //       final post = postDb.toAppModel();
  //       _addToMemoryCache(post);
  //     }
  //   }
  // }
}
