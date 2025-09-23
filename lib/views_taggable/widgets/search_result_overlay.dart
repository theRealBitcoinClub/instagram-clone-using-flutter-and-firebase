// widgets/search_result_overlay.dart - WITH EXTERNAL TAP SUPPORT
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/views_taggable/taggable_providers.dart';
import 'package:mahakka/views_taggable/view_models/search_view_model.dart';
import 'package:mahakka/views_taggable/widgets/hashtag_list_view.dart';
import 'package:mahakka/views_taggable/widgets/topic_list_view.dart';

class SearchResultBox extends ConsumerWidget {
  const SearchResultBox({Key? key}) : super(key: key);

  // _dismissOverlay(ref) {
  //   // final animationController = ref.read(animationControllerNotifierProvider);
  //   final tagController = ref.read(taggableControllerProvider);
  //   // if (animationController != null) animationController.reverse();
  //   tagController.dismissOverlay();
  // }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final searchState = ref.watch(searchViewModelProvider);
    // final animationController = ref.watch(animationControllerNotifierProvider);
    final tagController = ref.watch(taggableControllerProvider);
    // final animation = ref.watch(overlayAnimationProvider);

    return
    // GestureDetector(
    // onTap: _dismissOverlay(ref), // Dismiss on external tap
    // behavior: HitTestBehavior.opaque,
    // child:
    // SlideTransition(
    //   position: animation,
    //   child:
    Material(
      elevation: 4.0,
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(8.0), topRight: Radius.circular(8.0)),
      child: GestureDetector(
        onTap: () {}, // Prevent tap from bubbling up to parent
        child: _buildContent(searchState, theme, tagController),
      ),
      // ),
      // ),
    );
  }

  Widget _buildContent(SearchState state, ThemeData theme, tagController) {
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
        return TaggerTopicListView(tagController: tagController, topics: state.topics);
      case SearchResultView.hashtag:
        return TaggerHashtagListView(tagController: tagController, hashtags: state.hashtags);
      case SearchResultView.none:
      default:
        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Text(
              "Write @ to attach a post to any topic or # to add hashtags to your post, you can post to one topic and add up to three hashtags",
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        );
    }
  }
}
