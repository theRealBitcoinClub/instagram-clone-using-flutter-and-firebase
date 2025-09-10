// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/odysee/video_providers.dart';

import 'odysee_video_player.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Odysee Video Player', theme: ThemeData.dark(), home: const VideoExamplePage());
  }
}

class VideoExamplePage extends ConsumerWidget {
  const VideoExamplePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Odysee Video Player'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh the video
              ref.invalidate(streamUrlProvider);
            },
          ),
        ],
      ),
      body: const Column(
        children: [
          Expanded(
            child: OdyseeVideoPlayer(
              autoPlay: true,
              aspectRatio: 16 / 9,
              loadingWidget: Center(child: CircularProgressIndicator()),
              errorWidget: Center(child: Text('Failed to load video')),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Hijacking Bitcoin - BitcoinMap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
