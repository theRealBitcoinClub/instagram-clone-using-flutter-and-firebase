import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mahakka/memo/memo_reg_exp.dart';
import 'package:mahakka/screens/add/add_post_providers.dart';
import 'package:video_player/video_player.dart';

import 'odysee_service.dart';

// Provider for HTTP client
final httpClientProvider = Provider<http.Client>((ref) => http.Client());

// Provider for OdyseeService
final odyseeServiceProvider = Provider<OdyseeService>((ref) {
  final client = ref.watch(httpClientProvider);
  return OdyseeService(client: client);
});

// Provider for stream URL
final streamUrlProvider = FutureProvider<String>((ref) async {
  final odyseeService = ref.watch(odyseeServiceProvider);
  final videoUrl = ref.watch(odyseeUrlProvider);
  return await odyseeService.getVideoStreamUrl(videoUrl);
});

// Provider for VideoPlayerController (auto-dispose)
final videoPlayerControllerProvider = FutureProvider.autoDispose.family<VideoPlayerController, String>((ref, streamUrl) async {
  if (MemoRegExp(streamUrl).hasOdyseeUrl()) //TODO CHECK HOW TO USE EXISTING FUNCTIONALITY TO AUTO TRANSLATE WITH STREAM URL PROVIDER
    streamUrl = await ref.read(odyseeServiceProvider).getVideoStreamUrl(streamUrl);

  final controller = VideoPlayerController.networkUrl(Uri.parse(streamUrl));
  // final controller = VideoPlayerController.networkUrl(
  //   Uri.parse(
  //     "https://player.odycdn.com/api/v3/streams/free/Smurf---Rescue-in-Gargamel's-Castle---Atar/78b2edb9122b46552833dcf852a71d85591f31b4/9c90e4.mp4",
  //   ),
  // );
  await controller.initialize();
  await controller.setLooping(true);

  ref.onDispose(() {
    controller.dispose();
  });

  return controller;
});

// Provider for theme-aware ChewieController (auto-dispose)
final chewieControllerProvider = FutureProvider.autoDispose
    .family<
      ChewieController,
      ({
        String streamUrl,
        bool autoPlay,
        BuildContext context, // Add context for theme access
      })
    >((ref, params) async {
      // Get the current theme
      final theme = Theme.of(params.context);
      final colorScheme = Theme.of(params.context).colorScheme;
      final isDark = theme.brightness == Brightness.dark;

      // Get the VideoPlayerController first
      final videoController = await ref.watch(videoPlayerControllerProvider(params.streamUrl).future);

      // Define theme-aware colors
      final primaryColor = colorScheme.primary;
      final secondaryColor = colorScheme.secondary;
      final surfaceColor = colorScheme.surface;
      final onSurfaceColor = colorScheme.onSurface;
      final backgroundColor = isDark ? Colors.black : Colors.white;
      final progressBackgroundColor = isDark ? Colors.white30 : Colors.black26;

      // Create ChewieController with theme-aware colors
      final chewieController = ChewieController(
        videoPlayerController: videoController,
        autoPlay: params.autoPlay,
        looping: true,
        progressIndicatorDelay: Platform.isAndroid ? const Duration(days: 1) : null,

        // Theme-aware progress colors
        materialProgressColors: ChewieProgressColors(
          playedColor: primaryColor,
          handleColor: primaryColor,
          backgroundColor: progressBackgroundColor,
          bufferedColor: isDark ? Colors.white54 : Colors.black54,
        ),

        // Theme-aware controls
        // materialProgressBarTheme: ChewieProgressBarTheme(padding: EdgeInsets.only(bottom: 2), barCap: StrokeCap.round),

        // Theme-aware placeholder
        placeholder: Container(
          color: surfaceColor,
          child: Center(child: Icon(Icons.play_circle_filled, color: onSurfaceColor.withOpacity(0.5), size: 48)),
        ),

        // Theme-aware overlay
        overlay: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.5), Colors.transparent, Colors.transparent, Colors.black.withOpacity(0.5)],
            ),
          ),
        ),

        // Theme-aware settings
        autoInitialize: true,
        showControls: true,
        showControlsOnInitialize: false,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,

        // Theme-aware control icons
        customControls: const CupertinoControls(
          backgroundColor: Color.fromRGBO(41, 41, 41, 0.7),
          iconColor: Color.fromARGB(255, 200, 200, 200),
        ),

        // Theme-aware error widget
        errorBuilder: (context, errorMessage) {
          return Container(
            color: surfaceColor,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: colorScheme.error, size: 48),
                  const SizedBox(height: 16),
                  Text('Failed to load video', style: theme.textTheme.bodyLarge?.copyWith(color: onSurfaceColor)),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    style: theme.textTheme.bodySmall?.copyWith(color: onSurfaceColor.withOpacity(0.7)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },

        // Theme-aware options
        // additionalOptions: (context) => [
        //   OptionItem(iconData: Icons.info, title: 'Video Info', onTap: (BuildContext context) { showSnackBar(content, context) }),
        //   OptionItem(onTap: () => debugPrint('Option 2 selected'), iconData: Icons.share, title: 'Share'),
        // ],

        // Theme-aware options translation
        optionsTranslation: OptionsTranslation(
          playbackSpeedButtonText: 'Playback Speed',
          subtitlesButtonText: 'Subtitles',
          cancelButtonText: 'Cancel',
        ),

        // Theme-aware device options
        // deviceOrientationsOnEnterFullScreen: [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
        // deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
      );

      ref.onDispose(() {
        chewieController.dispose();
      });

      return chewieController;
    });

// Helper provider to get theme context (if needed elsewhere)
final themeContextProvider = Provider<BuildContext>((ref) {
  throw UnimplementedError('Context should be provided through family parameters');
});
