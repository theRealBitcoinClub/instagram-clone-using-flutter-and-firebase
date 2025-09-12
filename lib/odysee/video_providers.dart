// providers/video_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
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

// Provider for video URL
// final videoUrlProvider = StateProvider<String>((ref) => '');
// final videoUrlProvider = StateProvider<String>((ref) => 'https://odysee.com/@BitcoinMap:9/HijackingBitcoin:73');

// Provider for stream URL
final streamUrlProvider = FutureProvider<String>((ref) async {
  final odyseeService = ref.watch(odyseeServiceProvider);
  final videoUrl = ref.watch(odyseeUrlProvider);
  return await odyseeService.getVideoStreamUrl(videoUrl);
});

//https://player.odycdn.com/api/v3/streams/free/Smurf---Rescue-in-Gargamel's-Castle---Atar/78b2edb9122b46552833dcf852a71d85591f31b4/9c90e4.mp4
// Provider for video controller (auto-dispose)
final videoControllerProvider = FutureProvider.autoDispose.family<VideoPlayerController, ({String streamUrl, bool autoPlay})>((
  ref,
  params,
) async {
  final controller = VideoPlayerController.networkUrl(
    Uri.parse(
      "https://player.odycdn.com/api/v3/streams/free/Smurf---Rescue-in-Gargamel's-Castle---Atar/78b2edb9122b46552833dcf852a71d85591f31b4/9c90e4.mp4",
    ),
  );

  //TODO DOES CONTROLLER MANAGEMENT WORK WITH THIS PROVIDER AS YOU WILL HAVE VARIOUS CONTROLLERS AT THE SAME TIME?
  //SHOULDNT IT HAVE A SIMILAR DESIGN TO THE YOUTUBE CONTROLLER SETUP?
  //THEN AFTER THAT ONE TRY THE CUPERTINO CONTROLLED PLAYER TO HAVE MORE BEAUTIFUL UI

  // final controller = VideoPlayerController.networkUrl(Uri.parse(params.streamUrl));
  await controller.initialize();
  await controller.setLooping(true);

  if (params.autoPlay) {
    await controller.play();
  }

  ref.onDispose(() {
    controller.dispose();
  });

  return controller;
});
