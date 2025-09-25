import 'package:clipboard/clipboard.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/widgets/animations/animated_grow_fade_in.dart';

import '../../memo/base/memo_verifier.dart';
import '../character_limited_textfield.dart';
import '../hashtag_display_widget.dart';

// If _PostCardState constants like _maxTagsCounter were used, they need to be accessible
// or passed down. For now, assuming they are either not critical or will be handled.
// Example: const int _maxTagsCounter = 3; (if needed locally)

class PostCardFooter extends StatelessWidget {
  final MemoModelPost post;
  final TextEditingController textEditController;
  final bool showInput;
  final bool showSend;
  final bool hasSelectedTopic;
  final List<bool> selectedHashtags;
  final ValueChanged<String> onInputText;
  final ValueChanged<int> onSelectHashtag;
  final VoidCallback onSelectTopic;
  final VoidCallback onSend;
  final VoidCallback onCancel;
  final int maxTagsCounter; // Pass this if it was from _PostCardState

  const PostCardFooter({
    super.key,
    required this.post,
    required this.textEditController,
    required this.showInput,
    required this.showSend,
    required this.hasSelectedTopic,
    required this.selectedHashtags,
    required this.onInputText,
    required this.onSelectHashtag,
    required this.onSelectTopic,
    required this.onSend,
    required this.onCancel,
    required this.maxTagsCounter, // Added
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // Assuming creator null check is handled before this widget is built
    final creatorName = post.creator?.profileIdShort ?? "User"; // Fallback if creator is somehow null
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.text != null && post.text!.isNotEmpty) ...[
            GestureDetector(
              onDoubleTap: () {
                FlutterClipboard.clear();
                FlutterClipboard.copy("${post.creator!.name} wrote on ${post.dateTimeFormattedSafe()}: ${post.text}" ?? "");
                showSnackBar("Text copied to clipboard", context, type: SnackbarType.info);
              },
              child: ExpandableText(
                // Using creatorName here
                "$creatorName: ${post.text!}",
                // prefixText: post.creator != null ? "${post.creator!.profileIdShort}" : "", // Handle potential null creator
                prefixStyle: theme.textTheme.titleSmall?.copyWith(letterSpacing: 2.0),
                expandText: 'show more',
                collapseText: 'show less',
                maxLines: 6,
                linkColor: theme.colorScheme.primary,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.3),
                animation: true,
                linkEllipsis: true,
                linkStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 10),
          ],
          // if (showInput)
          AnimatedGrowFadeIn(
            delay: const Duration(milliseconds: 200), // Optional: small delay
            show: showInput,
            child: Padding(
              padding: EdgeInsets.only(bottom: isKeyboardVisible ? 0 : mediaQuery.padding.bottom + 2, left: 4, right: 4, top: 8),
              child:
                  // TaggableInputWidget(onChanged: onInputText, onPublish: onSend),
                  // ),
                  Column(
                    // Wrap your original content in a single child
                    mainAxisSize: MainAxisSize.min, // Important for Column to not take infinite height
                    // crossAxisAlignment: CrossAxisAlignment.start, // Or your desired alignment
                    children: [
                      CharacterLimitedTextField(
                        controller: textEditController,
                        maxLength: MemoVerifier.maxPostLength, // Set your desired character limit
                        hintText: 'Write your reply...',
                        onChanged: onInputText,
                        normalTextStyle: theme.textTheme.bodyMedium,
                        exceededTextStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                      ),
                    ],
                  ),
            ),
          ),
          if (post.topicId.isNotEmpty) ...[_buildTopicCheckBoxWidget(theme)],
          if (post.tagIds.isNotEmpty) ...[const SizedBox(height: 6), _buildHashtagCheckboxesWidget(theme), const SizedBox(height: 8)],
          AnimatedGrowFadeIn(
            show: showSend,
            delay: const Duration(milliseconds: 200), // Optional: small delay
            child: Column(
              // Wrap your original content in a single child
              mainAxisSize: MainAxisSize.min, // Important for Column to not take infinite height
              crossAxisAlignment: CrossAxisAlignment.start, // Or your desired alignment
              children: [
                Divider(color: theme.dividerColor.withOpacity(0.5)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [_buildCancelButtonWidget(theme), const SizedBox(width: 8), _buildSendButtonWidget(theme)],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCheckBoxWidget(ThemeData theme) {
    final bool topicTextIsEffectivelyEmpty = post.topicId.isEmpty;

    return InkWell(
      onTap: onSelectTopic,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
        child: Align(
          alignment: topicTextIsEffectivelyEmpty ? Alignment.center : Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: hasSelectedTopic,
                onChanged: (value) => onSelectTopic(),
                activeColor: theme.colorScheme.primary,
                checkColor: theme.colorScheme.onPrimary,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              if (!topicTextIsEffectivelyEmpty) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    post.topicId,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: hasSelectedTopic ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                      fontWeight: hasSelectedTopic ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHashtagCheckboxesWidget(ThemeData theme) {
    return HashtagDisplayWidget(
      hashtags: post.tagIds,
      theme: theme,
      selectedHashtags: selectedHashtags,
      onSelectHashtag: (index) => onSelectHashtag(index),
    );
  }

  Widget _buildCancelButtonWidget(ThemeData theme) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: theme.colorScheme.error,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
        ),
        textStyle: theme.textTheme.labelLarge,
      ),
      onPressed: onCancel,
      child: const Text("Cancel"),
    );
  }

  Widget _buildSendButtonWidget(ThemeData theme) {
    String buttonText = "Post";
    if (hasSelectedTopic && selectedHashtags.any((s) => s)) {
      buttonText = "Reply to Topic with tags";
    } else if (hasSelectedTopic) {
      buttonText = "Reply to Topic";
    } else if (selectedHashtags.any((s) => s)) {
      buttonText = "Post with tags";
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
      onPressed: onSend,
      child: Text(buttonText),
    );
  }
}
