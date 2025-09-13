import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/firebase/post_service.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/repositories/post_cache_repository.dart';
import 'package:mahakka/screens/feed_screen.dart';

import '../memo/firebase/post_service_provider.dart'; // For PostFilterType

// --- State for the Feed ---
class FeedState {
  final List<MemoModelPost> posts;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final String? errorMessage;
  final DocumentSnapshot? lastDocument;
  final PostFilterType? activeFilter;
  final bool isUsingCache;
  final int totalPostCount;
  final bool isRefreshing;
  //TODO Post Counter is tricky because it must persist the last post count and
  // there might be posts included in the total number that are not visible on the feed (videos)
  final bool showPostCounter; // Add this field

  FeedState({
    this.posts = const [],
    this.isLoadingInitial = true,
    this.isLoadingMore = false,
    this.errorMessage,
    this.lastDocument,
    this.activeFilter,
    this.isUsingCache = false,
    this.totalPostCount = 0,
    this.isRefreshing = false,
    //TODO check that the feed_screen is repainted
    this.showPostCounter = false, // Initialize to false
  });

  FeedState copyWith({
    List<MemoModelPost>? posts,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    String? errorMessage,
    DocumentSnapshot? lastDocument,
    bool? isUsingCache,
    bool clearErrorMessage = false,
    PostFilterType? activeFilter,
    int? totalPostCount,
    bool? isRefreshing,
    bool? showPostCounter, // Add to copyWith
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      lastDocument: lastDocument ?? this.lastDocument,
      activeFilter: activeFilter ?? this.activeFilter,
      isUsingCache: isUsingCache ?? this.isUsingCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      totalPostCount: totalPostCount ?? this.totalPostCount,
      showPostCounter: showPostCounter ?? this.showPostCounter, // Include in copy
    );
  }

  get hasMorePosts {
    return posts.length < totalPostCount;
  }
}

// --- StateNotifier ---
class FeedPostsNotifier extends StateNotifier<FeedState> {
  final PostService _postService;
  final PostCacheRepository _cacheRepository;
  final int _pageSize = 100; // Changed from 50 to 10

  int _lastKnownPostCount = 0; // Track last known count for comparison

  FeedPostsNotifier(this._postService, this._cacheRepository) : super(FeedState()) {
    fetchInitialPosts();
    _setupPostCounterListener();
  }

  // Add post counter listener
  void _setupPostCounterListener() {
    // Listen to Firestore for post count changes
    FirebaseFirestore.instance.collection('metadata').doc('posts').snapshots().listen((snapshot) {
      if (snapshot.exists && mounted) {
        final newCount = snapshot.data()?['count'] as int? ?? 0;

        // Show counter if count increased since last check and we have posts loaded
        if (newCount > _lastKnownPostCount && state.posts.isNotEmpty) {
          state = state.copyWith(
            showPostCounter: true,
            totalPostCount: newCount, // Also update total count
          );
        }

        // Update last known count
        _lastKnownPostCount = newCount;
      }
    });
  }

  // Method to hide the post counter
  void hidePostCounter() {
    if (state.showPostCounter) {
      state = state.copyWith(showPostCounter: false);
    }
  }

  // Method to manually show the post counter (if needed)
  void showPostCounter() {
    if (!state.showPostCounter) {
      state = state.copyWith(showPostCounter: true);
    }
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }

  Future<void> fetchInitialPosts() async {
    // Reset state for a new initial fetch, keeping the current activeFilter
    state = FeedState(
      isLoadingInitial: true,
      activeFilter: state.activeFilter,
      lastDocument: null,
      // hasMorePosts: true,
      posts: [],
      isUsingCache: false,
    );
    await _fetchPostsPage(isInitial: true);
  }

  Future<void> fetchMorePosts() async {
    if (state.isLoadingMore || !state.hasMorePosts) return;

    state = state.copyWith(
      isLoadingMore: true,
      clearErrorMessage: true,
      isLoadingInitial: false,
      lastDocument: state.lastDocument,
      // hasMorePosts: state.hasMorePosts,
      posts: state.posts,
      activeFilter: state.activeFilter,
      errorMessage: null,
    );
    await _fetchPostsPage(isInitial: false);
  }
  // In your feed_posts_provider.dart - FIXED VERSION

