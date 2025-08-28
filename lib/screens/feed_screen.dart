import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:provider/provider.dart';

import '../memo/firebase/post_service.dart';
import '../theme_provider.dart';
import '../utils/snackbar.dart';
import '../widgets/post_card.dart';
import 'home.dart';

enum PostFilterType { images, videos, hashtags, topics }

class ScrollUpIntent extends Intent {}

class ScrollDownIntent extends Intent {}

class PageUpIntent extends Intent {}

class PageDownIntent extends Intent {}

class HomeIntent extends Intent {}

class EndIntent extends Intent {}

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, required this.navBarCallback});
  final NavBarCallback navBarCallback;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PostService _postService = PostService();
  final Set<PostFilterType> _activeFilters = {};

  List<MemoModelPost> _allFirebasePosts = [];
  List<MemoModelPost> _filteredPosts = [];

  Stream<List<MemoModelPost>>? _postsStream;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _listViewFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _postsStream = _postService.getAllPostsStream();
    _activateKeyboardScrollingNoListClickNeeded();
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
    _scrollController.dispose();
    _listViewFocusNode.dispose();
    super.dispose();
  }

  bool hasFilter(PostFilterType filterType) {
    return _activeFilters.contains(filterType);
  }

  void toggleFilter(PostFilterType filterType) {
    setState(() {
      if (_activeFilters.contains(filterType)) {
        _activeFilters.remove(filterType);
      } else {
        _activeFilters.add(filterType);
      }
      _applyFiltersOnData(_allFirebasePosts);
    });
    _showFilterChangeSnackbar(filterType);
  }

  void _applyFiltersOnData(List<MemoModelPost> allPosts) {
    if (!mounted) return;

    if (_activeFilters.isEmpty) {
      _filteredPosts = List.from(allPosts);
    } else {
      _filteredPosts = allPosts.where((post) {
        bool matches = false;
        if (_activeFilters.contains(PostFilterType.images) && post.imgurUrl != null && post.imgurUrl!.isNotEmpty) {
          matches = true;
        }
        if (!matches && _activeFilters.contains(PostFilterType.videos) && post.youtubeId != null && post.youtubeId!.isNotEmpty) {
          matches = true;
        }
        if (!matches && _activeFilters.contains(PostFilterType.hashtags) && post.tagIds.isNotEmpty) {
          matches = true;
        }
        if (!matches && _activeFilters.contains(PostFilterType.topics) && post.topicId.isNotEmpty) {
          matches = true;
        }
        return matches;
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 50,
        title: Text("mahakka.com", style: theme.appBarTheme.titleTextStyle),
        actions: [_buildMenuTheme(themeProvider, theme), _buildMenuFilter(theme)],
      ),
      body: StreamBuilder<List<MemoModelPost>>(
        stream: _postsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Error in posts stream: ${snapshot.error}");
            return Center(child: Text('Error loading posts: ${snapshot.error}.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            _allFirebasePosts = [];
            _applyFiltersOnData(_allFirebasePosts);
            if (_activeFilters.isNotEmpty && _filteredPosts.isEmpty) {
              return _widgetNoMatch(theme);
            }
            return _widgetNoFeed(theme);
          }

          //TODO filter out all video posts until video player works well
          // Store all posts from Firebase and then apply filters
          _allFirebasePosts = snapshot.data!
              .where((post) => post.youtubeId == null || post.youtubeId!.isNotEmpty) // Filter out posts with empty IDs
              .toList();
          _applyFiltersOnData(_allFirebasePosts);

          if (_filteredPosts.isEmpty && _activeFilters.isNotEmpty) {
            return _widgetNoMatch(theme);
          }
          if (_filteredPosts.isEmpty && _activeFilters.isEmpty) {
            return _widgetNoFeed(theme);
          }

          return FocusableActionDetector(
            autofocus: true, // Automatically request focus for the detector
            focusNode: _listViewFocusNode,
            shortcuts: _getKeyboardShortcuts(),
            actions: <Type, Action<Intent>>{
              ScrollUpIntent: CallbackAction<ScrollUpIntent>(onInvoke: (intent) => _handleScrollIntent(intent, context)),
              ScrollDownIntent: CallbackAction<ScrollDownIntent>(onInvoke: (intent) => _handleScrollIntent(intent, context)),
              PageUpIntent: CallbackAction<PageUpIntent>(onInvoke: (intent) => _handleScrollIntent(intent, context)),
              PageDownIntent: CallbackAction<PageDownIntent>(onInvoke: (intent) => _handleScrollIntent(intent, context)),
              HomeIntent: CallbackAction<HomeIntent>(onInvoke: (intent) => _handleScrollIntent(intent, context)),
              EndIntent: CallbackAction<EndIntent>(onInvoke: (intent) => _handleScrollIntent(intent, context)),
            },
            child: GestureDetector(
              // Optional: to allow clicking on list to focus
              onTap: () {
                if (!_listViewFocusNode.hasFocus) {
                  FocusScope.of(context).requestFocus(_listViewFocusNode);
                }
              },
              child: ListView.builder(
                controller: _scrollController,
                // Optional: To ensure focus can be given to the ListView itself,
                // you might need to ensure it's focusable, though FocusableActionDetector
                // often handles this for its descendants.
                // focusNode: _listViewFocusNode, // Can also be put here directly
                itemCount: _filteredPosts.length,
                itemBuilder: (context, index) {
                  return PostCard(_filteredPosts[index], widget.navBarCallback, key: ValueKey(_filteredPosts[index].id));
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Center _widgetNoFeed(ThemeData theme) {
    return Center(
      child: Text(
        'No posts available in the feed yet.',
        style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        textAlign: TextAlign.center,
      ),
    );
  }

  Center _widgetNoMatch(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          "No posts match the selected filters.",
          style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildMenuFilter(ThemeData theme) {
    return IconButton(
      icon: Icon(
        // Optionally change icon if any filter is active
        _activeFilters.isNotEmpty ? Icons.filter_alt_rounded : Icons.filter_list,
      ),
      // tooltip: "Filter Posts",
      onPressed: () {
        showDialog(
          context: context,
          builder: (dialogCtx) {
            return SimpleDialog(
              title: Text("Filter by", style: theme.dialogTheme.titleTextStyle),
              shape: theme.dialogTheme.shape,
              backgroundColor: theme.dialogTheme.backgroundColor,
              children: [
                _buildFilterOption(dialogCtx, theme, PostFilterType.images, "IMAGES", Icons.image_search_outlined, Icons.image_rounded),
                // _buildFilterOption(theme, PostFilterType.videos, "VIDEOS", Icons.video_library_outlined, Icons.video_library_rounded),
                _buildFilterOption(dialogCtx, theme, PostFilterType.hashtags, "HASHTAGS", Icons.tag_outlined, Icons.tag_rounded),
                _buildFilterOption(dialogCtx, theme, PostFilterType.topics, "TOPICS", Icons.topic_outlined, Icons.topic_rounded),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMenuTheme(ThemeProvider themeProvider, ThemeData theme) {
    return IconButton(
      icon: Icon(themeProvider.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      // tooltip: "Toggle Theme",
      onPressed: () {
        themeProvider.toggleTheme();
      },
    );
  }

  Widget _buildFilterOption(dialogCtx, ThemeData theme, PostFilterType filterType, String text, IconData icon, IconData activeIcon) {
    final bool isSelected = hasFilter(filterType);
    return SimpleDialogOption(
      onPressed: () {
        toggleFilter(filterType);
        Navigator.pop(dialogCtx);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.7),
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isSelected ? theme.colorScheme.primary : theme.textTheme.titleMedium?.color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            Checkbox(
              value: isSelected,
              onChanged: (value) {
                toggleFilter(filterType);
                Navigator.pop(dialogCtx);
              },
              activeColor: theme.colorScheme.primary,
              checkColor: theme.colorScheme.onPrimary,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterChangeSnackbar(PostFilterType filterType) {
    final filterName = _getFilterName(filterType);
    final isActive = hasFilter(filterType);
    showSnackBar("Filter for '$filterName' ${isActive ? 'activated' : 'deactivated'}.", context);
  }

  String _getFilterName(PostFilterType filterType) {
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

  Map<ShortcutActivator, Intent> _getKeyboardShortcuts() {
    return <ShortcutActivator, Intent>{
      const SingleActivator(LogicalKeyboardKey.arrowUp): ScrollUpIntent(),
      const SingleActivator(LogicalKeyboardKey.arrowDown): ScrollDownIntent(),
      const SingleActivator(LogicalKeyboardKey.pageUp): PageUpIntent(),
      const SingleActivator(LogicalKeyboardKey.pageDown): PageDownIntent(),
      const SingleActivator(LogicalKeyboardKey.home): HomeIntent(),
      const SingleActivator(LogicalKeyboardKey.end): EndIntent(),
    };
  }

  void _handleScrollIntent(Intent intent, BuildContext context) {
    if (!_scrollController.hasClients) return;

    double scrollAmount = 0;
    // Estimate item height - adjust this based on your average PostCard height
    // Or, for more precision, you could try to get the height of visible items.
    // This is a simpler approach.
    const double estimatedItemHeight = 300.0; // Adjust this value!
    final double viewportHeight = _scrollController.position.viewportDimension;

    if (intent is ScrollUpIntent) {
      scrollAmount = -estimatedItemHeight; // Scroll up by one item height
    } else if (intent is ScrollDownIntent) {
      scrollAmount = estimatedItemHeight; // Scroll down by one item height
    } else if (intent is PageUpIntent) {
      scrollAmount = -viewportHeight; // Scroll up by one viewport height
    } else if (intent is PageDownIntent) {
      scrollAmount = viewportHeight; // Scroll down by one viewport height
    } else if (intent is HomeIntent) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    } else if (intent is EndIntent) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }

    if (scrollAmount != 0) {
      _scrollController.animateTo(
        (_scrollController.offset + scrollAmount).clamp(_scrollController.position.minScrollExtent, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 200), // Adjust duration as needed
        curve: Curves.easeOut,
      );
    }
  }
}
