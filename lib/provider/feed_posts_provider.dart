import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/firebase/post_service.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/screens/feed_screen.dart'; // For PostFilterType

// --- State for the Feed ---
class FeedState {
  final List<MemoModelPost> posts; // All posts are now directly from server query
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final String? errorMessage;
  final DocumentSnapshot? lastDocument;
  final bool hasMorePosts; // Renamed from hasMoreRawPosts, as all are "raw" now
  final PostFilterType? activeFilter; // Single optional filter

  FeedState({
    this.posts = const [],
    this.isLoadingInitial = true,
    this.isLoadingMore = false,
    this.errorMessage,
    this.lastDocument,
    this.hasMorePosts = true,
    this.activeFilter, // Can be null
  });

  FeedState copyWith({
    List<MemoModelPost>? posts,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    String? errorMessage,
    DocumentSnapshot? lastDocument, // Allow explicitly setting/clearing
    bool? hasMorePosts,
    bool clearErrorMessage = false,
    PostFilterType? activeFilter, // Allow setting or clearing (by passing null)
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      lastDocument: lastDocument, // Use new value; if null, it means reset cursor
      hasMorePosts: hasMorePosts ?? this.hasMorePosts,
      activeFilter: activeFilter, // Use new value; if null, it means no filter
    );
  }
}

// --- StateNotifier ---
class FeedPostsNotifier extends StateNotifier<FeedState> {
  final PostService _postService;
  final int _pageSize = 10;

  FeedPostsNotifier(this._postService) : super(FeedState()) {
    fetchInitialPosts();
  }

  Future<void> fetchInitialPosts() async {
    // Reset state for a new initial fetch, keeping the current activeFilter
    state = FeedState(
      isLoadingInitial: true,
      activeFilter: state.activeFilter, // Preserve current filter
      lastDocument: null, // Critical: Reset pagination cursor
      hasMorePosts: true, // Assume more posts initially
      posts: [], // Clear displayed posts
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
      hasMorePosts: state.hasMorePosts,
      posts: state.posts,
      activeFilter: state.activeFilter,
      errorMessage: null,
    );
    await _fetchPostsPage(isInitial: false);
  }

  Future<void> _fetchPostsPage({required bool isInitial}) async {
    try {
      final DocumentSnapshot? cursorForThisFetch = isInitial ? null : state.lastDocument;
      print("-----------------------------------------------------");
      print("FeedPostsNotifier: Attempting to fetch posts page.");
      print("  isInitial: $isInitial");
      print("  startAfterDoc ID: ${cursorForThisFetch?.id}"); // Log the ID of the cursor document
      if (cursorForThisFetch?.data() != null) {
        print(
          "  startAfterDoc Data (first few fields for check): ${(cursorForThisFetch!.data() as Map<String, dynamic>).entries.take(2).map((e) => '${e.key}: ${e.value}').join(', ')}",
        );
      }

      final List<MemoModelPost> newPosts = await _postService.getPostsPaginated(
        limit: _pageSize,
        startAfterDoc: cursorForThisFetch, // Pass the single active filter
        activeFilter: state.activeFilter,
      );

      if (!mounted) return;

      print("  Fetched ${newPosts.length} new posts.");
      if (newPosts.isNotEmpty) {
        print(
          "  First new post ID: ${newPosts.first.id}, Text: ${newPosts.first.text?.substring(0, (newPosts.first.text?.length ?? 0) > 20 ? 20 : (newPosts.first.text?.length ?? 0))}",
        );
        print(
          "  Last new post ID: ${newPosts.last.id}, Text: ${newPosts.last.text?.substring(0, (newPosts.last.text?.length ?? 0) > 20 ? 20 : (newPosts.last.text?.length ?? 0))}",
        );
      }

      DocumentSnapshot? newLastDocumentForState = newPosts.isNotEmpty ? newPosts.last.docSnapshot : null;

      print("  Updating state. Next lastDocument ID will be: ${newLastDocumentForState?.id}");
      print("-----------------------------------------------------");

      state = state.copyWith(
        posts: isInitial ? newPosts : [...state.posts, ...newPosts],
        isLoadingInitial: false,
        isLoadingMore: false,
        // CRITICAL: Ensure lastDocument is correctly updated from the NEWLY fetched posts
        lastDocument: newLastDocumentForState ?? (isInitial ? null : state.lastDocument),
        hasMorePosts: newPosts.length == _pageSize,
        errorMessage: null,
      );
    } catch (e, s) {
      _logFeedError("Error fetching posts page", e, s);
      if (mounted) {
        state = state.copyWith(isLoadingInitial: false, isLoadingMore: false, errorMessage: "Failed to load posts. Please try again.");
      }
    }
  }

  void setFilter(PostFilterType? filterType) {
    // Can be null to show all
    if (state.activeFilter == filterType) return; // No change

    state = state.copyWith(activeFilter: filterType); // Update the active filter
    fetchInitialPosts(); // This will reset list and fetch from start with new filter
  }

  void clearFilter() {
    if (state.activeFilter == null) return; // No filter active

    state = state.copyWith(activeFilter: null); // Explicitly pass null
    fetchInitialPosts();
  }

  void refreshFeed() {
    // This will use the current activeFilter and fetch from the beginning.
    fetchInitialPosts();
  }
}

// --- Provider Definition ---
final feedPostsProvider = StateNotifierProvider<FeedPostsNotifier, FeedState>((ref) {
  return FeedPostsNotifier(PostService());
});

// Helper for logging
void _logFeedError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR FeedPostsNotifier: $message ${error != null ? '- $error' : ''}${stackTrace != null ? '\n$stackTrace' : ''}');
}

// void _logFeedInfo(String message) { // If needed
//   print('INFO FeedPostsNotifier: $message');
// }
