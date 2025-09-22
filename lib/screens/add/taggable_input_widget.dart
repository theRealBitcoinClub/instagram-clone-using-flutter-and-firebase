// widgets/taggable_input_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertagger/fluttertagger.dart';
import 'package:mahakka/views_taggable/view_models/search_view_model.dart';
import 'package:mahakka/views_taggable/widgets/comment_text_field.dart';
import 'package:mahakka/views_taggable/widgets/search_result_overlay.dart';

// CHANGE: Convert from ConsumerWidget to ConsumerStatefulWidget
class TaggableInputWidget extends ConsumerStatefulWidget {
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

  // ADD: Override createState
  @override
  ConsumerState<TaggableInputWidget> createState() => _TaggableInputWidgetState();
}

// ADD: New State class
class _TaggableInputWidgetState extends ConsumerState<TaggableInputWidget> {
  // ADD: Dismissal method
  void _dismissOverlay() {
    widget.animationController.reverse();
    widget.textInputController.dismissOverlay();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchViewModel = ref.read(searchViewModelProvider.notifier);

    // ADD: Wrap with GestureDetector for external tap dismissal
    return GestureDetector(
      onTap: _dismissOverlay,
      behavior: HitTestBehavior.opaque,
      child: Material(
        elevation: 4.0,
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FlutterTagger(
            triggerStrategy: TriggerStrategy.eager,
            controller: widget.textInputController, // ADD: widget. prefix
            animationController: widget.animationController, // ADD: widget. prefix
            onSearch: (query, triggerChar) {
              if (triggerChar == "@") {
                searchViewModel.searchTopic(query);
              } else if (triggerChar == "#") {
                searchViewModel.searchHashtag(query);
              }
            },
            triggerCharacterAndStyles: _buildTriggerStyles(theme),
            tagTextFormatter: (id, tag, triggerChar) => "$triggerChar$id#$tag#",
            overlayHeight: widget.overlayHeight, // ADD: widget. prefix
            // CHANGE: Pass dismissal callback to overlay
            overlay: SearchResultOverlay(
              tagController: widget.textInputController, // ADD: widget. prefix
              animationController: widget.animationController, // ADD: widget. prefix
              onExternalTap: _dismissOverlay, // ADD: This line
            ),
            builder: (context, containerKey) {
              return CommentTextField(
                onInputText: (value) {
                  if (value.contains('\n')) {
                    widget.textInputController.text = value.replaceAll("\n", ""); // ADD: widget. prefix
                    widget.onPublish(); // ADD: widget. prefix
                  }
                },
                focusNode: widget.focusNode, // ADD: widget. prefix
                containerKey: containerKey,
                insets: widget.viewInsets, // ADD: widget. prefix
                controller: widget.textInputController, // ADD: widget. prefix
                hintText: "Add a caption... use @ for topics, # for tags",
                onSend: widget.onPublish, // ADD: widget. prefix
              );
            },
          ),
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
