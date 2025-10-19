import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/screens/icon_action_button.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/views_taggable/widgets/post_expandable_text_widget.dart';
import 'package:mahakka/widgets/animations/animated_grow_fade_in.dart';

import '../../memo/base/memo_verifier.dart';
import '../character_limited_textfield.dart';
import '../hashtag_display_widget.dart';

class PostCardFooter extends ConsumerWidget {
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
  final String? topicIdPrefix;
  // final int maxTagsCounter;

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
    this.topicIdPrefix,
    // required this.maxTagsCounter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;

    if (post.text != null && post.text!.isNotEmpty && post.hasMedia) {
      post.text = post.text!.replaceAll(post.mediaUrl, "");
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.topicId.isNotEmpty) _buildTopicCheckBoxWidget(theme),
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
                    ref.read(snackbarServiceProvider).showTranslatedSnackBar("Text copied to clipboard", type: SnackbarType.success);
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
                  topicIdPrefix: topicIdPrefix,
                  controller: textEditController,
                  maxLength: MemoVerifier.maxPostLength,
                  hintText: "Touch here to write...",
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
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 0, horizontal: 3),
                    child: Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                      clipBehavior: Clip.antiAlias,
                      padding: EdgeInsets.zero,
                      // padding: EdgeInsets.symmetric(vertical: 0, horizontal: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // IconAction(text: "RESET", onTap: onCancel, type: IAB.cancel, icon: Icons.cancel_outlined),
                          IconAction(text: "COMMENT", onTap: onSend, type: IAB.alternative, icon: Icons.comment),
                          IconAction(
                            disabled: !post.hasMedia,
                            disabledMessage: "There is not image nor video attached to this publication.",
                            text: "REPOST",
                            onTap: () => onSend(isRepost: true),
                            type: IAB.success,
                            icon: Icons.repeat_outlined,
                          ),
                        ],
                      ),
                    ),
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
    var color = theme.colorScheme.secondary;
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onSelectTopic,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 9, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: hasSelectedTopic,
                onChanged: (value) => onSelectTopic(),
                activeColor: color,
                checkColor: theme.colorScheme.onSecondary,
                visualDensity: VisualDensity.comfortable,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 2),
              SizedBox(
                width: 288,
                child: Text(
                  post.topicId,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: hasSelectedTopic ? color : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
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
}
