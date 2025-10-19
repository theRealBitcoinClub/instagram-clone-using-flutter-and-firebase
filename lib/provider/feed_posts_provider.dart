import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/providers/token_limits_provider.dart';

import '../main.dart';
import '../memo/firebase/post_service_feed.dart';
import '../memo/isar/isar_shared_preferences.dart';
import '../repositories/feed_post_cache.dart';
import '../repositories/post_repository.dart';
import 'mute_creator_provider.dart';

// --- State for the Feed ---
class FeedState {
  final Ref ref;
  final List<MemoModelPost> posts;
  final bool isLoadingInitialAtTop;
  final bool isLoadingMorePostsAtBottom;
  final String? errorMessage;
  final int totalPostCountInFirebase;
  final bool isRefreshingByUserRequest;
  final bool hasReachedCacheEnd;
  final bool forceFetchFirebase;
  final int feedLimitForThisTier;
  // final bool isMaxFreeLimitReached;

  // List<MemoModelPost> get uniquePosts {
  //   final seenIds = <String>{};
  //   return posts.where((post) {
  //     if (seenIds.contains(post.id)) return false; // Remove duplicate
  //     seenIds.add(post.id!);
  //     return true;
  //   }).toList();
  // }

  List<MemoModelPost> _removeDuplicates(List<MemoModelPost> posts) {
    final seenIds = <String>{};
    return posts.where((post) {
      if (post.id == null) return true;
      if (seenIds.contains(post.id)) return false;
      seenIds.add(post.id!);
      return true;
    }).toList();
  }

  FeedState(
    this.ref, {
    this.posts = const [],
    this.isLoadingInitialAtTop = true,
    this.isLoadingMorePostsAtBottom = false,
    this.errorMessage,
    this.totalPostCountInFirebase = 0,
    this.isRefreshingByUserRequest = false,
    this.hasReachedCacheEnd = false,
    this.forceFetchFirebase = false,
    required this.feedLimitForThisTier,
    // this.isMaxFreeLimitReached = false,
  });

  FeedState copyWith({
    List<MemoModelPost>? posts,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearErrorMessage = false,
    int? totalPostCount,
    bool? isRefreshing,
    bool? hasReachedCacheEnd,
    bool? forceFetchFirebase,
    int? feedLimitForThisTier,
    // bool? isMaxFreeLimitReached,
  }) {
    final uniquePosts = posts != null ? _removeDuplicates(posts) : null;
    print('FPPR:🔄 FeedState.copyWith called - clearErrorMessage: $clearErrorMessage');
    print('FPPR:   Current posts: ${this.posts.length}, new posts: ${posts?.length}');
    return FeedState(
      ref,
      posts: uniquePosts ?? this.posts,
      isLoadingInitialAtTop: isLoadingInitial ?? this.isLoadingInitialAtTop,
      isLoadingMorePostsAtBottom: isLoadingMore ?? this.isLoadingMorePostsAtBottom,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      isRefreshingByUserRequest: isRefreshing ?? this.isRefreshingByUserRequest,
      totalPostCountInFirebase: totalPostCount ?? this.totalPostCountInFirebase,
      hasReachedCacheEnd: hasReachedCacheEnd ?? this.hasReachedCacheEnd,
      forceFetchFirebase: forceFetchFirebase ?? this.forceFetchFirebase,
      feedLimitForThisTier: feedLimitForThisTier ?? this.feedLimitForThisTier,
      // isMaxFreeLimitReached: isMaxFreeLimitReached ?? this.isMaxFreeLimitReached,
    );
  }

  bool get isMaxFreeLimit {
    return posts.length >= feedLimitForThisTier;
  }

  bool get hasMorePosts {
    final hasMore = posts.length < totalPostCountInFirebase;
    // print('FPPR:📊 FeedState.hasMorePosts: $hasMore (posts: ${posts.length}, total: $totalPostCountInFirebase)');
    return hasMore;
  }
}

