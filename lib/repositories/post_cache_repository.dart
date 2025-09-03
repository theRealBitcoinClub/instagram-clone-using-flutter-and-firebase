// repositories/post_cache_repository.dart

import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';

import '../memo/isar/memo_model_post_db.dart';
import '../memo/scraper/memo_post_service.dart';
import '../provider/isar_provider.dart';
import '../provider/post_update_provider.dart';

final postCacheRepositoryProvider = Provider((ref) => PostCacheRepository(ref));

class PostCacheRepository {
  final Ref ref;

  // Memory cache for fast individual post access
  final _memoryCache = LinkedHashMap<String, MemoModelPost>();
  static const int _maxMemoryCacheSize = 200; // Keep 200 most recent posts in memory

  // Memory cache for paginated results (page-based caching)
  final _pageCache = LinkedHashMap<String, List<String>>(); // cacheKey -> list of post IDs
  static const int _maxPageCacheSize = 50; // Keep 50 most recent pages in memory

  PostCacheRepository(this.ref);

  Future<Isar> get _isar async => await ref.read(isarProvider.future);

  Future<void> updatePopularityScore(String postId, int newScore) async {
    MemoModelPost post = (await getPost(postId))!;

    MemoModelPost? scrapedPost = await MemoPostScraper().fetchAndParsePost(postId, filterOn: false);

    if (scrapedPost == null) {
      print("UPDATE POPULARITY FETCH UP TO DATE SCORE FAILED");
      return;
    } else {
      newScore += scrapedPost.popularityScore;
      post.popularityScore += newScore;
      await savePosts([post]);
      // Update just the popularity score in the provider
      ref.read(postPopularityProvider.notifier).updatePopularityScore(postId, post.popularityScore);
    } // return post.popularityScore!.toString();
  }

  // --- Memory Cache Management ---

  void _addToMemoryCache(MemoModelPost post) {
    if (post.id == null) return;

    // Add to memory cache (LRU behavior)
    _memoryCache.remove(post.id!);
    _memoryCache[post.id!] = post;

    // Enforce size limit
    if (_memoryCache.length > _maxMemoryCacheSize) {
      _memoryCache.remove(_memoryCache.keys.first);
    }
  }

  void _addPageToMemoryCache(String cacheKey, List<MemoModelPost> posts) {
    // Store only post IDs for page cache to save memory
    final postIds = posts.where((p) => p.id != null).map((p) => p.id!).toList();
    _pageCache.remove(cacheKey);
    _pageCache[cacheKey] = postIds;

    // Enforce size limit
    if (_pageCache.length > _maxPageCacheSize) {
      _pageCache.remove(_pageCache.keys.first);
    }

    // Also add individual posts to memory cache
    for (final post in posts) {
      if (post.id != null) {
        _addToMemoryCache(post);
      }
    }
  }

  void clearMemoryCache() {
    _memoryCache.clear();
    _pageCache.clear();
  }

  // --- Core Cache Operations ---

  // Save or update posts (both memory and disk)
  Future<void> savePosts(List<MemoModelPost> posts) async {
    final validPosts = posts.where((post) => post.id != null && post.id!.isNotEmpty).toList();
    if (validPosts.isEmpty) return;

    // Update memory cache
    for (final post in validPosts) {
      _addToMemoryCache(post);
    }

    // Update disk cache
    final isar = await _isar;
    final postsDb = validPosts.map((post) => MemoModelPostDb.fromAppModel(post)).toList();

    await isar.writeTxn(() async {
      await isar.memoModelPostDbs.putAll(postsDb);
    });
  }

  // Get a post by ID - check memory first, then disk
  Future<MemoModelPost?> getPost(String postId) async {
    // First check memory cache
    final memoryCached = _memoryCache[postId];
    if (memoryCached != null) {
      return memoryCached;
    }

    // Then check disk cache
    final isar = await _isar;
    final postDb = await isar.memoModelPostDbs.get(postId.hashCode);

    if (postDb != null) {
      final post = postDb.toAppModel();
      _addToMemoryCache(post);
      return post;
    }

    return null;
  }

  // --- Pagination Support (10 posts per page) ---

  // Generate cache key for paginated queries
  String _getPageCacheKey(int pageNumber, String? filter) {
    return 'page_${filter ?? 'all'}_$pageNumber';
  }

  // Save a page of posts to cache
  Future<void> savePage(List<MemoModelPost> posts, int pageNumber, {String? filter}) async {
    if (posts.isEmpty) return;

    final cacheKey = _getPageCacheKey(pageNumber, filter);

    // Save to memory cache
    _addPageToMemoryCache(cacheKey, posts);
    //TODO check how to avoid save twice to cache
    // Save individual posts to disk
    await savePosts(posts);

    // Save page metadata to disk (optional, for persistence across app restarts)
    final isar = await _isar;
    //always silent because data that triggers an update is always from firebase after scraping
    await isar.writeTxn(silent: true, () async {
      // You could store page metadata here if needed
    });
  }

