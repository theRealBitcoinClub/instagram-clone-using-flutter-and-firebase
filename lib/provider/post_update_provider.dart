import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to track popularity score updates for individual posts
final postPopularityProvider = StateNotifierProvider<PostPopularityNotifier, Map<String, int>>((ref) {
  return PostPopularityNotifier();
});

class PostPopularityNotifier extends StateNotifier<Map<String, int>> {
  PostPopularityNotifier() : super({});

  // Update the popularity score for a specific post
  void updatePopularityScore(String postId, int newScore) {
    state = {...state, postId: newScore};
  }

  // Get the updated popularity score for a post, or null if not updated
  int? getPopularityScore(String postId) {
    return state[postId];
  }

  // Clear all popularity score updates
  void clearAll() {
    state = {};
  }

  // Remove a specific post's popularity score update
  void removePost(String postId) {
    final newState = {...state};
    newState.remove(postId);
    state = newState;
  }
}
