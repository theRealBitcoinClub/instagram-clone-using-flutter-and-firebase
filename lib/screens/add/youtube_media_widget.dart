import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/widgets/red_action_button.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

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
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    final videoId = widget.youtubeId ?? ref.read(youtubeVideoIdProvider)!;
    if (videoId.isNotEmpty) {
      _controller = YoutubePlayerController(initialVideoId: videoId, flags: const YoutubePlayerFlags(autoPlay: false, mute: false));
    }
  }

  @override
  void dispose() {
    // final controller = ref.read(youtubeControllerProvider);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoId = ref.watch(youtubeVideoIdProvider);
    // final controller = ref.watch(youtubeControllerProvider);

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
              child: _controller != null
                  ? YoutubePlayer(
                      controller: _controller!,
                      showVideoProgressIndicator: true,
                      progressIndicatorColor: widget.colorScheme.primary,
                      progressColors: ProgressBarColors(
                        playedColor: widget.colorScheme.primary,
                        handleColor: widget.colorScheme.secondary,
                        bufferedColor: widget.colorScheme.primary.withOpacity(0.4),
                        backgroundColor: widget.colorScheme.onSurface.withOpacity(0.1),
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.videocam_off_outlined, color: widget.colorScheme.error, size: 36),
                          const SizedBox(height: 8),
                          Text("Video player error", style: widget.textTheme.bodyMedium?.copyWith(color: widget.colorScheme.error)),
                        ],
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        widget.youtubeId == null
            ? ChangeVideoButton(
                onPressed: () {
                  ref.read(youtubeVideoIdProvider.notifier).state = '';
                },
              )
            : const SizedBox.shrink(),
        const SizedBox(height: 8),
        Text(
          "Video Id: $videoId",
          style: widget.textTheme.bodySmall?.copyWith(color: widget.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
