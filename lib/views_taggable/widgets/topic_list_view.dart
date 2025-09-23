import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_topic.dart';
import 'package:mahakka/views_taggable/view_models/search_view_model.dart';

import '../../custom_flutter_tagger_controller.dart';

class TaggerTopicListView extends ConsumerWidget {
  const TaggerTopicListView({Key? key, required this.tagController, required this.topics}) : super(key: key);

  final CustomFlutterTaggerController tagController;
  // final AnimationController animationController;
  final List<MemoModelTopic> topics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final searchState = ref.watch(searchViewModelProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Padding(
          //   padding: const EdgeInsets.fromLTRB(0.0, 2.0, 0.0, 4.0),
          //   child: Row(
          //     children: [
          //       Expanded(
          //         child: Text(
          //           "Topics",
          //           style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
          //           textAlign: TextAlign.center,
          //         ),
          //       ),
          //       // IconButton(
          //       //   icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
          //       //   onPressed: () {
          //       //     // animationController.reverse();
          //       //     tagController.dismissOverlay();
          //       //   },
          //       // ),
          //     ],
          //   ),
          // ),
          // Divider(color: theme.dividerColor, height: 1, thickness: 0.5),
          Expanded(child: _buildContent(searchState, theme, colorScheme, textTheme)),
        ],
      ),
    );
  }

  Widget _buildContent(SearchState state, ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    if (state.isLoading && topics.isEmpty) {
      return Center(heightFactor: 6, child: LinearProgressIndicator());
    }

    if (!state.isLoading && topics.isEmpty) {
      return Center(
        heightFactor: 6,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Write or remove letters to match any existing topic to maximize your outreach, unmatched topics automatically create new topics!",
            style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (topics.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 0.0, top: 0.0),
        itemCount: topics.length,
        itemBuilder: (context, index) {
          final topic = topics[index];
          return ListTile(
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.secondaryContainer,
              child: Text(
                "@",
                style: textTheme.titleMedium?.copyWith(color: colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(topic.header, style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface)),
            onTap: () => _selectTopic(topic),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  void _selectTopic(MemoModelTopic topic) {
    // CORRECTED: addTag only takes id and name parameters
    tagController.addTag(
      id: topic.id.startsWith("@") ? topic.id.substring(1) : topic.id, // Use header as fallback if id is null
      name: topic.header.startsWith("@") ? topic.header.substring(1) : topic.header,
    );

    // animationController.reverse();
    // tagController.dismissOverlay();
  }
}
