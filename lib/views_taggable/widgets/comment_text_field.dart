import 'package:flutter/material.dart';
import 'package:mahakka/app_utils.dart';

// Assuming CustomTextField is in the same directory or correctly imported
import '../../custom_flutter_tagger_controller.dart';
import 'custom_text_field.dart';

class CommentTextField extends StatelessWidget {
  final CustomFlutterTaggerController controller; // Changed to FlutterTaggerController for clarity if that's its type
  final VoidCallback? onSend; // Allow null if send button can be disabled
  final EdgeInsets insets;
  final FocusNode? focusNode;
  final ValueChanged<String> onInputText;
  final String hintText;
  final Key? containerKey; // Key passed down from FlutterTagger

  const CommentTextField({
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
    // final TextTheme textTheme = theme.textTheme; // Not directly used here, but good practice to have if needed

    // Determine the alignment of the input field within its constrained box.
    // This logic seems specific to your layout needs based on insets.
    final MainAxisAlignment columnMainAxisAlignment = insets == EdgeInsets.zero ? MainAxisAlignment.end : MainAxisAlignment.start;

    // Default height for the input area.
    // const double defaultInputAreaHeight = 115.0; // Your original height for the CustomTextField SizedBox
    const double baseMaxHeight = 150.0; // Your original baseMaxHeight

    return Container(
      key: containerKey,
      // Constraints logic kept as per your original design
      constraints: BoxConstraints(maxHeight: insets == EdgeInsets.zero ? baseMaxHeight : baseMaxHeight + insets.bottom),
      padding: const EdgeInsets.fromLTRB(0, 4, 2, 2), // Adjusted padding for better spacing
      // Use a themed background color. theme.canvasColor is often suitable for input areas,
      // or theme.colorScheme.surface if it's meant to look like a card.
      // theme.bottomAppBarTheme.color could also be an option if this acts like a bottom app bar.
      // decoration: BoxDecoration(
      //   color: theme.canvasColor, // Or theme.colorScheme.surface or theme.bottomAppBarTheme.color
      //   // Optional: add a top border if this sits above other content
      //   border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      // ),
      child: Column(
        mainAxisAlignment: columnMainAxisAlignment,
        mainAxisSize: MainAxisSize.min, // Important for Column in a constrained box
        children: [
          // Commented out Emoji section remains unchanged
          // ...
          Row(
            crossAxisAlignment: CrossAxisAlignment.center, // Align items to the bottom, especially the send button
            children: [
              // Commented out User Avatar section remains unchanged
              // ...
              // const SizedBox(width: 8), // Add spacing if avatar is present
              Expanded(
                // Allow CustomTextField to take available width
                child: SizedBox(
                  // The fixed height here might be restrictive.
                  // Consider allowing CustomTextField to determine its own height based on minLines/maxLines,
                  // or adjusting this based on content.
                  // For now, keeping your specified height.
                  // height: defaultInputAreaHeight,
                  // width: 380, // Using Expanded, so width is flexible

                  // CustomTextField needs to be theme-aware internally
                  // Its hintText, text style, cursor color, and border styles should
                  // come from the theme (InputDecorationTheme, TextTheme).
                  child: CustomTextField(
                    onChanged: onInputText,
                    focusNode: focusNode,
                    controller: controller,
                    hintText: hintText,
                    minLines: 4, // Example: Start with 1 line
                    maxLines: 4, // Allow up to 4 lines before scrolling
                    // suffixIcon is handled below as a separate IconButton for better alignment
                    // and theming control for the button itself.
                  ),
                ),
              ),
              const SizedBox(width: 8), // Spacing between text field and send button
              Column(
                children: [
                  IconButton(
                    iconSize: 26, // Adjusted icon size
                    padding: const EdgeInsets.all(0.0), // Ensure good tap target size
                    visualDensity: VisualDensity.compact, // Slightly smaller visual footprint
                    // Use a themed color for the send icon.
                    // colorScheme.primary is a common choice for action buttons.
                    icon: Icon(Icons.alternate_email_outlined, color: onSend != null ? colorScheme.primary : theme.disabledColor),
                    // tooltip: "Send",
                    onPressed: () => onActionText("@", ctx), // onPressed can be null to disable the button
                  ),
                  IconButton(
                    iconSize: 50, // Adjusted icon size
                    padding: const EdgeInsets.all(0.0), // Ensure good tap target size
                    visualDensity: VisualDensity.compact, // Slightly smaller visual footprint
                    // Use a themed color for the send icon.
                    // colorScheme.primary is a common choice for action buttons.
                    icon: Icon(Icons.send, color: onSend != null ? colorScheme.primary : theme.disabledColor),
                    // tooltip: "Send",
                    onPressed: onSend, // onPressed can be null to disable the button
                  ),
                  IconButton(
                    iconSize: 26, // Adjusted icon size
                    padding: EdgeInsets.all(0.0), // Ensure good tap target size
                    visualDensity: VisualDensity.compact, // Slightly smaller visual footprint
                    // Use a themed color for the send icon.
                    // colorScheme.primary is a common choice for action buttons.
                    icon: Icon(Icons.tag_outlined, color: onSend != null ? colorScheme.primary : theme.disabledColor),
                    // tooltip: "Send",
                    onPressed: () => onActionText("#", ctx), // onPressed can be null to disable the button
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
      final text = controller.text;
      final selection = controller.selection;

      // Get cursor position
      final cursorPosition = selection.baseOffset;

      if (cursorPosition < 0) {
        // No cursor position, append at the end
        controller.text = "${text.trim()} $action ";
        controller.selection = TextSelection.collapsed(offset: controller.text.length);
        return;
      }

      // Check whitespace before and after cursor
      final hasSpaceBefore = cursorPosition == 0 || text[cursorPosition - 1] == ' ';
      final hasSpaceAfter = cursorPosition == text.length || text[cursorPosition] == ' ';

      // Build the new text
      String newText;
      int newCursorPosition;

      if (hasSpaceBefore && hasSpaceAfter) {
        // Perfect case: just insert the action
        newText = text.replaceRange(cursorPosition, cursorPosition, action);
        newCursorPosition = cursorPosition + action.length;
      } else if (!hasSpaceBefore && hasSpaceAfter) {
        // Need space before
        newText = text.replaceRange(cursorPosition, cursorPosition, ' $action');
        newCursorPosition = cursorPosition + action.length + 1;
      } else if (hasSpaceBefore && !hasSpaceAfter) {
        // Need space after
        newText = text.replaceRange(cursorPosition, cursorPosition, '$action ');
        newCursorPosition = cursorPosition + action.length;
      } else {
        // Need spaces on both sides
        newText = text.replaceRange(cursorPosition, cursorPosition, ' $action ');
        newCursorPosition = cursorPosition + action.length + 1;
      }

      controller.text = newText;
      controller.selection = TextSelection.collapsed(offset: newCursorPosition);
    }, refreshUI: true);
  }

  // void onActionText(String action, BuildContext ctx) {
  //   ctx.afterLayout(() {
  //     controller.text = "${controller.text.trim()} $action";
  //   }, refreshUI: true);
  // }
}
