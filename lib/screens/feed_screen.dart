import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/config_ipfs.dart';
import 'package:mahakka/provider/feed_posts_provider.dart'; // Your updated feed provider
import 'package:mahakka/theme_provider.dart'; // Your theme provider
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/widgets/burner_balance_widget.dart';
// import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/widgets/postcard/post_card_widget.dart';
import 'package:url_launcher/url_launcher.dart';

import '../memo/model/memo_model_post.dart';
import '../memo_data_checker.dart';
import '../provider/bch_burner_balance_provider.dart';
import '../widgets/post_counter_widget.dart';
import '../widgets/post_dialog.dart';

// Enum for filter types - this should be consistent with what PostService and FeedPostsNotifier expect
enum PostFilterType {
  images,
  // videos,
  //, hashtags
  topics,
}

// Intents for keyboard scrolling (remains unchanged)
class ScrollUpIntent extends Intent {}

class ScrollDownIntent extends Intent {}

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});
  // final NavBarCallback navBarCallback;

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

    _activateKeyboardScrollingNoListClickNeeded();
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

  @override
  Widget build(BuildContext context) {
    final asyncThemeState = ref.watch(themeNotifierProvider);
    final asyncBurnerBalance = ref.watch(bchBurnerBalanceProvider);
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
        title: Row(
          children: [
            BurnerBalanceWidget(),
            Spacer(),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('https://mahakka.com')),
              child: Text("mahakka.com", style: theme.appBarTheme.titleTextStyle),
            ),
          ],
        ),
        actions: [
          _buildMenuTheme(currentThemeState, theme),
          // _buildMenuFilter(theme, feedState.activeFilter), // Pass the single active filter
        ],
      ),
      body: Column(
        children: [
          // Post counter at the top
          const PostCounterWidget(),

          // Your existing feed content
          Expanded(child: _buildFeedBody(theme, feedState)),
          // ),
        ],
      ),
    );
  }

  Widget _buildRefreshableNoPostsWidget(ThemeData theme, Widget child) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(feedPostsProvider.notifier).refreshFeed();
      },
      color: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      child: Stack(
        children: [
          ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height), // Fills the screen to enable scroll
            ],
          ),
          Center(child: child), // Display your no-post widget here
        ],
      ),
    );
  }

  bool _hasValidImageUrl(MemoModelPost post) {
    // if (_filterSpam(post)) return false;

    final imgurUrl = post.imgurUrl;
    final imageUrl = post.imageUrl;
    final ipfsUrl = post.ipfsCid;

    // Check if either imgurUrl or imageUrl is not null and not empty
    return (imgurUrl != null && imgurUrl.isNotEmpty) || (imageUrl != null && imageUrl.isNotEmpty) || (ipfsUrl != null && ipfsUrl.isNotEmpty);
  }

  Widget _buildFeedBody(ThemeData theme, FeedState feedState) {
    // Use a different widget for the "no feed" case that is still scrollable.
    // This allows RefreshIndicator to work.
    if (feedState.posts.isEmpty && !feedState.isLoadingInitial && !feedState.isLoadingMore) {
      return _buildRefreshableNoPostsWidget(theme, _widgetNoFeed(theme));
    }

    // Display list of posts
    return RefreshIndicator(
      onRefresh: () => ref.read(feedPostsProvider.notifier).refreshFeed(),
      color: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      child: FocusableActionDetector(
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

                // Check if post.text exists and contains any hidden words
                // if (_filterSpam(post)) {
                //   return const SizedBox.shrink(); // Hide the post
                // }

                return wrapInDoubleTapDetectorImagesOnly(post, context, feedState, theme);

                // return PostCard(post, key: ValueKey(post.id) /*, navBarCallback: widget.navBarCallback */);
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
      ),
    );
  }

  GestureDetector wrapInDoubleTapDetectorImagesOnly(MemoModelPost post, BuildContext context, FeedState feedState, ThemeData theme) {
    return GestureDetector(
      onDoubleTap: () async {
        final imageUrl = post.imgurUrl ?? post.imageUrl ?? "";
        final ipfsId = post.ipfsCid ?? "";
        if (imageUrl.isEmpty && ipfsId.isEmpty) {
          showSnackBar("No valid image available for this post", context, type: SnackbarType.info);
          return;
        }

        if (imageUrl.isNotEmpty && !(await ref.read(imageValidationProvider(imageUrl).future))) {
          showSnackBar("Image is not accessible, active VPN!", context, type: SnackbarType.error);
          return;
        }

        if (ipfsId.isNotEmpty && !(await ref.read(imageValidationProvider(IpfsConfig.preferredNode + ipfsId).future))) {
          showSnackBar("Incompatible IPFS format!", context, type: SnackbarType.error);
          return;
        }

        // Filter posts to only include those with valid images
        final validImagePosts = feedState.posts.where(_hasValidImageUrl).toList();

        // Find the index of the current post in the filtered list
        final validIndex = validImagePosts.indexWhere((p) => p.id == post.id);

        if (validIndex == -1) {
          showSnackBar("Could not open image viewer", context, type: SnackbarType.error);
          return;
        }

        // Show the fullscreen activity
        showPostImageFullscreenWidget(context: context, theme: theme, posts: validImagePosts, initialIndex: validIndex);
      },
      child: PostCard(post, key: ValueKey(post.id)),
    );
  }

  // bool _filterSpam(MemoModelPost post) =>
  //     post.text != null && hideOnFeedTrigger.any((word) => post.text!.toLowerCase().contains(word.toLowerCase()));

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
