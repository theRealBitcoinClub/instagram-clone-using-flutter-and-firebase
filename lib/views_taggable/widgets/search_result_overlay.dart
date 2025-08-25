import 'package:flutter/material.dart';
import 'package:fluttertagger/fluttertagger.dart'; // Keep if FlutterTaggerController is used directly for styling
import 'package:mahakka/views_taggable/widgets/hashtag_list_view.dart';
// Ensure these child widgets are also theme-aware
import 'package:mahakka/views_taggable/widgets/topic_list_view.dart';

// Assuming SearchResultView and searchViewModel are correctly imported and accessible
import '../view_models/search_view_model.dart';

// Define SearchResultView enum if it's not already defined elsewhere accessible here
// enum SearchResultView { users, topics, hashtag } // Example definition

class SearchResultOverlay extends StatelessWidget {
  const SearchResultOverlay({
    Key? key,
    required this.tagController,
    required this.animation,
    // Optional: Pass the SearchViewModel directly if it's not a global/singleton
    // required this.searchViewModel,
  }) : super(key: key);

  final FlutterTaggerController tagController;
  final Animation<Offset> animation;
  // final SearchViewModel searchViewModel; // Uncomment if passing viewModel as a param

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context); // Get the current theme

    // The overlay itself is often displayed within a Material widget provided by FlutterTagger
    // or the OverlayPortal. However, if this widget itself needs a specific background,
    // you can wrap its content in a Container or Card.
    // For this example, we'll assume the direct child list views handle their own backgrounds.

    return SlideTransition(
      // Apply the animation given by FlutterTagger
      position: animation,
      child: Material(
        // Provides a default canvas color and elevation
        elevation: 4.0, // Standard elevation for overlays
        color: theme.colorScheme.surface, // Use theme's surface color for the overlay background
        borderRadius: const BorderRadius.only(
          // Optional: if you want rounded corners
          topLeft: Radius.circular(8.0),
          topRight: Radius.circular(8.0),
          // Adjust based on OverlayPosition in FlutterTagger
        ),
        child: ValueListenableBuilder<SearchResultView>(
          // Assuming searchViewModel is a global/singleton or provided via Provider/DI.
          // If not, it should be passed as a constructor argument.
          valueListenable: searchViewModel.activeView,
          builder: (context, view, __) {
            // Ensure TopicListView and HashtagListView are theme-aware.
            // They should use Theme.of(context) for their internal styling
            // (list item backgrounds, text styles, icon colors, dividers, etc.).
            switch (view) {
              // case SearchResultView.users:
              //   return UserListView( // Ensure UserListView is themed
              //     tagController: tagController,
              //     // animation: animation, // Animation is applied to the parent
              //   );
              case SearchResultView.topics:
                return TopicListView(
                  tagController: tagController,
                  // animation: animation,
                  // Pass theme if TopicListView needs it directly,
                  // but it's better if it uses Theme.of(context) internally.
                );
              case SearchResultView.hashtag:
                return HashtagListView(
                  tagController: tagController,
                  // animation: animation
                );
              default:
                // Return a themed empty placeholder if no view matches
                // or if the view is for an unsupported type.
                return Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "No suggestions available.",
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}