// --- StateNotifier ---
class FeedPostsNotifier extends StateNotifier<FeedState> {
  final PostServiceFeed _postService;
  final FeedPostCache _cacheRepository;
  final Ref _ref; // Add Ref here
  int _currentFeedLimit = 0;

  // static const String _lastTotalCountKey = 'last_total_post_count';
  IsarSharedPreferences? _prefs;

  FeedPostsNotifier(this._ref, this._postService, this._cacheRepository)
    : _currentFeedLimit = _ref.read(feedLimitProvider),
      super(FeedState(_ref, feedLimitForThisTier: _ref.read(feedLimitProvider))) {
    print('FPPR:🚀 FeedPostsNotifier constructor called');

    _ref.listen<int>(feedLimitProvider, (previous, next) {
      _currentFeedLimit = next;
      state = state.copyWith(feedLimitForThisTier: _currentFeedLimit);
      print('FPPR:📊 Feed limit updated: $next');

      bool forceFetchAfterUpgrade = false;
      if (previous != null && previous < next) forceFetchAfterUpgrade = true;
      // Optionally trigger a refresh when limit changes
      fetchInitialPosts(forceFetchFire: forceFetchAfterUpgrade);
    });

    Future.microtask(() async {
      print('FPPR:🚀 FeedPostsNotifier constructor called _initSharedPreferences');
      await _initSharedPreferences();
      print('FPPR:🚀 FeedPostsNotifier constructor called _initSharedPreferences FINISHED');
      fetchInitialPosts();
      print('FPPR:🚀 FeedPostsNotifier constructor called fetchInitialPosts FINISHED');
    });
  }

  Future<void> _initSharedPreferences() async {
    try {
      _prefs = _ref.read(sharedPreferencesProvider);
      print('FPPR:💾 SharedPreferences initialized');
    } catch (e, s) {
      print('FPPR:❌ SharedPreferences initialization ERROR: $e');
      _logFeedError("Failed to initialize SharedPreferences", e, s);
    }
  }

  @override
  void dispose() {
    print('FPPR:♻️ FeedPostsNotifier dispose called');
    super.dispose();
  }

  Future<void> fetchInitialPosts({bool forceFetchFire = false}) async {
    print('FPPR:🔄 fetchInitialPosts called');
    state = FeedState(
      feedLimitForThisTier: _currentFeedLimit,
      _ref,
      isLoadingInitialAtTop: true,
      isLoadingMorePostsAtBottom: false,
      posts: [],
    ).copyWith(forceFetchFirebase: forceFetchFire);
    print('FPPR:✅ State reset for initial fetch');
    try {
      _cacheRepository.resetLoadedItems();
      await _fetchData();
    } catch (e, s) {
      _handleError("FPPR:❌ _loadInitialData", "Error loading initial data", e, s);
      try {
        await _loadFromCache();
      } catch (ex, st) {
        _handleError("Fallback", "Failed to load feed please restart the app or check your connection:", ex, st, setState: true);
      }
    } finally {
      state = state.copyWith(isLoadingInitial: false);
    }
  }

