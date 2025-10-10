import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/provider/translation_service.dart';
import 'package:mahakka/views_taggable/taggable_providers.dart';
import 'package:mahakka/views_taggable/view_models/search_view_model.dart';
import 'package:mahakka/views_taggable/widgets/hashtag_list_view.dart';
import 'package:mahakka/views_taggable/widgets/topic_list_view.dart';

class SearchResultBox extends ConsumerWidget {
  const SearchResultBox({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final searchState = ref.watch(searchViewModelProvider);
    final tagController = ref.watch(taggableControllerProvider);

    return Material(
      elevation: 4.0,
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(8.0), topRight: Radius.circular(8.0)),
      child:
          // GestureDetector(
          //   onTap: () {}, // Prevent tap from bubbling up to parent
          //   child:
          _buildContent(searchState, theme, tagController, ref),
      // ),
    );
  }

  Widget _buildContent(SearchState state, ThemeData theme, tagController, WidgetRef ref) {
    if (state.isLoading) {
      return LinearProgressIndicator();
    }

    if (state.error != null) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16.0),
        child: Text(state.error!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
      );
    }

    switch (state.activeView) {
      case SearchResultView.topics:
        return TaggerTopicListView(tagController: tagController, topics: state.topics, searchState: state);
      case SearchResultView.hashtag:
        return TaggerHashtagListView(tagController: tagController, hashtags: state.hashtags, searchState: state);
      case SearchResultView.hintText:
        var s =
            "Write @ to attach a post to any @topic or # to add #hashtags to your post. You can post to one topic and/or add up to three hashtags";
        String displayText = ref.read(autoTranslationTextProvider(s)).value ?? s;
        return Container(
          alignment: Alignment.center,
          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Center(
            child: Text(
              displayText,
              style: theme.textTheme.bodyMedium!.copyWith(color: theme.colorScheme.onSurfaceVariant, letterSpacing: 0.5),
            ),
          ),
        );
    }
  }
}
