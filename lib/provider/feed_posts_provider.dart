import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/config.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../memo/firebase/post_service_feed.dart';
import '../repositories/feed_post_cache.dart';
import '../repositories/post_repository.dart';

// --- State for the Feed ---
class FeedState {
  final List<MemoModelPost> posts;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final String? errorMessage;
  final bool isUsingCache;
  final int totalPostCount;
  final bool isRefreshing;
  final bool hasReachedCacheEnd;

  FeedState({
    this.posts = const [],
    this.isLoadingInitial = true,
    this.isLoadingMore = false,
    this.errorMessage,
    this.isUsingCache = false,
    this.totalPostCount = 0,
    this.isRefreshing = false,
    this.hasReachedCacheEnd = false,
  });

  FeedState copyWith({
    List<MemoModelPost>? posts,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    String? errorMessage,
    bool? isUsingCache,
    bool clearErrorMessage = false,
    int? totalPostCount,
    bool? isRefreshing,
    bool? hasReachedCacheEnd,
  }) {
    print('FPPR:🔄 FeedState.copyWith called - clearErrorMessage: $clearErrorMessage');
    print('FPPR:   Current posts: ${this.posts.length}, new posts: ${posts?.length}');
    return FeedState(
      posts: posts ?? this.posts,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      isUsingCache: isUsingCache ?? this.isUsingCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      totalPostCount: totalPostCount ?? this.totalPostCount,
      hasReachedCacheEnd: hasReachedCacheEnd ?? this.hasReachedCacheEnd,
    );
  }

  bool get hasMorePosts {
    final hasMore = posts.length < totalPostCount;
    print('FPPR:📊 FeedState.hasMorePosts: $hasMore (posts: ${posts.length}, total: $totalPostCount)');
    return hasMore;
  }
}

// --- StateNotifier ---
class FeedPostsNotifier extends StateNotifier<FeedState> {
  final PostServiceFeed _postService;
  final FeedPostCache _cacheRepository;
  static const int maxLoadItems = 30;
  static const int pageSize = 10;

  static const String _lastTotalCountKey = 'last_total_post_count';
  SharedPreferences? _prefs;

  FeedPostsNotifier(this._postService, this._cacheRepository) : super(FeedState()) {
    print('FPPR:🚀 FeedPostsNotifier constructor called');
    _initSharedPreferences().then((_) {
      fetchInitialPosts();
    });
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    print('FPPR:💾 SharedPreferences initialized');
  }

  @override
  void dispose() {
    print('FPPR:♻️ FeedPostsNotifier dispose called');
    super.dispose();
  }

  Future<void> fetchInitialPosts() async {
    print('FPPR:🔄 fetchInitialPosts called');
    state = FeedState(isLoadingInitial: true, posts: [], isUsingCache: false, hasReachedCacheEnd: false);
    print('FPPR:✅ State reset for initial fetch');
    await _loadInitialData();
  }

  Future<void> fetchMorePosts() async {
    print('FPPR:📥 fetchMorePosts called - isLoadingMore: ${state.isLoadingMore}, hasMorePosts: ${state.hasMorePosts}');

    if (state.isLoadingMore || !state.hasMorePosts) {
      print('FPPR:⏸️ fetchMorePosts skipped - condition not met');
      return;
    }

    state = state.copyWith(isLoadingMore: true, clearErrorMessage: true);
    print('FPPR:✅ State updated for loading more posts');

    await _loadMorePosts();
  }

  Future<void> _loadInitialData() async {
    print('FPPR:📄 _loadInitialData called');
    _cacheRepository.resetLoadedItems();
    try {
      await _fetchData(isInitial: true);
    } catch (e, s) {
      print('FPPR:❌ _loadInitialData ERROR: $e');
      _logFeedError("Error loading initial data", e, s);

      // Fallback: try to load from cache
      await _loadFromCache(isInitial: true, fallback: true);
    }
  }

  Future<void> refreshFeed() async {
    print('FPPR:🔄 refreshFeed called');

    try {
      state = state.copyWith(isRefreshing: true);
      await _fetchData(isInitial: false);
      print('FPPR:✅ Refresh completed');
    } catch (e, s) {
      print('FPPR:❌ refreshFeed ERROR: $e');
      _logFeedError("Error during refresh", e, s);

      state = state.copyWith(isRefreshing: false, errorMessage: "Refresh failed");
    }
  }

