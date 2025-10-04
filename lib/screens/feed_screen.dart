import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/app_bar_burn_mahakka_theme.dart';
import 'package:mahakka/app_utils.dart';
import 'package:mahakka/intros/intro_enums.dart';
import 'package:mahakka/intros/intro_state_notifier.dart';
import 'package:mahakka/memo/base/memo_bitcoin_base.dart';
import 'package:mahakka/provider/feed_posts_provider.dart';
import 'package:mahakka/provider/user_provider.dart';
import 'package:mahakka/providers/navigation_providers.dart';
import 'package:mahakka/screens/icon_action_button.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/views_taggable/widgets/qr_code_dialog.dart';
import 'package:mahakka/widgets/postcard/post_card_widget.dart';

import '../intros/intro_overlay.dart';
import '../memo/model/memo_model_post.dart';
import '../widgets/post_dialog.dart';

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
  }

  void _scrollListener() {
    final scrollPosition = _scrollController.position;
    final pixels = scrollPosition.pixels;
    final maxScrollExtent = scrollPosition.maxScrollExtent;
    final threshold = maxScrollExtent - 300;

    // print('FSCR:📜 Scroll listener - pixels: $pixels, maxScrollExtent: $maxScrollExtent, threshold: $threshold');

    if (pixels >= threshold && !ref.read(feedPostsProvider).isLoadingMorePostsAtBottom && ref.read(feedPostsProvider).hasMorePosts) {
      // print('FSCR:📥 Triggering fetchMorePosts - reached scroll threshold');
      ref.read(feedPostsProvider.notifier).fetchMorePosts();
    } else {
      // print('FSCR:⏸️ Scroll threshold not met or conditions not satisfied');
      // print('FSCR:   - isLoadingMore: ${ref.read(feedPostsProvider).isLoadingMorePostsAtBottom}');
      // print('FSCR:   - hasMorePosts: ${ref.read(feedPostsProvider).hasMorePosts}');
      // print('FSCR:   - pixels >= threshold: ${pixels >= threshold}');
    }
  }

  void _scrollDownForPost(MemoModelPost post) {
    if (!_scrollController.hasClients) {
      print('FSCR:📜 _scrollDownForPost - scroll controller has no clients');
      return;
    }

    final feedState = ref.read(feedPostsProvider);
    final postIndex = feedState.posts.indexWhere((p) => p.id == post.id);
    print('FSCR:📜 _scrollDownForPost - postId: ${post.id}, found at index: $postIndex');

    if (postIndex != -1) {
      final targetPosition = _scrollController.offset + 50.0;
      print('FSCR:📜 _scrollDownForPost - current offset: ${_scrollController.offset}, target: $targetPosition');

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
    final theme = Theme.of(context);

    print('FSCR:📊 FeedState in build:');
    print('FSCR:   - posts: ${feedState.posts.length}');
    print('FSCR:   - isLoadingInitial: ${feedState.isLoadingInitialAtTop}');
    print('FSCR:   - isLoadingMore: ${feedState.isLoadingMorePostsAtBottom}');
    print('FSCR:   - hasMorePosts: ${feedState.hasMorePosts}');
    print('FSCR:   - totalPostCount: ${feedState.totalPostCountInFirebase}');
    print('FSCR:   - isRefreshing: ${feedState.isRefreshingByUserRequest}');
    print('FSCR:   - errorMessage: ${feedState.errorMessage}');
    print('FSCR:   - isMaxFreeLimitReached: ${feedState.isMaxFreeLimitReached}');

    return Scaffold(
      backgroundColor: Colors.black.withAlpha(21),
      appBar: AppBarBurnMahakkaTheme(),
      body: Stack(
        children: [
          // Loading indicator
          if (feedState.isLoadingInitialAtTop) Center(child: Image.asset("assets/icon_round_200.png", height: 120)),

          // Error banner at top of stack
          if (feedState.errorMessage != null) _buildErrorBanner(feedState.errorMessage!, theme),

          // Main content
          if (!feedState.isLoadingInitialAtTop || feedState.posts.isNotEmpty)
            Column(children: [Expanded(child: _buildFeedBody(feedState, theme))]),

          // Intro overlay - should be at the top of the Stack to overlay everything
          if (shouldShowIntro) IntroOverlay(introType: _introType, onComplete: () {}),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String errorMessage, ThemeData theme) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        color: theme.colorScheme.errorContainer,
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(errorMessage, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onErrorContainer)),
            ),
            IconButton(
              icon: Icon(Icons.close, color: theme.colorScheme.onErrorContainer),
              onPressed: () {
                ref.read(feedPostsProvider.notifier).fetchInitialPosts();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshableNoPostsWidget(ThemeData theme, Widget child) {
    print('FSCR:🔄 Building refreshable no posts widget');
    return RefreshIndicator(
      onRefresh: () async {
        print('FSCR:🔄 no posts widget load triggered');
        await ref.read(feedPostsProvider.notifier).fetchInitialPosts();
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

  Widget _buildFeedBody(FeedState feedState, ThemeData theme) {
    print('FSCR:🏗️ _buildFeedBody called');

    if (feedState.posts.isEmpty && !feedState.isLoadingInitialAtTop && !feedState.isLoadingMorePostsAtBottom) {
      print('FSCR:📭 No posts available, showing empty state');
      return _buildRefreshableNoPostsWidget(theme, _widgetNoFeed(theme));
    }

    print('FSCR:📜 Building ListView with ${feedState.posts.length} posts');
    print('FSCR:📜 ListView itemCount breakdown:');
    print('FSCR:   - base posts: ${feedState.posts.length}');
    print('FSCR:   - loadingMore indicator: ${feedState.isLoadingMorePostsAtBottom ? 1 : 0}');
    print('FSCR:   - free plan limit: ${feedState.isMaxFreeLimitReached ? 1 : 0}');
    print(
      'FSCR:   - end message: ${(!feedState.hasMorePosts && feedState.posts.isNotEmpty && !feedState.isLoadingInitialAtTop && !feedState.isLoadingMorePostsAtBottom && !feedState.isMaxFreeLimitReached) ? 1 : 0}',
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
                (feedState.isLoadingMorePostsAtBottom && !feedState.isMaxFreeLimitReached ? 1 : 0) +
                (feedState.isMaxFreeLimitReached ? 1 : 0) +
                (!feedState.hasMorePosts &&
                        feedState.posts.isNotEmpty &&
                        !feedState.isLoadingInitialAtTop &&
                        !feedState.isLoadingMorePostsAtBottom &&
                        !feedState.isMaxFreeLimitReached
                    ? 1
                    : 0),
            itemBuilder: (context, index) {
              print('FSCR:📜 ListView building item at index: $index');

              if (index < feedState.posts.length) {
                final post = feedState.posts[index];
                print('FSCR:📜 Building PostCard for post ${post.id} at index $index');
                return _wrapInDoubleTapDetectorImagesOnly(post, context, feedState, theme);
              } else if (feedState.isMaxFreeLimitReached && index == feedState.posts.length) {
                print('FSCR:💰 Building free plan limit widget at index $index');
                return _buildFreePlanLimitWidget(theme);
              } else if (feedState.isLoadingMorePostsAtBottom &&
                  !feedState.isMaxFreeLimitReached &&
                  index == feedState.posts.length + (feedState.isMaxFreeLimitReached ? 1 : 0)) {
                print('FSCR:⏳ Building loading indicator at index $index');
                return _buildLoadingIndicator();
              } else if (!feedState.hasMorePosts &&
                  index ==
                      feedState.posts.length +
                          (feedState.isMaxFreeLimitReached ? 1 : 0) +
                          (feedState.isLoadingMorePostsAtBottom && !feedState.isMaxFreeLimitReached ? 1 : 0)) {
                print('FSCR:🏁 Building end of feed message at index $index');
                return _buildEndOfFeedWidget(theme);
              }
              print('FSCR:❌ Unexpected index in ListView builder: $index');
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFreePlanLimitWidget(ThemeData theme) {
    var headerColor = theme.colorScheme.secondary;
    var borderColor = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.fromLTRB(6, 3, 6, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.1),
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(Icons.workspace_premium, color: headerColor, size: 32),
          const SizedBox(height: 9),
          Text('Free Plan Limit Reached', style: theme.textTheme.titleLarge?.copyWith(color: headerColor)),
          const SizedBox(height: 9),
          Text(
            'You\'ve loaded the maximum posts available for non token users. Deposit 100 tokens to unlock limits! These tokens stay in your wallet, depositing them simply proofs that you are ready to level up! You can also mute some users to get a more focused perspective on what you really care about!',
            textAlign: TextAlign.justify,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 9),
          Center(
            child: Row(
              children: [
                IconAction(
                  text: 'Swap',
                  onTap: () {
                    ref.read(navigationStateProvider.notifier).navigateToUrl(MemoBitcoinBase.cauldronSwapTokenUrl);
                  },
                  type: IAB.alternative,
                  icon: Icons.swap_horizontal_circle_outlined,
                ),
                const SizedBox(height: 9),
                IconAction(
                  text: 'Deposit',
                  onTap: () {
                    showQrCodeDialog(ctx: context, user: ref.read(userProvider), tokenOnly: true);
                  },
                  type: IAB.success,
                  icon: Icons.qr_code_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return LinearProgressIndicator(minHeight: 3);
  }

  Widget _buildEndOfFeedWidget(ThemeData theme) {
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

  Widget _wrapInDoubleTapDetectorImagesOnly(MemoModelPost post, BuildContext context, FeedState feedState, ThemeData theme) {
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

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upgrade to Pro'),
        content: Text('Get unlimited access to all features!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              // Implement upgrade logic
              Navigator.pop(context);
            },
            child: Text('Upgrade'),
          ),
        ],
      ),
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
