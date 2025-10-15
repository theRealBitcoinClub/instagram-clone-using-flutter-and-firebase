// widgets/taggable_input_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/provider/translation_service.dart';
import 'package:mahakka/screens/add_post_controller.dart';
import 'package:mahakka/views_taggable/view_models/search_view_model.dart';
import 'package:mahakka/views_taggable/widgets/search_result_overlay.dart';

import '../../custom_tagger.dart';
import '../../views_taggable/taggable_providers.dart';
import '../../views_taggable/widgets/post_composer_widget.dart';

class TaggableInputWidget extends ConsumerWidget {
  const TaggableInputWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final searchViewModel = ref.read(searchViewModelProvider.notifier);
    final postController = ref.read(addPostControllerProvider.notifier);
    final textInputController = ref.watch(taggableControllerProvider);
    final focusNode = ref.watch(focusNodeProvider);
    final viewInsets = MediaQuery.of(context).viewInsets;
    var s = "Tap here to write the description for the media";
    var hintTextTranslated = ref.read(autoTranslationTextProvider(s)).value ?? s;

    return Material(
      elevation: 3.0,
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(9),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
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
          // overlayHeight: 350, // ADD: widget. prefix
          // CHANGE: Pass dismissal callback to overlay
          overlay: SearchResultBox(),
          builder: (context, containerKey) {
            return PostComposerWidget(
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
              hintText: hintTextTranslated,
              onSend: postController.publishPost, // ADD: widget. prefix
            );
          },
        ),
      ),
      // ),
    );
  }

  Map<String, TextStyle> _buildTriggerStyles(ThemeData theme) {
    return {
      "@": theme.textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
      "#": theme.textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
    };
  }
}
