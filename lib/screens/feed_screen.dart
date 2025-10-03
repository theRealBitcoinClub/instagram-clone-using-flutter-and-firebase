import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/app_bar_burn_mahakka_theme.dart';
import 'package:mahakka/app_utils.dart';
import 'package:mahakka/intros/intro_enums.dart';
import 'package:mahakka/intros/intro_state_notifier.dart';
import 'package:mahakka/provider/feed_posts_provider.dart';
import 'package:mahakka/theme_provider.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/widgets/postcard/post_card_widget.dart';

import '../intros/intro_animated_icon.dart';
import '../intros/intro_overlay.dart';
import '../memo/model/memo_model_post.dart';
import '../widgets/post_dialog.dart';

enum PostFilterType { images, topics }

class ScrollUpIntent extends Intent {}

class ScrollDownIntent extends Intent {}

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _listViewFocusNode = FocusNode();
  bool _isRenderingContent = true;
  Object? _loadingError;
  final _introType = IntroType.mainApp;

  @override
  void initState() {
    super.initState();
    print('FSCR:🚀 FeedScreen initState called');
    _scrollController.addListener(_scrollListener);
    print('FSCR:📜 Scroll listener added');

    context.afterLayout(refreshUI: false, () {
      print('FSCR:🎯 Requesting focus for list view');
      FocusScope.of(context).requestFocus(_listViewFocusNode);
    });

    // Schedule rendering completion after the first frame
    context.afterLayout(refreshUI: true, () {
      print('FSCR:🎨 Initial rendering completed, setting _isRenderingContent to false');
      _isRenderingContent = false;
    });
  }

  void _scrollListener() {
    final scrollPosition = _scrollController.position;
    final pixels = scrollPosition.pixels;
    final maxScrollExtent = scrollPosition.maxScrollExtent;
    final threshold = maxScrollExtent - 300;

    print('FSCR:📜 Scroll listener - pixels: $pixels, maxScrollExtent: $maxScrollExtent, threshold: $threshold');

    if (pixels >= threshold && !ref.read(feedPostsProvider).isLoadingMore && ref.read(feedPostsProvider).hasMorePosts) {
      print('FSCR:📥 Triggering fetchMorePosts - reached scroll threshold');
      ref.read(feedPostsProvider.notifier).fetchMorePosts();
    } else {
      print('FSCR:⏸️ Scroll threshold not met or conditions not satisfied');
      print('FSCR:   - isLoadingMore: ${ref.read(feedPostsProvider).isLoadingMore}');
      print('FSCR:   - hasMorePosts: ${ref.read(feedPostsProvider).hasMorePosts}');
      print('FSCR:   - pixels >= threshold: ${pixels >= threshold}');
    }
  }

  // Add this method to handle scrolling down for a specific post
  void _scrollDownForPost(MemoModelPost post) {
    if (!_scrollController.hasClients) {
      print('FSCR:📜 _scrollDownForPost - scroll controller has no clients');
      return;
    }

    // Find the position of the post in the list
    final feedState = ref.read(feedPostsProvider);
    final postIndex = feedState.posts.indexWhere((p) => p.id == post.id);
    print('FSCR:📜 _scrollDownForPost - postId: ${post.id}, found at index: $postIndex');

    if (postIndex != -1) {
      final targetPosition = _scrollController.offset + 50.0;
      print('FSCR:📜 _scrollDownForPost - current offset: ${_scrollController.offset}, target: $targetPosition');

      // Ensure we don't scroll beyond the maximum scroll extent
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      final clampedPosition = targetPosition.clamp(_scrollController.position.minScrollExtent, maxScrollExtent);
      print('FSCR:📜 _scrollDownForPost - clamped position: $clampedPosition');

      _scrollController.animateTo(clampedPosition, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      print('FSCR:📜 _scrollDownForPost - scroll animation started');
    } else {
      print('FSCR:❌ _scrollDownForPost - post not found in current posts list');
    }
  }

  @override
  void dispose() {
    print('FSCR:♻️ FeedScreen dispose called');
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _listViewFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('FSCR:🏗️ FeedScreen build started');
    final feedState = ref.watch(feedPostsProvider);
    final shouldShowIntro = ref.read(introStateNotifierProvider.notifier).shouldShow(_introType);

    print('FSCR:📊 FeedState in build:');
    print('FSCR:   - posts: ${feedState.posts.length}');
    print('FSCR:   - isLoadingInitial: ${feedState.isLoadingInitial}');
    print('FSCR:   - isLoadingMore: ${feedState.isLoadingMore}');
    print('FSCR:   - hasMorePosts: ${feedState.hasMorePosts}');
    print('FSCR:   - totalPostCount: ${feedState.totalPostCount}');
    print('FSCR:   - isRefreshing: ${feedState.isRefreshing}');

    return Scaffold(
      backgroundColor: Colors.black.withAlpha(21),
      appBar: AppBarBurnMahakkaTheme(),
      body: Stack(
        children: [
          if (_isRenderingContent || feedState.isLoadingInitial) Center(child: Image.asset("assets/icon_round_200.png", height: 120)),
          if (_loadingError != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Failed to load feed', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Error: $_loadingError', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      print('FSCR:🔄 Retry button pressed');
                      setState(() {
                        _isRenderingContent = true;
                        _loadingError = null;
                      });
                      await ref.read(feedPostsProvider.notifier).refreshFeed();

                      context.afterLayout(refreshUI: true, () {
                        print('FSCR:_isRenderingContent');
                        _isRenderingContent = false;
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),

          // Main content - initially transparent during rendering
          Opacity(
            opacity: (_isRenderingContent || feedState.isLoadingInitial) ? 0.0 : 1.0,
            child: Column(
              children: [
                // // Post counter at the top
                // const PostCounterWidget(),

                // Feed content
                Expanded(child: _buildFeedBody(feedState)),
              ],
            ),
          ),
          // Intro overlay - should be at the top of the Stack to overlay everything
          if (shouldShowIntro) IntroOverlay(introType: _introType, onComplete: () {}),
        ],
      ),
    );
  }

  Widget _buildRefreshableNoPostsWidget(ThemeData theme, Widget child) {
    print('FSCR:🔄 Building refreshable no posts widget');
    return RefreshIndicator(
      onRefresh: () async {
        print('FSCR:🔄 RefreshIndicator triggered');
        await ref.read(feedPostsProvider.notifier).refreshFeed();
      },
      color: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      child: Stack(
        children: [
          ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [SizedBox(height: MediaQuery.of(context).size.height)],
          ),
          Center(child: child),
        ],
      ),
    );
  }

  bool _hasValidImageUrl(MemoModelPost post) {
    final imgurUrl = post.imgurUrl;
    final imageUrl = post.imageUrl;
    final ipfsUrl = post.ipfsCid;

    final hasValidUrl =
        (imgurUrl != null && imgurUrl.isNotEmpty) || (imageUrl != null && imageUrl.isNotEmpty) || (ipfsUrl != null && ipfsUrl.isNotEmpty);

    print('FSCR:🖼️ _hasValidImageUrl for post ${post.id}: $hasValidUrl');
    return hasValidUrl;
  }

  Widget _buildFeedBody(FeedState feedState) {
    print('FSCR:🏗️ _buildFeedBody called');
    ThemeData theme = Theme.of(context);

    if (feedState.posts.isEmpty && !feedState.isLoadingInitial && !feedState.isLoadingMore) {
      print('FSCR:📭 No posts available, showing empty state');
      return _buildRefreshableNoPostsWidget(theme, _widgetNoFeed(theme));
    }

    print('FSCR:📜 Building ListView with ${feedState.posts.length} posts');
    print('FSCR:📜 ListView itemCount breakdown:');
    print('FSCR:   - base posts: ${feedState.posts.length}');
    print('FSCR:   - loadingMore indicator: ${feedState.isLoadingMore ? 1 : 0}');
    print(
      'FSCR:   - end message: ${(!feedState.hasMorePosts && feedState.posts.isNotEmpty && !feedState.isLoadingInitial && !feedState.isLoadingMore) ? 1 : 0}',
    );
    print(
      'FSCR:   - total itemCount: ${feedState.posts.length + (feedState.isLoadingMore ? 1 : 0) + (!feedState.hasMorePosts && feedState.posts.isNotEmpty && !feedState.isLoadingInitial && !feedState.isLoadingMore ? 1 : 0)}',
    );

    return RefreshIndicator(
      onRefresh: () {
        print('FSCR:🔄 ListView RefreshIndicator triggered');
        return ref.read(feedPostsProvider.notifier).refreshFeed();
      },
      color: theme.colorScheme.onPrimary,
      backgroundColor: theme.colorScheme.primary,
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
              print('FSCR:🎯 Requesting focus via GestureDetector tap');
              FocusScope.of(context).requestFocus(_listViewFocusNode);
            }
          },
          child: ListView.builder(
            controller: _scrollController,
            itemCount:
                feedState.posts.length +
                (feedState.isLoadingMore ? 1 : 0) +
                (!feedState.hasMorePosts && feedState.posts.isNotEmpty && !feedState.isLoadingInitial && !feedState.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              print('FSCR:📜 ListView building item at index: $index');

              if (index < feedState.posts.length) {
                final post = feedState.posts[index];
                print('FSCR:📜 Building PostCard for post ${post.id} at index $index');
                return wrapInDoubleTapDetectorImagesOnly(post, context, feedState, theme);
              } else if (feedState.isLoadingMore && index == feedState.posts.length) {
                print('FSCR:⏳ Building loading indicator at index $index');
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
                );
              } else if (!feedState.hasMorePosts &&
                  index == feedState.posts.length &&
                  feedState.posts.isNotEmpty &&
                  !feedState.isLoadingInitial &&
                  !feedState.isLoadingMore) {
                print('FSCR:🏁 Building end of feed message at index $index');
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                  child: Center(
                    child: Text(
                      "You've reached the end of the feed!",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                );
              }
              print('FSCR:❌ Unexpected index in ListView builder: $index');
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget wrapInDoubleTapDetectorImagesOnly(MemoModelPost post, BuildContext context, FeedState feedState, ThemeData theme) {
    print('FSCR:👆 Wrapping post ${post.id} in GestureDetector');
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () async {
        print('FSCR:👆 Post ${post.id} tapped');
        final imageUrl = post.imgurUrl ?? post.imageUrl ?? "";
        final ipfsId = post.ipfsCid ?? "";
        if (imageUrl.isEmpty && ipfsId.isEmpty) {
          print('FSCR:❌ No valid image available for post ${post.id}');
          showSnackBar("No valid image available for this post", type: SnackbarType.info);
          return;
        }

        final validImagePosts = feedState.posts.where(_hasValidImageUrl).toList();
        final validIndex = validImagePosts.indexWhere((p) => p.id == post.id);
        print('FSCR:🖼️ Valid image posts count: ${validImagePosts.length}, current post index: $validIndex');

        if (validIndex == -1) {
          print('FSCR:❌ Could not find post in valid image posts list');
          showSnackBar("Could not open image viewer", type: SnackbarType.error);
          return;
        }

        print('FSCR:🖼️ Opening image viewer for post ${post.id} at index $validIndex');
        showPostImageFullscreenWidget(context: context, theme: theme, posts: validImagePosts, initialIndex: validIndex);
      },
      child: PostCard(
        post,
        key: ValueKey(post.id),
        onShowSendButton: () {
          print('FSCR:📜 onShowSendButton callback triggered for post ${post.id}');
          _scrollDownForPost(post);
        },
      ),
    );
  }

  Center _widgetNoFeed(ThemeData theme) {
    print('FSCR:📭 Building no feed widget');
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
    print('FSCR:🔍 Building no match widget for filter: $filterName');
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

  Widget _buildMenuTheme(ThemeState themeState) {
    return IntroAnimatedIcon(
      icon: themeState.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      introType: IntroType.mainApp,
      introStep: IntroStep.mainTheme,
      size: 24,
      padding: EdgeInsets.all(12),
      onTap: () {
        ref.read(introStateNotifierProvider.notifier).triggerIntroAction(IntroType.mainApp, IntroStep.mainTheme, context);
        ref.read(themeNotifierProvider.notifier).toggleTheme();
      },
    );
  }

  Map<ShortcutActivator, Intent> _getKeyboardShortcuts() {
    return <ShortcutActivator, Intent>{
      const SingleActivator(LogicalKeyboardKey.arrowUp): ScrollUpIntent(),
      const SingleActivator(LogicalKeyboardKey.arrowDown): ScrollDownIntent(),
    };
  }

  void _handleScrollIntent(Intent intent, BuildContext context) {
    print('FSCR:⌨️ Keyboard scroll intent: $intent');
    if (!_scrollController.hasClients) {
      print('FSCR:❌ Scroll controller has no clients');
      return;
    }

    double scrollAmount = 0;
    const double estimatedItemHeight = 300.0;

    if (intent is ScrollUpIntent) {
      scrollAmount = -estimatedItemHeight;
      print('FSCR:⬆️ Scrolling up by $scrollAmount');
    } else if (intent is ScrollDownIntent) {
      scrollAmount = estimatedItemHeight;
      print('FSCR:⬇️ Scrolling down by $scrollAmount');
    }

    if (scrollAmount != 0) {
      final currentOffset = _scrollController.offset;
      final targetOffset = currentOffset + scrollAmount;
      final clampedOffset = targetOffset.clamp(_scrollController.position.minScrollExtent, _scrollController.position.maxScrollExtent);

      print('FSCR:📜 Animating scroll from $currentOffset to $clampedOffset');
      _scrollController.animateTo(clampedOffset, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }
}
