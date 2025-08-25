import 'package:flutter/material.dart';
// Assuming these imports are still relevant for your project structure
import 'package:instagram_clone1/memomodel/memo_model_post.dart';
import 'package:instagram_clone1/resources/auth_method.dart';
// import 'package:instagram_clone1/utils/colors.dart'; // We will remove this if it only contains colors
import 'package:instagram_clone1/widgets/post_card.dart'; // Ensure PostCard also uses Theme
import 'package:provider/provider.dart';

import '../theme_provider.dart'; // Your ThemeProvider
import '../utils/snackbar.dart'; // Assuming this is theme-aware or uses context for theming

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key); // Use Key? key

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  // Example filter state - you might want to manage this more robustly
  Map<int, bool> _activeFilters = {
    0: true, // Example: Images filter is initially on
    1: false,
    2: false,
    3: false,
  };

  bool hasFilter(int filterIndex) {
    return _activeFilters[filterIndex] ?? false;
  }

  void toggleFilter(int filterIndex) {
    setState(() {
      _activeFilters[filterIndex] = !(_activeFilters[filterIndex] ?? false);
    });
    // You might want to actually apply the filter logic here
    onFilter(filterIndex);
  }

  void _signOut() async {
    // Renamed to avoid conflict with State's signOut
    // Consider showing a confirmation dialog before signing out
    AuthChecker().logOut(context); // Assuming AuthChecker handles context appropriately
  }

  @override
  Widget build(BuildContext context) {
    // Access Theme and ThemeProvider
    final ThemeData theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false); // listen:false for actions

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Use theme color
      appBar: AppBar(
        // backgroundColor is handled by AppBarTheme in your main theme
        // foregroundColor for icons/text is also handled by AppBarTheme
        centerTitle: true,
        toolbarHeight: 50, // This is fine if a specific height is always needed
        title: Text(
          "mahakka.com", // Your app name or title
          style: theme.appBarTheme.titleTextStyle, // Use titleTextStyle from AppBarTheme
          // If you had a specific font family like "Open Sans",
          // it should be part of your global TextTheme in app_themes.dart
        ),
        actions: [
          _buildMenuTheme(themeProvider, theme), // Pass theme for icon color
          _buildMenuFilter(theme), // Pass theme for icon color and dialog styling
        ],
      ),
      body: ListView.builder(
        itemCount: MemoModelPost.allPosts.length, // Ensure this model data is available
        itemBuilder: (context, index) {
          // IMPORTANT: PostCard itself MUST also be refactored to use Theme.of(context)
          // for its internal colors and text styles.
          return PostCard(MemoModelPost.allPosts[index]);
        },
      ),
    );
  }

  Widget _buildMenuFilter(ThemeData theme) {
    // Accept ThemeData
    return IconButton(
      icon: Icon(
        Icons.filter_list,
        // color: theme.appBarTheme.foregroundColor, // Icon color from AppBarTheme
      ), // Icon color will be inherited from AppBar's iconTheme or foregroundColor
      tooltip: "Filter Posts",
      onPressed: () {
        showDialog(
          context: context,
          builder: (dialogCtx) {
            // SimpleDialog will pick up styles from theme.dialogTheme
            return SimpleDialog(
              title: Text("Filter by", style: theme.dialogTheme.titleTextStyle),
              shape: theme.dialogTheme.shape, // Use theme shape
              backgroundColor: theme.dialogTheme.backgroundColor, // Use theme background
              children: [
                //TODO: Change icon based on filter state (e.g., filled vs. outlined)
                _buildFilterOption(theme, 0, "IMAGES", Icons.image_search_outlined, Icons.image_rounded),
                _buildFilterOption(theme, 1, "VIDEOS", Icons.video_library_outlined, Icons.video_library_rounded),
                _buildFilterOption(theme, 2, "HASHTAGS", Icons.tag_outlined, Icons.tag_rounded),
                _buildFilterOption(theme, 3, "TOPICS", Icons.topic_outlined, Icons.topic_rounded),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMenuTheme(ThemeProvider themeProvider, ThemeData theme) {
    // Accept ThemeData
    // Listen to themeProvider changes if the icon needs to update dynamically
    // For this example, we'll make it dynamic if the consumer is higher up or if this widget rebuilds.
    // final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode; // Or context.watch<ThemeProvider>().isDarkMode

    return IconButton(
      icon: Icon(
        themeProvider.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        // color: theme.appBarTheme.foregroundColor, // Icon color from AppBarTheme
      ), // Icon color will be inherited
      tooltip: "Toggle Theme",
      onPressed: () {
        themeProvider.toggleTheme();
        // The setState here was only for the DynamicTheme package example.
        // With Provider, the MaterialApp rebuilds when themeProvider notifies listeners.
        // No local setState is needed in _FeedScreenState for theme toggling itself.
      },
    );
  }

  // Updated to manage state via _activeFilters and use ThemeData
  Widget _buildFilterOption(ThemeData theme, int index, String text, IconData icon, IconData activeIcon) {
    final bool isSelected = hasFilter(index);
    return SimpleDialogOption(
      onPressed: () {
        toggleFilter(index);
        Navigator.pop(context); // Close dialog after selection
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0), // Add some padding
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.7),
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              // Ensure text doesn't overflow
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
                toggleFilter(index);
                Navigator.pop(context); // Close dialog after selection
              },
              activeColor: theme.colorScheme.primary, // Use theme color
              checkColor: theme.colorScheme.onPrimary, // Color of the check mark
              visualDensity: VisualDensity.compact, // Make checkbox a bit smaller
            ),
          ],
        ),
      ),
    );
  }

  void onFilter(int i) {
    // Assuming showSnackBar uses context to pick up theme for its styling
    showSnackBar("Filter for '${_getFilterName(i)}' ${hasFilter(i) ? 'activated' : 'deactivated'}.", context);
    // Actual filter logic would go here
  }

  String _getFilterName(int index) {
    switch (index) {
      case 0:
        return "IMAGES";
      case 1:
        return "VIDEOS";
      case 2:
        return "HASHTAGS";
      case 3:
        return "TOPICS";
      default:
        return "Unknown";
    }
  }
}
