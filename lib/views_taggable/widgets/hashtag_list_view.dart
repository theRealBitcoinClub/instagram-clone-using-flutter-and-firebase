import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/memo_reg_exp.dart';
import 'package:mahakka/memo/model/memo_model_tag.dart';
import 'package:mahakka/views_taggable/taggable_providers.dart';
import 'package:mahakka/views_taggable/view_models/search_view_model.dart';
import 'package:mahakka/views_taggable/widgets/loading_indicator.dart';
import 'package:mahakka/widgets/hashtag_display_widget.dart';

import '../../custom_flutter_tagger_controller.dart';

class TaggerHashtagListView extends ConsumerWidget {
  const TaggerHashtagListView({Key? key, required this.tagController, required this.hashtags}) : super(key: key);

  final CustomFlutterTaggerController tagController;
  // final AnimationController animationController;
  final List<MemoModelTag> hashtags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final searchState = ref.watch(searchViewModelProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      // decoration: BoxDecoration(
      //   borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
      // ),
      child: Column(
        children: [
          // Padding(
          //   padding: const EdgeInsets.fromLTRB(16.0, 4.0, 4.0, 4.0),
          //   child: Row(
          //     children: [
          //       // Expanded(
          //       //   child: Text(
          //       //     "Hashtags",
          //       //     style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
          //       //     textAlign: TextAlign.center,
          //       //   ),
          //       // ),
          //       // IconButton(
          //       //   icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
          //       //   onPressed: () {
          //       //     // Dismiss overlay when close button is pressed
          //       //     // animationController.reverse();
          //       //     tagController.dismissOverlay();
          //       //   },
          //       // ),
          //     ],
          //   ),
          // ),
          // Divider(color: theme.dividerColor, height: 1, thickness: 0.5),
          Expanded(child: _buildContent(searchState, theme, colorScheme, textTheme, ref)),
        ],
      ),
    );
  }

  Widget _buildContent(SearchState state, ThemeData theme, ColorScheme colorScheme, TextTheme textTheme, WidgetRef ref) {
    if (state.isLoading && hashtags.isEmpty) {
      return Center(heightFactor: 6, child: LoadingWidget());
    }

    if (!state.isLoading && hashtags.isEmpty) {
      return Center(
        heightFactor: 6,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Add or remove letters to match any existing #hashtag to maximize your outreach, unmatched tags automatically create new tags!",
            style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (hashtags.isNotEmpty) {
      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          width: double.infinity,
          child: Wrap(
            direction: Axis.horizontal,
            alignment: WrapAlignment.start,
            runAlignment: WrapAlignment.start,
            spacing: 8.0,
            runSpacing: 4.0,
            children: hashtags.map((hashtag) {
              return GestureDetector(
                onTap: () => _selectHashtag(hashtag),
                child: Container(
                  decoration: HashtagDisplayWidget.borderDecoration(isSelected: true, theme: theme),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: Text("#${hashtag.name}", style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
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
    // animationController.reverse();
    tagController.dismissOverlay();
  }

  bool hasSelectedTag(MemoModelTag hashtag, WidgetRef ref) {
    return MemoRegExp.extractHashtags(ref.read(taggableControllerProvider).text).contains(hashtag.name);
  }
}
