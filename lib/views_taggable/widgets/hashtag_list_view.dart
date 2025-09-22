import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertagger/fluttertagger.dart';
import 'package:mahakka/memo/model/memo_model_tag.dart';
import 'package:mahakka/views_taggable/view_models/search_view_model.dart';
import 'package:mahakka/views_taggable/widgets/loading_indicator.dart';

class HashtagListView extends ConsumerWidget {
  const HashtagListView({Key? key, required this.tagController, required this.animationController, required this.hashtags}) : super(key: key);

  final FlutterTaggerController tagController;
  final AnimationController animationController;
  final List<MemoModelTag> hashtags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final searchState = ref.watch(searchViewModelProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 4.0, 4.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Hashtags",
                    style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                  onPressed: () {
                    // Dismiss overlay when close button is pressed
                    animationController.reverse();
                    tagController.dismissOverlay();
                  },
                ),
              ],
            ),
          ),
          Divider(color: theme.dividerColor, height: 1, thickness: 0.5),
          Expanded(child: _buildContent(searchState, theme, colorScheme, textTheme)),
        ],
      ),
    );
  }

  Widget _buildContent(SearchState state, ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    if (state.isLoading && hashtags.isEmpty) {
      return Center(heightFactor: 6, child: LoadingWidget());
    }

    if (!state.isLoading && hashtags.isEmpty) {
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
        padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
        itemCount: hashtags.length,
        itemBuilder: (context, index) {
          final hashtag = hashtags[index];
          return ListTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                "#",
                style: textTheme.titleMedium?.copyWith(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(hashtag.name, style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface)),
            onTap: () => _selectHashtag(hashtag),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  void _selectHashtag(MemoModelTag hashtag) {
    // CORRECTED: addTag only takes id and name parameters
    // The trigger character is handled internally by FlutterTagger
    tagController.addTag(
      id: hashtag.id ?? hashtag.name, // Use name as fallback if id is null
      name: hashtag.name,
    );

    // Dismiss the overlay using both methods for reliability
    animationController.reverse();
    tagController.dismissOverlay();
  }
}
