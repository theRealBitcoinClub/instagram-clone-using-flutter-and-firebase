// Updated PostExpandableText widget
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../memo/model/memo_model_post.dart';
import '../../providers/navigation_providers.dart';
import '../../utils/snackbar.dart';
import 'animated_translated_text.dart';

class PostExpandableText extends ConsumerWidget {
  final MemoModelPost post;
  final bool? hidePrefix;
  final bool? doTranslate;

  const PostExpandableText({Key? key, required this.post, this.hidePrefix, this.doTranslate}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AnimatedTranslatedText(
      post: post,
      originalText: post.text ?? "",
      doTranslate: doTranslate ?? false,
      style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.85)),
      maxLines: 5,
      linkColor: theme.colorScheme.onTertiaryFixedVariant,
      hashtagStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onTertiaryFixedVariant),
      onHashtagTap: (String hashtag) {
        ref.read(navigationStateProvider.notifier).navigateToTag(hashtag, context: context);
        ref.read(snackbarServiceProvider).showTranslatedSnackBar("$hashtag charts are loading...", type: SnackbarType.info, wait: true);
      },
      mentionStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onTertiaryFixedVariant),
      urlStyle: _buildUrlStyle(theme),
      onUrlTap: (String url) async {
        await _onUrlTap(url, context, ref);
      },
      prefixText: hidePrefix != null && hidePrefix! ? "" : (post.topicId.isNotEmpty ? "${post.topicId}\n\n" : null),
      prefixStyle: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w400),
      onPrefixTap: () {
        ref.read(navigationStateProvider.notifier).navigateToTopic(post.topicId, context: context);
        ref.read(snackbarServiceProvider).showTranslatedSnackBar("${post.topicId} charts are loading...", type: SnackbarType.info, wait: true);
      },
    );
  }

  TextStyle? _buildUrlStyle(ThemeData theme) {
    return theme.textTheme.labelSmall!.copyWith();
  }

  Future<void> _onUrlTap(String url, BuildContext context, WidgetRef ref) async {
    try {
      ref.read(navigationStateProvider.notifier).navigateToUrl(url, context: context);
    } catch (e) {
      ref.read(snackbarServiceProvider).showTranslatedSnackBar("Error opening URL", type: SnackbarType.error);
    }
  }
}
