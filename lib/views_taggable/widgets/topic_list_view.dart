import 'package:flutter/material.dart';
import 'package:fluttertagger/fluttertagger.dart';
import 'package:mahakka/memo/model/memo_model_topic.dart'; // Assuming this model_original is appropriate

// Assuming SearchViewModel and LoadingWidget are correctly imported
import '../view_models/search_view_model.dart';
import 'loading_indicator.dart'; // Ensure LoadingWidget is theme-aware

class TopicListView extends StatelessWidget {
  const TopicListView({
    Key? key,
    required this.tagController,
    // The animation is used by the parent (SearchResultOverlay) for the SlideTransition.
    // This widget itself doesn't directly use it for its internal build if the parent handles the slide.
    // If TopicListView had its own internal animations driven by this, you'd keep it.
    // For now, assuming it's for the parent's SlideTransition.
    // required this.animation,
  }) : super(key: key);

  final FlutterTaggerController tagController;
  // final Animation<Offset> animation; // See comment above

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    // This widget is typically the direct child of SearchResultOverlay's Material widget.
    // The SlideTransition is handled by SearchResultOverlay.
    // So, this Container is the main visual element for the list itself.
    return Container(
      // The SearchResultOverlay now wraps this in a Material widget with elevation
      // and a themed background color (e.g., theme.colorScheme.surface).
      // So, this container can often be transparent or use a color that complements the overlay's surface.
      // If you want this specific list view to have a *different* background than the
      // generic overlay background, you can set it here. Otherwise, Colors.transparent is fine.
      decoration: BoxDecoration(
        color: colorScheme.surface, // Or theme.cardColor, or keep as is if SearchResultOverlay handles background
        // The borderRadius is likely best applied on the parent Material widget in SearchResultOverlay
        // for consistency if this is part of a larger overlay structure.
        // If this TopicListView is always the topmost part of the overlay, this is fine.
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16), // Adjusted radius
          topRight: Radius.circular(16),
        ),
        // Box shadow is also likely better on the parent Material in SearchResultOverlay
        // to avoid double shadows or inconsistent shadow application.
        // boxShadow: [
        //   BoxShadow(
        //     color: theme.shadowColor.withOpacity(0.15), // Use theme's shadow color
        //     offset: const Offset(0, -4), // Softer, more conventional offset for top shadow
        //     blurRadius: 12,
        //     spreadRadius: 1,
        //   ),
        // ],
      ),
      child: Column(
        // Using Column directly instead of nested Material if background is handled by parent
        children: [
          Padding(
            // Add padding for the close button
            padding: const EdgeInsets.only(top: 4.0, right: 4.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant), // Themed icon color
                tooltip: "Close suggestions",
                onPressed: tagController.dismissOverlay,
              ),
            ),
          ),
          Expanded(
            // Expanded to make ListView take available space in Column
            child: ValueListenableBuilder<bool>(
              valueListenable: searchViewModel.loading,
              builder: (_, isLoading, __) {
                return ValueListenableBuilder<List<MemoModelTopic>>(
                  valueListenable: searchViewModel.topics,
                  builder: (_, topics, __) {
                    if (isLoading && topics.isEmpty) {
                      // Ensure LoadingWidget is theme-aware
                      return Center(heightFactor: 6, child: LoadingWidget());
                    }
                    if (!isLoading && topics.isEmpty) {
                      return Center(
                        heightFactor: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            "No topics found matching your search.",
                            style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    if (topics.isNotEmpty) {
                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 8.0), // Padding at the bottom of the list
                        itemCount: topics.length,
                        itemBuilder: (context, index) {
                          final topic = topics[index];
                          return ListTile(
                            // ListTile properties will pick up styles from theme.listTileTheme
                            // leading: CircleAvatar( // Example of a themed leading widget
                            //   backgroundColor: colorScheme.primaryContainer,
                            //   child: Text(
                            //     topic.header.isNotEmpty ? topic.header[0].toUpperCase() : "?",
                            //     style: textTheme.titleMedium?.copyWith(color: colorScheme.onPrimaryContainer),
                            //   ),
                            //   // backgroundImage: topic.avatar.isNotEmpty ? NetworkImage(topic.avatar) : null,
                            //   // onBackgroundImageError: topic.avatar.isNotEmpty ? (_, __) {} : null,
                            // ),
                            title: Text(
                              topic.header,
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface, // Explicitly use onSurface
                              ),
                            ),
                            subtitle: Text(
                              "@${topic.header}", // Or a different property if available
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant, // Subtler color for subtitle
                              ),
                            ),
                            onTap: () {
                              tagController.addTag(id: topic.header, name: topic.header);
                              tagController.dismissOverlay(); // Dismiss overlay after selection
                            },
                            // visualDensity: VisualDensity.compact, // Optional: for tighter list items
                            // contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0), // Customize padding
                          );
                        },
                      );
                    }
                    // Fallback, though the conditions above should cover all cases
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
