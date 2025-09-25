import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../expandable_text_custom.dart';
import '../../memo/model/memo_model_post.dart';
import '../../providers/webview_providers.dart';
import '../../utils/snackbar.dart'; // Adjust import path

class PostExpandableText extends ConsumerWidget {
  final MemoModelPost post;
  final bool? hidePrefix;

  const PostExpandableText({Key? key, required this.post, this.hidePrefix}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ExpandableTextCustom(
      post.text ?? "",
      expandText: ' show more',
      collapseText: 'show less',
      maxLines: 5,
      linkColor: theme.colorScheme.onTertiaryFixedVariant,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontFamily: "Open Sans",
        fontSize: 15,
        height: 1.4,
        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.85),
      ),
      hashtagStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onTertiaryFixedVariant, fontWeight: FontWeight.w500),
      onHashtagTap: (String hashtag) {
        WebViewNavigator.navigateTo(ref, WebViewShow.tag, hashtag);
        showSnackBar("Loading $hashtag charts!", context, type: SnackbarType.success);
        showSnackBar("$hashtag charts are loading...", context, type: SnackbarType.info);
      },
      mentionStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onTertiaryFixedVariant, fontWeight: FontWeight.w500),
      urlStyle: _buildUrlStyle(theme),
      onUrlTap: (String url) async {
        await _onUrlTap(url, context, ref);
      },
      prefixText: hidePrefix != null && hidePrefix! ? "" : (post.topicId.isNotEmpty ? "${post.topicId}\n\n" : null),
      prefixStyle: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w400),
      onPrefixTap: () {
        WebViewNavigator.navigateTo(ref, WebViewShow.topic, post.topicId);
        showSnackBar("Loading ${post.topicId} charts!", context, type: SnackbarType.success);
        showSnackBar("${post.topicId} charts are loading...", context, type: SnackbarType.info);
      },
    );
  }

  TextStyle? _buildUrlStyle(ThemeData theme) {
    return theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onTertiaryFixedVariant.withAlpha(189),
      fontStyle: FontStyle.italic,
      // decoration: TextDecoration.underline,
      fontWeight: FontWeight.w600,
    );
  }

  Future<void> _onUrlTap(String url, BuildContext context, WidgetRef ref) async {
    try {
      WebViewNavigator.navigateTo(ref, WebViewShow.url, url);
    } catch (e) {
      showSnackBar("Error opening URL", context, type: SnackbarType.error);
    }
  }
}

// Alternative version using a Provider if you need to create a provider for the post
final postProvider = Provider.family<MemoModelPost, String>((ref, postId) {
  // You'll need to implement how to fetch the post by ID
  throw UnimplementedError('Implement post fetching logic');
});

class PostExpandableTextWithProvider extends ConsumerWidget {
  final String postId;

  const PostExpandableTextWithProvider({Key? key, required this.postId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final post = ref.watch(postProvider(postId));
    return PostExpandableText(post: post);
  }
}
