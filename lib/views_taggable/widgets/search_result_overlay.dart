// widgets/search_result_overlay.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertagger/fluttertagger.dart';
import 'package:mahakka/views_taggable/view_models/search_view_model.dart';
import 'package:mahakka/views_taggable/widgets/hashtag_list_view.dart';
import 'package:mahakka/views_taggable/widgets/topic_list_view.dart';

class SearchResultOverlay extends ConsumerWidget {
  final FlutterTaggerController tagController;
  final AnimationController animationController;

  const SearchResultOverlay({Key? key, required this.tagController, required this.animationController}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final searchState = ref.watch(searchViewModelProvider);

    // Create animation here to match original implementation
    final animation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animationController, curve: Curves.easeInOutSine));

    return SlideTransition(
      position: animation,
      child: Material(
        elevation: 4.0,
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(8.0), topRight: Radius.circular(8.0)),
        child: _buildContent(searchState, theme),
      ),
    );
  }

  Widget _buildContent(SearchState state, ThemeData theme) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
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
        return TopicListView(tagController: tagController, animationController: animationController, topics: state.topics);
      case SearchResultView.hashtag:
        return HashtagListView(tagController: tagController, animationController: animationController, hashtags: state.hashtags);
      case SearchResultView.none:
      default:
        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(16.0),
          child: Text("No suggestions available.", style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        );
    }
  }
}
