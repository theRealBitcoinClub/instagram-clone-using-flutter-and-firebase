import 'package:flutter/material.dart';
import 'package:mahakka/app_utils.dart';
import 'package:mahakka/memo/base/memo_verifier.dart';

import '../../custom_flutter_tagger_controller.dart';
import '../../widgets/character_limited_textfield.dart';

class PostComposerWidget extends StatelessWidget {
  final CustomFlutterTaggerController controller;
  final VoidCallback? onSend;
  final EdgeInsets insets;
  final FocusNode? focusNode;
  final ValueChanged<String> onInputText;
  final String hintText;
  final Key? containerKey;

  const PostComposerWidget({
    Key? key,
    required this.controller,
    this.onSend,
    required this.insets,
    this.focusNode,
    required this.hintText,
    this.containerKey,
    required this.onInputText,
  }) : super(key: key);

  @override
  Widget build(BuildContext ctx) {
    final ThemeData theme = Theme.of(ctx);
    final ColorScheme colorScheme = theme.colorScheme;
    final MainAxisAlignment columnMainAxisAlignment = insets == EdgeInsets.zero ? MainAxisAlignment.end : MainAxisAlignment.start;
    const double baseMaxHeight = 150.0;

    return Container(
      key: containerKey,
      constraints: BoxConstraints(maxHeight: insets == EdgeInsets.zero ? baseMaxHeight : baseMaxHeight + insets.bottom),
      padding: const EdgeInsets.fromLTRB(10, 2, 2, 0),
      child: Column(
        mainAxisAlignment: columnMainAxisAlignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SizedBox(
                  child: CharacterLimitedTextField(
                    controller: controller,
                    maxLength: MemoVerifier.maxPostLength,
                    hintText: hintText,
                    onChanged: onInputText,
                    minLines: 4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  IconButton(
                    iconSize: 26,
                    padding: const EdgeInsets.all(0.0),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.alternate_email_outlined, color: onSend != null ? colorScheme.primary : theme.disabledColor),
                    onPressed: () => onActionText("@", ctx),
                  ),
                  IconButton(
                    iconSize: 50,
                    padding: const EdgeInsets.all(0.0),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.send, color: onSend != null ? colorScheme.primary : theme.disabledColor),
                    onPressed: onSend,
                  ),
                  IconButton(
                    iconSize: 26,
                    padding: EdgeInsets.all(0.0),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.tag_outlined, color: onSend != null ? colorScheme.primary : theme.disabledColor),
                    onPressed: () => onActionText("#", ctx),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void onActionText(String action, BuildContext ctx) {
    ctx.afterLayout(() {
      final text = controller.text.trim().isEmpty ? controller.text.trim() : controller.text;
      final selection = controller.selection;
      final cursorPosition = selection.baseOffset;

      if (cursorPosition < 0) {
        controller.text = "${text.trim()} $action ";
        controller.selection = TextSelection.collapsed(offset: controller.text.length);
        return;
      }

      final hasSpaceBefore = cursorPosition == 0 || text[cursorPosition - 1] == ' ';
      final hasSpaceAfter = cursorPosition == text.length || text[cursorPosition] == ' ';

      String newText;
      int newCursorPosition;

      if (hasSpaceBefore && hasSpaceAfter) {
        newText = text.replaceRange(cursorPosition, cursorPosition, action);
        newCursorPosition = cursorPosition + action.length;
      } else if (!hasSpaceBefore && hasSpaceAfter) {
        newText = text.replaceRange(cursorPosition, cursorPosition, ' $action');
        newCursorPosition = cursorPosition + action.length + 1;
      } else if (hasSpaceBefore && !hasSpaceAfter) {
        newText = text.replaceRange(cursorPosition, cursorPosition, '$action ');
        newCursorPosition = cursorPosition + action.length;
      } else {
        newText = text.replaceRange(cursorPosition, cursorPosition, ' $action ');
        newCursorPosition = cursorPosition + action.length + 1;
      }

      controller.text = newText;
      controller.selection = TextSelection.collapsed(offset: newCursorPosition);
    }, refreshUI: true);
  }
}
