// import 'package:chewie/chewie.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:mahakka/odysee/video_providers.dart';
//
// class OdyseeVideoPlayer extends ConsumerStatefulWidget {
//   final double? aspectRatio;
//   final bool autoPlay;
//   final Widget? loadingWidget;
//   final Widget? errorWidget;
//   final String? videoUrl;
//
//   const OdyseeVideoPlayer({super.key, this.aspectRatio, this.autoPlay = true, this.loadingWidget, this.errorWidget, this.videoUrl});
//
//   @override
//   ConsumerState<OdyseeVideoPlayer> createState() => _OdyseeVideoPlayerState();
// }
//
// class _OdyseeVideoPlayerState extends ConsumerState<OdyseeVideoPlayer> {
//   // Default aspect ratio for most videos (16:9)
//   static const double defaultAspectRatio = 16 / 9;
//
//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         // Calculate fixed height based on available width and aspect ratio
//         final expectedAspectRatio = widget.aspectRatio ?? defaultAspectRatio;
//         final fixedHeight = constraints.maxWidth / expectedAspectRatio;
//
//         return SizedBox(height: fixedHeight, child: _buildVideoContent(fixedHeight));
//       },
//     );
//   }
//
//   Widget _buildVideoContent(double fixedHeight) {
//     // If videoUrl is provided directly, use it instead of watching the provider
//     if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
//       return _buildVideoFromUrl(widget.videoUrl!, fixedHeight);
//     }
//
//     // Fall back to provider-based approach
//     final streamUrlAsync = ref.watch(streamUrlProvider);
//
//     return streamUrlAsync.when(
//       loading: () => widget.loadingWidget ?? _buildLoading(fixedHeight),
//       error: (error, stack) => widget.errorWidget ?? _buildError(error.toString(), fixedHeight),
//       data: (streamUrl) {
//         return _VideoPlayerContent(streamUrl: streamUrl, aspectRatio: widget.aspectRatio, autoPlay: widget.autoPlay, fixedHeight: fixedHeight);
//       },
//     );
//   }
//
//   // Build video player from direct URL using Chewie
//   Widget _buildVideoFromUrl(String videoUrl, double fixedHeight) {
//     final chewieControllerAsync = ref.watch(chewieControllerProvider((streamUrl: videoUrl, autoPlay: widget.autoPlay, context: context)));
//
//     return chewieControllerAsync.when(
//       loading: () => widget.loadingWidget ?? _buildLoading(fixedHeight),
//       error: (error, stack) => widget.errorWidget ?? _buildError(error.toString(), fixedHeight),
//       data: (chewieController) {
//         return _buildVideoPlayer(chewieController, fixedHeight);
//       },
//     );
//   }
//
//   Widget _buildVideoPlayer(ChewieController chewieController, double fixedHeight) {
//     final actualAspectRatio = chewieController.videoPlayerController.value.aspectRatio;
//     final effectiveAspectRatio = actualAspectRatio > 0 ? actualAspectRatio : (widget.aspectRatio ?? defaultAspectRatio);
//
//     return SizedBox(
//       height: fixedHeight,
//       child: AspectRatio(
//         aspectRatio: effectiveAspectRatio,
//         child: Chewie(controller: chewieController),
//       ),
//     );
//   }
//
//   Widget _buildLoading(double height) {
//     return Container(
//       height: height,
//       color: Colors.black,
//       child: const Center(child: CircularProgressIndicator(color: Colors.white)),
//     );
//   }
//
//   Widget _buildError(String error, double height) {
//     return Container(
//       height: height,
//       color: Colors.black,
//       child: Center(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(Icons.error_outline, color: Colors.white, size: 48),
//                 const SizedBox(height: 16),
//                 Text(
//                   'Failed to load video',
//                   style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   error,
//                   style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
//                   textAlign: TextAlign.center,
//                   maxLines: 3,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _VideoPlayerContent extends ConsumerStatefulWidget {
//   final String streamUrl;
//   final double? aspectRatio;
//   final bool autoPlay;
//   final double fixedHeight;
//
//   const _VideoPlayerContent({required this.streamUrl, required this.fixedHeight, this.aspectRatio, this.autoPlay = true});
//
//   @override
//   ConsumerState<_VideoPlayerContent> createState() => _VideoPlayerContentState();
// }
//
// class _VideoPlayerContentState extends ConsumerState<_VideoPlayerContent> {
//   // Default aspect ratio for most videos (16:9)
//   static const double defaultAspectRatio = 16 / 9;
//
//   @override
//   Widget build(BuildContext context) {
//     final chewieControllerAsync = ref.watch(
//       chewieControllerProvider((streamUrl: widget.streamUrl, autoPlay: widget.autoPlay, context: context)),
//     );
//
//     return chewieControllerAsync.when(
//       loading: () => _buildLoading(widget.fixedHeight),
//       error: (error, stack) => _buildError(error.toString(), widget.fixedHeight),
//       data: (chewieController) {
//         return _buildVideoPlayer(chewieController, widget.fixedHeight);
//       },
//     );
//   }
//
//   Widget _buildVideoPlayer(ChewieController chewieController, double fixedHeight) {
//     final actualAspectRatio = chewieController.videoPlayerController.value.aspectRatio;
//     final effectiveAspectRatio = actualAspectRatio > 0 ? actualAspectRatio : (widget.aspectRatio ?? defaultAspectRatio);
//
//     return SizedBox(
//       height: fixedHeight,
//       child: AspectRatio(
//         aspectRatio: effectiveAspectRatio,
//         child: Chewie(controller: chewieController),
//       ),
//     );
//   }
//
//   Widget _buildLoading(double height) {
//     return Container(
//       height: height,
//       color: Colors.black,
//       child: const Center(child: CircularProgressIndicator(color: Colors.white)),
//     );
//   }
//
//   Widget _buildError(String error, double height) {
//     return Container(
//       height: height,
//       color: Colors.black,
//       child: Center(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(Icons.error_outline, color: Colors.white, size: 48),
//                 const SizedBox(height: 16),
//                 Text(
//                   'Failed to load video',
//                   style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   error,
//                   style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
//                   textAlign: TextAlign.center,
//                   maxLines: 3,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
