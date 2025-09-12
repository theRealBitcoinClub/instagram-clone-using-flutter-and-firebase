import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../odysee/video_providers.dart';

enum VideoPlayerType { youtube, odysee, generic }

class UnifiedVideoPlayer extends ConsumerStatefulWidget {
  final VideoPlayerType type;
  final String? videoId; // For YouTube
  final String? videoUrl; // For Odysee/Generic
  final double? aspectRatio;
  final bool autoPlay;
  final bool showControls;
  final ThemeData? theme;
  final ColorScheme? colorScheme;
  final TextTheme? textTheme;

  const UnifiedVideoPlayer({
    super.key,
    required this.type,
    this.videoId,
    this.videoUrl,
    this.aspectRatio,
    this.autoPlay = false,
    this.showControls = true,
    this.theme,
    this.colorScheme,
    this.textTheme,
  });

  @override
  ConsumerState<UnifiedVideoPlayer> createState() => _UnifiedVideoPlayerState();
}

class _UnifiedVideoPlayerState extends ConsumerState<UnifiedVideoPlayer> {
  // Default aspect ratio for most videos (16:9)
  static const double defaultAspectRatio = 16 / 9;
  YoutubePlayerController? _youtubeController;
  late ThemeData _theme;
  late ColorScheme _colorScheme;
  late TextTheme _textTheme;

  @override
  void initState() {
    super.initState();
    if (widget.type == VideoPlayerType.youtube && widget.videoId != null) {
      _initializeYoutubeController();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = widget.theme ?? Theme.of(context);
    _colorScheme = widget.colorScheme ?? _theme.colorScheme;
    _textTheme = widget.textTheme ?? _theme.textTheme;
  }

  void _initializeYoutubeController() {
    if (widget.videoId != null && widget.videoId!.isNotEmpty) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: widget.videoId!,
        flags: YoutubePlayerFlags(
          autoPlay: widget.autoPlay,
          mute: false,
          disableDragSeek: false,
          loop: false,
          forceHD: false,
          enableCaption: true,
        ),
      );
    }
  }

  @override
  void didUpdateWidget(UnifiedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.type == VideoPlayerType.youtube && widget.videoId != oldWidget.videoId && widget.videoId != null) {
      _youtubeController?.dispose();
      _initializeYoutubeController();
    }
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final expectedAspectRatio = widget.aspectRatio ?? defaultAspectRatio;
        final fixedHeight = constraints.maxWidth / expectedAspectRatio;

        return SizedBox(height: fixedHeight, child: _buildVideoContent(fixedHeight));
      },
    );
  }

  Widget _buildVideoContent(double fixedHeight) {
    switch (widget.type) {
      case VideoPlayerType.youtube:
        return _buildYoutubePlayer(fixedHeight);
      case VideoPlayerType.odysee:
      case VideoPlayerType.generic:
        return _buildChewieBasedVideo(fixedHeight);
    }
  }

  Widget _buildYoutubePlayer(double fixedHeight) {
    if (widget.videoId == null || widget.videoId!.isEmpty) {
      return _buildPlaceholder(fixedHeight, Icons.videocam_off_outlined, "No video selected");
    }

    if (_youtubeController == null) {
      return _buildLoading(fixedHeight);
    }

    return YoutubePlayer(
      controller: _youtubeController!,
      showVideoProgressIndicator: true,
      progressIndicatorColor: _colorScheme.primary,
      progressColors: ProgressBarColors(
        playedColor: _colorScheme.primary,
        handleColor: _colorScheme.primaryContainer,
        bufferedColor: _colorScheme.primary.withOpacity(0.2),
        backgroundColor: _colorScheme.onSurface.withOpacity(0.1),
      ),
      onReady: () {
        setState(() {});
      },
      onEnded: (data) {
        // Handle video ended
      },
      bottomActions: [CurrentPosition(), ProgressBar(isExpanded: true), RemainingDuration(), FullScreenButton()],
    );
  }

  Widget _buildChewieBasedVideo(double fixedHeight) {
    if (widget.videoUrl == null || widget.videoUrl!.isEmpty) {
      return _buildPlaceholder(fixedHeight, Icons.videocam_off_outlined, "No video URL provided");
    }

    final chewieControllerAsync = ref.watch(
      chewieControllerProvider((streamUrl: widget.videoUrl!, autoPlay: widget.autoPlay, context: context)),
    );

    return chewieControllerAsync.when(
      loading: () => _buildLoading(fixedHeight),
      error: (error, stack) => _buildError(error.toString(), fixedHeight),
      data: (chewieController) {
        return _buildChewiePlayer(chewieController, fixedHeight);
      },
    );
  }

  Widget _buildChewiePlayer(ChewieController chewieController, double fixedHeight) {
    final actualAspectRatio = chewieController.videoPlayerController.value.aspectRatio;
    final effectiveAspectRatio = actualAspectRatio > 0 ? actualAspectRatio : (widget.aspectRatio ?? defaultAspectRatio);

    return AspectRatio(
      aspectRatio: effectiveAspectRatio,
      child: Chewie(controller: chewieController),
    );
  }

  Widget _buildLoading(double height) {
    return Container(
      height: height,
      color: _colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(_colorScheme.primary)),
            const SizedBox(height: 16),
            Text('Loading video...', style: _textTheme.bodyMedium?.copyWith(color: _colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error, double height) {
    return Container(
      height: height,
      color: _colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: _colorScheme.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load video',
                style: _textTheme.bodyLarge?.copyWith(color: _colorScheme.onSurface, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: _textTheme.bodySmall?.copyWith(color: _colorScheme.onSurface.withOpacity(0.7)),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(double height, IconData icon, String message) {
    return Container(
      height: height,
      color: _colorScheme.surface.withOpacity(0.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _colorScheme.onSurface.withOpacity(0.5), size: 36),
            const SizedBox(height: 8),
            Text(
              message,
              style: _textTheme.bodyMedium?.copyWith(color: _colorScheme.onSurface.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