  Future<void> _fetchData({required bool isInitial}) async {
    // Get current total count from Firebase
    final int currentTotalCount = await _postService.getTotalPostCount();
    print('FPPR:📊 Current total post count: $currentTotalCount');

    if (currentTotalCount == -1) {
      throw Exception('Failed to get total post count');
    }

    // Get previous total count from SharedPreferences
    final int previousTotalCount = _prefs?.getInt(_lastTotalCountKey) ?? 0;
    print('FPPR:📊 Previous total post count: $previousTotalCount');

    // Update stored total count
    await _prefs?.setInt(_lastTotalCountKey, currentTotalCount);

    state = state.copyWith(totalPostCount: currentTotalCount);

    if (currentTotalCount > previousTotalCount) {
      // New posts available - fetch and cache them
      await _fetchAndCacheNewPosts(previousTotalCount, currentTotalCount);
    } else {
      // No new posts - load from cache
      await _loadFromCache(isInitial: isInitial);
    }

    if (!isInitial) {
      state = state.copyWith(isRefreshing: false);
    }
  }

  Future<void> _fetchAndCacheNewPosts(int previousCount, int currentCount) async {
    print('FPPR:🔄 _fetchAndCacheNewPosts - previous: $previousCount, current: $currentCount');

    final int newPostsCount = currentCount - previousCount;
    print('FPPR:📥 Fetching $newPostsCount new posts from Firebase');

    try {
      // Fetch all new posts from Firebase
      final List<MemoModelPost> newPosts = await _postService.getPostsPaginated(
        limit: previousCount == 0 ? pageSize : newPostsCount,
        startAfterDoc: null,
      );

      print('FPPR:🌐 New posts fetched: ${newPosts.length}');

      if (newPosts.isNotEmpty) {
        // Cache all new posts
        print('FPPR:💾 Caching ${newPosts.length} new posts');
        await _cacheRepository.saveFeedPosts(newPosts);
        print('FPPR:✅ New posts cached successfully');
      }

      // Now load from cache (which includes the new posts)
      await _loadFromCache(isInitial: true);
    } catch (e, s) {
      print('FPPR:❌ _fetchAndCacheNewPosts ERROR: $e');
      _logFeedError("Error fetching and caching new posts", e, s);
      throw e;
    }
  }

  Future<void> _loadFromCache({bool isInitial = true, bool fallback = false}) async {
    print('FPPR:💾 _loadFromCache - isInitial: $isInitial, fallback: $fallback');

    try {
      final pageNumber = isInitial ? 1 : (state.posts.length ~/ pageSize) + 1;
      print('FPPR:📄 Loading page $pageNumber from cache');

      final cachedPosts = await _cacheRepository.getFeedPage(pageNumber);
      print('FPPR:💾 Cache result - posts: ${cachedPosts?.length}');

      if (cachedPosts != null && cachedPosts.isNotEmpty) {
        // Successfully loaded from cache
        final newPosts = isInitial ? cachedPosts : [...state.posts, ...cachedPosts];

        state = state.copyWith(
          posts: newPosts,
          isLoadingInitial: false,
          isLoadingMore: false,
          isUsingCache: true,
          hasReachedCacheEnd: cachedPosts.length < pageSize,
          clearErrorMessage: true,
        );

        print('FPPR:✅ Loaded ${cachedPosts.length} posts from cache - total: ${state.posts.length}');

        // If we got less than a full page from cache, we've reached cache end
        if (cachedPosts.length < pageSize && state.hasMorePosts) {
          print('FPPR:🏁 Reached end of cache, next load will use network');
        }
      } else {
        // No posts in cache
        if (isInitial) {
          if (fallback) {
            // Even fallback failed - go to network
            print('FPPR:🌐 Cache fallback failed, fetching from network');
            await _fetchFromNetwork(isInitial: true);
          } else {
            // First load with no cache - go to network
            print('FPPR:🌐 No cache available, fetching from network');
            await _fetchFromNetwork(isInitial: true);
          }
        } else {
          // Loading more but cache is empty
          state = state.copyWith(isLoadingMore: false, hasReachedCacheEnd: true);
          print('FPPR:🏁 No more posts in cache');
        }
      }
    } catch (e, s) {
      print('FPPR:❌ _loadFromCache ERROR: $e');
      _logFeedError("Error loading from cache", e, s);

      if (isInitial && !fallback) {
        await _fetchFromNetwork(isInitial: true);
      } else {
        state = state.copyWith(isLoadingInitial: false, isLoadingMore: false, errorMessage: "Failed to load posts");
      }
    }
  }

