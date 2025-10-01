import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/scraper/memo_post_scraper.dart';
import 'package:mahakka/provider/popularity_score_cache.dart';

// Provider to track popularity score updates for individual posts
final postPopularityProvider = StateNotifierProvider<PostPopularityNotifier, Map<String, int>>((ref) {
  return PostPopularityNotifier(ref);
});

class PostPopularityNotifier extends StateNotifier<Map<String, int>> {
  final Ref ref;
  final PopularityScoreCache _popularityCache = PopularityScoreCache();

  PostPopularityNotifier(this.ref) : super({});

  Future<void> fetchPopularityScore(String postId) async {
    // Check cache first
    final cachedScore = _popularityCache.get(postId);
    if (cachedScore != null) {
      state = {...state, postId: cachedScore};
      return;
    }

    try {
      final scrapedPost = await MemoPostScraper().fetchAndParsePost(postId, filterOn: false);
      if (scrapedPost != null) {
        _popularityCache.put(postId, scrapedPost.popularityScore);
        state = {...state, postId: scrapedPost.popularityScore};
      }
    } catch (error) {
      print('Error fetching popularity score for post $postId: $error');
    }
  }

  void updatePopularityScore(String postId, int newScore) {
    _popularityCache.put(postId, newScore);
    state = {...state, postId: newScore};
  }

  // Add method to clear expired cache periodically
  void clearExpiredCache() {
    _popularityCache.clearExpired();
  }
}