  // Get a page from cache - returns null if not cached or stale
  Future<List<MemoModelPost>?> getPage(int pageNumber, {String? filter, Duration maxAge = const Duration(minutes: 15)}) async {
    final cacheKey = _getPageCacheKey(pageNumber, filter);

    // First check memory cache
    final memoryPageIds = _pageCache[cacheKey];
    if (memoryPageIds != null) {
      // Get posts from memory cache
      final posts = memoryPageIds.map((id) => _memoryCache[id]).whereType<MemoModelPost>().toList();
      if (posts.length == memoryPageIds.length) {
        return posts; // Full page found in memory
      }
    }

    // If not in memory, try to reconstruct from disk cache
    // This is more complex and may not be needed for your use case
    // For simplicity, we'll primarily use memory cache for pages

    return null;
  }

  // Check if a page is available in cache
  bool hasPage(int pageNumber, {String? filter}) {
    final cacheKey = _getPageCacheKey(pageNumber, filter);
    return _pageCache.containsKey(cacheKey);
  }

  // Clear cache for a specific page
  void clearPage(int pageNumber, {String? filter}) {
    final cacheKey = _getPageCacheKey(pageNumber, filter);
    _pageCache.remove(cacheKey);
  }

  // Clear all pages for a filter (useful when filter changes)
  void clearPagesForFilter(String? filter) {
    final keysToRemove = _pageCache.keys.where((key) => key.contains('_${filter ?? 'all'}_')).toList();
    for (final key in keysToRemove) {
      _pageCache.remove(key);
    }
  }

  // --- Profile Posts Support ---

  // Cache profile posts (used by profile screen)
  Future<void> cacheProfilePosts(String creatorId, List<MemoModelPost> posts) async {
    // Save individual posts
    await savePosts(posts);

    // Also cache as a "page" for potential reuse
    final cacheKey = 'profile_$creatorId';
    _addPageToMemoryCache(cacheKey, posts);
  }

  // Get cached profile posts
  Future<List<MemoModelPost>> getCachedProfilePosts(String creatorId) async {
    final cacheKey = 'profile_$creatorId';
    final memoryPageIds = _pageCache[cacheKey];

    if (memoryPageIds != null) {
      final posts = memoryPageIds.map((id) => _memoryCache[id]).whereType<MemoModelPost>().toList();
      if (posts.isNotEmpty) {
        return posts;
      }
    }

    // Fall back to querying disk cache by creatorId using filter
    final isar = await _isar;
    final postsDb = await isar.memoModelPostDbs
        .where()
        .filter()
        .creatorIdEqualTo(creatorId) // Now works with filter()
        .sortByCreatedDateTimeDesc()
        .limit(100)
        .findAll();

    final posts = postsDb.map((db) => db.toAppModel()).toList();

    if (posts.isNotEmpty) {
      _addPageToMemoryCache(cacheKey, posts);
    }

    return posts;
  }

  // --- Cache Management ---

  Future<int> clearExpiredCache({Duration maxAge = const Duration(days: 7)}) async {
    final isar = await _isar;
    final cutoff = DateTime.now().toUtc().subtract(maxAge);

    // Clear memory cache
    clearMemoryCache();

    // Clear old disk cache entries
    return await isar.writeTxn(() async {
      return await isar.memoModelPostDbs.where().cachedAtLessThan(cutoff).deleteAll();
    });
  }

  Future<void> clearAllCache() async {
    clearMemoryCache();

    final isar = await _isar;
    await isar.writeTxn(() async {
      await isar.memoModelPostDbs.clear();
    });
  }

  // Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {'memoryPosts': _memoryCache.length, 'memoryPages': _pageCache.length, 'totalMemoryItems': _memoryCache.length + _pageCache.length};
  }

  // Preload posts into memory cache
  Future<void> preloadPosts(List<String> postIds) async {
    final postsToLoad = <String>[];

    // Filter out posts already in memory
    for (final postId in postIds) {
      if (!_memoryCache.containsKey(postId)) {
        postsToLoad.add(postId);
      }
    }

    if (postsToLoad.isEmpty) return;

    // Load missing posts from disk
    final isar = await _isar;
    final postsDb = await isar.memoModelPostDbs.getAll(postsToLoad.map((id) => id.hashCode).toList());

    for (final postDb in postsDb) {
      if (postDb != null) {
        final post = postDb.toAppModel();
        _addToMemoryCache(post);
      }
    }
  }
}