  Future<void> _fetchPostsPage({required bool isInitial}) async {
    try {
      final DocumentSnapshot? cursorForThisFetch = isInitial ? null : state.lastDocument;

      // Calculate current page number
      var totalPostsLoadedCounter = state.posts.length;
      final pageIndex = isInitial ? 1 : (totalPostsLoadedCounter ~/ _pageSize) + 1;
      final cacheKey = _getCacheKey(pageIndex);

      List<MemoModelPost> newPosts;
      bool fromCache = false;

      if (isInitial) {
        // Get total count on initial load
        final totalCount = await _postService.getTotalPostCount();
        if (totalCount != -1) {
          state = state.copyWith(totalPostCount: totalCount);
        }
        // Try cache first for initial load
        final cachedPosts = await _cacheRepository.getPage(pageIndex, filter: state.activeFilter?.name);
        if (cachedPosts != null && cachedPosts.isNotEmpty) {
          newPosts = cachedPosts;
          fromCache = true;
          print("\nFEED POSTS PROVIDER\nUsing cached page $pageIndex with ${newPosts.length} posts");
        } else {
          // Fall back to network
          newPosts = await _postService.getPostsPaginated(limit: _pageSize, startAfterDoc: cursorForThisFetch);
          // Cache the new results
          if (newPosts.isNotEmpty) {
            await _cacheRepository.savePage(newPosts, pageIndex, filter: state.activeFilter?.name);
          }
        }
      } else {
        // For "load more", always use network to ensure correct pagination
        newPosts = await _postService.getPostsPaginated(limit: _pageSize, startAfterDoc: cursorForThisFetch);

        // **CRITICAL FIX: Check for duplicates before adding to state**
        //TODO THIS SHOULDNT BE HAPPENING FIX THE ALGORITHM INSTEAD
        final existingPostIds = state.posts.map((post) => post.id).whereType<String>().toSet();
        final uniqueNewPosts = newPosts.where((post) => post.id != null && !existingPostIds.contains(post.id)).toList();

        // If we filtered out duplicates, use the unique ones
        if (uniqueNewPosts.length != newPosts.length) {
          print("\nFEED POSTS PROVIDER\nFiltered out ${newPosts.length - uniqueNewPosts.length} duplicate posts");
          newPosts = uniqueNewPosts;
        }

        // Cache the new results
        if (newPosts.isNotEmpty) {
          await _cacheRepository.savePage(newPosts, pageIndex, filter: state.activeFilter?.name);
        }
      }

      if (!mounted) return;

      DocumentSnapshot? newLastDocumentForState = newPosts.isNotEmpty ? newPosts.last.docSnapshot : null;

      state = state.copyWith(
        posts: isInitial ? newPosts : [...state.posts, ...newPosts],
        isLoadingInitial: false,
        isLoadingMore: false,
        activeFilter: state.activeFilter,
        clearErrorMessage: true,
        lastDocument: newLastDocumentForState ?? (isInitial ? null : state.lastDocument),
        // hasMorePosts: newPosts.length == _pageSize, // Still check against original page size
        errorMessage: null,
        isUsingCache: fromCache,
      );
    } catch (e, s) {
      _logFeedError("Error fetching posts page", e, s);

      // On error, try to serve from cache for initial load
      if (isInitial && mounted) {
        final currentPage = 1;
        final cachedPosts = await _cacheRepository.getPage(currentPage, filter: state.activeFilter?.name);
        if (cachedPosts != null && cachedPosts.isNotEmpty) {
          // **CHECK FOR DUPLICATES IN CACHE FALLBACK TOO**
          //TODO THIS IS SO GAY NEEDS TO BE FIXED
          final existingPostIds = state.posts.map((post) => post.id).whereType<String>().toSet();
          final uniqueCachedPosts = cachedPosts.where((post) => post.id != null && !existingPostIds.contains(post.id)).toList();

          state = state.copyWith(
            posts: uniqueCachedPosts,
            isLoadingInitial: false,
            lastDocument: uniqueCachedPosts.isNotEmpty ? uniqueCachedPosts.last.docSnapshot : null,
            // hasMorePosts: uniqueCachedPosts.length == _pageSize,
            isUsingCache: true,
            errorMessage: uniqueCachedPosts.length < cachedPosts.length
                ? "Using cached data (some duplicates filtered)"
                : "Using cached data (offline mode)",
          );
          return;
        }
      }

      if (mounted) {
        state = state.copyWith(
          isLoadingInitial: false,
          isLoadingMore: false,
          errorMessage: "Failed to load posts. Please try again.",
          isUsingCache: false,
        );
      }
    }
  }

  String _getCacheKey(int pageNumber) {
    return 'feed_${state.activeFilter?.name ?? 'all'}_page_$pageNumber';
  }

  void setFilter(PostFilterType? filterType) {
    if (state.activeFilter == filterType) return;

    // Clear cache for the old filter when changing filters
    if (state.activeFilter != null) {
      _cacheRepository.clearPagesForFilter(state.activeFilter?.name);
    }

    state = state.copyWith(activeFilter: filterType);
    fetchInitialPosts();
  }

  void clearFilter() {
    if (state.activeFilter == null) return;

    // Clear cache for the current filter
    _cacheRepository.clearPagesForFilter(state.activeFilter?.name);

    state = state.copyWith(activeFilter: null);
    fetchInitialPosts();
  }