  Future<void> _loadMorePosts() async {
    print('FPPR:📥 _loadMorePosts called');

    if (state.hasReachedCacheEnd) {
      // Load from network using last post ID as cursor
      await _fetchFromNetwork(isInitial: false);
    } else {
      // Load next page from cache
      await _loadFromCache(isInitial: false);
    }
  }

  Future<void> _fetchFromNetwork({bool isInitial = true}) async {
    print('FPPR:🌐 _fetchFromNetwork - isInitial: $isInitial');

    try {
      DocumentSnapshot? startAfterDoc;

      if (!isInitial && state.posts.isNotEmpty) {
        // Use last post's ID as cursor (since postId = Firestore document ID)
        final lastPost = state.posts.last;
        if (lastPost.id != null) {
          print('FPPR:📄 Using last post ID as cursor: ${lastPost.id}');
          // We need to get the document snapshot for the last post
          // This would require a method in PostService to get document by ID
          startAfterDoc = await _getDocumentSnapshot(lastPost.id!);
        }
      }

      final newPosts = await _postService.getPostsPaginated(limit: pageSize, startAfterDoc: startAfterDoc);

      print('FPPR:🌐 Network fetch completed - posts: ${newPosts.length}');

      if (newPosts.isNotEmpty) {
        // Cache the new posts
        await _cacheRepository.saveFeedPosts(newPosts);
        print('FPPR:💾 Cached ${newPosts.length} posts from network');

        // Update state
        final updatedPosts = isInitial ? newPosts : [...state.posts, ...newPosts];

        state = state.copyWith(
          posts: updatedPosts,
          isLoadingInitial: false,
          isLoadingMore: false,
          isUsingCache: false,
          hasReachedCacheEnd: newPosts.length < pageSize,
          clearErrorMessage: true,
        );

        print('FPPR:✅ Updated state with ${newPosts.length} new posts - total: ${state.posts.length}');
      } else {
        // No more posts from network
        state = state.copyWith(isLoadingInitial: false, isLoadingMore: false, hasReachedCacheEnd: true);
        print('FPPR:🏁 No more posts available from network');
      }
    } catch (e, s) {
      print('FPPR:❌ _fetchFromNetwork ERROR: $e');
      _logFeedError("Error fetching from network", e, s);

      state = state.copyWith(isLoadingInitial: false, isLoadingMore: false, errorMessage: "Failed to load posts from network");
    }
  }

  Future<DocumentSnapshot?> _getDocumentSnapshot(String postId) async {
    // This method would need to be implemented in PostService
    // to get a DocumentSnapshot by post ID
    print('FPPR:🔍 Getting document snapshot for post: $postId');
    // Placeholder implementation - you'll need to implement this
    try {
      // Assuming posts are stored in a 'posts' collection
      final doc = await FirebaseFirestore.instance.collection(FirestoreCollections.posts).doc(postId).get();
      return doc.exists ? doc : null;
    } catch (e) {
      print('FPPR:❌ Error getting document snapshot: $e');
      return null;
    }
  }
}

// --- Provider Definition ---
final feedPostsProvider = StateNotifierProvider<FeedPostsNotifier, FeedState>((ref) {
  print('FPPR:🏭 feedPostsProvider creating FeedPostsNotifier');
  return FeedPostsNotifier(ref.read(postServiceFeedProvider), ref.read(feedPostCacheProvider));
});

// Helper for logging
void _logFeedError(String message, [dynamic error, StackTrace? stackTrace]) {
  print(
    '\nFEED POSTS PROVIDER\nERROR FeedPostsNotifier: $message ${error != null ? '- $error' : ''}${stackTrace != null ? '\n$stackTrace' : ''}',
  );
}
