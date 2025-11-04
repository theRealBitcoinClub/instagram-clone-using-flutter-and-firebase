import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/app_bar_burn_mahakka_theme.dart';
import 'package:mahakka/app_utils.dart';
import 'package:mahakka/intros/intro_enums.dart';
import 'package:mahakka/intros/intro_state_notifier.dart';
import 'package:mahakka/provider/feed_posts_provider.dart';
import 'package:mahakka/provider/translation_service.dart';
import 'package:mahakka/providers/scroll_controller_provider.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/widgets/postcard/post_card_widget.dart';

import '../intros/intro_overlay.dart';
import '../memo/model/memo_model_post.dart';
import '../providers/token_limits_provider.dart';
import '../widgets/limit_info_widget.dart';
import '../widgets/post_dialog.dart';
import 'home.dart';

class ScrollUpIntent extends Intent {}

class ScrollDownIntent extends Intent {}

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final ScrollController _scrollController = ScrollController();
  final _introType = IntroType.mainApp;

  @override
  void initState() {
    super.initState();
    _print('FSCR:🚀 FeedScreen initState called');
    context.afterBuild(refreshUI: false, () {
      ref.read(feedScrollControllerProvider.notifier).setController(_scrollController);
    });
    context.afterLayout(() {
      ref.read(feedFocusNodeProvider).requestFocus();
    }, refreshUI: false);
    _print('FSCR:📜 Scroll listener added');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _print('FSCR:🏗️ FeedScreen build started');
    final feedState = ref.watch(feedPostsProvider);
    _print('FSCR:📊 FeedState in build:');
    _print('FSCR:   - posts: ${feedState.posts.length}');
    _print('FSCR:   - isLoadingInitial: ${feedState.isLoadingInitialAtTop}');
    _print('FSCR:   - isLoadingMore: ${feedState.isLoadingMorePostsAtBottom}');
    _print('FSCR:   - hasMorePosts: ${feedState.hasMorePosts}');
    _print('FSCR:   - totalPostCount: ${feedState.totalPostCountInFirebase}');
    _print('FSCR:   - isRefreshing: ${feedState.isRefreshingByUserRequest}');
    _print('FSCR:   - errorMessage: ${feedState.errorMessage}');
    final shouldShowIntro = ref.read(introStateNotifierProvider.notifier).shouldShow(_introType);
    ref.watch(feedLimitProvider);

    return Scaffold(
      backgroundColor: Colors.black.withAlpha(21),
      appBar: AppBarBurnMahakkaTheme(true),
      body: Stack(
        children: [
          if (!feedState.isLoadingInitialAtTop || feedState.posts.isNotEmpty)
            Column(children: [Expanded(child: _buildFeedBody(feedState, theme))]),
          if (feedState.errorMessage != null) _buildErrorBanner(feedState.errorMessage!, theme),
          if (feedState.isLoadingInitialAtTop) LinearProgressIndicator(),
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
    _print('FSCR:🔄 Building refreshable no posts widget');
    return RefreshIndicator(
      onRefresh: () async {
        _print('FSCR:🔄 no posts widget load triggered');
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

    _print('FSCR:🖼️ _hasValidImageUrl for post ${post.id}: $hasValidUrl');
    return hasValidUrl;
  }

  Widget _buildFeedBody(FeedState feedState, ThemeData theme) {
    _print('FSCR:🏗️ _buildFeedBody called');
    // final focusNode = ref.read(feedFocusNodeProvider);
    // focusNode.requestFocus();

    if (feedState.posts.isEmpty && !feedState.isLoadingInitialAtTop && !feedState.isLoadingMorePostsAtBottom) {
      _print('FSCR:📭 No posts available, showing empty state');
      return _buildRefreshableNoPostsWidget(theme, _widgetNoFeed(theme));
    }

    _print('FSCR:📜 Building ListView with ${feedState.posts.length} posts');
    _print('FSCR:📜 ListView itemCount breakdown:');
    _print('FSCR:   - base posts: ${feedState.posts.length}');
    _print('FSCR:   - loadingMore indicator: ${feedState.isLoadingMorePostsAtBottom ? 1 : 0}');
    // _print('FSCR:   - free plan limit: ${feedState.isMaxFreeLimit ? 1 : 0}');
    print(
      'FSCR:   - end message: ${(!feedState.hasMorePosts && feedState.posts.isNotEmpty && !feedState.isLoadingInitialAtTop && !feedState.isLoadingMorePostsAtBottom && !feedState.isMaxFreeLimit) ? 1 : 0}',
    );

    return
    // Focus(
    // focusNode: ref.read(feedFocusNodeProvider), // Use read, not watch
    // // focusNode: ref.read(feedFocusNodeProvider), // Use read, not watch
    // onFocusChange: (hasFocus) {
    //   print('FOCUS: FeedScreen focus changed: $hasFocus');
    // },
    // child:
    RefreshIndicator(
      onRefresh: () {
        setState(() {});
        _print('FSCR:🔄 ListView RefreshIndicator triggered');
        return ref.read(feedPostsProvider.notifier).refreshFeed();
      },
      color: theme.colorScheme.onPrimary,
      backgroundColor: theme.colorScheme.primary,
      child: FocusableActionDetector(
        autofocus: false,
        onFocusChange: (hasFocus) {
          print('FOCUS: FeedScreen focus changed: $hasFocus');
        },
        focusNode: ref.read(feedFocusNodeProvider),
        // focusNode: focusNode,
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.arrowUp): ScrollUpIntent(),
          LogicalKeySet(LogicalKeyboardKey.arrowDown): ScrollDownIntent(),
          LogicalKeySet(LogicalKeyboardKey.pageUp): ScrollUpIntent(),
          LogicalKeySet(LogicalKeyboardKey.pageDown): ScrollDownIntent(),
        },
        actions: {
          ScrollUpIntent: CallbackAction<ScrollUpIntent>(
            onInvoke: (ScrollUpIntent intent) {
              _scrollController.animateTo(_scrollController.offset - 180, duration: const Duration(milliseconds: 240), curve: Curves.easeInOut);
              return null;
            },
          ),
          ScrollDownIntent: CallbackAction<ScrollDownIntent>(
            onInvoke: (ScrollDownIntent intent) {
              _scrollController.animateTo(_scrollController.offset + 180, duration: const Duration(milliseconds: 240), curve: Curves.easeInOut);
              return null;
            },
          ),
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: _scrollController,
          itemCount: _getDisplayedItemCount(feedState),
          itemBuilder: (context, index) {
            _print('FSCR:📜 ListView building item at index: $index');

            // Apply soft limit to displayed posts
            final displayedPosts = _getDisplayedPosts(feedState);

            if (index < displayedPosts.length) {
              final post = displayedPosts[index];
              _print('FSCR:📜 Building PostCard for post ${post.id} at index $index');
              return _wrapInDoubleTapDetectorImagesOnly(post, context, feedState, theme, index: index);
            } else if (feedState.isMaxFreeLimit && index >= displayedPosts.length) {
              _print('FSCR:💰 Building free plan limit widget at index $index');
              return _buildFreePlanLimitWidget(theme);
            } else if (feedState.isLoadingMorePostsAtBottom && !feedState.isMaxFreeLimit && index >= displayedPosts.length) {
              _print('FSCR:⏳ Building loading indicator at index $index');
              return _buildLoadingIndicator();
            } else if (!feedState.hasMorePosts && index == displayedPosts.length) {
              _print('FSCR:🏁 Building end of feed message at index $index');
              return _buildEndOfFeedWidget(theme);
            }
            _print('FSCR:❌ Unexpected index in ListView builder: $index');
            return const SizedBox.shrink();
          },
        ),
      ),
      // ),
    );
  }

  int _getDisplayedItemCount(FeedState feedState) {
    final displayedPostsCount = _getDisplayedPosts(feedState).length;
    final loadingIndicatorCount = (feedState.isLoadingMorePostsAtBottom && !feedState.isMaxFreeLimit) ? 1 : 0;
    final freeLimitCount = feedState.isMaxFreeLimit ? 1 : 0;
    final endOfFeedCount =
        (!feedState.hasMorePosts &&
            displayedPostsCount > 0 &&
            !feedState.isLoadingInitialAtTop &&
            !feedState.isLoadingMorePostsAtBottom &&
            !feedState.isMaxFreeLimit)
        ? 1
        : 0;

    return displayedPostsCount + loadingIndicatorCount + freeLimitCount + endOfFeedCount;
  }

  List<MemoModelPost> _getDisplayedPosts(FeedState feedState) {
    // Apply soft limit - only show up to maxLoadItems
    if (feedState.posts.length <= ref.watch(feedLimitProvider)) {
      return feedState.posts;
    } else {
      // If we have more posts than the limit, only show the first maxLoadItems
      return feedState.posts.sublist(0, ref.watch(feedLimitProvider));
    }
  }

  Widget _buildFreePlanLimitWidget(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.0, horizontal: 6),
      child: LimitInfoWidget(limitType: LimitType.feed, compact: false),
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

  Widget _wrapInDoubleTapDetectorImagesOnly(MemoModelPost post, BuildContext context, FeedState feedState, ThemeData theme, {int? index}) {
    // _print('FSCR:👆 Wrapping post ${post.id} in GestureDetector');
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () async {
        _print('FSCR:👆 Post ${post.id} tapped');
        final imageUrl = post.imgurUrl ?? post.imageUrl ?? "";
        final ipfsId = post.ipfsCid ?? "";
        if (imageUrl.isEmpty && ipfsId.isEmpty) {
          _print('FSCR:❌ No valid image available for post ${post.id}');
          ref.read(snackbarServiceProvider).showTranslatedSnackBar("No valid image available for this post", type: SnackbarType.info);
          return;
        }

        final validImagePosts = feedState.posts.where(_hasValidImageUrl).toList();
        final validIndex = validImagePosts.indexWhere((p) => p.id == post.id);
        _print('FSCR:🖼️ Valid image posts count: ${validImagePosts.length}, current post index: $validIndex');

        if (validIndex == -1) {
          _print('FSCR:❌ Could not find post in valid image posts list');
          ref.read(snackbarServiceProvider).showTranslatedSnackBar("Could not open image viewer", type: SnackbarType.error);
          return;
        }

        _print('FSCR:🖼️ Opening image viewer for post ${post.id} at index $validIndex');
        showPostImageFullscreenWidget(context: context, theme: theme, posts: validImagePosts, initialIndex: validIndex);
      },
      child: PostCard(
        post,
        key: ValueKey(post.id.toString() + feedState.feedLimitForThisTier.toString()),
        onShowSendButton: () async {
          if (post.hasMedia) {
            var hint = "To RePublish this image or video touch the green button.";
            hint = await ref.read(autoTranslationTextProvider(hint).future);
            ref.read(snackbarServiceProvider).showTranslatedSnackBar(hint, type: SnackbarType.success);
          }

          var hint = "Comments are tied to #tags or @topics, not the original post.";
          hint = await ref.read(autoTranslationTextProvider(hint).future);
          ref.read(snackbarServiceProvider).showTranslatedSnackBar(hint, type: SnackbarType.info, wait: true);

          _print('FSCR:📜 onShowSendButton callback triggered for post ${post.id}');
          ref.read(feedScrollControllerProvider.notifier).scrollDownForPost();
        },
        index: index,
      ),
    );
  }

  Center _widgetNoFeed(ThemeData theme) {
    _print('FSCR:📭 Building no feed widget');
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

  void _print(String s) {
    if (kDebugMode) print(s);
  }
}
