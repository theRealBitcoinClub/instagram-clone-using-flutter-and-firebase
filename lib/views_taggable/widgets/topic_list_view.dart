// widgets/topic_list_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/provider/translation_service.dart';
import 'package:mahakka/views_taggable/view_models/search_view_model.dart';

import '../../base_scrollable_list_view.dart';
import '../../custom_flutter_tagger_controller.dart';
import '../../memo/model/memo_model_topic_light.dart';

class TaggerTopicListView extends BaseScrollableListView {
  final CustomFlutterTaggerController tagController;
  final List<MemoModelTopicLight> topics;
  final SearchState searchState;

  const TaggerTopicListView({Key? key, required this.tagController, required this.topics, required this.searchState}) : super(key: key);

  @override
  ConsumerState<TaggerTopicListView> createState() => _TaggerTopicListViewState();
}

class _TaggerTopicListViewState extends BaseScrollableListViewState<TaggerTopicListView> {
  @override
  Widget buildContent(BuildContext context, ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      children: widget.topics.map((topic) {
        return ListTile(
          minTileHeight: 45,
          leading: CircleAvatar(
            radius: 15,
            backgroundColor: colorScheme.primary.withAlpha(159),
            child: Text(
              "@",
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(topic.id, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface)),
          onTap: () => _selectTopic(topic),
        );
      }).toList(),
    );
  }

  @override
  Widget buildEmptyState(BuildContext context, ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    var s = "Write or remove letters to match any existing topic to maximize your outreach, unmatched topics automatically create new topics!";
    String translated = ref.read(autoTranslationTextProvider(s)).value ?? s;
    return Center(
      heightFactor: 6,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 0, 15, 9),
        child: Text(
          translated,
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant, letterSpacing: 1.2),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget buildLoadingState(BuildContext context, ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    return Center(heightFactor: 6, child: LinearProgressIndicator());
  }

  void _selectTopic(MemoModelTopicLight topic) {
    widget.tagController.addTag(
      id: topic.id.startsWith("@") ? topic.id.substring(1) : topic.id,
      name: topic.id.startsWith("@") ? topic.id.substring(1) : topic.id,
    );
    ref.read(searchViewModelProvider.notifier).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.searchState.isLoading && widget.topics.isEmpty) {
      return buildLoadingState(context, Theme.of(context), Theme.of(context).colorScheme, Theme.of(context).textTheme);
    }

    if (!widget.searchState.isLoading && widget.topics.isEmpty) {
      return buildEmptyState(context, Theme.of(context), Theme.of(context).colorScheme, Theme.of(context).textTheme);
    }

    if (widget.topics.isNotEmpty) {
      return super.build(context);
    }

    return const SizedBox.shrink();
  }
}
