import 'package:flutter/material.dart';
import 'package:fluttertagger/fluttertagger.dart';
import 'package:mahakka/memo/memomodel/memo_model_tag.dart'; // Ensure correct model_original import

// Assuming SearchViewModel and LoadingWidget are correctly imported
import '../view_models/search_view_model.dart';
import 'loading_indicator.dart'; // Ensure LoadingWidget is theme-aware

class HashtagListView extends StatelessWidget {
  const HashtagListView({
    Key? key,
    required this.tagController,
    // Animation is likely handled by the parent SearchResultOverlay
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
    return Container(
      // The SearchResultOverlay now wraps this in a Material widget with elevation
      // and a themed background color (e.g., theme.colorScheme.surface).
      padding: const EdgeInsets.symmetric(horizontal: 4.0), // Consistent horizontal padding
      decoration: BoxDecoration(
        color: colorScheme.surface, // Use theme's surface color
        // borderRadius is likely best on the parent Material in SearchResultOverlay
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
        // boxShadow is also likely better on the parent Material in SearchResultOverlay
        // boxShadow: [
        //   BoxShadow(
        //     color: theme.shadowColor.withOpacity(0.15),
        //     offset: const Offset(0, -4),
        //     blurRadius: 12,
        //     spreadRadius: 1,
        //   ),
        // ],
      ),
      child: Column(
        // Using Column directly
        children: [
          Padding(
            // Padding for the header row
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 4.0, 4.0), // Adjusted padding
            child: Row(
              // mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute space
              children: [
                // SizedBox(width: 40), // Placeholder for symmetry if needed, or remove
                Expanded(
                  child: Text(
                    "Hashtags",
                    style: textTheme.titleLarge?.copyWith(
                      // More prominent title
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                  tooltip: "Close suggestions",
                  onPressed: tagController.dismissOverlay,
                ),
              ],
            ),
          ),
          // const SizedBox(height: 4), // Reduce spacing if header is padded
          Divider(color: theme.dividerColor, height: 1, thickness: 0.5), // Themed divider
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: searchViewModel.loading,
              builder: (_, isLoading, __) {
                return ValueListenableBuilder<List<MemoModelTag>>(
                  valueListenable: searchViewModel.hashtags,
                  builder: (_, hashtags, __) {
                    if (isLoading && hashtags.isEmpty) {
                      return Center(heightFactor: 6, child: LoadingWidget());
                    }
                    if (!isLoading && hashtags.isEmpty) {
                      return Center(
                        heightFactor: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            "Didn't find any tags matching your search!",
                            style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    if (hashtags.isNotEmpty) {
                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 8.0, top: 4.0), // Padding for the list
                        itemCount: hashtags.length,
                        itemBuilder: (context, index) {
                          final hashtag = hashtags[index];
                          // Use a more standard ListTile appearance
                          return ListTile(
                            leading: CircleAvatar(
                              // Themed CircleAvatar for '#'
                              radius: 20,
                              backgroundColor: colorScheme.primaryContainer,
                              child: Text(
                                "#",
                                style: textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              hashtag.name ?? "Unnamed Tag", // Handle null name
                              style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
                            ),
                            // subtitle: Text(" Posts: ${hashtag.postCount ?? 0}", // Example if you have post count
                            //   style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                            // ),
                            onTap: () {
                              if (hashtag.name != null) {
                                tagController.addTag(id: hashtag.name!, name: hashtag.name!);
                                tagController.dismissOverlay(); // Dismiss overlay after selection
                              }
                            },
                            // Add a subtle border or keep it clean
                            // dense: true, // For a more compact list
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink(); // Fallback
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
