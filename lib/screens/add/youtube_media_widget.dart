import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/widgets/red_action_button.dart';
import 'package:mahakka/widgets/unified_video_player.dart';

import 'add_post_providers.dart';

class YouTubeMediaWidget extends ConsumerStatefulWidget {
  final ThemeData theme;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final String? youtubeId;

  const YouTubeMediaWidget({super.key, required this.theme, required this.colorScheme, required this.textTheme, this.youtubeId});

  @override
  ConsumerState<YouTubeMediaWidget> createState() => _YouTubeMediaWidgetState();
}

class _YouTubeMediaWidgetState extends ConsumerState<YouTubeMediaWidget> {
  @override
  Widget build(BuildContext context) {
    final videoId = ref.watch(youtubeVideoIdProvider);

    if (videoId.isEmpty) {
      return const SizedBox();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: widget.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.colorScheme.outline.withOpacity(0.3), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11.5),
              child: UnifiedVideoPlayer(type: VideoPlayerType.youtube, videoId: videoId),
            ),
          ),
        ),
        const SizedBox(height: 12),
        widget.youtubeId == null
            ? Column(
                children: [
                  ChangeVideoButton(
                    onPressed: () {
                      ref.read(youtubeVideoIdProvider.notifier).state = '';
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Video: $videoId",
                    style: widget.textTheme.bodySmall?.copyWith(color: widget.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}
