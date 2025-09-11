// widgets/odysee_video_player.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/odysee/video_providers.dart';
import 'package:video_player/video_player.dart';

class OdyseeVideoPlayer extends ConsumerStatefulWidget {
  final double? aspectRatio;
  final bool autoPlay;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final String? videoUrl; // Direct video URL from post

  const OdyseeVideoPlayer({super.key, this.aspectRatio, this.autoPlay = true, this.loadingWidget, this.errorWidget, this.videoUrl});

  @override
  ConsumerState<OdyseeVideoPlayer> createState() => _OdyseeVideoPlayerState();
}

class _OdyseeVideoPlayerState extends ConsumerState<OdyseeVideoPlayer> {
  @override
  Widget build(BuildContext context) {
    // If videoUrl is provided directly, use it instead of watching the provider
    if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      return _buildVideoFromUrl(widget.videoUrl!);
    }

    // Fall back to provider-based approach
    final streamUrlAsync = ref.watch(streamUrlProvider);

    return streamUrlAsync.when(
      loading: () => widget.loadingWidget ?? _buildLoading(),
      error: (error, stack) => widget.errorWidget ?? _buildError(error.toString()),
      data: (streamUrl) {
        return _VideoPlayerContent(streamUrl: streamUrl, aspectRatio: widget.aspectRatio, autoPlay: widget.autoPlay);
      },
    );
  }

  // NEW: Build video player from direct URL
  Widget _buildVideoFromUrl(String videoUrl) {
    final controllerAsync = ref.watch(videoControllerProvider((streamUrl: videoUrl, autoPlay: widget.autoPlay)));

    return controllerAsync.when(
      loading: () => widget.loadingWidget ?? _buildLoading(),
      error: (error, stack) => widget.errorWidget ?? _buildError(error.toString()),
      data: (controller) {
        return AspectRatio(aspectRatio: widget.aspectRatio ?? controller.value.aspectRatio, child: VideoPlayer(controller));
      },
    );
  }

  Widget _buildLoading() {
    return Container(
      color: Colors.black,
      child: const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }

  Widget _buildError(String error) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text('Failed to load video', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPlayerContent extends ConsumerStatefulWidget {
  final String streamUrl;
  final double? aspectRatio;
  final bool autoPlay;

  const _VideoPlayerContent({required this.streamUrl, this.aspectRatio, this.autoPlay = true});

  @override
  ConsumerState<_VideoPlayerContent> createState() => _VideoPlayerContentState();
}

class _VideoPlayerContentState extends ConsumerState<_VideoPlayerContent> {
  @override
  Widget build(BuildContext context) {
    final controllerAsync = ref.watch(videoControllerProvider((streamUrl: widget.streamUrl, autoPlay: widget.autoPlay)));

    return controllerAsync.when(
      loading: () => Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      error: (error, stack) => Container(
        color: Colors.black,
        child: Center(
          child: Text('Player Error: $error', style: const TextStyle(color: Colors.white)),
        ),
      ),
      data: (controller) {
        return AspectRatio(aspectRatio: widget.aspectRatio ?? controller.value.aspectRatio, child: VideoPlayer(controller));
      },
    );
  }
}
