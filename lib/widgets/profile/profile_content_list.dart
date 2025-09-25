// lib/widgets/profile/profile_content_list.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/theme_provider.dart';
import 'package:mahakka/views_taggable/widgets/post_expandable_text_widget.dart';
import 'package:mahakka/widgets/profile/profile_placeholders.dart';
import 'package:mahakka/widgets/unified_video_player.dart';
import 'package:mahakka/youtube_video_checker.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

void _logListError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: ProfileContentList - $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

class ProfileContentList extends ConsumerStatefulWidget {
  final List<MemoModelPost> posts;
  final bool isYouTubeList;
  final Map<String, ValueNotifier<YoutubePlayerController?>>? ytControllerNotifiers;
  final String creatorName;
  final bool showMedia;

  const ProfileContentList._({
    Key? key,
    required this.posts,
    required this.isYouTubeList,
    this.ytControllerNotifiers,
    required this.creatorName,
    required this.showMedia,
  }) : super(key: key);

  factory ProfileContentList.youTube({
    Key? key,
    required List<MemoModelPost> posts,
    required Map<String, ValueNotifier<YoutubePlayerController?>> ytControllerNotifiers,
    required String creatorName,
  }) {
    return ProfileContentList._(
      key: key,
      posts: posts,
      isYouTubeList: true,
      ytControllerNotifiers: ytControllerNotifiers,
      creatorName: creatorName,
      showMedia: true,
    );
  }

  factory ProfileContentList.generic({Key? key, required List<MemoModelPost> posts, required String creatorName}) {
    return ProfileContentList._(
      key: key,
      posts: posts,
      isYouTubeList: false,
      ytControllerNotifiers: null,
      creatorName: creatorName,
      showMedia: false,
    );
  }

  @override
  ConsumerState<ProfileContentList> createState() => _ProfileContentListState();
}

