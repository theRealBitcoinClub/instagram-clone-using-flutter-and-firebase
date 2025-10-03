import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/views_taggable/widgets/post_expandable_text_widget.dart';
import 'package:mahakka/widgets/animations/animated_grow_fade_in.dart';

import '../../memo/base/memo_verifier.dart';
import '../character_limited_textfield.dart';
import '../hashtag_display_widget.dart';

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
  final onSend;
  final VoidCallback onCancel;
  final int maxTagsCounter;

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
    required this.maxTagsCounter,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;

    if (post.text != null && post.text!.isNotEmpty && post.hasMedia) {
      post.text = post.text!.replaceAll(post.mediaUrl, "");
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.topicId.isNotEmpty) ...[_buildTopicCheckBoxWidget(theme)],
          if (post.tagIds.isNotEmpty) ...[const SizedBox(height: 4), _buildHashtagCheckboxesWidget(theme), const SizedBox(height: 8)],
          if (post.text != null && post.text!.isNotEmpty) ...[
            // Force left alignment for text
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: GestureDetector(
                  onTap: () {
                    FlutterClipboard.clear();
                    FlutterClipboard.copy("${post.creator!.name} wrote on ${post.dateTimeFormattedSafe()}: ${post.text}" ?? "");
                    showSnackBar("Text copied to clipboard", type: SnackbarType.success);
                  },
                  child: PostExpandableText(post: post, hidePrefix: true, doTranslate: true),
                ),
              ),
            ),
            const SizedBox(height: 2),
          ],
          AnimGrowFade(
            delay: const Duration(milliseconds: 200),
            show: showInput,
            child: Padding(
              padding: EdgeInsets.only(bottom: isKeyboardVisible ? 0 : mediaQuery.padding.bottom + 2, left: 4, right: 4, top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: CharacterLimitedTextField(
                  controller: textEditController,
                  maxLength: MemoVerifier.maxPostLength,
                  hintText: 'Write your reply...',
                  onChanged: onInputText,
                ),
              ),
            ),
          ),
          AnimGrowFade(
            show: showSend,
            // delay: const Duration(milliseconds: 500),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildCancelButtonWidget(theme),
                      post.hasMedia ? const SizedBox(width: 9) : SizedBox.shrink(),
                      post.hasMedia ? _buildRepostButtonWidget(theme) : SizedBox.shrink(),
                      const SizedBox(width: 9),
                      _buildSendButtonWidget(theme),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCheckBoxWidget(ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onSelectTopic,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 2, 9, 0),
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
              if (post.topicId.isNotEmpty) ...[
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    post.topicId,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: hasSelectedTopic ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.normal,
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 2, 0, 0),
        child: HashtagDisplayWidget(
          hashtags: post.tagIds,
          theme: theme,
          selectedHashtags: selectedHashtags,
          onSelectHashtag: (index) => onSelectHashtag(index),
        ),
      ),
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
      child: const Text("Reset"),
    );
  }

  Widget _buildRepostButtonWidget(ThemeData theme) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: Colors.yellow[900],
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.yellow[900]!.withOpacity(0.5)),
        ),
        textStyle: theme.textTheme.labelLarge,
      ),
      onPressed: () => onSend(isRepost: true),
      child: const Text("Repost"),
    );
  }

  Widget _buildSendButtonWidget(ThemeData theme) {
    String buttonText = "Post";
    if (hasSelectedTopic && selectedHashtags.any((s) => s)) {
      buttonText = "Reply w/ tags";
    } else if (hasSelectedTopic) {
      buttonText = "Topic reply";
    } else if (selectedHashtags.any((s) => s)) {
      buttonText = "Post /w tags";
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
      onPressed: onSend,
      child: Text(buttonText),
    );
  }
}
