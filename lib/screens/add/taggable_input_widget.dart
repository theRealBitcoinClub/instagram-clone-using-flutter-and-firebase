// widgets/taggable_input_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/custom_flutter_tagger_controller.dart';
import 'package:mahakka/screens/add_post_controller.dart';
import 'package:mahakka/views_taggable/view_models/search_view_model.dart';
import 'package:mahakka/views_taggable/widgets/comment_text_field.dart';
import 'package:mahakka/views_taggable/widgets/search_result_overlay.dart';

import '../../custom_tagger.dart';
import '../../views_taggable/taggable_providers.dart';

class TaggableInputWidget extends ConsumerWidget {
  const TaggableInputWidget({Key? key}) : super(key: key);

  _dismissOverlay(ref) {
    // final animationController = ref.read(animationControllerNotifierProvider);
    CustomFlutterTaggerController tagController = ref.read(taggableControllerProvider);
    // animationController.reverse();
    tagController.dismissOverlay();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final searchViewModel = ref.read(searchViewModelProvider.notifier);
    final postController = ref.read(addPostControllerProvider.notifier);
    final textInputController = ref.watch(taggableControllerProvider);
    // final animationController = ref.watch(animationControllerNotifierProvider);
    final focusNode = ref.watch(focusNodeProvider);
    // final overlayDismissal = ref.read(overlayDismissalProvider);
    final viewInsets = MediaQuery.of(context).viewInsets;

    return GestureDetector(
      onTap: _dismissOverlay(ref),
      behavior: HitTestBehavior.opaque,
      child: Material(
        elevation: 4.0,
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: CustomFlutterTagger(
            triggerStrategy: TriggerStrategy.eager,
            controller: textInputController, // ADD: widget. prefix
            // animationController: animationController, // ADD: widget. prefix
            onSearch: (query, triggerChar) {
              if (triggerChar == "@") {
                searchViewModel.searchTopic(query);
              } else if (triggerChar == "#") {
                searchViewModel.searchHashtag(query);
              }
            },
            triggerCharacterAndStyles: _buildTriggerStyles(theme),
            tagTextFormatter: (id, tag, triggerChar) => "$triggerChar$id#$tag#",
            overlayHeight: 350, // ADD: widget. prefix
            // CHANGE: Pass dismissal callback to overlay
            overlay: SearchResultBox(),
            builder: (context, containerKey) {
              return CommentTextField(
                onInputText: (value) {
                  if (value.contains('\n')) {
                    textInputController.text = value.replaceAll("\n", ""); // ADD: widget. prefix
                    postController.publishPost(); // ADD: widget. prefix
                  }
                },
                focusNode: focusNode, // ADD: widget. prefix
                containerKey: containerKey,
                insets: viewInsets, // ADD: widget. prefix
                controller: textInputController, // ADD: widget. prefix
                hintText: "Tell us what's on your mind...",
                onSend: postController.publishPost, // ADD: widget. prefix
              );
            },
          ),
        ),
      ),
    );
  }

  Map<String, TextStyle> _buildTriggerStyles(ThemeData theme) {
    return {
      "@": theme.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
      "#": theme.textTheme.bodyLarge!.copyWith(fontStyle: FontStyle.italic),
    };
  }
}
