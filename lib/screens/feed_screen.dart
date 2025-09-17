import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/config_ipfs.dart';
import 'package:mahakka/provider/feed_posts_provider.dart';
import 'package:mahakka/theme_provider.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/widgets/burner_balance_widget.dart';
import 'package:mahakka/widgets/postcard/post_card_widget.dart';
import 'package:url_launcher/url_launcher.dart';

import '../memo/model/memo_model_post.dart';
import '../memo_data_checker.dart';
import '../widgets/post_counter_widget.dart';
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _activateKeyboardScrollingNoListClickNeeded();

    // Schedule rendering completion after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isRenderingContent = false;
        });
      }
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300 &&
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

  bool isFilterActive(PostFilterType filterType) {
    return ref.watch(feedPostsProvider).activeFilter == filterType;
  }

  @override
  Widget build(BuildContext context) {
    final asyncThemeState = ref.watch(themeNotifierProvider);
    // final asyncBurnerBalance = ref.watch(bchBurnerBalanceProvider);
    final ThemeState currentThemeState = asyncThemeState.maybeWhen(data: (data) => data, orElse: () => defaultThemeState);
    final ThemeData theme = currentThemeState.currentTheme;

    final feedState = ref.watch(feedPostsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.primary.withAlpha(21),
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
        actions: [_buildMenuTheme(currentThemeState, theme)],
      ),
      body: Stack(
        children: [
          // Show progress indicator during initial rendering
          if (_isRenderingContent || feedState.isLoadingInitial) const Center(child: CircularProgressIndicator()),

          // Show error state if something went wrong
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
                    onPressed: () {
                      setState(() {
                        _isRenderingContent = true;
                        _loadingError = null;
                      });
                      ref.read(feedPostsProvider.notifier).refreshFeed();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _isRenderingContent = false;
                          });
                        }
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
                // Post counter at the top
                const PostCounterWidget(),

                // Feed content
                Expanded(child: _buildFeedBody(theme, feedState)),
              ],
            ),
          ),
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

    return (imgurUrl != null && imgurUrl.isNotEmpty) || (imageUrl != null && imageUrl.isNotEmpty) || (ipfsUrl != null && ipfsUrl.isNotEmpty);
  }

  Widget _buildFeedBody(ThemeData theme, FeedState feedState) {
    if (feedState.posts.isEmpty && !feedState.isLoadingInitial && !feedState.isLoadingMore) {
      return _buildRefreshableNoPostsWidget(theme, _widgetNoFeed(theme));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(feedPostsProvider.notifier).refreshFeed(),
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
              if (index < feedState.posts.length) {
                final post = feedState.posts[index];
                return wrapInDoubleTapDetectorImagesOnly(post, context, feedState, theme);
              } else if (feedState.isLoadingMore && index == feedState.posts.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
                );
              } else if (!feedState.hasMorePosts &&
                  index == feedState.posts.length &&
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

        final validImagePosts = feedState.posts.where(_hasValidImageUrl).toList();
        final validIndex = validImagePosts.indexWhere((p) => p.id == post.id);

        if (validIndex == -1) {
          showSnackBar("Could not open image viewer", context, type: SnackbarType.error);
          return;
        }

        showPostImageFullscreenWidget(context: context, theme: theme, posts: validImagePosts, initialIndex: validIndex);
      },
      child: PostCard(post, key: ValueKey(post.id)),
    );
  }

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

  Widget _buildMenuTheme(ThemeState themeState, ThemeData theme) {
    return IconButton(
      icon: Icon(themeState.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      tooltip: "Toggle Theme",
      onPressed: () {
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
    if (!_scrollController.hasClients) return;
    double scrollAmount = 0;
    const double estimatedItemHeight = 300.0;

    if (intent is ScrollUpIntent) {
      scrollAmount = -estimatedItemHeight;
    } else if (intent is ScrollDownIntent) {
      scrollAmount = estimatedItemHeight;
    }

    if (scrollAmount != 0) {
      _scrollController.animateTo(
        (_scrollController.offset + scrollAmount).clamp(_scrollController.position.minScrollExtent, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }
}
