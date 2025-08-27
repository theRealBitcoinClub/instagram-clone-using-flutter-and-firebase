import 'package:flutter/material.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:provider/provider.dart';

import '../memo/firebase/post_service.dart';
import '../theme_provider.dart';
import '../utils/snackbar.dart';
import '../widgets/post_card.dart';
import 'home.dart';

enum PostFilterType { images, videos, hashtags, topics }

class FeedScreen extends StatefulWidget {
  // const FeedScreen({super.key});

  const FeedScreen({super.key, required this.navBarCallback});
  final NavBarCallback navBarCallback;

  @override
  State<FeedScreen> createState() => _FeedScreenState(); // Removed constructor argument here
}

class _FeedScreenState extends State<FeedScreen> {
  // No constructor needed here for widget.navBarCallback
  final PostService _postService = PostService(); // Instance of your PostService
  final Set<PostFilterType> _activeFilters = {};

  // This will hold all posts fetched from Firebase before filtering
  List<MemoModelPost> _allFirebasePosts = [];
  // This will hold the posts to be displayed after filtering
  List<MemoModelPost> _filteredPosts = [];

  Stream<List<MemoModelPost>>? _postsStream;

  @override
  void initState() {
    super.initState();
    // Initialize the stream. You might want to order it, e.g., by creation date
    _postsStream = _postService.getAllPostsStream(orderByField: 'createdDateTime', descending: true);
    // Note: _applyFilters will now be called by the StreamBuilder
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
      // _applyFilters will be called based on the StreamBuilder's new data
      // or if you explicitly call it on the current _allFirebasePosts
      _applyFiltersOnData(_allFirebasePosts); // Apply filters to the current set of all posts
    });
    _showFilterChangeSnackbar(filterType);
  }

  // Modified to take a list of posts as input
  void _applyFiltersOnData(List<MemoModelPost> allPosts) {
    if (!mounted) return; // Ensure widget is still in the tree

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
        // Assuming post.tagIds is List<String> from Firestore for hashtags
        if (!matches && _activeFilters.contains(PostFilterType.hashtags) && post.tagIds.isNotEmpty) {
          //Check post.tagIds
          matches = true;
        }
        // Assuming post.topicId is a String from Firestore for topics
        if (!matches && _activeFilters.contains(PostFilterType.topics) && post.topicId != null && post.topicId!.isNotEmpty) {
          // Check post.topicId
          matches = true;
        }
        return matches;
      }).toList();
    }
    // No direct setState here for _filteredPosts because this function is called
    // from within StreamBuilder's builder or toggleFilter (which has setState).
    // The StreamBuilder itself will handle rebuilding when its input stream changes,
    // and toggleFilter has its own setState.
    // However, if called from toggleFilter, we might need a setState if StreamBuilder isn't active.
    // The setState in toggleFilter already covers this.
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
            return Center(child: Text('Error loading posts: ${snapshot.error}. Check Firestore indexes.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            _allFirebasePosts = []; // Clear if no data
            _applyFiltersOnData(_allFirebasePosts); // Apply filters (will result in empty _filteredPosts)
            // Still show "No posts match..." if filters are active but stream is empty
            // Or show "No posts available." if stream is empty and no filters
            if (_activeFilters.isNotEmpty && _filteredPosts.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    "No posts match the selected filters from the available feed.",
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return Center(
              child: Text(
                'No posts available in the feed yet.',
                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            );
          }

          // Store all posts from Firebase and then apply filters
          _allFirebasePosts = snapshot.data!;
          // .where((post) => post.id.isNotEmpty) // Filter out posts with empty IDs
          // .toList();
          _applyFiltersOnData(_allFirebasePosts);

          if (_filteredPosts.isEmpty && _activeFilters.isNotEmpty) {
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
          if (_filteredPosts.isEmpty && _activeFilters.isEmpty) {
            // This case should ideally be covered by the (!snapshot.hasData || snapshot.data!.isEmpty)
            // but as a safeguard if _applyFiltersOnData somehow results in empty for no filters.
            return Center(
              child: Text(
                'No posts available to display.',
                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            itemCount: _filteredPosts.length,
            itemBuilder: (context, index) {
              return PostCard(
                _filteredPosts[index],
                widget.navBarCallback,
                // key: ValueKey<String>("key${Random().nextInt(99999999)}$index"), // Use a unique ID from your post
              );
              return SizedBox(height: 100, width: 100);
            },
          );
        },
      ),
    );
  }

  Widget _buildMenuFilter(ThemeData theme) {
    return IconButton(
      icon: Icon(
        // Optionally change icon if any filter is active
        _activeFilters.isNotEmpty ? Icons.filter_alt_rounded : Icons.filter_list,
      ),
      tooltip: "Filter Posts",
      onPressed: () {
        showDialog(
          context: context,
          builder: (dialogCtx) {
            // Use StatefulBuilder if the dialog content itself needs to rebuild
            // when filters are toggled *while the dialog is open*.
            // For this example, we pop the dialog on selection, so SimpleDialog is fine.
            return SimpleDialog(
              title: Text("Filter by", style: theme.dialogTheme.titleTextStyle),
              shape: theme.dialogTheme.shape,
              backgroundColor: theme.dialogTheme.backgroundColor,
              children: [
                _buildFilterOption(theme, PostFilterType.images, "IMAGES", Icons.image_search_outlined, Icons.image_rounded),
                _buildFilterOption(theme, PostFilterType.videos, "VIDEOS", Icons.video_library_outlined, Icons.video_library_rounded),
                _buildFilterOption(theme, PostFilterType.hashtags, "HASHTAGS", Icons.tag_outlined, Icons.tag_rounded),
                _buildFilterOption(theme, PostFilterType.topics, "TOPICS", Icons.topic_outlined, Icons.topic_rounded),
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
      tooltip: "Toggle Theme",
      onPressed: () {
        themeProvider.toggleTheme();
      },
    );
  }

  Widget _buildFilterOption(ThemeData theme, PostFilterType filterType, String text, IconData icon, IconData activeIcon) {
    final bool isSelected = hasFilter(filterType);
    return SimpleDialogOption(
      onPressed: () {
        toggleFilter(filterType);
        Navigator.pop(context);
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
                Navigator.pop(context);
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
}
