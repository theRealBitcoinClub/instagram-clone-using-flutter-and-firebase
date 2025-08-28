import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/provider/feed_posts_provider.dart'; // Your updated feed provider
import 'package:mahakka/theme_provider.dart'; // Your theme provider
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/widgets/postcard/post_card_widget.dart';

import 'home.dart'; // For NavBarCallback, if still used by PostCard

// Enum for filter types - this should be consistent with what PostService and FeedPostsNotifier expect
enum PostFilterType { images, videos, hashtags, topics }

// Intents for keyboard scrolling (remains unchanged)
class ScrollUpIntent extends Intent {}

class ScrollDownIntent extends Intent {}

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key, required this.navBarCallback});
  final NavBarCallback navBarCallback;

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _listViewFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    // Experiment: Force a rebuild after the initial data should have arrived
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        // Small delay
        if (mounted) {
          print("Forcing a setState in FeedScreen after initial frame and delay");
          setState(() {});
        }
      });
    });
    // _activateKeyboardScrollingNoListClickNeeded();
    // Initial data fetch is handled by the feedPostsProvider when it's first read/watched.
    // No explicit call needed here if the provider's constructor calls fetchInitialPosts.
  }

  void _scrollListener() {
    // Load more when near the bottom, not already loading, and more posts might exist
    // The provider's `hasMorePosts` now directly reflects server-side pagination for the current filter
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300 && // Threshold
        !ref.read(feedPostsProvider).isLoadingMore &&
        ref.read(feedPostsProvider).hasMorePosts) {
      ref.read(feedPostsProvider.notifier).fetchMorePosts();
    }
  }

  void _activateKeyboardScrollingNoListClickNeeded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_listViewFocusNode);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _listViewFocusNode.dispose();
    super.dispose();
  }

  // Checks if a specific filter type is the currently active one
  bool isFilterActive(PostFilterType filterType) {
    return ref.watch(feedPostsProvider).activeFilter == filterType;
  }

  // Sets or clears the single active filter
  void _selectFilter(PostFilterType? filterType) {
    final currentActiveFilterInState = ref.read(feedPostsProvider).activeFilter;

    // If the user taps the currently active filter, treat it as an action to clear the filter (show all).
    // Or, if they explicitly tap "ALL POSTS" (filterType == null).
    if (filterType == currentActiveFilterInState) {
      // Tapping the same active filter again clears it
      ref.read(feedPostsProvider.notifier).clearFilter();
      _showFilterChangeSnackbar(currentActiveFilterInState, isActive: false); // Show it was deactivated
    } else {
      // Set a new filter or clear if filterType is null (from "ALL POSTS" option)
      ref.read(feedPostsProvider.notifier).setFilter(filterType);
      _showFilterChangeSnackbar(filterType, isActive: filterType != null);
    }

    // Always scroll to top when a filter action is taken
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncThemeState = ref.watch(themeNotifierProvider);
    final ThemeState currentThemeState = asyncThemeState.maybeWhen(
      data: (data) => data,
      orElse: () => defaultThemeState, // Your default theme state
    );
    final ThemeData theme = currentThemeState.currentTheme;

    // Watch the state of the feed posts from the provider
    final feedState = ref.watch(feedPostsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 50,
        title: Text("mahakka.com", style: theme.appBarTheme.titleTextStyle),
        actions: [
          _buildMenuTheme(currentThemeState, theme),
          _buildMenuFilter(theme, feedState.activeFilter), // Pass the single active filter
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Tell the provider to refresh the feed (fetches first page with current filter)
          ref.read(feedPostsProvider.notifier).refreshFeed();
        },
        color: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surface,
        child: _buildFeedBody(theme, feedState),
      ),
    );
  }

  Widget _buildFeedBody(ThemeData theme, FeedState feedState) {
    // Initial loading state (only when posts list is truly empty and initial fetch is happening)
    if (feedState.isLoadingInitial && feedState.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state (only if posts list is empty and an error message exists)
    if (feedState.errorMessage != null && feedState.posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: ${feedState.errorMessage}',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => ref.read(feedPostsProvider.notifier).fetchInitialPosts(), child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    // No posts available (either no posts at all, or none match the active server-side filter)
    // This check is done after isLoadingInitial is false and no error.
    if (feedState.posts.isEmpty && !feedState.isLoadingInitial && !feedState.isLoadingMore) {
      if (feedState.activeFilter != null) {
        // A specific filter is active but returned no results
        return _widgetNoMatch(theme, _getFilterName(feedState.activeFilter!));
      }
      return _widgetNoFeed(theme); // No filter active, and still no posts
    }

    // Display list of posts
    return FocusableActionDetector(
      autofocus: true,
      focusNode: _listViewFocusNode,
      shortcuts: _getKeyboardShortcuts(),
      actions: <Type, Action<Intent>>{
        ScrollUpIntent: CallbackAction<ScrollUpIntent>(onInvoke: (intent) => _handleScrollIntent(intent, context)),
        ScrollDownIntent: CallbackAction<ScrollDownIntent>(onInvoke: (intent) => _handleScrollIntent(intent, context)),
      },
      child: GestureDetector(
        onTap: () {
          if (!_listViewFocusNode.hasFocus) {
            FocusScope.of(context).requestFocus(_listViewFocusNode);
          }
        },
        child: ListView.builder(
          controller: _scrollController,
          // itemExtent: 300,
          itemCount:
              feedState.posts.length +
              (feedState.isLoadingMore ? 1 : 0) + // For loading indicator
              (!feedState.hasMorePosts && feedState.posts.isNotEmpty && !feedState.isLoadingInitial && !feedState.isLoadingMore
                  ? 1
                  : 0), // For end of feed message
          itemBuilder: (context, index) {
            // Post item
            if (index < feedState.posts.length) {
              final post = feedState.posts[index];
              // Ensure PostCard does not require filter-related logic from FeedScreen anymore
              return PostCard(post, key: ValueKey(post.id) /*, navBarCallback: widget.navBarCallback */);
            }
            // Loading more indicator
            else if (feedState.isLoadingMore && index == feedState.posts.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
              );
            }
            // End of feed message
            else if (!feedState.hasMorePosts &&
                index == feedState.posts.length &&
                feedState.posts.isNotEmpty &&
                !feedState.isLoadingInitial && // Not in initial full-screen load
                !feedState.isLoadingMore) {
              // Not actively loading more
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                child: Center(
                  child: Text(
                    "You've reached the end of the feed${feedState.activeFilter != null ? ' for this filter' : ''}!",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              );
            }
            return const SizedBox.shrink(); // Should not be reached
          },
        ),
      ),
    );
  }

  // --- Helper Widgets (No Feed, No Match - adjusted message for No Match) ---
  Center _widgetNoFeed(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          'No posts available in the feed yet.\nPull down to refresh.',
          style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Center _widgetNoMatch(ThemeData theme, String filterName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          "No posts found for the '$filterName' filter.\nTry a different filter or pull to refresh.",
          style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // --- Menu Widgets (Theme unchanged, Filter UI adapted) ---
  Widget _buildMenuTheme(ThemeState themeState, ThemeData theme) {
    return IconButton(
      icon: Icon(themeState.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      tooltip: "Toggle Theme",
      onPressed: () {
        ref.read(themeNotifierProvider.notifier).toggleTheme();
      },
    );
  }

  Widget _buildMenuFilter(ThemeData theme, PostFilterType? currentActiveFilter) {
    return IconButton(
      icon: Icon(currentActiveFilter != null ? Icons.filter_alt_rounded : Icons.filter_list_outlined),
      tooltip: "Filter Posts",
      onPressed: () {
        showDialog(
          context: context,
          builder: (dialogCtx) {
            return SimpleDialog(
              title: Text("Filter by Content Type", style: theme.dialogTheme.titleTextStyle),
              shape: theme.dialogTheme.shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: theme.dialogTheme.backgroundColor ?? theme.cardColor,
              children: [
                // Option to show all posts (clear filter)
                _buildExclusiveFilterOption(dialogCtx, theme, null, "ALL POSTS", Icons.clear_all_outlined, Icons.clear_all_rounded),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildExclusiveFilterOption(dialogCtx, theme, PostFilterType.images, "IMAGES", Icons.image_outlined, Icons.image_rounded),
                // Your videos filter was commented out, so I've kept it that way.
                // _buildExclusiveFilterOption(dialogCtx, theme, PostFilterType.videos, "VIDEOS", Icons.video_library_outlined, Icons.video_library_rounded),
                _buildExclusiveFilterOption(dialogCtx, theme, PostFilterType.hashtags, "HASHTAGS", Icons.tag_outlined, Icons.tag_rounded),
                _buildExclusiveFilterOption(dialogCtx, theme, PostFilterType.topics, "TOPICS", Icons.topic_outlined, Icons.topic_rounded),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildExclusiveFilterOption(
    BuildContext dialogCtx,
    ThemeData theme,
    PostFilterType? filterType,
    String text,
    IconData icon,
    IconData activeIcon,
  ) {
    // Determine if this option represents the currently active filter (or no filter if filterType is null)
    final bool isSelected =
        (filterType == null && ref.read(feedPostsProvider).activeFilter == null) || (filterType != null && isFilterActive(filterType));

    return SimpleDialogOption(
      onPressed: () {
        _selectFilter(filterType); // This handles setting or clearing
        Navigator.pop(dialogCtx);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0), // Adjusted padding
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? theme.colorScheme.primary : theme.iconTheme.color?.withOpacity(0.7),
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isSelected ? theme.colorScheme.primary : theme.textTheme.titleMedium?.color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            // Visual cue for selection (e.g., a check mark or radio button style)
            if (isSelected)
              Icon(Icons.check_circle_outline_rounded, color: theme.colorScheme.primary, size: 24)
            else
              const SizedBox(width: 24), // Placeholder for alignment
          ],
        ),
      ),
    );
  }

  void _showFilterChangeSnackbar(PostFilterType? filterType, {required bool isActive}) {
    // Use Future.delayed to ensure the state has propagated and snackbar shows correctly
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      String message;
      if (filterType == null) {
        // This means "ALL POSTS" was selected
        message = "Showing all posts.";
      } else {
        final filterName = _getFilterName(filterType);
        message = isActive ? "Showing '$filterName' posts." : "Filter for '$filterName' removed. Showing all posts.";
      }
      showSnackBar(message, context);
    });
  }

  String _getFilterName(PostFilterType filterType) {
    // Your existing implementation
    switch (filterType) {
      case PostFilterType.images:
        return "IMAGES";
      case PostFilterType.videos:
        return "VIDEOS";
      case PostFilterType.hashtags:
        return "TAGS";
      case PostFilterType.topics:
        return "TOPICS";
    }
  }

  // Keyboard scroll logic (remains unchanged)
  Map<ShortcutActivator, Intent> _getKeyboardShortcuts() {
    return <ShortcutActivator, Intent>{
      const SingleActivator(LogicalKeyboardKey.arrowUp): ScrollUpIntent(),
      const SingleActivator(LogicalKeyboardKey.arrowDown): ScrollDownIntent(),
    };
  }

  void _handleScrollIntent(Intent intent, BuildContext context) {
    if (!_scrollController.hasClients) return;
    double scrollAmount = 0;
    const double estimatedItemHeight = 300.0; // Adjust if your average item height is different
    // final double viewportHeight = _scrollController.position.viewportDimension; // For page scrolling

    if (intent is ScrollUpIntent) {
      scrollAmount = -estimatedItemHeight;
    } else if (intent is ScrollDownIntent) {
      scrollAmount = estimatedItemHeight;
    }

    if (scrollAmount != 0) {
      _scrollController.animateTo(
        (_scrollController.offset + scrollAmount).clamp(_scrollController.position.minScrollExtent, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 250), // Slightly faster for keyboard
        curve: Curves.easeOut,
      );
    }
  }
}
