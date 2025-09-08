import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:instagram_clone1/utils/colors.dart';
import 'package:instagram_clone1/widgets/post_card.dart';

<<<<<<< Updated upstream
class FeedScreen extends StatefulWidget {
=======
import '../provider/bch_burner_balance_provider.dart';
import '../widgets/post_counter_widget.dart';

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
>>>>>>> Stashed changes
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

<<<<<<< Updated upstream
class _FeedScreenState extends State<FeedScreen> {
  void signUserOut() async {
    // final GoogleSignIn googleSignIn = GoogleSignIn();
    await FirebaseAuth.instance.signOut();
    // await googleSignIn.signOut();
=======
class _FeedScreenState extends ConsumerState<FeedScreen> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _listViewFocusNode = FocusNode();
  bool _isCounterVisible = false;

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
    _activateKeyboardScrollingNoListClickNeeded();
    // Initial data fetch is handled by the feedPostsProvider when it's first read/watched.
    // No explicit call needed here if the provider's constructor calls fetchInitialPosts.
>>>>>>> Stashed changes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: mobileBackgroundColor,
          centerTitle: false,
          title: SvgPicture.asset(
            'assets/images/instagram.svg',
            color: blackColor,
            height: 50,
          ),
          actions: [
            IconButton(
                onPressed: () {
                  signUserOut();
                },
                icon: Icon(
                  Icons.messenger_outline,
                  color: blackColor,
                ))
          ],
        ),
<<<<<<< Updated upstream
        body: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .orderBy('datePublished', descending: true)
                .snapshots(),
            builder: (context,
                AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) =>
                    PostCard(snap: snapshot.data!.docs[index].data()),
              );
            }));
=======
        actions: [
          _buildMenuTheme(currentThemeState, theme),
          // _buildMenuFilter(theme, feedState.activeFilter), // Pass the single active filter
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Tell the provider to refresh the feed (fetches first page with current filter)
          await ref.read(feedPostsProvider.notifier).refreshFeed();
          // ref.invalidate(feedPostsProvider);
          setState(() {
            _isCounterVisible = false;
          });
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
          itemCount:
              (_isCounterVisible ? 1 : 0) + // Add counter item if visible
              feedState.posts.length +
              (feedState.isLoadingMore ? 1 : 0) +
              (!feedState.hasMorePosts && feedState.posts.isNotEmpty && !feedState.isLoadingInitial && !feedState.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            // Post counter header (first item)
            if (_isCounterVisible && index == 0) {
              return _buildPostCounterHeader(theme);
            }

            // Adjust post index based on counter visibility
            final postIndex = _isCounterVisible ? index - 1 : index;

            // Post item
            if (postIndex < feedState.posts.length) {
              final post = feedState.posts[postIndex];
              return PostCard(post, key: ValueKey(post.id));
            }
            // Loading more indicator
            else if (feedState.isLoadingMore && postIndex == feedState.posts.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
              );
            }
            // End of feed message
            else if (!feedState.hasMorePosts &&
                postIndex == feedState.posts.length &&
                feedState.posts.isNotEmpty &&
                !feedState.isLoadingInitial &&
                !feedState.isLoadingMore) {
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
            return const SizedBox.shrink();
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

  // Keyboard scroll logic (remains unchanged)
  Map<ShortcutActivator, Intent> _getKeyboardShortcuts() {
    return <ShortcutActivator, Intent>{
      const SingleActivator(LogicalKeyboardKey.arrowUp): ScrollUpIntent(),
      const SingleActivator(LogicalKeyboardKey.arrowDown): ScrollDownIntent(),
    };
  }

  Widget _buildPostCounterHeader(ThemeData theme) {
    return PostCounterWidget(
      onRefresh: () async {
        await ref.read(feedPostsProvider.notifier).refreshFeed();
      },
      onVisibilityChanged: _handleCounterVisibilityChanged, // Add the callback,
    );
  }

  void _handleCounterVisibilityChanged(bool isVisible) {
    setState(() {
      _isCounterVisible = isVisible;
    });
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
>>>>>>> Stashed changes
  }
}