  Future<void> fetchMorePosts() async {
    print('FPPR:📥 fetchMorePosts called - isLoadingMore: ${state.isLoadingMorePostsAtBottom}, hasMorePosts: ${state.hasMorePosts}');

    if (state.isLoadingMorePostsAtBottom || !state.hasMorePosts) {
      print('FPPR:⏸️ fetchMorePosts skipped - condition not met');
      return;
    }

    state = resetTemporaryStates().copyWith(isLoadingMore: true, isLoadingInitial: false);
    print('FPPR:✅ State updated for loading more posts');

    if (hasReachedMaxPostsOfThisLimit()) {
      return;
    }

    try {
      if (state.hasReachedCacheEnd) {
        await _fetchFromNetwork();
      } else {
        await _loadFromCache();
      }
    } catch (e, s) {
      _handleError("fetchMorePosts", "Failed to load more posts:", e, s, setState: true);
    } finally {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  FeedState resetTemporaryStates() {
    state = state.copyWith(clearErrorMessage: true, isRefreshing: false);
    return state;
  }

  // bool _isFreeLimitReached() {
  //   final bool reached = state.posts.length >= _ref.read(feedLimitProvider);
  //   if (reached) {
  //     print('FPPR:💰 Free plan limit reached: ${state.posts.length}/${_ref.read(feedLimitProvider)}');
  //     // state = state.copyWith(isMaxFreeLimitReached: true);
  //   }
  //   return reached;
  // }

  Future<void> refreshFeed() async {
    print('FPPR:🔄 refreshFeed called');

    try {
      state = resetTemporaryStates().copyWith(isRefreshing: true, isLoadingInitial: true, isLoadingMore: false);
      await _fetchData();
      print('FPPR:✅ Refresh completed');
    } catch (e, s) {
      _handleError("refreshFeed", "Error during refresh", e, s, setState: true);
    } finally {
      state = state.copyWith(isRefreshing: false, isLoadingInitial: false);
    }
  }

  void _handleError(String methodName, String description, dynamic error, StackTrace? stackTrace, {bool setState = true}) {
    print('FPPR:❌ $methodName ERROR: $error');
    _logFeedError(description, error, stackTrace);
    if (setState) {
      state = state.copyWith(errorMessage: "$description: $error");
    }
  }

  Future<void> _fetchData() async {
    // Get current total count from Firebase
    final int currentTotalCount = await _postService.getTotalPostCount();
    print('FPPR:📊 Current total post count: $currentTotalCount');

    if (currentTotalCount == -1) {
      throw Exception('Failed to get total post count');
    }

    String lastTotalCountKey = 'last_total_post_count$_currentFeedLimit';
    // Get previous total count from SharedPreferences
    final int previousTotalCount = _prefs?.getInt(lastTotalCountKey) ?? 0;
    print('FPPR:📊 Previous total post count: $previousTotalCount');

    // Update stored total count
    await _prefs?.setInt(lastTotalCountKey, currentTotalCount);

    state = state.copyWith(totalPostCount: currentTotalCount);

    if (state.forceFetchFirebase || state.hasReachedCacheEnd || currentTotalCount > previousTotalCount) {
      // New posts available - fetch and cache them
      await _fetchAndCacheNewPosts(previousTotalCount, currentTotalCount, _currentFeedLimit);
    } else {
      // No new posts - load from cache
      await _loadFromCache();
    }
  }

  Future<void> _loadFromCache() async {
    print('FPPR:💾 _loadFromCache');

    // try {
    // Determine if this is initial load or loading more based on current state
    final bool isTopLoad = state.isLoadingInitialAtTop || state.isRefreshingByUserRequest;

    // final pageNumber = isTopLoad ? 1 : (state.posts.length ~/ pageSize) + 1;
    print('FPPR:📄 Loading page from cache (isTopLoad: $isTopLoad)');

    final cachedPosts = await _cacheRepository.getFeedPage(1, _currentFeedLimit);
    // final cachedPosts = await _cacheRepository.getFeedPage(pageNumber);
    print('FPPR:💾 Cache result - posts: ${cachedPosts?.length}');

    if (cachedPosts != null && cachedPosts.isNotEmpty) {
      // Successfully loaded from cache
      final newPosts = isTopLoad ? cachedPosts : [...state.posts, ...cachedPosts];

      state = state.copyWith(
        posts: newPosts,
        isLoadingInitial: false,
        // hasReachedCacheEnd: cachedPosts.length < pageSize,
        clearErrorMessage: true,
      );

      print('FPPR:✅ Loaded ${cachedPosts.length} posts from cache - total: ${state.posts.length}');

      // // If we got less than a full page from cache, we've reached cache end
      // if (cachedPosts.length < pageSize && state.hasMorePosts) {
      //   print('FPPR:🏁 Reached end of cache, next load will use network');
      //   // if (state.posts.length < pageSize) fetchInitialPosts();
      // }
    } else {
      // No posts in cache
      if (isTopLoad) {
        print('FPPR:🌐 No cache available, fetching from network');
        state = state.copyWith(isLoadingInitial: true, clearErrorMessage: true, totalPostCount: 0);
        await _fetchFromNetwork();
      } else {
        // Loading more but cache is empty
        state = state.copyWith(hasReachedCacheEnd: true);
        print('FPPR:🏁 No more posts in cache');
      }
    }
  }

  Future<List<MemoModelPost>?> _fetchPostsFromNetworkToFeedTheCache({required int limit, String? postId}) async {
    print('FPPR:🌐 _fetchPostsFromNetwork - limit: $limit, postId: ${postId != null}');
    if (hasReachedMaxPostsOfThisLimit()) {
      print('FPPR:🌐 _fetchPostsFromNetwork - state.totalPostCount >= maxLoadItems: ${state.posts.length} >= ${_currentFeedLimit}');
      return null;
    }

    try {
      final newPosts = await _postService
          .getPostsPaginated(limit: limit, postId: postId, mutedCreators: _ref.read(muteCreatorProvider))
          .timeout(Duration(seconds: 15));

      print('FPPR:🌐 Network fetch completed - posts: ${newPosts.length}');

      if (newPosts.isNotEmpty) {
        await _cacheRepository.saveFeedPosts(newPosts);
        print('FPPR:💾 Cached ${newPosts.length} posts from network');
      }

      return newPosts;
    } catch (e, s) {
      _handleError("_fetchPostsFromNetwork", "Error fetching posts from network", e, s);
      rethrow;
    }
  }

  bool hasReachedMaxPostsOfThisLimit() => state.posts.length >= _currentFeedLimit;

  Future<void> _fetchAndCacheNewPosts(int previousCount, int currentCount, int limit) async {
    print('FPPR:🔄 _fetchAndCacheNewPosts - previous: $previousCount, current: $currentCount');

    final int newPostsCount = currentCount - previousCount;
    print('FPPR:📥 Fetching $newPostsCount new posts from Firebase');
    print('FPPR:📥 Fetching as has reached end of cache ${state.hasReachedCacheEnd}');

    try {
      final newPosts = await _fetchPostsFromNetworkToFeedTheCache(
        limit: (previousCount == 0 || state.hasReachedCacheEnd || state.forceFetchFirebase) ? limit * 2 : newPostsCount,
        postId: null,
      );
      print('FPPR:🌐 New posts fetched: ${newPosts?.length ?? 0}');
      await _loadFromCache();
    } catch (e, s) {
      _handleError("_fetchAndCacheNewPosts", "Error fetching and caching new posts", e, s, setState: false);
      throw e;
    }
  }

  Future<void> _fetchFromNetwork() async {
    print('FPPR:🌐 _fetchFromNetwork - isLoadingInitial: ${state.isLoadingInitialAtTop}');

    try {
      String? lastPostId;
      if (!state.isLoadingInitialAtTop && state.posts.isNotEmpty) {
        final lastPost = state.posts.last;
        if (lastPost.id != null) {
          print('FPPR:📄 Using last post ID as cursor: ${lastPost.id}');
          lastPostId = lastPost.id!;
        }
      }

      final newPosts = await _fetchPostsFromNetworkToFeedTheCache(limit: _currentFeedLimit * 2, postId: lastPostId);

      if (newPosts != null && newPosts.isNotEmpty) {
        await _loadFromCache();
      } else {
        state = state.copyWith(hasReachedCacheEnd: true);
        print('FPPR:🏁 No more posts available from network');
      }
    } catch (e, s) {
      _handleError("_fetchFromNetwork", "Error fetching from network", e, s, setState: true);
    }
  }
}

// --- Provider Definition ---
final feedPostsProvider = StateNotifierProvider<FeedPostsNotifier, FeedState>((ref) {
  print('FPPR:🏭 feedPostsProvider creating FeedPostsNotifier');
  return FeedPostsNotifier(
    ref, // Pass ref here
    ref.read(postServiceFeedProvider),
    ref.read(feedPostCacheProvider),
  );
});

// Helper for logging
void _logFeedError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('FPPR: $message ${error != null ? '- $error' : ''}${stackTrace != null ? '\n$stackTrace' : ''}');
}
