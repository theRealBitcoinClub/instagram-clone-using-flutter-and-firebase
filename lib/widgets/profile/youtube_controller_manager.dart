import 'package:flutter/cupertino.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../memo/model/memo_model_post.dart';

class YouTubeControllerManager {
  final Map<String, ValueNotifier<YoutubePlayerController?>> _controllers = {};

  void dispose() {
    for (var notifier in _controllers.values) {
      notifier.value?.pause();
      notifier.value?.dispose();
      notifier.value = null;
      notifier.dispose();
    }
    _controllers.clear();
  }

  void pauseAll() {
    for (var notifier in _controllers.values) {
      notifier.value?.pause();
    }
  }

  void cleanupUnused(List<MemoModelPost> currentVideoPosts) {
    final currentVideoIds = currentVideoPosts.map((post) => post.id).whereType<String>().toSet();
    final controllersToRemove = _controllers.keys.where((id) => !currentVideoIds.contains(id)).toList();

    for (var id in controllersToRemove) {
      final notifier = _controllers.remove(id);
      notifier?.value?.pause();
      notifier?.value?.dispose();
      notifier?.dispose();
    }
  }

  Map<String, ValueNotifier<YoutubePlayerController?>> get controllers => _controllers;
}
