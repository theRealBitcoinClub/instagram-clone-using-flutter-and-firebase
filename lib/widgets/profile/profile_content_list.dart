// lib/widgets/profile/profile_content_list.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/providers/token_limits_provider.dart';
import 'package:mahakka/theme_provider.dart';
import 'package:mahakka/views_taggable/widgets/post_expandable_text_widget.dart';
import 'package:mahakka/widgets/limit_info_widget.dart';
import 'package:mahakka/widgets/profile/profile_placeholders.dart';
import 'package:mahakka/widgets/unified_video_player.dart';
import 'package:mahakka/youtube_video_checker.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

void _logListError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: ProfileContentList - $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

class ProfileContentList extends ConsumerStatefulWidget {
  final List<MemoModelPost> posts;
  final bool isYouTubeList;
  final bool isTopicList;
  final Map<String, ValueNotifier<YoutubePlayerController?>>? ytControllerNotifiers;
  final String creatorName;
  final bool showMedia;
  final int totalCount;
  final LimitType limitType;

  const ProfileContentList._({
    Key? key,
    required this.posts,
    required this.isYouTubeList,
    required this.isTopicList,
    this.ytControllerNotifiers,
    required this.creatorName,
    required this.showMedia,
    required this.totalCount,
    required this.limitType,
  }) : super(key: key);

  factory ProfileContentList.youTube({
    Key? key,
    required List<MemoModelPost> posts,
    required Map<String, ValueNotifier<YoutubePlayerController?>> ytControllerNotifiers,
    required String creatorName,
    required int totalCount,
  }) {
    return ProfileContentList._(
      key: key,
      posts: posts,
      isYouTubeList: true,
      isTopicList: false,
      ytControllerNotifiers: ytControllerNotifiers,
      creatorName: creatorName,
      showMedia: true,
      totalCount: totalCount,
      limitType: LimitType.profile,
    );
  }

  factory ProfileContentList.generic({
    Key? key,
    required List<MemoModelPost> posts,
    required String creatorName,
    required bool isTopicList,
    required int totalCount,
  }) {
    return ProfileContentList._(
      key: key,
      posts: posts,
      isYouTubeList: false,
      isTopicList: isTopicList,
      ytControllerNotifiers: null,
      creatorName: creatorName,
      showMedia: false,
      totalCount: totalCount,
      limitType: LimitType.profile,
    );
  }

  @override
  ConsumerState<ProfileContentList> createState() => _ProfileContentListState();
}

class _ProfileContentListState extends ConsumerState<ProfileContentList> {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final profileLimit = ref.watch(profileLimitProvider);

    // Check if we should show the limit card
    final bool shouldShowLimitCard = widget.totalCount >= profileLimit;
    final int itemCount = widget.posts.length + (shouldShowLimitCard ? 1 : 0);

    if (widget.posts.isEmpty && !shouldShowLimitCard) {
      final String message = widget.isYouTubeList
          ? "No video posts by this creator yet."
          : widget.isTopicList
          ? "No topic posts by this creator yet."
          : "No tagged posts by this creator yet.";
      final IconData icon = widget.isYouTubeList ? Icons.videocam_off_outlined : Icons.list_alt_outlined;
      return EmptySliverContent(message: message, icon: icon, theme: theme);
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        // Check if this is the limit card (last item)
        if (shouldShowLimitCard && index >= widget.posts.length) {
          return _buildLimitCard(theme);
        }

        final post = widget.posts[index];
        if (widget.isYouTubeList && widget.showMedia) {
          return _buildVideoListItem(context, theme, post);
        } else {
          return _buildTextOnlyListItem(context, theme, post, index);
        }
      }, childCount: itemCount),
    );
  }

  Widget _buildLimitCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
      // margin: const EdgeInsets.fromLTRB(6, 3, 6, 6),
      child: LimitInfoWidget(limitType: widget.limitType, compact: false),
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
          return _buildVideoCard(
            context: context,
            theme: theme,
            videoPost: videoPost,
            player: UnifiedVideoPlayer(videoId: videoPost.youtubeId, type: VideoPlayerType.youtube, aspectRatio: 16 / 9, autoPlay: false),
          );
        },
      );
    }

    if (hasVideoUrl) {
      return _buildVideoCard(
        context: context,
        theme: theme,
        videoPost: videoPost,
        player: UnifiedVideoPlayer(type: VideoPlayerType.generic, aspectRatio: 16 / 9, autoPlay: false, videoUrl: videoPost.videoUrl!),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildVideoCard({required BuildContext context, required ThemeData theme, required MemoModelPost videoPost, required Widget player}) {
    return Card(
      color: ref.read(themeNotifierProvider).value!.isDarkMode ? Colors.black.withAlpha(33) : Colors.white.withAlpha(169),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          player,
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (videoPost.text != null && videoPost.text!.isNotEmpty) ...[PostExpandableText(post: videoPost), const SizedBox(height: 8)],
                Text(
                  // "${widget.creatorName}, ${videoPost.age}",
                  "${widget.creatorName}",
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextOnlyListItem(BuildContext context, ThemeData theme, MemoModelPost post, int index) {
    String postTimestamp = "";
    try {
      postTimestamp = post.createdDateTime!.toLocal().toString().split(' ')[0];
    } catch (e) {
      Sentry.captureException(e);
    }
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
                    '${index + 1}. ${widget.creatorName}',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 9),
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
}