  // Future<void> _performRefresh([int? newTotalCount]) async {
  //   // Clear cache for current filter and reload
  //   _cacheRepository.clearPagesForFilter(state.activeFilter?.name);
  //   fetchInitialPosts();
  // }
  Future<void> refreshFeed() async {
    try {
      // Hide counter when refresh starts
      hidePostCounter();

      // First check the current total post count from Firebase
      final int currentTotalCount = await _postService.getTotalPostCount();

      if (currentTotalCount == -1) {
        await _performFullRefresh();
        return;
      }

      final int previousTotalCount = state.totalPostCount;
      final int newPostsCount = currentTotalCount - previousTotalCount;

      if (newPostsCount <= 0) {
        print('\nFEED POSTS PROVIDER\nNo new posts, total count unchanged: $currentTotalCount');
        state = state.copyWith(totalPostCount: currentTotalCount, isRefreshing: false);
        return;
      }

      state = state.copyWith(isRefreshing: true);

      print('\nFEED POSTS PROVIDER\nFound $newPostsCount new posts, fetching all at once...');

      final List<MemoModelPost> allNewPosts = await _postService.getPostsPaginated(limit: newPostsCount, startAfterDoc: null);

      if (!mounted) return;

      await _mergeNewPostsWithExisting(allNewPosts, currentTotalCount);
    } catch (e, s) {
      _logFeedError("Error during refresh", e, s);
      await _performFullRefresh();
    }
  }

  Future<void> _mergeNewPostsWithExisting(List<MemoModelPost> allNewPosts, int currentTotalCount) async {
    final List<MemoModelPost> existingPosts = state.posts;

    if (allNewPosts.isEmpty) {
      state = state.copyWith(isRefreshing: false, totalPostCount: currentTotalCount);
      return;
    }

    // Remove any duplicates (in case of overlap)
    //TODO THERE CAN NOT BE ANY OVERLAP OR SOMETHING IS WRONG IN THE ALGORITHM
    final existingPostIds = existingPosts.map((post) => post.id).whereType<String>().toSet();
    final uniqueNewPosts = allNewPosts.where((post) => post.id != null && !existingPostIds.contains(post.id)).toList();

    if (uniqueNewPosts.isEmpty) {
      state = state.copyWith(isRefreshing: false, totalPostCount: currentTotalCount);
      return;
    }

    // Merge new posts at the beginning (newest first)
    final List<MemoModelPost> mergedPosts = [...uniqueNewPosts, ...existingPosts];
    //
    if (allNewPosts.isEmpty) {
      state = state.copyWith(isRefreshing: false, totalPostCount: currentTotalCount);
      return;
    }

    // Merge new posts at the beginning (newest first)
    // final List<MemoModelPost> mergedPosts = [...allNewPosts, ...existingPosts];

    //TODO NOTHING CHANGED FOR HAS MORE WITH MERGING AS MERGE IS INSERTED AT THE TOP OF LIST
    // Recalculate pagination state
    // final bool hasMore = mergedPosts.length > _pageSize || (state.lastDocument != null && mergedPosts.isNotEmpty);

    // Get the last document for pagination (should be the last post in the list)
    // final DocumentSnapshot? newLastDocument = mergedPosts.isNotEmpty ? mergedPosts.last.docSnapshot : null;

    state = state.copyWith(
      posts: mergedPosts,
      isRefreshing: false,
      totalPostCount: currentTotalCount,
      // lastDocument: newLastDocument, //TODO check this, must not be updated at all as the end of the list remained unchanged and the endless scrolling continues where it was before
      // hasMorePosts: hasMore,
    );

    // Update cache - we need to recache all pages since structure changed
    await _recacheAllPages(mergedPosts);
  }

  Future<void> _recacheAllPages(List<MemoModelPost> allPosts) async {
    // Clear existing cache for this filter
    _cacheRepository.clearPagesForFilter(state.activeFilter?.name);

    // Split into pages and cache each page
    for (int i = 0; i < allPosts.length; i += _pageSize) {
      final end = (i + _pageSize < allPosts.length) ? i + _pageSize : allPosts.length;
      final pagePosts = allPosts.sublist(i, end);
      final pageNumber = (i ~/ _pageSize) + 1;

      await _cacheRepository.savePage(pagePosts, pageNumber, filter: state.activeFilter?.name);
    }
  }

  Future<void> _performFullRefresh() async {
    // Clear cache for current filter
    _cacheRepository.clearPagesForFilter(state.activeFilter?.name);

    // Get current total count
    final totalCount = await _postService.getTotalPostCount();

    // Reset state for refresh
    state = state.copyWith(
      isLoadingInitial: true,
      lastDocument: null,
      // hasMorePosts: true,
      posts: [],
      isUsingCache: false,
      clearErrorMessage: true,
      totalPostCount: totalCount != -1 ? totalCount : state.totalPostCount,
      isRefreshing: false,
      // newPosts: [],
    );

    await _fetchPostsPage(isInitial: true);
  }
}

// --- Provider Definition ---
final feedPostsProvider = StateNotifierProvider<FeedPostsNotifier, FeedState>((ref) {
  return FeedPostsNotifier(ref.read(postServiceProvider), ref.read(postCacheRepositoryProvider));
});

// Helper for logging
void _logFeedError(String message, [dynamic error, StackTrace? stackTrace]) {
  print(
    '\nFEED POSTS PROVIDER\nERROR FeedPostsNotifier: $message ${error != null ? '- $error' : ''}${stackTrace != null ? '\n$stackTrace' : ''}',
  );
}
