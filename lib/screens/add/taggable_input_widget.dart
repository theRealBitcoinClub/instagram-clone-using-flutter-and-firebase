// widgets/taggable_input_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertagger/fluttertagger.dart';
import 'package:mahakka/views_taggable/view_models/search_view_model.dart';
import 'package:mahakka/views_taggable/widgets/comment_text_field.dart';
import 'package:mahakka/views_taggable/widgets/search_result_overlay.dart';

class TaggableInputWidget extends ConsumerWidget {
  final FlutterTaggerController textInputController;
  final AnimationController animationController;
  final FocusNode focusNode;
  final EdgeInsets viewInsets;
  final VoidCallback onPublish;
  final double overlayHeight;

  const TaggableInputWidget({
    Key? key,
    required this.textInputController,
    required this.animationController,
    required this.focusNode,
    required this.viewInsets,
    required this.onPublish,
    this.overlayHeight = 300,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final searchViewModel = ref.read(searchViewModelProvider.notifier);

    return Material(
      elevation: 4.0,
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FlutterTagger(
          triggerStrategy: TriggerStrategy.eager,
          controller: textInputController,
          animationController: animationController,
          onSearch: (query, triggerChar) {
            if (triggerChar == "@") {
              searchViewModel.searchTopic(query);
            } else if (triggerChar == "#") {
              searchViewModel.searchHashtag(query);
            }
          },
          triggerCharacterAndStyles: _buildTriggerStyles(theme),
          tagTextFormatter: (id, tag, triggerChar) => "$triggerChar$id#$tag#",
          overlayHeight: overlayHeight,
          overlay: SearchResultOverlay(tagController: textInputController, animationController: animationController),
          builder: (context, containerKey) {
            return CommentTextField(
              onInputText: (value) {
                if (value.contains('\n')) {
                  textInputController.text = value.replaceAll("\n", "");
                  onPublish();
                }
              },
              focusNode: focusNode,
              containerKey: containerKey,
              insets: viewInsets,
              controller: textInputController,
              hintText: "Add a caption... use @ for topics, # for tags",
              onSend: onPublish,
            );
          },
        ),
      ),
    );
  }

  Map<String, TextStyle> _buildTriggerStyles(ThemeData theme) {
    return {
      "@": theme.textTheme.bodyLarge!.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
      "#": theme.textTheme.bodyLarge!.copyWith(color: theme.colorScheme.tertiary, fontWeight: FontWeight.bold),
    };
  }
}
