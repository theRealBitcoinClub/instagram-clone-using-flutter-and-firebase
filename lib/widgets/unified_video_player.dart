import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/external_browser_launcher.dart';
import 'package:mahakka/youtube_video_checker.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _youtubeError150 = false;
  String? _youtubeErrorVideoId;
  bool _isCheckingVideo = false;
  bool _videoRemoved = false;

  @override
  void initState() {
    super.initState();
    if (widget.type == VideoPlayerType.youtube && widget.videoId != null) {
      _checkVideoAvailability().then((isAvailable) {
        if (isAvailable) {
          _initializeYoutubeController();
        } else {
          setState(() {
            _videoRemoved = true;
          });
        }
      });
    } else if (widget.type == VideoPlayerType.youtube && widget.videoId != null) {
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
      )..addListener(_youtubePlayerListener);
    }
  }

  Future<bool> _checkVideoAvailability() async {
    if (widget.type != VideoPlayerType.youtube || widget.videoId == null) {
      return true;
    }

    setState(() {
      _isCheckingVideo = true;
    });

    bool isAvailable = await ref.read(youtubeVideoAvailabilityChecker(widget.videoId!).future);
    setState(() {
      _isCheckingVideo = false;
    });
    return isAvailable;
  }

  void _youtubePlayerListener() {
    if (_youtubeController != null) {
      final playerState = _youtubeController!.value.playerState;
      final errorCode = _youtubeController!.value.errorCode;

      // Check for error code 150
      if (errorCode == 150) {
        setState(() {
          _youtubeError150 = true;
          _youtubeErrorVideoId = widget.videoId;
        });
      }
    }
  }

  Future<void> _openInBrowser() async {
    final videoId = _youtubeErrorVideoId ?? widget.videoId;
    if (videoId == null) return;

    final url = 'https://www.youtube.com/watch?v=$videoId';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      ExternalBrowserLauncher().launchUrlWithConfirmation(context, url);
    }
  }

  @override
  void didUpdateWidget(UnifiedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.type == VideoPlayerType.youtube && widget.videoId != oldWidget.videoId && widget.videoId != null) {
      setState(() {
        _youtubeError150 = false;
        _youtubeErrorVideoId = null;
        _videoRemoved = false;
      });

      _youtubeController?.removeListener(_youtubePlayerListener);
      _youtubeController?.dispose();
      _youtubeController = null;

      // Re-check video availability for new video ID
      _checkVideoAvailability().then((isAvailable) {
        if (isAvailable) {
          _initializeYoutubeController();
        } else {
          setState(() {
            _videoRemoved = true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _youtubeController?.removeListener(_youtubePlayerListener);
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _isCheckingVideo ? _checkVideoAvailability() : Future.value(true),
      builder: (context, snapshot) {
        if (_isCheckingVideo) {
          return _buildVideoCheckingUI();
        }

        if (widget.type == VideoPlayerType.youtube && _videoRemoved) {
          return _buildRemovedVideoUI();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final expectedAspectRatio = widget.aspectRatio ?? defaultAspectRatio;
            final fixedHeight = constraints.maxWidth / expectedAspectRatio;

            return SizedBox(height: fixedHeight, child: _buildVideoContent(fixedHeight));
          },
        );
      },
    );
  }

  Widget _buildVideoCheckingUI() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final expectedAspectRatio = widget.aspectRatio ?? defaultAspectRatio;
        final fixedHeight = constraints.maxWidth / expectedAspectRatio;

        return Container(
          height: fixedHeight,
          color: _colorScheme.surface,
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(_colorScheme.primary)),
                  const SizedBox(height: 16),
                  Text('Checking video availability...', style: _textTheme.bodyMedium?.copyWith(color: _colorScheme.onSurface)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRemovedVideoUI() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final expectedAspectRatio = widget.aspectRatio ?? defaultAspectRatio;
        final fixedHeight = constraints.maxWidth / expectedAspectRatio;

        return Container(
          height: fixedHeight,
          color: _colorScheme.surface,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.remove_circle_outline, color: _colorScheme.error, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Video Removed',
                      style: _textTheme.bodyLarge?.copyWith(color: _colorScheme.onSurface, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This video has been removed from YouTube and is no longer available.',
                      style: _textTheme.bodyMedium?.copyWith(color: _colorScheme.onSurface.withOpacity(0.8)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Video ID: ${widget.videoId}',
                      style: _textTheme.bodySmall?.copyWith(color: _colorScheme.onSurface.withOpacity(0.6)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoContent(double fixedHeight) {
    if (widget.type == VideoPlayerType.youtube && _youtubeError150) {
      return _buildYoutubeError150(fixedHeight);
    }

    switch (widget.type) {
      case VideoPlayerType.youtube:
        return _buildYoutubePlayer(fixedHeight);
      case VideoPlayerType.odysee:
      case VideoPlayerType.generic:
        return _buildChewieBasedVideo(fixedHeight);
    }
  }

  Widget _buildYoutubeError150(double height) {
    return Container(
      height: height,
      color: _colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Video Playback Error',
                  style: _textTheme.bodyLarge?.copyWith(color: _colorScheme.onSurface, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 9),
                Text(
                  'This video cannot be played in the embedded player due to copyright or embedding restrictions.',
                  style: _textTheme.bodyMedium?.copyWith(color: _colorScheme.onSurface.withOpacity(0.8)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Video ID: $_youtubeErrorVideoId',
                  style: _textTheme.bodySmall?.copyWith(color: _colorScheme.onSurface.withOpacity(0.6)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 9),
                ElevatedButton.icon(
                  onPressed: _openInBrowser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _colorScheme.error,
                    foregroundColor: _colorScheme.onError,
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: Icon(Icons.open_in_browser, size: 20),
                  label: Text('Open in Browser', style: _textTheme.bodyMedium!.copyWith(color: _theme.colorScheme.onPrimary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(_colorScheme.primary)),
              const SizedBox(height: 16),
              Text('Loading video...', style: _textTheme.bodyMedium?.copyWith(color: _colorScheme.onSurface)),
            ],
          ),
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
          child: SingleChildScrollView(
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
      ),
    );
  }

  Widget _buildPlaceholder(double height, IconData icon, String message) {
    return Container(
      height: height,
      color: _colorScheme.surface.withOpacity(0.5),
      child: Center(
        child: SingleChildScrollView(
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
      ),
    );
  }
}