class _ProfileContentListState extends ConsumerState<ProfileContentList> {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (widget.posts.isEmpty) {
      final String message = widget.isYouTubeList ? "No video posts by this creator yet." : "No posts in this category yet.";
      final IconData icon = widget.isYouTubeList ? Icons.videocam_off_outlined : Icons.list_alt_outlined;
      return EmptySliverContent(message: message, icon: icon, theme: theme);
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final post = widget.posts[index];
        if (widget.isYouTubeList && widget.showMedia) {
          return _buildVideoListItem(context, theme, post);
        } else {
          return _buildTextOnlyListItem(context, theme, post);
        }
      }, childCount: widget.posts.length),
    );
  }

  Widget _buildVideoListItem(BuildContext context, ThemeData theme, MemoModelPost videoPost) {
    final bool hasYoutubeId = videoPost.youtubeId != null && videoPost.youtubeId!.isNotEmpty;
    final bool hasVideoUrl = videoPost.videoUrl != null && videoPost.videoUrl!.isNotEmpty;

    if ((!hasYoutubeId && !hasVideoUrl) || widget.ytControllerNotifiers == null) {
      return const SizedBox.shrink();
    }

    if (hasYoutubeId) {
      final availability = ref.read(youtubeVideoAvailabilityChecker(videoPost.youtubeId ?? ""));

      return availability.when(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        skipError: true,
        loading: () => const SizedBox.shrink(),
        error: (error, stack) => const SizedBox.shrink(),
        data: (isAvailable) {
          if (!isAvailable) {
            return const SizedBox.shrink();
          }

          return Card(
            color: ref.read(themeNotifierProvider).value!.isDarkMode ? Colors.black.withAlpha(33) : Colors.white.withAlpha(169),
            clipBehavior: Clip.antiAlias,
            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UnifiedVideoPlayer(videoId: videoPost.youtubeId, type: VideoPlayerType.youtube, aspectRatio: 16 / 9, autoPlay: false),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (videoPost.text != null && videoPost.text!.isNotEmpty) ...[
                        PostExpandableText(post: videoPost),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        "${widget.creatorName}, ${videoPost.age}",
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    if (hasVideoUrl) {
      return Card(
        color: ref.read(themeNotifierProvider).value!.isDarkMode ? Colors.black.withAlpha(33) : Colors.white.withAlpha(169),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UnifiedVideoPlayer(type: VideoPlayerType.generic, aspectRatio: 16 / 9, autoPlay: false, videoUrl: videoPost.videoUrl!),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (videoPost.text != null && videoPost.text!.isNotEmpty) ...[PostExpandableText(post: videoPost), const SizedBox(height: 8)],
                  Text(
                    "${widget.creatorName}, ${videoPost.age}",
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTextOnlyListItem(BuildContext context, ThemeData theme, MemoModelPost post) {
    final String postTimestamp = post.age;

    return Card(
      color: ref.read(themeNotifierProvider).value!.isDarkMode ? Colors.black.withAlpha(33) : Colors.white.withAlpha(169),
      elevation: 1.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.creatorName,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (postTimestamp.isNotEmpty)
                  Text(
                    postTimestamp,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7), fontSize: 11),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Divider(color: theme.dividerColor.withAlpha(222), height: 1),
            const SizedBox(height: 4),
            PostExpandableText(post: post),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ExpandableTextCustom expandableTextCustom(MemoModelPost post, ThemeData theme, BuildContext context) {
  //   return ExpandableTextCustom(
  //     post.text ?? " ",
  //     expandText: ' show more',
  //     collapseText: 'show less',
  //     maxLines: 5,
  //     linkColor: theme.colorScheme.onTertiaryFixedVariant,
  //     style: theme.textTheme.bodyMedium?.copyWith(
  //       fontFamily: "Open Sans",
  //       fontSize: 15,
  //       height: 1.4,
  //       color: theme.textTheme.bodyMedium?.color?.withOpacity(0.85),
  //     ),
  //     hashtagStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onTertiaryFixedVariant, fontWeight: FontWeight.w500),
  //     onHashtagTap: (String hashtag) {
  //       WebViewNavigator.navigateTo(ref, WebViewShow.tag, hashtag);
  //       showSnackBar("Loading $hashtag charts!", context, type: SnackbarType.success);
  //       showSnackBar("$hashtag charts are loading...", context, type: SnackbarType.info);
  //     },
  //     mentionStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onTertiaryFixedVariant, fontWeight: FontWeight.w500),
  //     urlStyle: buildUrlStyle(theme),
  //     onUrlTap: (String url) async {
  //       await _onUrlTap(url, context);
  //     },
  //     prefixText: post.topicId.isNotEmpty ? "${post.topicId}\n\n" : null,
  //     prefixStyle: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w400),
  //     onPrefixTap: () {
  //       WebViewNavigator.navigateTo(ref, WebViewShow.topic, post.topicId);
  //       showSnackBar("Loading ${post.topicId} charts!", context, type: SnackbarType.success);
  //       showSnackBar("${post.topicId} charts are loading...", context, type: SnackbarType.info);
  //     },
  //   );
  // }
  //
  // TextStyle? buildUrlStyle(ThemeData theme) {
  //   return theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onTertiaryFixedVariant);
  // }
  //
  // Future<void> _onUrlTap(String url, BuildContext context) async {
  //   _logListError('URL tapped: $url');
  //   Uri? uri = Uri.tryParse(url);
  //   if (uri != null) {
  //     if (!uri.hasScheme && (url.startsWith('www.') || RegExp(r'^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(url))) {
  //       uri = Uri.parse('http://$url');
  //     }
  //     try {
  //       if (await canLaunchUrl(uri)) {
  //         ExternalBrowserLauncher launcher = ExternalBrowserLauncher(whitelistedDomains: whitelistPatterns);
  //         await launcher.launchUrlWithConfirmation(context, url);
  //       } else {
  //         _logListError('Could not launch $uri');
  //         if (context.mounted) {
  //           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open link: $url')));
  //         }
  //       }
  //     } catch (e) {
  //       _logListError('Error launching URL $url: $e');
  //       if (context.mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error opening link: $url')));
  //       }
  //     }
  //   } else {
  //     _logListError('Invalid URL: $url');
  //     if (context.mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid link format: $url')));
  //     }
  //   }
  // }
}
