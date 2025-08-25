import 'package:flutter/material.dart';
import 'package:mahakka/memomodel/memo_model_post.dart';
import 'package:mahakka/resources/auth_method.dart';
import 'package:mahakka/widgets/post_card.dart';
import 'package:provider/provider.dart';

import '../theme_provider.dart';
import '../utils/snackbar.dart';

// Enum for better filter management (optional but good practice)
enum PostFilterType { images, videos, hashtags, topics }

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  // Use a Set for active filters for easier management
  final Set<PostFilterType> _activeFilters = {
    // PostFilterType.images // Example: Start with Images filter on by default
  }; // Start with no filters active or define defaults

  // This will hold the posts to be displayed after filtering
  List<MemoModelPost> _filteredPosts = [];

  @override
  void initState() {
    super.initState();
    _applyFilters(); // Apply initial filters (which might be none, showing all posts)
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
      _applyFilters(); // Re-apply filters whenever a filter is toggled
    });
    // The onFilter method is now primarily for the snackbar
    _showFilterChangeSnackbar(filterType);
  }

  void _applyFilters() {
    final allPosts = MemoModelPost.allPosts; // Get all posts from your static source

    if (_activeFilters.isEmpty) {
      // If no filters are active, show all posts
      _filteredPosts = List.from(allPosts);
    } else {
      _filteredPosts = allPosts.where((post) {
        // Check if the post matches ANY of the active filters
        bool matches = false;
        if (_activeFilters.contains(PostFilterType.images) && post.imgurUrl != null && post.imgurUrl!.isNotEmpty) {
          matches = true;
        }
        if (!matches && // Optimization: if already matched, no need to check further for this post
            _activeFilters.contains(PostFilterType.videos) &&
            post.youtubeId != null &&
            post.youtubeId!.isNotEmpty) {
          matches = true;
        }
        if (!matches && _activeFilters.contains(PostFilterType.hashtags) && post.hashtags.isNotEmpty) {
          // Assuming `hashtags` is a List<String>
          matches = true;
        }
        if (!matches &&
            _activeFilters.contains(PostFilterType.topics) &&
            post.topic != null /* && post.topic.header.isNotEmpty - if topic is an object */ ) {
          matches = true;
        }
        return matches;
      }).toList();
    }
    // No need to call setState here for _filteredPosts because
    // _applyFilters is called within setState when toggleFilter is used.
    // The ListView.builder will use the updated _filteredPosts.
  }

  void _signOut() async {
    AuthChecker().logOut(context);
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
      body: _filteredPosts.isEmpty && _activeFilters.isNotEmpty
          ? Center(
              // Show a message if filters are active but no posts match
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "No posts match the selected filters.",
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              itemCount: _filteredPosts.length, // Use the filtered list
              itemBuilder: (context, index) {
                return PostCard(_filteredPosts[index]); // Pass the filtered post
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
                _buildFilterOption(
                  theme,
                  PostFilterType.images,
                  "IMAGES",
                  Icons.image_search_outlined,
                  Icons.image_rounded,
                ),
                _buildFilterOption(
                  theme,
                  PostFilterType.videos,
                  "VIDEOS",
                  Icons.video_library_outlined,
                  Icons.video_library_rounded,
                ),
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

  Widget _buildFilterOption(
    ThemeData theme,
    PostFilterType filterType,
    String text,
    IconData icon,
    IconData activeIcon,
  ) {
    // We need a StatefulWidget or StatefulBuilder for the dialog options if we want them
    // to update their checkbox state live while the dialog is open without closing it.
    // However, since we pop the dialog on selection, we can use the main state.
    final bool isSelected = hasFilter(filterType);

    return SimpleDialogOption(
      onPressed: () {
        toggleFilter(filterType); // This will call setState in _FeedScreenState
        Navigator.pop(context); // Close dialog after selection
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
                // This onChanged is redundant if SimpleDialogOption.onPressed does the job,
                // but standard for Checkbox.
                toggleFilter(filterType);
                Navigator.pop(context); // Close dialog after selection
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

  // Renamed from onFilter to be more specific
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
        return "HASHTAGS";
      case PostFilterType.topics:
        return "TOPICS";
    }
  }
}
