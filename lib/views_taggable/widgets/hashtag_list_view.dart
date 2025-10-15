// widgets/hashtag_list_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_tag.dart';
import 'package:mahakka/provider/translation_service.dart';
import 'package:mahakka/views_taggable/view_models/search_view_model.dart';
import 'package:mahakka/views_taggable/widgets/loading_indicator.dart';
import 'package:mahakka/widgets/hashtag_display_widget.dart';

import '../../base_scrollable_list_view.dart';
import '../../custom_flutter_tagger_controller.dart';

class TaggerHashtagListView extends BaseScrollableListView {
  final CustomFlutterTaggerController tagController;
  final List<MemoModelTag> hashtags;
  final SearchState searchState;
  // final WidgetRef ref;

  const TaggerHashtagListView({Key? key, required this.tagController, required this.hashtags, required this.searchState}) : super(key: key);

  @override
  ConsumerState<TaggerHashtagListView> createState() => _TaggerHashtagListViewState();
}

class _TaggerHashtagListViewState extends BaseScrollableListViewState<TaggerHashtagListView> {
  @override
  Widget buildContent(BuildContext context, ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    return Wrap(
      direction: Axis.horizontal,
      alignment: WrapAlignment.start,
      runAlignment: WrapAlignment.start,
      spacing: 9.0,
      runSpacing: 6.0,
      children: widget.hashtags.map((hashtag) {
        return GestureDetector(
          onTap: () => _selectHashtag(hashtag),
          child: Container(
            decoration: HashtagDisplayWidget.borderDecoration(isSelected: true, theme: theme),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              child: Text("#${hashtag.name}", style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface)),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget buildEmptyState(BuildContext context, ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    var s = "Add or remove letters to match any existing #hashtag to maximize your outreach, unmatched tags automatically create new tags!";
    String translated = ref.read(autoTranslationTextProvider(s)).value ?? s;
    return Center(
      heightFactor: 6,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 0, 15, 9),
        child: Text(
          translated,
          style: textTheme.bodyMedium!.copyWith(color: colorScheme.onSurfaceVariant, letterSpacing: 1.2),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget buildLoadingState(BuildContext context, ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    return Center(heightFactor: 6, child: LoadingWidget());
  }

  void _selectHashtag(MemoModelTag hashtag) {
    widget.tagController.addTag(id: hashtag.id, name: hashtag.name);
    ref.read(searchViewModelProvider.notifier).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.searchState.isLoading && widget.hashtags.isEmpty) {
      return buildLoadingState(context, Theme.of(context), Theme.of(context).colorScheme, Theme.of(context).textTheme);
    }

    if (!widget.searchState.isLoading && widget.hashtags.isEmpty) {
      return buildEmptyState(context, Theme.of(context), Theme.of(context).colorScheme, Theme.of(context).textTheme);
    }

    if (widget.hashtags.isNotEmpty) {
      return super.build(context);
    }

    return const SizedBox.shrink();
  }
}
